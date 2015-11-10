// CVSEditorBitmapStore.m
// DrawQuest
// Created by Justin Carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"
#import "CVSDMEditorBitmapStore.h"

#import "CVSDMMutableBitmap.h"
#import "CVSDMEditorBitmapStoreReference.h"

bool CVSEditorBitmapStoreIdentifierIsValid(const CVSEditorBitmapStoreIdentifier pBitmapStoreIdentifier) {
    switch (pBitmapStoreIdentifier) {
        case CVSEditorBitmapStoreIdentifier_CacheView :
            return true;

        case CVSEditorBitmapStoreIdentifier_Undefined :
            break;
    }
    return false;
}

@interface CVSDMEditorBitmapStore ()

@property (nonatomic, strong, readwrite) CVSDMMutableBitmap * cacheView;

- (CVSDMMutableBitmap *)bitmap:(CVSEditorBitmapStoreIdentifier)pIdentifier;

@end

@implementation CVSDMEditorBitmapStore
{
    CVSDMBitmapDimensions _bitmapDimensions;
}

@synthesize cacheView = _cacheView;

- (id)init
{
    assert(0 && "invalid initializer");
    return nil;
}

- (instancetype)initWithBitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions
{
    assert((pBitmapDimensions.width * pBitmapDimensions.height) && "invalid area");
    assert(4000 > pBitmapDimensions.width && 4000 > pBitmapDimensions.height && "suspiciously large area");
    self = [super init];
    if (!self) {
        return nil;
    }
    _bitmapDimensions = pBitmapDimensions;
    _cacheView = [[CVSDMMutableBitmap alloc] initWithBitmapDimensions:pBitmapDimensions];
    if (!_cacheView) {
        return nil;
    }
    return self;
}

- (CVSDMBitmapDimensions)bitmapDimensions
{
    return _bitmapDimensions;
}

- (CGSize)bitmapDimensionsAsCGSize
{
    const CVSDMBitmapDimensions dim = self.bitmapDimensions;
    return (CGSize){dim.width, dim.height};
}

- (CVSDMEditorBitmapStoreReference *)createBitmapStoreReference:(CVSEditorBitmapStoreIdentifier)pBitmapStoreIdentifier
{
    assert(CVSEditorBitmapStoreIdentifierIsValid(pBitmapStoreIdentifier));
    return [[CVSDMEditorBitmapStoreReference alloc] initWithBitmapStore:self bitmapStoreIdentifier:pBitmapStoreIdentifier];
}

- (CVSDMMutableBitmap *)bitmap:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    switch (pIdentifier) {
        case CVSEditorBitmapStoreIdentifier_CacheView :
            return _cacheView;

        case CVSEditorBitmapStoreIdentifier_Undefined :
            break;
    }
    assert(0 && "invalid bitmap requested");
}

- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    [[self bitmap:pIdentifier] drawImageInRect:pRect context:pContext];
}

- (void)renderUsingContextRenderBlock:(CVSMutableBitmapCGContextRenderBlock)pContextRenderBlock bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    [[self bitmap:pIdentifier] renderUsingContextRenderBlock:pContextRenderBlock];
}

- (void)clear:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    [[self bitmap:pIdentifier] clear];
}

- (void)copyBitmapTo:(CVSDMMutableBitmap *)pBitmap bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    assert(pBitmap);
    // operand swap
    [pBitmap copyBitmapFrom:[self bitmap:pIdentifier]];
}

- (void)copyBitmapFrom:(CVSDMMutableBitmap *)pBitmap bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    [[self bitmap:pIdentifier] copyBitmapFrom:pBitmap];
}

- (void)exportRawBitmapDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    [[self bitmap:pIdentifier] exportRawBitmapDataToDestination:pFileExportDestination closure:pClosure];
}

- (void)writeBitmapContents:(CVSDMImmutableDataReference *)pImmutableDataReference bitmapStoreIdentifier:(CVSEditorBitmapStoreIdentifier)pIdentifier
{
    [[self bitmap:pIdentifier] writeBitmapContents:pImmutableDataReference];
}

@end
