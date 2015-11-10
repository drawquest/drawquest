// CVSDMFileSystemIOQueue.h
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief a block for a I/O task. this task is performed on the I/O queue's dispatch queue.
 */
typedef void(^CVSDMFileSystemIOQueueTask)(void);

/**
 @brief a block for an I/O task closure. the closure is performed on the I/O queue's dispatch queue after the task has completed.
 */
typedef void(^CVSDMFileSystemIOQueueClosure)(void);

/**
 @class an interface for a named I/O queues, used for filesystem operations.
 @details the class defines a one named serial dispatch queue (FIFO) and one named concurrent dispatch queue.
 */
@interface CVSDMFileSystemIOQueue : NSObject

/**
 @return a new instance which dispatches using serial (or FIFO) dispatch.
 */
- (instancetype)initSerialQueue;
+ (instancetype)serialQueue;

/**
 @return a new instance which dispatches using concurrent dispatch.
 */
- (instancetype)initConcurrentQueue;
+ (instancetype)concurrentQueue;

/**
 @brief adds the I/O task @p pTask to the queue, to be performed asynchronously. the block is copied.
 */
- (void)dispatch:(CVSDMFileSystemIOQueueTask)pTask;

///// Convenience Methods /////

- (void)removeItemAtURL:(NSURL *)pURL;

@end
