// CVSDMLockingBlock.m
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

void CVSDMLockingBlock_NSLocking(id<NSLocking> pLock, CVSDMLockingBlockTask pBlock) {
    assert(nil != pLock);
    assert(nil != pBlock);
    [pLock lock];
    pBlock();
    [pLock unlock];
}

bool CVSDMLockingBlock_NSLockingWithTryLock(id<CVSDM_NSLockingWithTryLock> pLock, CVSDMLockingBlockTask pBlock) {
    assert(nil != pLock);
    assert(nil != pBlock);
    if (![pLock tryLock]) {
        return false;
    }
    pBlock();
    [pLock unlock];
    return true;
}
