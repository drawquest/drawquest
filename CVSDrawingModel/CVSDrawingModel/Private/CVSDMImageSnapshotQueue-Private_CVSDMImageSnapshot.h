// CVSDMImageSnapshotQueue-Private_CVSDMImageSnapshot.h
// CVSDrawingModel
// Created by justin carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief private APIs -- should be available only to CVSDMImageSnapshots
 */
@interface CVSDMImageSnapshotQueue (Private_CVSDMImageSnapshot)

/**
 @brief adds the async I/O task to the queue.
 */
- (void)dispatch:(CVSDMImageSnapshotQueueAsyncIOTask)pAsyncIOTask;

@end
