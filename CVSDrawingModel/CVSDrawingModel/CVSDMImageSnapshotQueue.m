// CVSDMImageSnapshotQueue.m
// CVSDrawingModel
// Created by justin carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"
#import "Private/CVSDMImageSnapshot.h"
#import "Private/CVSDMImageSnapshotQueueBitmap.h"
#import "Private/CVSDMImageSnapshotQueue-Private_CVSDMImageSnapshot.h"

const uint32_t CVSDMImageSnapshot_NonSnapshotStrokeCount = 0;

/* the minimum number of strokes to accumulate before a snapshot is saved. */
static const NSInteger NStrokesPerSnapshot = 20;

// this is to avoid a slowness bug in DQ 3.0.0. it disables fs caching, and should not be present after 3.0.0
bool CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0(void) {return true;}
// this is to avoid a slowness bug in DQ 3.0.0. it disables fs caching, and should not be present after 3.0.0
static const NSInteger NStrokesPerSnapshot_ForHack_NotSoSlowIn3_0_0 = 30;

@interface CVSDMImageSnapshotQueue ()

/* CVSDMImageSnapshot[] */
@property (nonatomic, strong, readwrite) NSMutableArray * snapshots;
@property (nonatomic, strong, readwrite) NSLock * snapshotsLock;

@property (nonatomic, strong, readwrite) CVSDMFileSystemIOQueue * fileSystemIOQueue;
@property (nonatomic, readonly) CVSDMTemporaryDirectory * temporaryDirectory;
@property (nonatomic, readonly) CVSDMImageSnapshotQueueBitmap * imageSnapshotQueueBitmap;
// this is to avoid a slowness bug in DQ 3.0.0. it disables I/O, and should not be present after 3.0.0
@property (nonatomic, assign, readwrite) NSUInteger inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0;

@end

@implementation CVSDMImageSnapshotQueue

@synthesize snapshots = _snapshots;
@synthesize snapshotsLock = _snapshotsLock;
@synthesize fileSystemIOQueue = _fileSystemIOQueue;
@synthesize temporaryDirectory = _temporaryDirectory;
@synthesize imageSnapshotQueueBitmap = _imageSnapshotQueueBitmap;

// this is to avoid a slowness bug in DQ 3.0.0. it disables I/O, and should not be present after 3.0.0
@synthesize inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0 = _inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0;

