// CVSDMLockingBlock.h
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief simply identifies NSLocking type which also provides -tryLock
 */
@protocol CVSDM_NSLockingWithTryLock <NSLocking>
@required
- (BOOL)tryLock;
@end

@interface NSLock (CVSDM_NSLockingWithTryLock) <CVSDM_NSLockingWithTryLock>
@end
@interface NSConditionLock (CVSDM_NSLockingWithTryLock) <CVSDM_NSLockingWithTryLock>
@end
@interface NSRecursiveLock (CVSDM_NSLockingWithTryLock) <CVSDM_NSLockingWithTryLock>
@end


/**
 @brief defines the type of block to pass for the task to perform while locked.
 */
typedef void(^CVSDMLockingBlockTask)(void);

/**
 @brief executes the block while the lock is acquired. if an error is encountered unlocking, the behavior is undefined.
 */
extern void CVSDMLockingBlock_NSLocking(id<NSLocking> pLock, CVSDMLockingBlockTask pBlock);

/**
 @brief executes the block while the lock is acquired, unless it would block. if an error is encountered unlocking, the behavior is undefined.
 @return true if @p pBlock was executed. false if it would block.
 */
extern bool CVSDMLockingBlock_NSLockingWithTryLock(id<CVSDM_NSLockingWithTryLock> pLock, CVSDMLockingBlockTask pBlock) __attribute__((__warn_unused_result__));
