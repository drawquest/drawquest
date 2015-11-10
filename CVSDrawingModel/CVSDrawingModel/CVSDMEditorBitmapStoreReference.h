// CVSEditorBitmapStoreReference.h
// DrawQuest
// Created by Justin Carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief pairs a CVSEditorBitmapStore with a CVSEditorBitmapStoreIdentifier. purely convenience/abstraction.
 */
@interface CVSDMEditorBitmapStoreReference : NSObject

@property (nonatomic, readonly) CVSDMEditorBitmapStore * bitmapStore;
@property (nonatomic, readonly) CVSEditorBitmapStoreIdentifier bitmapStoreIdentifier;

// designated initializer
- (instancetype)initWithBitmapStore:(CVSDMEditorBitmapStore *)pBitmapStore bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pBitmapStoreIdentifier;

// The following just calls through self's bitmapStore using self's bitmapStoreIdentifier
- (CVSDMBitmapDimensions)bitmapDimensions;
- (CGSize)bitmapDimensionsAsCGSize;
- (BOOL)areDimensionsEqualTo:(CVSDMMutableBitmap *)pOther;
- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext;
- (void)renderUsingContextRenderBlock:(CVSMutableBitmapCGContextRenderBlock)pContextRenderBlock;
- (void)clear;

/**
 @brief copies self's bitmap to @p pBitmap
 */
- (void)copyBitmapTo:(CVSDMMutableBitmap *)pBitmap;

/**
 @brief copies @p pBitmap to self's bitmap
 */
- (void)copyBitmapFrom:(CVSDMMutableBitmap *)pBitmap;

/**
 @brief writes the bitmap data to the destination
 */
- (void)exportRawBitmapDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure;

/**
 @brief writes the bitmap's contents using the provided data reference's data. the data's length must be equal to the size of the allocation of the bitmap.
 */
- (void)writeBitmapContents:(CVSDMImmutableDataReference *)pImmutableDataReference;

@end
