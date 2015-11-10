// CVSEditorBitmapStore.h
// DrawQuest
// Created by Justin Carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDMMutableBitmap.h"

@class CVSDMMutableBitmap;
@class CVSDMEditorBitmapStoreReference;

/**
 @brief identifies a bitmap
 */
typedef NS_ENUM(uint8_t, CVSEditorBitmapStoreIdentifier) {
    /**
     @constant do not use
     */
    CVSEditorBitmapStoreIdentifier_Undefined = 0,
    /**
     @constant the cache view's bitmap
     */
    CVSEditorBitmapStoreIdentifier_CacheView
};

/**
 @return true if the bitmap identifier is a valid/defined enum value
 */
extern bool CVSEditorBitmapStoreIdentifierIsValid(const CVSEditorBitmapStoreIdentifier pBitmapStoreIdentifier);

/**
 @brief the editor's bitmap store. presently, there is just one bitmap in use.
 */
@interface CVSDMEditorBitmapStore : NSObject

// designated initalizer
- (instancetype)initWithBitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions;

/**
 @return a new bitmap store reference associated with the bitmap specified
 */
- (CVSDMEditorBitmapStoreReference *)createBitmapStoreReference:(CVSEditorBitmapStoreIdentifier)pBitmapStoreIdentifier;

// Dimensions
- (CVSDMBitmapDimensions)bitmapDimensions;
- (CGSize)bitmapDimensionsAsCGSize;

// Bitmap Operations and Mutators

/**
 @brief draws the bitmap into the context. the context must be configured by the client
 */
- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier;

/**
 @brief render to the bitmap specified
 */
- (void)renderUsingContextRenderBlock:(CVSMutableBitmapCGContextRenderBlock)pContextRenderBlock bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier;

/**
 @brief clears the bitmap's contents
 */
- (void)clear:(CVSEditorBitmapStoreIdentifier)pIdentifier;

/**
 @brief copies from self's bitmap to @p pBitmap
 */
- (void)copyBitmapTo:(CVSDMMutableBitmap *)pBitmap bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier;
/**
 @brief copies from @p pBitmap to self's bitmap
 */
- (void)copyBitmapFrom:(CVSDMMutableBitmap *)pBitmap bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier;

/**
 @brief initiates an export for the selected bitmap
 */
- (void)exportRawBitmapDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier;

/**
 @brief initiates an write to the selected bitmap using the content of pImmutableDataReference.
 */
- (void)writeBitmapContents:(CVSDMImmutableDataReference *)pImmutableDataReference bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier;

@end
