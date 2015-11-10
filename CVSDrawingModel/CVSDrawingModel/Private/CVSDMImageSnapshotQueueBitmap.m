// CVSDMImageSnapshotQueueBitmap.m
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"
#import "CVSDMImageSnapshot.h"
#import "CVSDMImageSnapshotQueueBitmap.h"

typedef NS_ENUM(uint8_t, CVSDMImageSnapshotQueueActiveBufferStatus) {
    /**
     @constant do not use
     */
    CVSDMImageSnapshotQueueActiveBufferStatus_Undefined = 0,
    /**
     @constant the buffer is not currently being used (although it may represent a valid snapshot)
     */
    CVSDMImageSnapshotQueueActiveBufferStatus_Idle,
    /**
     @constant the buffer is currently being use for a bitmap transaction
     */
    CVSDMImageSnapshotQueueActiveBufferStatus_BitmapTransaction,
    /**
     @constant the buffer is currently being used for an import/read
     */
    CVSDMImageSnapshotQueueActiveBufferStatus_Importing,
    /**
     @constant the buffer is currently being used for an export/write
     */
    CVSDMImageSnapshotQueueActiveBufferStatus_Exporting
};

@interface CVSDMImageSnapshotQueueBitmap ()

@property (nonatomic, readonly) NSLock * lock;
@property (nonatomic, readonly) CVSDMMutableBitmap * bitmap;
@property (nonatomic, assign, readwrite) CVSDMImageSnapshotQueueActiveBufferStatus activeBufferStatus;
@property (nonatomic, readonly) CVSDMFileSystemIOQueue * fileSystemIOQueue;
@property (nonatomic, strong, readwrite) CVSDMImageSnapshot * snapshotInMemory;
@property (nonatomic, readonly) NSMutableArray * importCompletions;

@end

@implementation CVSDMImageSnapshotQueueBitmap

@synthesize activeBufferStatus = _activeBufferStatus;
@synthesize bitmap = _bitmap;
@synthesize lock = _lock;
@synthesize fileSystemIOQueue = _fileSystemIOQueue;
@synthesize snapshotInMemory = _snapshotInMemory;
@synthesize importCompletions = _importCompletions;

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue bitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _lock = [NSLock new];
    _bitmap = [[CVSDMMutableBitmap alloc] initWithBitmapDimensions:pBitmapDimensions];
    _fileSystemIOQueue = pFileSystemIOQueue;
    _importCompletions = [NSMutableArray new];

    if (!_lock || !_bitmap || !_fileSystemIOQueue) {
        assert(0 && "initialization failed");
        return nil;
    }
    _activeBufferStatus = CVSDMImageSnapshotQueueActiveBufferStatus_Idle;
    return self;
}

- (void)dealloc
{
    @autoreleasepool {
        _bitmap = nil;
        _lock = nil;
    }
}

- (CVSDMBitmapDimensions)bitmapDimensions
{
    return self.bitmap.bitmapDimensions;
}

- (void)attemptToImportSnapshot:(CVSDMImageSnapshot *)pSnapshot initiationBlock:(CVSDMImageSnapshotQueueInitiationBlock)pInitiationBlock outIsCurrentSnapshot:(BOOL*)pOutIsCurrentSnapshot
{
    assert(pSnapshot);
    assert(pInitiationBlock);
    assert(!*pOutIsCurrentSnapshot);
    __block bool ioInProgress = false;
    CVSDMLockingBlock_NSLocking(self.lock, ^{
        if (self.snapshotInMemory == pSnapshot) {
            *pOutIsCurrentSnapshot = YES;
            return;
        }
        // [self.importCompletions addObject:[pInitiationBlock() copy]];
        switch (self.activeBufferStatus) {
            case CVSDMImageSnapshotQueueActiveBufferStatus_Importing :
            case CVSDMImageSnapshotQueueActiveBufferStatus_Exporting :
                ioInProgress = true;
                return;
            case CVSDMImageSnapshotQueueActiveBufferStatus_BitmapTransaction :
                return;
            case CVSDMImageSnapshotQueueActiveBufferStatus_Idle : {
                [self performStatusChangeFrom_noLock:CVSDMImageSnapshotQueueActiveBufferStatus_Idle to:CVSDMImageSnapshotQueueActiveBufferStatus_Importing];
                [self.importCompletions addObject:[pInitiationBlock() copy]];
                return;
            }
            case CVSDMImageSnapshotQueueActiveBufferStatus_Undefined :
                break;
        }
        assert(0 && "invalid enum");
    });
    if (*pOutIsCurrentSnapshot) {
        return;
    }
    if (ioInProgress) {
        return;
    }
    [self.fileSystemIOQueue dispatch:^{
        CVSDMLockingBlock_NSLocking(self.lock, ^{
            assert(self.activeBufferStatus == CVSDMImageSnapshotQueueActiveBufferStatus_Importing);
            if (!pSnapshot.isDataReferenceAccessible) {
                assert(0 && "should not happen -- this is a serial I/O queue");
                return;
            }
            CVSDMImmutableDataReference * const data = pSnapshot.dataReference;
            [self.bitmap writeBitmapContents:data];
            self.snapshotInMemory = pSnapshot;
            [self performStatusChangeFrom_noLock:CVSDMImageSnapshotQueueActiveBufferStatus_Importing to:CVSDMImageSnapshotQueueActiveBufferStatus_Idle];
            if (self.importCompletions.count) {
                NSArray * const closures = self.importCompletions.copy;
                [self.importCompletions removeAllObjects];
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (void(^at)(void) in closures) {
                        at();
                    }
                });
            }
        });
    }];
}

