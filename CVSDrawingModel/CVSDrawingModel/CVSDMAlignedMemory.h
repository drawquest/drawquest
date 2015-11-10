// CVSDMAlignedMemory.h
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief aligned heap memory container. represents an allocation which has the default malloc alignment. similar to NSData/NSMutableData.
 @todo consider adopting <NSCoding>
 */
@interface CVSDMAlignedMemory : NSObject

/**
 @brief creates a new aligned memory buffer with the specified length (using calloc). designated initializer.
 @p pLength the octet count
 @p pHot NO should be your default.
 */
- (instancetype)initWithLength:(size_t)pLength hot:(BOOL)pHot;

- (const char*)bytes NS_RETURNS_INNER_POINTER;
- (char*)mutableBytes NS_RETURNS_INNER_POINTER;

- (size_t)length;

/**
 @brief writes the contents of @p pAlignedMemory to self. the length of the regions must not overlap, and the length must be identical.
 */
- (void)copyMemoryFrom:(CVSDMAlignedMemory *)pAlignedMemory;

/**
 @brief zeroes the memory
 */
- (void)clear;

/**
 @brief exports the entire block of memory to the destination
 */
- (void)exportDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure;

/**
 @brief fills the allocation self represents to the content of @p pImmutableDataReference. the data must have equal lengths.
 */
- (void)setMemoryContentsToContentOfImmutableData:(CVSDMImmutableDataReference *)pImmutableDataReference;

/**
 @brief fills the allocation self represents to the content of @p pData. the data must have equal lengths.
 */
- (void)setMemoryContentsToContentOfData:(NSData *)pData;

@end
