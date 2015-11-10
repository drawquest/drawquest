//
//  CVSCacheView.m
//  Editor
//
//  Created by Phillip Bowden on 10/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSCacheView.h"

#import "CVSEditorView.h"
#import "CVSDrawingTypes.h"
#import "CVSStroke.h"
#import "CVSEditorViewRenderOptions.h"
#import "CVSStrokeArray.h"
#import "CVSStrictGeometry.h"
#import "CVSViewsStrokeArray.h"
#import "CVSDrawingModel.h"
#import "DQHUDView.h"

@interface CVSCacheView ()

@property (nonatomic, strong) CVSViewsStrokeArray *cachedStrokes;
@property (nonatomic, assign, readwrite) CGFloat contentZoomScale;
// @todo JC: rather than -drawRect:, use layers
@property (nonatomic, strong, readwrite) CVSDMEditorBitmapStoreReference * bitmapStoreReference;
@property (nonatomic, readonly) CVSDMImageSnapshotQueue * imageSnapshotQueue;

@end

@implementation CVSCacheView
{
    bool enableSnapshotting;
}

- (id)initWithFrame:(CGRect)pFrame
{
#pragma unused(pFrame)
    assert(0 && "invalid initalizer");
}

- (id)initWithFrame:(CGRect)pFrame bitmapStoreReference:(CVSDMEditorBitmapStoreReference *)pBitmapStoreReference imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue enableSnapshotting:(BOOL)pEnableSnapshotting
{
    assert(pBitmapStoreReference);
    self = [super initWithFrame:pFrame];
    if (!self) {
        return nil;
    }
    enableSnapshotting = pEnableSnapshotting;
    self.userInteractionEnabled = NO;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    _cachedStrokes = [CVSViewsStrokeArray new];
    _contentZoomScale = 1.0;
    _bitmapStoreReference = pBitmapStoreReference;
    if (!_bitmapStoreReference) {
        assert(0 && "invalid bitmap store reference");
        return nil;
    }
    _imageSnapshotQueue = pImageSnapshotQueue;
    if (!_imageSnapshotQueue) {
        assert(0 && "invalid image snapshot queue");
        return nil;
    }
    self.opaque = NO;
    return self;
}

#pragma mark - Bitmap Support

+ (CGFloat)screenScale
{
    return [UIScreen mainScreen].scale;
}

- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext
{
    // if snapshotting is enabled, make sure we have the latest and most complete information.
    // if not, the client is managing that aspect (e.g. the playback view -- append only)
    if (enableSnapshotting) {
        while (false == [self renderFromSnapshot]) {
            /* i recommend this to be async where possible. it could take a while for a snapshot to load. */
        }
    }
    [self.bitmapStoreReference drawImageInRect:pRect context:pContext];
}

#pragma mark - Editor Subview Support

- (void)drawingDidFinishLoading
{
    assert(!self.opaque);
    [self synchronizeRasterizationScale];
    self.layer.drawsAsynchronously = [CVSEditorViewRenderOptions drawsAsynchronously];
    self.layer.shouldRasterize = [CVSEditorViewRenderOptions useSelectiveRasterization];
    // priming attempt -- to avoid initial stroke delay
    [self setNeedsDisplay];
}

- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale
{
    self.contentZoomScale = pZoomScale;
}

#pragma mark - Custom Accessors

- (void)setContentZoomScale:(CGFloat)contentZoomScale
{
    _contentZoomScale = contentZoomScale;
    [self synchronizeRasterizationScale];
}

#pragma mark - Snapshot Cache

- (void)rebuildSnapshotCache
{
    if (CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0()) {
        // memory cache only in this scenario
        return;
    }
    @autoreleasepool {
        [self incrementTimeConsumingUndo];
        // this is a quick implementation of a full rebuild. partial rebuild would probably be best UX.
        for (CVSStroke * at in self.dequeueStrokesAndClearCache) {
            [self enqueueAndRenderStrokes:[CVSStrokeArray newStrokeArrayWithStroke:at]];
        }
        [self decrementTimeConsumingUndo];
    }
}

#pragma mark - Rasterization

- (void)synchronizeRasterizationScale
{
    const CGFloat tx = 1.0f + self.transform.tx;
    const CGFloat contentScale = self.contentScaleFactor;
    const CGFloat screenScale = [self class].screenScale;
    const CGFloat scale = tx * contentScale * self.contentZoomScale * screenScale;
    self.layer.rasterizationScale = scale;
}

// UIView override
- (void)setTransform:(CGAffineTransform)transform
{
    [super setTransform:transform];
    [self synchronizeRasterizationScale];
}

#pragma mark - Blocking Undo

- (void)incrementTimeConsumingUndo
{
    if (CVSDMImageSnapshotQueue_ApplyHack_NotSoSlowIn_3_0_0()) {
        assert(0 && "hack should have no time consuming undos (fs reads)");
    }
    id<CVSEditorViewDelegate> delegate = self.editorViewDelegate;
    assert(delegate);
    const NSUInteger depth = delegate.timeConsumingUndoWillBegin;
#pragma unused(depth)
}

- (void)decrementTimeConsumingUndo
{
    id<CVSEditorViewDelegate> delegate = self.editorViewDelegate;
    assert(delegate);
    const NSUInteger depth = delegate.timeConsumingUndoDidEnd;
    if (0 != depth) {
        return;
    }
    [self renderFromSnapshot];
    [self setNeedsDisplay];
}