- (void)snapshotsWereInvalidated:(NSArray *)pSnapshots activeSnapshots:(NSArray *)pRemainingSnapshots
{
    assert(pSnapshots);
    assert(pSnapshots.count);
    assert(pRemainingSnapshots);
    __block CVSDMImageSnapshot * snapshotToImport = nil;
    CVSDMLockingBlock_NSLocking(self.lock, ^{
        if (nil != self.snapshotInMemory && [pSnapshots containsObject:self.snapshotInMemory]) {
            self.snapshotInMemory = nil;
        }
        if (nil != self.snapshotInMemory) {
            assert([pRemainingSnapshots containsObject:self.snapshotInMemory]);
        }
        if (nil == self.snapshotInMemory && pRemainingSnapshots.count && (self.activeBufferStatus != CVSDMImageSnapshotQueueActiveBufferStatus_Importing)) {
            snapshotToImport = pRemainingSnapshots.lastObject;
        }
    });
    if (snapshotToImport) {
        BOOL outIsCurrentSnapshot = NO;
        [self attemptToImportSnapshot:snapshotToImport initiationBlock:^{return ^{};} outIsCurrentSnapshot:&outIsCurrentSnapshot];
    }
}

- (void)performStatusChangeFrom_noLock:(CVSDMImageSnapshotQueueActiveBufferStatus)pStatusAtEntry to:(CVSDMImageSnapshotQueueActiveBufferStatus)pStatusAtExit
{
    if (pStatusAtEntry != self.activeBufferStatus) {
        assert(0 && "synchronization error");
    }
    self.activeBufferStatus = pStatusAtExit;
}


- (void)performStatusChangeFrom_lock:(CVSDMImageSnapshotQueueActiveBufferStatus)pStatusAtEntry to:(CVSDMImageSnapshotQueueActiveBufferStatus)pStatusAtExit
{
    assert(pStatusAtEntry != pStatusAtExit);
    CVSDMLockingBlock_NSLocking(self.lock, ^{
        [self performStatusChangeFrom_noLock:pStatusAtEntry to:pStatusAtExit];
    });
}

- (CVSDMFileExportDestinationExportClosure)closure_performStatusChangeFrom:(CVSDMImageSnapshotQueueActiveBufferStatus)pStatusAtEntry to:(CVSDMImageSnapshotQueueActiveBufferStatus)pStatusAtExit
{
    CVSDMFileExportDestinationExportClosure closure = ^{[self performStatusChangeFrom_lock:pStatusAtEntry to:pStatusAtExit];};
    assert(closure);
    CVSDMFileExportDestinationExportClosure copy = [closure copy];
    assert(copy);
    return copy;
}

