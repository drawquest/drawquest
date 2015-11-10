// CVSDMReadWriteLock.m
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <pthread.h>
#import "CVSDrawingModel.h"

static bool Check(const int pError) {
    if (0 == pError) {
        return true;
    }
    assert(0 && "unhandled error encountered in rwlock");
    return false;
}

@implementation CVSDMReadWriteLock
{
    pthread_rwlock_t lock;
    bool didInit;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    lock = (pthread_rwlock_t)PTHREAD_RWLOCK_INITIALIZER;
    if (!Check(pthread_rwlock_init(&lock, NULL))) {
        assert(0 && "failed to init rwlock");
        return nil;
    }
    didInit = true;
    return self;
}

- (void)dealloc
{
    if (didInit) {
        Check(pthread_rwlock_destroy(&lock));
    }
}

#pragma mark - <CVSDMReadWriteLocking>

- (BOOL)rwlock_acquireReadLock
{
    return Check(pthread_rwlock_rdlock(&lock));
}

- (BOOL)rwlock_tryReadLock
{
    return Check(pthread_rwlock_tryrdlock(&lock));
}

- (BOOL)rwlock_acquireWriteLock
{
    return Check(pthread_rwlock_wrlock(&lock));
}

- (BOOL)rwlock_tryWriteLock
{
    return Check(pthread_rwlock_trywrlock(&lock));
}

- (BOOL)rwlock_unlock
{
    return Check(pthread_rwlock_unlock(&lock));
}

@end