#pragma mark - Stroke Management

- (BOOL)hasStrokes
{
    return self.cachedStrokes.hasStrokes;
}

- (void)invalidateSnapshotsGreaterThan:(NSUInteger)pValue
{
    [self.imageSnapshotQueue invalidateSnapshotsWithCountsGreaterThan:pValue];
}

- (void)invalidateSnapshotsGreaterThanOrEqualTo:(NSUInteger)pValue
{
    const NSUInteger i = pValue ? pValue-1U : 0;
    [self invalidateSnapshotsGreaterThan:i];
}

- (void)provideBitmapForSnapshotting
{
    if (enableSnapshotting) {
        [self invalidateSnapshotsGreaterThanOrEqualTo:self.cachedStrokes.count];
        [self.imageSnapshotQueue enqueueSnapshotForStrokeCount:self.cachedStrokes.count bitmapReference:self.bitmapStoreReference];
    }
}

- (void)strokeCountDidChange
{
    [self invalidateSnapshotsGreaterThan:self.cachedStrokes.count];
}

// returns true if the bitmap is up to date
- (bool)renderFromSnapshot
{
    if (!self.hasStrokes) {
        [self clearBitmap];
        return true;
    }
    while (1) {
        CVSDMImageSnapshotQueue * const snapshotQueue = self.imageSnapshotQueue;
        [self invalidateSnapshotsGreaterThan:self.cachedStrokes.count];
        BOOL outIsImporting = NO;
        const NSUInteger strokeCountOfLoadedSnapshot = [snapshotQueue loadMostRecentSnapshot:self.bitmapStoreReference outIsImporting:&outIsImporting initiationBlock:^{
            [self incrementTimeConsumingUndo];
            return ^{[self decrementTimeConsumingUndo];};
        }];
        if (outIsImporting) {
            return false;
        }
        if (CVSDMImageSnapshot_NonSnapshotStrokeCount == strokeCountOfLoadedSnapshot) {
            [self clearBitmap];
        }
        const NSUInteger nStrokes = self.cachedStrokes.count;
        if (nStrokes == strokeCountOfLoadedSnapshot) {
            return true;
        }
        else if (strokeCountOfLoadedSnapshot < nStrokes) {
            CVSStrokeArray * const allStrokes = self.cachedStrokes.copyStrokeArray;
            const NSUInteger nStrokesToRender = allStrokes.count - strokeCountOfLoadedSnapshot;
            CVSStrokeArray * const strokesToRender = [allStrokes dequeueLastNStrokes:nStrokesToRender];
            [self.bitmapStoreReference renderUsingContextRenderBlock:^(CGContextRef pContext) {
                const CGFloat scale = [[self class] screenScale];
                CGContextScaleCTM(pContext, scale, scale);
                [strokesToRender renderInContext:pContext clippingRect:(CGRect){CGPointZero, self.bitmapStoreReference.bitmapDimensionsAsCGSize}];
            }];
            [self provideBitmapForSnapshotting];
            return true;
        }
        else {
            // retry render
            assert(0 && "can this really not be avoided?");
        }
    }
}

- (void)enqueueAndRenderStrokes:(CVSStrokeArray *)strokes
{
    if (0 == strokes.count) {
        assert(0 && "careful what you push around to avoid unnecessary drawing");
        return;
    }
    [self invalidateSnapshotsGreaterThan:self.cachedStrokes.count];
    [self.bitmapStoreReference renderUsingContextRenderBlock:^(CGContextRef pContext) {
        const CGFloat scale = [[self class] screenScale];
        CGContextScaleCTM(pContext, scale, scale);
        [strokes renderInContext:pContext clippingRect:(CGRect){CGPointZero, self.bitmapStoreReference.bitmapDimensionsAsCGSize}];
    }];
    [self.cachedStrokes addStrokes:strokes toView:self];
    [strokes purgeStrokesCachedPaths];
    [self strokeCountDidChange];
    [self provideBitmapForSnapshotting];
}

- (void)clearAllStrokesAndEraseView
{
    @autoreleasepool {
        CVSStrokeArray * dequeued = [self dequeueStrokesAndClearCache];
#pragma unused(dequeued)
    }
}

- (CVSStroke *)dequeueTopStroke
{
    CVSStroke * const stroke = [self.cachedStrokes dequeueLastStroke:self];
    assert(stroke);
    [self strokeCountDidChange];
    [self renderFromSnapshot];
    return stroke;
}

- (void)clearBitmap
{
    [self.bitmapStoreReference clear];
}

- (CVSStrokeArray *)dequeueStrokesAndClearCache
{
    CVSStrokeArray * strokes = [self.cachedStrokes dequeueAllStrokes:self];
    [self strokeCountDidChange];
    [self clearBitmap];
    return strokes;
}

- (void)drawRect:(CGRect)pRect
{
    assert(CGRectIntersectsRect(pRect, self.bounds));
    pRect = CGRectIntersection(pRect, self.bounds);
    // printf("%s drawing rect: %s\n", object_getClassName(self), NSStringFromCGRect(pRect).UTF8String);
    assert(CGRectContainsRect(self.bounds, pRect));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextClipToRect(context, pRect);
    CGContextSetInterpolationQuality(context, [CVSEditorViewRenderOptions interpolationQualityForDrawnImages]);
    [self.bitmapStoreReference drawImageInRect:self.bounds context:context];
    CGContextRestoreGState(context);
}

@end
