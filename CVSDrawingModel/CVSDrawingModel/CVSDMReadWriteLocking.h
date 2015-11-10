// CVSDMReadWriteLocking.h
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @protocol the base interface for a type which supports read/write locking
 @details tip: use the block functions below, rather than acquiring the lock manually
 */
@protocol CVSDMReadWriteLocking <NSObject>
@required
// these all return YES for success, else NO.
- (BOOL)rwlock_acquireReadLock;
- (BOOL)rwlock_tryReadLock;

- (BOOL)rwlock_acquireWriteLock;
- (BOOL)rwlock_tryWriteLock;

- (BOOL)rwlock_unlock;

@end

/**
 @brief defines the type of block to pass for the task to perform while locked.
 */
typedef void(^CVSDMReadWriteLockingTask)(void);

/**
 @brief executes the block while the read lock is acquired. if an error is encountered unlocking, the behavior is undefined.
 */
extern void CVSDMReadWriteLocking_Read(id<CVSDMReadWriteLocking> pObject, CVSDMReadWriteLockingTask pBlock);

/**
 @brief executes the block while the write lock is acquired. if an error is encountered unlocking, the behavior is undefined.
 */
extern void CVSDMReadWriteLocking_Write(id<CVSDMReadWriteLocking> pObject, CVSDMReadWriteLockingTask pBlock);

/**
 @protocol type that provides a read/write lock.
 @details tip: use the block functions below, rather than acquiring the lock manually
 */
@protocol CVSDMReadWriteLockProvider <NSObject>
@required
// never return nil
- (id<CVSDMReadWriteLocking>)readWriteLock;
@end

/**
 @brief executes the block while the read lock is acquired. if an error is encountered unlocking, the behavior is undefined.
 */
extern void CVSDMReadWriteLocking_ReadWriteLockProvider_Read(id<CVSDMReadWriteLockProvider> pObject, CVSDMReadWriteLockingTask pBlock);

/**
 @brief executes the block while the write lock is acquired. if an error is encountered unlocking, the behavior is undefined.
 */
extern void CVSDMReadWriteLocking_ReadWriteLockProvider_Write(id<CVSDMReadWriteLockProvider> pObject, CVSDMReadWriteLockingTask pBlock);
