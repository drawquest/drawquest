// CVSDMAlignedMemory.m
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

// allocates zeroed memory. option for hot or cold
static char* Allocate(const size_t pOctetCount, const bool pHot) {
    char* result = NULL;
    if (!pHot) {
        result = calloc(1, pOctetCount);
        assert(result);
    }
    else {
        result = malloc(pOctetCount);
        assert(result);
        bzero(result, pOctetCount);
    }
    return result;
}

@implementation CVSDMAlignedMemory
{
    char* memory;
    size_t length;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    assert(0 && "invalid initializer");
    return nil;
}

- (instancetype)initWithLength:(size_t)pLength hot:(BOOL)pHot
{
    self = [super init];
    if (!self) {
        return nil;
    }
    memory = Allocate(pLength, pHot);
    if (!memory) {
        return nil;
    }
    length = pLength;
    return self;
}

- (void)dealloc
{
    free(memory), memory = NULL;
}

- (const char*)bytes
{
    return memory;
}

- (char*)mutableBytes
{
    return memory;
}

- (size_t)length
{
    return length;
}

- (void)private_memcpy:(const char*)pSource
{
    assert(pSource);
    const size_t n = self.length;
    assert(n);
    memcpy(self.mutableBytes, pSource, n);
}

- (void)copyMemoryFrom:(CVSDMAlignedMemory *)pAlignedMemory
{
    assert(pAlignedMemory);
    assert(self.length == pAlignedMemory.length);
    assert(self != pAlignedMemory);
    [self private_memcpy:pAlignedMemory.bytes];
}

- (void)clear
{
    bzero(self.mutableBytes, self.length);
}

- (void)exportDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure
{
    @autoreleasepool {
        NSData * data = [[NSData alloc] initWithBytesNoCopy:self.mutableBytes length:self.length freeWhenDone:NO];
        assert(data);
        [pFileExportDestination exportDataToDestination:data closure:pClosure];
    }
}

- (void)setMemoryContentsToContentOfImmutableData:(CVSDMImmutableDataReference *)pImmutableDataReference
{
    assert(pImmutableDataReference);
    @autoreleasepool {
        NSData * const data = pImmutableDataReference.data;
        [self setMemoryContentsToContentOfData:data];
    }
}

- (void)setMemoryContentsToContentOfData:(NSData *)pData
{
    assert(pData);
    assert(pData);
    assert(pData.length == self.length);
    const char* const bytes = pData.bytes;
    assert(bytes);
    [self private_memcpy:bytes];
}

@end
