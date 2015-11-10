//
//  CVSStrokeView.m
//  Editor
//
//  Created by Phillip Bowden on 10/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSStrokeView.h"

#import "UIBezierPath+CVSAdditions.h"

#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "CVSEditorViewRenderOptions.h"
#import "CVSStrokeArray.h"
#import "CVSStrokeRenderer.h"
#import "CVSStrictGeometry.h"
#import "CVSViewsStrokeArray.h"
#import "CVSTrackingBrush.h"

@interface CVSStrokeView ()

@property (strong, nonatomic) CVSTrackingBrush * trackingBrush;
@property (strong, nonatomic) CVSViewsStrokeArray *strokes;
@property (nonatomic, assign, getter = isDirty) BOOL dirty;

@property (nonatomic) CVSBrushAttributes currentBrushAttributes;
@property (strong, nonatomic) UIColor *currentStrokeColor;

@end

@implementation CVSStrokeView
{
    bool didPrimePathDrawing;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    self.opaque = NO;
    _strokes = [CVSViewsStrokeArray new];

    return self;
}

#pragma mark - Editor Subview Support

- (void)drawingDidFinishLoading
{
    self.layer.drawsAsynchronously = [CVSEditorViewRenderOptions drawsAsynchronously];
    // priming attempt -- to avoid initial stroke delay
    [self setNeedsDisplay];
}

- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale
{
#pragma unused(pZoomScale)
    // nothing to do right now
}

#pragma mark -

- (BOOL)containsStroke:(CVSStroke *)stroke
{
    return [self.strokes containsStroke:stroke];
}

- (BOOL)containsEraserStroke
{
    return [self.strokes containsStrokeWithBrushType:CVSBrushTypeEraser];
}

- (CVSStrokeArray *)dequeueStrokesToFitBelowRenderComplexityThreshold:(CVSMultipleStrokeRenderComplexity)pThreshold
{
    return [self.strokes dequeueStrokesToFitBelowRenderComplexityThreshold:pThreshold view:self];
}

- (CVSStrokeArray *)dequeueAllStrokesAndEraseView
{
    assert(self.hasStrokes);
    CVSStrokeArray * copy = [self.strokes dequeueAllStrokes:self];
    self.dirty = NO;
    [self.trackingBrush ifTrackingEndTracking:self];
    return copy;
}

#pragma mark - Stroke Collections

- (BOOL)hasStrokes
{
    return self.strokes.hasStrokes;
}

- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity
{
    return [self.strokes isMultipleStrokeRenderComplexityBelow:pRenderComplexity];
}

#pragma mark - Drawing

- (void)addStroke:(CVSStroke *)stroke
{
    [self.strokes addStroke:stroke toView:self];
    assert(!self.containsEraserStroke);
    self.dirty = YES;
}

- (void)addStrokes:(CVSStrokeArray *)strokes
{
    if (0 == strokes.count) {
        assert(0 && "invalid parameter");
        return;
    }
    [self.strokes addStrokes:strokes toView:self];
    assert(!self.containsEraserStroke);
    self.dirty = YES;
}

- (void)removeStroke:(CVSStroke *)stroke
{
    [self.strokes removeStroke:stroke fromView:self];
    self.dirty = YES;
}

- (void)disposeActiveStroke
{
    [self.trackingBrush ifTrackingEndTracking:self];
}

#pragma mark - Drawing Context Configuration

- (void)drawComponent:(CVSStrokeComponent *)component brushType:(CVSBrushType)brushType strokeColor:(UIColor *)strokeColor
{
    self.currentBrushAttributes = CVSBrushAttributesForBrushType(brushType);
    self.currentStrokeColor = strokeColor;

    CVSTrackingBrush * tmpBrush = [[CVSTrackingBrush alloc] initWithBrushType:brushType];
    [tmpBrush beginTracking];
    [tmpBrush addStrokeComponent:component];
    // do not close the path. it makes for inconsistent strokes.
    // [tmpBrush closePath];

    if (!self.trackingBrush || !self.trackingBrush.isTracking) {
        self.trackingBrush = [[CVSTrackingBrush alloc] initWithBrushType:brushType];
        assert(self.trackingBrush);
        [self.trackingBrush beginTracking];
    }
    assert(self.trackingBrush.brushType == brushType);
    assert(self.trackingBrush.isTracking);
    [self.trackingBrush appendPathOfTrackingBrush:tmpBrush];
    [tmpBrush invalidateTrackingPathAndPathsRectInView:self];
}

- (void)finishRenderingStroke:(CVSStroke *)stroke
{
    [self.strokes addStroke:stroke toView:self];
    [self.trackingBrush endTracking];
}

- (void)primePathDrawing
{
    // there is a rendering issue where an initial stroke's first gestures get blocked. this is an attempt to work around aspects of lazy loading
    assert(false == didPrimePathDrawing);
    UIBezierPath * const path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    const CGRect r = self.bounds;
    const CGPoint center = CGPointMake(r.origin.x + (r.size.width/2), r.origin.y + (r.size.height/2));
    [path addQuadCurveToPoint:CGPointMake(r.origin.x, r.origin.y) controlPoint:center];
    [path addQuadCurveToPoint:center controlPoint:center];
    [path addQuadCurveToPoint:CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height) controlPoint:center];
    [[UIColor clearColor] setStroke];
    [path stroke];
    didPrimePathDrawing = true;
}

- (void)drawRect:(CGRect)pRect
{
    assert(CGRectIntersectsRect(pRect, self.bounds));
    pRect = CGRectIntersection(pRect, self.bounds);
    if (!didPrimePathDrawing) {
        [self primePathDrawing];
    }

    // printf("%s drawing rect: %s\n", object_getClassName(self), NSStringFromCGRect(rect).UTF8String);
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Draw any strokes marked as dirty
    if (self.dirty)
    {
        CGContextClearRect(context, pRect);
    }
    // presently, snapshot mode pushes to the cache view immediately after a stroke's completed.
    // if that holds, there will be a lot of code that can be removed from this entire view hierarchy.
    const bool SnapshotMode = true;
    if (SnapshotMode) {
        assert(0 == self.strokes.count);
    }
    else {
        if (self.strokes.hasStrokes && CGRectIntersectsRect(self.strokes.unionOfStrokesBounds, pRect)) {
            // favor the CGPath - these are 'hot' strokes
            [self.strokes renderInContext:context clippingRect:pRect useStrokesCGPath:true];
        }
    }
    self.dirty = NO;

    // Draw the current tracking path if there is one
    CVSTrackingBrush * const trackingBrush = self.trackingBrush;
    if (nil != trackingBrush) {
        if (trackingBrush.isTracking && !trackingBrush.isEmpty && CGRectIntersectsRect(pRect, trackingBrush.boundingBoxAsDrawn)) {
            const CVSBrushAttributes brush = self.currentBrushAttributes;
            [self.currentStrokeColor setStroke];
            [trackingBrush strokeWithBlendMode:[CVSStrokeRenderer blendModeForBrushType:brush.brushType] alpha:brush.alpha];
        }
    }
}

@end