- (id)init
{
    assert(0 && "invalid initializer for type");
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue bitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions
{
    self = [super init];
    if (!self) {
        assert(0 && "init error");
        return nil;
    }

    _temporaryDirectory = [CVSDMTemporaryDirectory temporaryDirectoryWithFileSystemIOQueue:pFileSystemIOQueue removalOption:CVSDMTemporaryResourceRemovalOption_Remove];
    _snapshots = [NSMutableArray new];
    _snapshotsLock = [NSLock new];
    _fileSystemIOQueue = pFileSystemIOQueue;
    _imageSnapshotQueueBitmap = [[CVSDMImageSnapshotQueueBitmap alloc] initWithFileSystemIOQueue:pFileSystemIOQueue bitmapDimensions:pBitmapDimensions];

    if (!_temporaryDirectory || !_snapshots || !_snapshotsLock || !_fileSystemIOQueue || !_imageSnapshotQueueBitmap) {
        assert(0 && "error creating image snapshot queue");
        return nil;
    }
    return self;
}

- (void)dealloc
{
    @autoreleasepool {
        [self invalidateAllTemporaryImages];
        _snapshots = nil;
        _snapshotsLock = nil;
        _imageSnapshotQueueBitmap = nil;
        _temporaryDirectory = nil;
        _fileSystemIOQueue = nil;
    }
}

- (CVSDMBitmapDimensions)bitmapDimensions
{
    return self.imageSnapshotQueueBitmap.bitmapDimensions;
}

- (void)invalidateAllTemporaryImages
{
    CVSDMLockingBlock_NSLocking(self.snapshotsLock, ^{
        @autoreleasepool {
            if (self.snapshots.count) {
                NSArray * const removed = self.snapshots.copy;
                [self.snapshots removeAllObjects];
                [self.imageSnapshotQueueBitmap snapshotsWereInvalidated:removed activeSnapshots:self.snapshots];
            }
        }
    });
}

// caller must lock
- (void)popStrokesGreaterThanOrEqualTo_unlocked:(NSUInteger)pCurrentStrokeCount
{

    // 3.0.0 HACK ALERT
    if (CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0()) {
        if (self.inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0 >= pCurrentStrokeCount) {
            self.inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0 = CVSDMImageSnapshot_NonSnapshotStrokeCount;
        }
        return;
    }
    else {
        // pop the old snapshots
        NSMutableArray * remove = [NSMutableArray new];
        for (CVSDMImageSnapshot * at in self.snapshots) {
            if (pCurrentStrokeCount <= at.imageSnapshotIndex) {
                [remove addObject:at];
            }
        }
        if (remove.count) {
            @autoreleasepool {
                // NSLog(@"Pre Pop | %i: %@", (int)pCurrentStrokeCount, self.snapshots);
                // NSLog(@"Removing: %@", remove);
                [self.snapshots removeObjectsInArray:remove];
                [self.imageSnapshotQueueBitmap snapshotsWereInvalidated:remove activeSnapshots:self.snapshots];
                // NSLog(@"Post Pop: %@", self.snapshots);
            }
        }
    }
}

- (void)invalidateSnapshotsWithCountsGreaterThan:(NSUInteger)pCurrentStrokeCount
{
    CVSDMLockingBlock_NSLocking(self.snapshotsLock, ^{
        [self popStrokesGreaterThanOrEqualTo_unlocked:1U + pCurrentStrokeCount];
    });
}

- (void)enqueueSnapshotForStrokeCount:(NSUInteger)pCurrentStrokeCount bitmapReference:(CVSDMEditorBitmapStoreReference *)pBitmapReference
{
    // 3.0.0 HACK ALERT
    if (CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0()) {
        assert(self.inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0 < pCurrentStrokeCount);

        const NSUInteger present = self.inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0 / NStrokesPerSnapshot_ForHack_NotSoSlowIn3_0_0;
        const NSUInteger next = pCurrentStrokeCount / NStrokesPerSnapshot_ForHack_NotSoSlowIn3_0_0;

        if (present == next) {
            return;
        }

        [self.imageSnapshotQueueBitmap notSoSlowIn300_setContentTo:pBitmapReference];
        self.inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0 = pCurrentStrokeCount;
        return;
    }
    else {
        assert(pBitmapReference);
        CVSDMLockingBlock_NSLocking(self.snapshotsLock, ^{
            const CVSDMImageSnapshotIndex snapshotIndex = (CVSDMImageSnapshotIndex)pCurrentStrokeCount;
            const NSInteger currentStrokeCount = (NSInteger)pCurrentStrokeCount;
            [self popStrokesGreaterThanOrEqualTo_unlocked:pCurrentStrokeCount];
            // determine the current stroke count
            NSInteger strokeCountOfLastSnapshot = CVSDMImageSnapshot_NonSnapshotStrokeCount;
            CVSDMImageSnapshot * const last = self.snapshots.lastObject;
            if (last) {
                strokeCountOfLastSnapshot = (NSInteger)last.imageSnapshotIndex;
            }

            assert(strokeCountOfLastSnapshot <= currentStrokeCount);
            const NSInteger nStrokesSinceLastSnapshot = currentStrokeCount - strokeCountOfLastSnapshot;
            if (NStrokesPerSnapshot > nStrokesSinceLastSnapshot) {
                // don't bother recording a snapshot which is so recent
                return;
            }

            {
                // make room for the next snapshot -- this must happen prior to creation
                const uint32_t MaxCacheMB = 200;
                const uint32_t MBPerSnapshot = 12;
                // GitHub ISSUE #338 -- the cache should rebuild itself if many undo actions have occurred
                const NSUInteger MaxSnapshots = MaxCacheMB/MBPerSnapshot;
                const NSUInteger nSnapshots = self.snapshots.count;
                assert(MaxSnapshots >= nSnapshots);

                if (MaxSnapshots == nSnapshots) {
                    // leave the latest close by. although it is naive, it will balance out pretty well in typical usage.
                    const NSUInteger i = arc4random_uniform((uint32_t)(MaxSnapshots - 3U));
                    NSArray * const removed = [NSArray arrayWithObject:self.snapshots[i]];
                    [self.snapshots removeObjectAtIndex:i];
                    [self.imageSnapshotQueueBitmap snapshotsWereInvalidated:removed activeSnapshots:self.snapshots];
                }
            }

            // create and record the snapshot
            CVSDMImageSnapshot * const snapshot = [self.imageSnapshotQueueBitmap nonBlockingAttemptToCreateSnapshotUsingBitmapReferencesData:pBitmapReference
                                                                                                                          parentDirectoryURL:self.temporaryDirectory.URL
                                                                                                                          imageSnapshotQueue:self
                                                                                                                          imageSnapshotIndex:snapshotIndex];

            if (nil == snapshot) {
                // nil indicates the operation would block (e.g. the shared I/O bitmap buffer is presently in use by another task)
                return;
            }

            [self.snapshots addObject:snapshot];
            // NSLog(@"Post Enqueue: %@", self.snapshots);
        });
    }
}

- (NSUInteger)loadMostRecentSnapshot:(CVSDMEditorBitmapStoreReference *)pDestinationBitmapReference outIsImporting:(BOOL*)pOutIsImporting initiationBlock:(CVSDMImageSnapshotQueueInitiationBlock)pInitiationBlock
{
    assert(pDestinationBitmapReference);
    assert(pInitiationBlock);
    assert(pOutIsImporting);
    assert(NO == *pOutIsImporting);

    // 3.0.0 HACK ALERT
    if (CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0()) {
        *pOutIsImporting = NO;
        [self.imageSnapshotQueueBitmap notSoSlowIn300_writeContentsTo:pDestinationBitmapReference];
        return self.inMemorySnapshotIndex_ForHack_NotSoSlowIn3_0_0;
    }
    else {


        __block NSUInteger snapshotIndex = CVSDMImageSnapshot_NonSnapshotStrokeCount;
        __block bool isEmpty = false;
        // need to retry if the snapshot state changes
        while (CVSDMImageSnapshot_NonSnapshotStrokeCount == snapshotIndex && NO == *pOutIsImporting && !isEmpty) {
            CVSDMLockingBlock_NSLocking(self.snapshotsLock, ^{
                if (0 == self.snapshots.count) {
                    isEmpty = true;
                    return;
                }
                {
                    // read the snapshot which is in memory, if possible
                    CVSDMImageSnapshot * const snapshotInMemory = [self.imageSnapshotQueueBitmap copyBitmapDataTo:pDestinationBitmapReference outIsImporting:pOutIsImporting initiationBlock:pInitiationBlock];
                    if (nil != snapshotInMemory) {
                        assert(NO == *pOutIsImporting);
                        assert([self.snapshots containsObject:snapshotInMemory]);
                        snapshotIndex = snapshotInMemory.imageSnapshotIndex;
                        return;
                    }
                }
                if (*pOutIsImporting) {
                    return;
                }
                BOOL outIsCurrentSnapshot = NO;
                [self.imageSnapshotQueueBitmap attemptToImportSnapshot:self.snapshots.lastObject initiationBlock:pInitiationBlock outIsCurrentSnapshot:&outIsCurrentSnapshot];
                if (!outIsCurrentSnapshot) {
                    *pOutIsImporting = YES;
                }
            });
        }
        return snapshotIndex;
    }
}

@end

@implementation CVSDMImageSnapshotQueue (Private_CVSDMImageSnapshot)

- (void)dispatch:(CVSDMImageSnapshotQueueAsyncIOTask)pAsyncIOTask
{
    assert(pAsyncIOTask);
    [self.fileSystemIOQueue dispatch:pAsyncIOTask];
}

@end