- (CVSDMImageSnapshot *)nonBlockingAttemptToCreateSnapshotUsingBitmapReferencesData:(CVSDMEditorBitmapStoreReference *)pBitmapReference
                                                                 parentDirectoryURL:(NSURL *)pParentDirectoryURL
                                                                 imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
                                                                 imageSnapshotIndex:(CVSDMImageSnapshotIndex)pImageSnapshotIndex
{
	assert(pBitmapReference);
    assert(pParentDirectoryURL);
    assert(pImageSnapshotQueue);

    assert([pBitmapReference areDimensionsEqualTo:self.bitmap] && "the implementation requires equal bitmap dimensions");

    __block CVSDMImageSnapshot * snapshot = nil;
    const bool didExecuteBlock = CVSDMLockingBlock_NSLockingWithTryLock(self.lock, ^{
        switch (self.activeBufferStatus) {
            case CVSDMImageSnapshotQueueActiveBufferStatus_Importing :
            case CVSDMImageSnapshotQueueActiveBufferStatus_Exporting :
            case CVSDMImageSnapshotQueueActiveBufferStatus_BitmapTransaction :
                // do not block in these cases
                return;

            case CVSDMImageSnapshotQueueActiveBufferStatus_Idle : {
                // commence export
                self.activeBufferStatus = CVSDMImageSnapshotQueueActiveBufferStatus_Exporting;
                // invalidate data
                self.snapshotInMemory = nil;
                // copy the input bitmap to our local buffer
                [pBitmapReference copyBitmapTo:self.bitmap];

                // create the post file export closure
                CVSDMFileExportDestinationExportClosure closure = [self closure_performStatusChangeFrom:CVSDMImageSnapshotQueueActiveBufferStatus_Exporting to:CVSDMImageSnapshotQueueActiveBufferStatus_Idle];
                assert(closure);

                id<CVSDMFileExportDestinationDataProvider> dataProvider = self.bitmap;
                assert(dataProvider);

                snapshot = [[CVSDMImageSnapshot alloc] initWithFileSystemIOQueue:self.fileSystemIOQueue
                                                              parentDirectoryURL:pParentDirectoryURL
                                                              imageSnapshotQueue:pImageSnapshotQueue
                                                              imageSnapshotIndex:pImageSnapshotIndex
                                                                    dataProvider:dataProvider
                                                                   exportClosure:closure];
                assert(snapshot);
                self.snapshotInMemory = snapshot;
                return;
            }
            case CVSDMImageSnapshotQueueActiveBufferStatus_Undefined :
                break;
        }
        assert(0 && "undefined active buffer status");
    });
#pragma unused(didExecuteBlock)
    // may be nil if would block
    return snapshot;
}

- (CVSDMImageSnapshot *)copyBitmapDataTo:(CVSDMEditorBitmapStoreReference *)pDestinationBitmapReference outIsImporting:(BOOL*)pOutIsImporting initiationBlock:(CVSDMImageSnapshotQueueInitiationBlock)pInitiationBlock
{
    assert(pOutIsImporting);
    assert(!*pOutIsImporting);
    assert([pDestinationBitmapReference areDimensionsEqualTo:self.bitmap] && "the implementation requires equal bitmap dimensions");

    __block CVSDMImageSnapshot * snapshot = nil;
    CVSDMLockingBlock_NSLocking(self.lock, ^{
        if (!self.snapshotInMemory) {
            return;
        }
        switch (self.activeBufferStatus) {
            case CVSDMImageSnapshotQueueActiveBufferStatus_Importing :
                // do not block in this case
                assert(pOutIsImporting);
                *pOutIsImporting = YES;
                [self.importCompletions addObject:[pInitiationBlock() copy]];
                return;

            case CVSDMImageSnapshotQueueActiveBufferStatus_Exporting :
            case CVSDMImageSnapshotQueueActiveBufferStatus_BitmapTransaction :
            case CVSDMImageSnapshotQueueActiveBufferStatus_Idle : {
                // copy to the output bitmap from our local buffer
                [pDestinationBitmapReference copyBitmapFrom:self.bitmap];

                snapshot = self.snapshotInMemory;
                assert(snapshot);
                return;
            }
            case CVSDMImageSnapshotQueueActiveBufferStatus_Undefined :
                break;
        }
        assert(0 && "undefined active buffer status");
    });

    // may be nil if would block
    return snapshot;
}

@end


@implementation CVSDMImageSnapshotQueueBitmap (UnitTest)

- (CVSDMImageSnapshot *)BLOCKING_UnitTest_createSnapshotUsingBitmapReferencesData:(CVSDMEditorBitmapStoreReference *)pBitmapReference
                                                               parentDirectoryURL:(NSURL *)pParentDirectoryURL
                                                               imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
                                                               imageSnapshotIndex:(CVSDMImageSnapshotIndex)pImageSnapshotIndex
{
    CVSDMImageSnapshot * snapshot = nil;
    while (nil == snapshot) {
        snapshot = [self nonBlockingAttemptToCreateSnapshotUsingBitmapReferencesData:pBitmapReference
                                                                  parentDirectoryURL:pParentDirectoryURL
                                                                  imageSnapshotQueue:pImageSnapshotQueue
                                                                  imageSnapshotIndex:pImageSnapshotIndex];
        if (nil == snapshot) {
            usleep(1000000);
        }
    }
    return snapshot;
}

@end

@implementation CVSDMImageSnapshotQueueBitmap (NotSoSlowIn300)

// these are HACKs which should not be present after 3.0.0
- (void)notSoSlowIn300_setContentTo:(CVSDMEditorBitmapStoreReference *)pBitmapReference
{
    // NSLog(@"write memsnap");
    [pBitmapReference copyBitmapTo:self.bitmap];
}

// these are HACKs which should not be present after 3.0.0
- (void)notSoSlowIn300_writeContentsTo:(CVSDMEditorBitmapStoreReference *)pBitmapReference
{
    // NSLog(@"read memsnap");
    [pBitmapReference copyBitmapFrom:self.bitmap];
}

@end
