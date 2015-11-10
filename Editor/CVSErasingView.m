//
//  CVSErasingView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSErasingView.h"

#import "UIBezierPath+CVSAdditions.h"

#import "CVSDrawingTypes.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "CVSEditorViewRenderOptions.h"
#import "CVSStrokeArray.h"
#import "CVSStrokeRenderer.h"
#import "CVSStrictGeometry.h"
#import "CVSViewsStrokeArray.h"
#import "CVSDrawingModel.h"
#import "CVSTrackingBrush.h"

@interface CVSErasingView ()

@property (strong, nonatomic) CVSDMEditorBitmapStoreReference * bitmapStoreReference;
@property (strong, nonatomic) CVSTrackingBrush * trackingBrush;
@property (strong, nonatomic, readwrite) CVSViewsStrokeArray *eraseStrokes;

@end

@implementation CVSErasingView

- (id)initWithFrame:(CGRect)pFrame bitmapStoreReference:(CVSDMEditorBitmapStoreReference *)pBitmapStoreReference
{
    self = [super initWithFrame:pFrame];
    if (!self) {
        return nil;
    }
    if (!pBitmapStoreReference) {
        assert(0 && "invalid parameter");
        return nil;
    }

    self.userInteractionEnabled  = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    self.opaque = NO;
    _eraseStrokes = [CVSViewsStrokeArray new];
    _bitmapStoreReference = pBitmapStoreReference;
    self.layer.drawsAsynchronously = [CVSEditorViewRenderOptions drawsAsynchronously];
    _trackingBrush = [[self class] newEraserTrackingBrush];
    return self;
}

- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale
{
#pragma unused(pZoomScale)
    // nothing to do right now
}

#pragma mark - Stroke Management

- (BOOL)hasStrokes
{
    return self.eraseStrokes.hasStrokes;
}

- (void)disposeActiveStroke
{
    [self.trackingBrush ifTrackingEndTracking:self];
}

- (CVSStrokeArray *)dequeueAllStrokes
{
    return [self.eraseStrokes dequeueAllStrokes:self];
}

- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity
{
    return [self.eraseStrokes isMultipleStrokeRenderComplexityBelow:pRenderComplexity];
}

#pragma mark - Drawing

+ (CVSTrackingBrush *)newEraserTrackingBrush
{
    return [[CVSTrackingBrush alloc] initWithBrushType:CVSBrushTypeEraser];
}

- (void)drawComponent:(CVSStrokeComponent *)component
{
    assert(component);
    CVSTrackingBrush * const temporaryPath = [[self class] newEraserTrackingBrush];
    [temporaryPath beginTracking];
    [temporaryPath addStrokeComponent:component];
    if (!self.trackingBrush.isTracking) {
        [self.trackingBrush beginTracking];
    }
    assert(self.trackingBrush.isTracking);
    [self.trackingBrush  appendPathOfTrackingBrush:temporaryPath];
    [temporaryPath invalidateTrackingPathAndPathsRectInView:self];
}

- (void)addStroke:(CVSStroke *)stroke
{
    [self.eraseStrokes addStroke:stroke toView:self];
}

- (void)removeStroke:(CVSStroke *)stroke
{
    [self.eraseStrokes removeStroke:stroke fromView:self];
}

- (BOOL)containsStroke:(CVSStroke *)stroke
{
    assert(stroke);
    return [self.eraseStrokes containsStroke:stroke];
}

- (void)finishRenderingStroke:(CVSStroke *)stroke
{
    assert(stroke);
    [self.trackingBrush endTracking];
    [self addStroke:stroke];
}

- (void)renderCurrentTrackingPathInRectIfPresent:(CGRect)pInvalidRect
{
    CVSTrackingBrush * const trackingBrush = self.trackingBrush;
    assert(trackingBrush);
    if (!trackingBrush) {
        return;
    }
    if (!trackingBrush.isTracking) {
        return;
    }
    if (trackingBrush.isEmpty) {
        return;
    }
    const CGRect expandedBoundingBox = trackingBrush.boundingBoxAsDrawn;
    if (CGRectIsNull(expandedBoundingBox)) {
        return;
    }
    const CVSBrushAttributes brush = CVSBrushAttributesForBrushType(CVSBrushTypeEraser);
    if (!CGRectIntersectsRect(expandedBoundingBox, pInvalidRect)) {
        return;
    }
    const CGRect intersection = CGRectIntersection(expandedBoundingBox, pInvalidRect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineJoin(context, brush.lineJoin);
    CGContextSetLineCap(context, brush.lineCap);
    CGContextSetLineWidth(context, brush.lineWidth);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetBlendMode(context, kCGBlendModeClear);

    CGContextClipToRect(context, intersection);
    CGContextBeginPath(context);
    [trackingBrush addPathToContext:context];
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

#pragma mark - UIView

- (void)drawRect:(CGRect)pRect
{
    assert(CGRectIntersectsRect(pRect, self.bounds));
    pRect = CGRectIntersection(pRect, self.bounds);
    // printf("%s drawing rect: %s\n", object_getClassName(self), NSStringFromCGRect(pRect).UTF8String);
    assert(CGRectContainsRect(self.bounds, pRect));
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    CGContextClipToRect(context, pRect);

    {
        CGContextSaveGState(context);
        CGContextSetAllowsAntialiasing(context, true);
        CGContextSetInterpolationQuality(context, [CVSEditorViewRenderOptions interpolationQualityForDrawnImages]);
        [self.bitmapStoreReference drawImageInRect:self.bounds context:context];
        CGContextRestoreGState(context);
    }
    // render previously recorded erase actions if present
    if (self.eraseStrokes.hasStrokes) {
        if (CGRectIntersectsRect(self.eraseStrokes.unionOfStrokesBounds, pRect)) {
            // favor the "hot" path
            [self.eraseStrokes renderInContext:context clippingRect:pRect useStrokesCGPath:true];
        }
    }
    // render current erase action
    [self renderCurrentTrackingPathInRectIfPresent:pRect];
    CGContextRestoreGState(context);
}

@end
