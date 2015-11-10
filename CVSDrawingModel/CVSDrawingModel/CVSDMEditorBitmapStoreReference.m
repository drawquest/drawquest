// CVSEditorBitmapStoreReference.m
// DrawQuest
// Created by Justin Carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

@interface CVSDMEditorBitmapStoreReference ()

@property (nonatomic, strong, readwrite) CVSDMEditorBitmapStore * bitmapStore;
@property (nonatomic, assign, readwrite) CVSEditorBitmapStoreIdentifier bitmapStoreIdentifier;

@end

@implementation CVSDMEditorBitmapStoreReference

@synthesize bitmapStore = _bitmapStore;
@synthesize bitmapStoreIdentifier = _bitmapStoreIdentifier;

- (instancetype)initWithBitmapStore:(CVSDMEditorBitmapStore *)pBitmapStore bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pBitmapStoreIdentifier
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _bitmapStore = pBitmapStore;
    if (!_bitmapStore) {
        assert(0 && "invalid bitmap store");
        return nil;
    }

    _bitmapStoreIdentifier = pBitmapStoreIdentifier;
    if (!CVSEditorBitmapStoreIdentifierIsValid(_bitmapStoreIdentifier)) {
        assert(0 && "invalid bitmap store identifier");
        return nil;
    }

    return self;
}

- (CVSDMBitmapDimensions)bitmapDimensions
{
    return self.bitmapStore.bitmapDimensions;
}

- (CGSize)bitmapDimensionsAsCGSize
{
    return self.bitmapStore.bitmapDimensionsAsCGSize;
}

- (BOOL)areDimensionsEqualTo:(CVSDMMutableBitmap *)pOther
{
    return CVSDMBitmapDimensionsAreEqual(self.bitmapDimensions, pOther.bitmapDimensions);
}

- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext
{
    [self.bitmapStore drawImageInRect:pRect context:pContext bitmapStoreIdentifier:self.bitmapStoreIdentifier];
}

- (void)renderUsingContextRenderBlock:(CVSMutableBitmapCGContextRenderBlock)pContextRenderBlock
{
    [self.bitmapStore renderUsingContextRenderBlock:pContextRenderBlock bitmapStoreIdentifier:self.bitmapStoreIdentifier];
}

- (void)clear
{
    [self.bitmapStore clear:self.bitmapStoreIdentifier];
}

- (void)copyBitmapTo:(CVSDMMutableBitmap *)pBitmap
{
    assert(pBitmap);
    [self.bitmapStore copyBitmapTo:pBitmap bitmapStoreIdentifier:self.bitmapStoreIdentifier];
}

- (void)copyBitmapFrom:(CVSDMMutableBitmap *)pBitmap
{
    assert(pBitmap);
    [self.bitmapStore copyBitmapFrom:pBitmap bitmapStoreIdentifier:self.bitmapStoreIdentifier];
}

- (void)exportRawBitmapDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure
{
    assert(pFileExportDestination);
    [self.bitmapStore exportRawBitmapDataToDestination:pFileExportDestination closure:pClosure bitmapStoreIdentifier:self.bitmapStoreIdentifier];
}

- (void)writeBitmapContents:(CVSDMImmutableDataReference *)pImmutableDataReference
{
    [self.bitmapStore writeBitmapContents:pImmutableDataReference bitmapStoreIdentifier:self.bitmapStoreIdentifier];
}

@end
