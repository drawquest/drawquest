// CVSMutableBitmap.h
// DrawQuest
// Created by Justin Carlson on 10/15/13.
// Copyright (c) 2013 Canvas. All rights reserved.

@class CALayer;

/**
 @brief block prototype for a client render in CGContext function
 */
typedef void (^CVSMutableBitmapCGContextRenderBlock)(CGContextRef pContext);

/**
 @brief specifically, an 8bpc color bitmap with premultiplied alpha.
 */
@interface CVSDMMutableBitmap : NSObject <CVSDMFileExportDestinationDataProvider>

- (instancetype)initWithBitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions;

- (CVSDMBitmapDimensions)bitmapDimensions;

- (CGRect)boundsAsCGRect;
- (BOOL)areDimensionsEqualTo:(CVSDMMutableBitmap *)pOther;

/**
 @brief rather than providing the CGContext (e.g. by an accessor), the approach here is to offer a client block for rendering using a CGContext. the client must never hold on to the block beyond the scope of the block.
 */
- (void)renderUsingContextRenderBlock:(CVSMutableBitmapCGContextRenderBlock)pContextRenderBlock;

/**
 @brief fills the bitmap with opaque black
 */
- (void)clear;
- (void)clearRect:(CGRect)pRect;

/**
 @brief note that this method does nothing special to set up the context. it's the client's responsibility to configure and clip the context as needed.
 @details we want to avoid handing out the image. the CGImage wrapper is generally cheap to "create", but modern implementations add copy on write protection.
 */
- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext;

/**
 @brief copies the bitmap from @p pBitmap to self
 */
- (void)copyBitmapFrom:(CVSDMMutableBitmap *)pBitmap;

/**
 @brief writes the bitmap's raw data to the destination
 */
- (void)exportRawBitmapDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure;

/**
 @brief writes the content of @p pImmutableDataReference to the bitmap. the data must have identical size.
 */
- (void)writeBitmapContents:(CVSDMImmutableDataReference *)pImmutableDataReference;

@end
