// CVSDMImageSnapshotQueueBitmap.h
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

@class CVSDMImageSnapshot;
@class CVSDMMutableBitmap;

/**
 @brief this is the temporary buffer used by the CVSDMImageSnapshotQueue
 */
@interface CVSDMImageSnapshotQueueBitmap : NSObject

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue bitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions;

- (CVSDMBitmapDimensions)bitmapDimensions;

/**
 @brief the bitmap records the snapshot it references. use this method to invalidate that reference.
 */
- (void)snapshotsWereInvalidated:(NSArray *)pSnapshots activeSnapshots:(NSArray *)pRemainingSnapshots;

/**
 @brief attempts to add an async non-blocking import request.
 */
- (void)attemptToImportSnapshot:(CVSDMImageSnapshot *)pSnapshot initiationBlock:(CVSDMImageSnapshotQueueInitiationBlock)pInitiationBlock outIsCurrentSnapshot:(BOOL*)pOutIsCurrentSnapshot;

/**
 @brief creates and returns a snapshot with an async file export -- but only if the operation would not block the calling thread.
 @p pBitmapReference the bitmap data source. if the operation commences, the bitmap data is copied from the source to self's buffer.
 @p pParentDirectoryURL the parent directory URL to save the bitmap data to. a temporary placeholder file with a unique name is created in this directory. the placeholder file is replaced during export. the file is deleted when the returned snapshot is deallocated.
 @p pImageSnapshotQueue the snapshot queue to associate with the new snapshot. a required CVSDMImageSnapshot initialization parameter.
 @p pImageSnapshotIndex the snapshot index -- bookkeeping identifier used by the queue. a required CVSDMImageSnapshot initialization parameter.
 @return nil if the operation would block. otherwise, a snapshot which has initiated an async export of the bitmap data.
 */
- (CVSDMImageSnapshot *)nonBlockingAttemptToCreateSnapshotUsingBitmapReferencesData:(CVSDMEditorBitmapStoreReference *)pBitmapReference
                                                                 parentDirectoryURL:(NSURL *)pParentDirectoryURL
                                                                 imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
                                                                 imageSnapshotIndex:(CVSDMImageSnapshotIndex)pImageSnapshotIndex;

/**
 @brief copies the current bitmap from self to @p pDestinationBitmapReference
 @return the snapshot self represents, or nil if self does not represent a snapshot or cannot fulfill the request without blocking for I/O.
 */
- (CVSDMImageSnapshot *)copyBitmapDataTo:(CVSDMEditorBitmapStoreReference *)pDestinationBitmapReference outIsImporting:(BOOL*)pOutIsImporting initiationBlock:(CVSDMImageSnapshotQueueInitiationBlock)pInitiationBlock;

@end

@interface CVSDMImageSnapshotQueueBitmap (UnitTest)
/**
 @brief this is for unit tests -- do not use this in production code
 @details until successful, repreatedly calls -nonBlockingAttemptToCreateSnapshotUsingBitmapReferencesData:parentDirectoryURL:imageSnapshotQueue:imageSnapshotIndex:
 */
- (CVSDMImageSnapshot *)BLOCKING_UnitTest_createSnapshotUsingBitmapReferencesData:(CVSDMEditorBitmapStoreReference *)pBitmapReference
                                                               parentDirectoryURL:(NSURL *)pParentDirectoryURL
                                                               imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
                                                               imageSnapshotIndex:(CVSDMImageSnapshotIndex)pImageSnapshotIndex;

@end

// these are HACKs which should not be present after 3.0.0
@interface CVSDMImageSnapshotQueueBitmap (NotSoSlowIn300)

// these are HACKs which should not be present after 3.0.0
- (void)notSoSlowIn300_setContentTo:(CVSDMEditorBitmapStoreReference *)pBitmapReference;
// these are HACKs which should not be present after 3.0.0
- (void)notSoSlowIn300_writeContentsTo:(CVSDMEditorBitmapStoreReference *)pBitmapReference;

@end
