// CVSDMImageSnapshotQueue.h
// CVSDrawingModel
// Created by justin carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

typedef void(^CVSDMImageSnapshotQueueAsyncIOTask)(void);

/**
 @brief completion closure.
 */
typedef void (^CVSDMImageSnapshotQueueCompletionClosure)(void);

/**
 @brief initiation block containing completion closure.
 */
typedef CVSDMImageSnapshotQueueCompletionClosure (^CVSDMImageSnapshotQueueInitiationBlock)(void);


/**
 @brief constant defines a number which represents the non-snapshot value.
 */
extern const uint32_t CVSDMImageSnapshot_NonSnapshotStrokeCount;

/**
 @class defines a snapshot queue
 @details note that this is a temporary V2 compatibility implementation. the destination, persistence, and abiity to simply swap bitmap store references does not currently exist, but they would be good additions.
 */
@interface CVSDMImageSnapshotQueue : NSObject

/**
 @brief initializes self to support bitmaps of the specified size for import and export. the queue uses one buffer for all import and export operations.
 */
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue bitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions;

/**
 @return the dimensions of the bitmap buffer.
 */
- (CVSDMBitmapDimensions)bitmapDimensions;

/**
 @brief invalidates all temporary images
 */
- (void)invalidateAllTemporaryImages;

/**
 @brief requests the snapshot create a snapshot of @p pBitmapReference with an associated stroke count of @p pCurrentStrokeCount.
 @details the queue uses one buffer. if the request would block, then the request may not be honored. otherwise, the time complexity is equivalent to the time required to copy.
 */
- (void)enqueueSnapshotForStrokeCount:(NSUInteger)pCurrentStrokeCount bitmapReference:(CVSDMEditorBitmapStoreReference *)pBitmapReference;

/**
 @brief the mechanism to invalidate snapshots
 */
- (void)invalidateSnapshotsWithCountsGreaterThan:(NSUInteger)pCurrentStrokeCount;

/**
 @brief performs a SYNCHRONOUS load of the latest snapshot.
 @p pBitmapReference the destination bitmap to write to
 @return the stroke count of the snapshot which was written. if 0 is returned, the snapshot was not written, and you probably want to clear the destination.
 @details the import was wrapped up quickly to jump to new features. this was never intended to be a blocking design.
 */
- (NSUInteger)loadMostRecentSnapshot:(CVSDMEditorBitmapStoreReference *)pDestinationBitmapReference outIsImporting:(BOOL*)pOutIsImporting initiationBlock:(CVSDMImageSnapshotQueueInitiationBlock)pInitiationBlock;

@end


extern bool CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0(void);
