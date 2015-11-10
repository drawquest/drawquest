// CVSDMReadWriteLocking.m
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

void CVSDMReadWriteLocking_Read(id<CVSDMReadWriteLocking> pObject, CVSDMReadWriteLockingTask pBlock) {
    assert(nil != pObject);
    assert(nil != pBlock);
    if (![pObject rwlock_acquireReadLock]) {
        assert(0 && "error acquiring lock");
        return;
    }
    pBlock();
    if (![pObject rwlock_unlock]) {
        assert(0 && "error unlocking");
    }
}

void CVSDMReadWriteLocking_Write(id<CVSDMReadWriteLocking> pObject, CVSDMReadWriteLockingTask pBlock) {
    assert(nil != pObject);
    assert(nil != pBlock);
    if (![pObject rwlock_acquireWriteLock]) {
        assert(0 && "error acquiring lock");
        return;
    }
    pBlock();
    if (![pObject rwlock_unlock]) {
        assert(0 && "error unlocking");
    }
}

void CVSDMReadWriteLocking_ReadWriteLockProvider_Read(id<CVSDMReadWriteLockProvider> pObject, CVSDMReadWriteLockingTask pBlock) {
    CVSDMReadWriteLocking_Read(pObject.readWriteLock, pBlock);
}

void CVSDMReadWriteLocking_ReadWriteLockProvider_Write(id<CVSDMReadWriteLockProvider> pObject, CVSDMReadWriteLockingTask pBlock) {
    CVSDMReadWriteLocking_Write(pObject.readWriteLock, pBlock);
}
