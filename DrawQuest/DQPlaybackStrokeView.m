// DQPlaybackStrokeView.m
// DrawQuest
// Created by Justin Carlson on 11/2/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "DQPlaybackStrokeView.h"

#import "CVSDrawing.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "CVSStrokeArray.h"
#import "DQPlaybackView.h"
#import "UIBezierPath+CVSAdditions.h"
#import "CVSViewsStrokeArray.h"
#import "CVSTrackingBrush.h"
#import "CVSCacheView.h"
#import "CVSEditorViewRenderOptions.h"
#import "CVSTemplateImage.h"

@interface DQPlaybackStrokeView ()

@property (nonatomic, readonly) CVSTemplateImage * templateImage;

@property (nonatomic, assign, getter=shouldIncrementCurrentStrokeIndex) BOOL incrementCurrentStrokeIndex;
@property (nonatomic) NSUInteger currentStrokeIndex;
@property (nonatomic) NSUInteger currentStrokeComponentIndex;
@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, assign, getter=isAnimating) BOOL animating;
@property (nonatomic, strong) CVSTrackingBrush * trackingBrush;
@property (nonatomic, readonly) CVSCacheView * cacheView;

@end


@implementation DQPlaybackStrokeView

- (id)initWithFrame:(CGRect)pFrame templateImage:(CVSTemplateImage *)pTemplateImage cacheView:(CVSCacheView *)pCacheView
{
    self = [super initWithFrame:pFrame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = nil;
    self.opaque = YES;
    self.clipsToBounds = YES;
    self.clearsContextBeforeDrawing = NO;

    _currentStrokeIndex = 0;
    _incrementCurrentStrokeIndex = NO;
    _currentStrokeComponentIndex = 0;

    _animating = NO;
    _trackingBrush = nil;
    _cacheView = pCacheView;
    _templateImage = pTemplateImage;
    if (!_cacheView || !_templateImage) {
        assert(0 && "invalid parameter");
        return nil;
    }
    return self;
}

- (void)dealloc
{
    [self disposeDisplayLink];
}

- (void)disposeDisplayLink
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)clearAllStrokesAndEraseView
{
    [self.trackingBrush ifTrackingEndTracking:self];
    [self.trackingBrush beginTracking];
}

- (void)startPlayback
{
    [self setNeedsDisplay];
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawNextFrame)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.animating  = YES;
}

- (void)pausePlayback
{
    [self disposeDisplayLink];
    self.animating = NO;
}

- (void)stopPlayback
{
    @autoreleasepool {
        [self disposeDisplayLink];
        self.animating = NO;
        self.incrementCurrentStrokeIndex = NO;
        self.currentStrokeComponentIndex = 0;
        self.currentStrokeIndex = 0;
        [self setNeedsDisplay];
        [self.playbackView.delegate playbackViewDidFinishPlayback:self.playbackView];
    }
}

#pragma mark -

- (void)configureContext:(CGContextRef)context withStroke:(CVSStroke *)stroke;
{
    [self configureContext:context withBrush:CVSBrushAttributesForBrushType(stroke.brushType) strokeColor:stroke.strokeColor];
}

- (void)configureContext:(CGContextRef)context withBrush:(CVSBrushAttributes)brush strokeColor:(UIColor *)strokeColor
{
    CGContextSetAlpha(context, brush.alpha);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetLineJoin(context, brush.lineJoin);
    CGContextSetLineCap(context, brush.lineCap);
    CGContextSetLineWidth(context, brush.lineWidth);
    CGContextSetAllowsAntialiasing(context, true);

    if(brush.brushType == CVSBrushTypeEraser) {
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    } else {
        CGContextSetBlendMode(context, kCGBlendModeNormal);
    }
}

- (void)drawComponent:(CVSStrokeComponent *)component forStroke:(CVSStroke *)stroke
{
    assert(component);
    assert(stroke);
    const CVSBrushType brushType = stroke.brushType;
    CVSTrackingBrush * const tmp = [[CVSTrackingBrush alloc] initWithBrushType:brushType];
    [tmp beginTracking];
    [tmp addStrokeComponent:component];
    // do not close the path. it makes for inconsistent strokes.
    // [tmp closePath];
    assert(!tmp.isEmpty);
    if (!self.trackingBrush) {
        self.trackingBrush = [[CVSTrackingBrush alloc] initWithBrushType:brushType];
        [self.trackingBrush beginTracking];
    }

    [self.trackingBrush appendPathOfTrackingBrush:tmp];
    [tmp invalidateTrackingPathAndPathsRectInView:self];
}

- (void)drawNextFrame
{
    @autoreleasepool {
        const NSInteger NComponentsPerFrame = 4;
        for (NSInteger component = 0; component < NComponentsPerFrame; component++) {
            // Check if current stroke is in bounds
            // If not, stop playback
            NSUInteger strokeCount = [self.drawing.strokes count];
            if (self.isAnimating && (self.currentStrokeIndex >= strokeCount || (self.shouldIncrementCurrentStrokeIndex && self.currentStrokeIndex + 1 >= strokeCount))) {
                [self stopPlayback];
                break;
            }

            if ([self drawNextComponent]) {
                break;
            }
        }
    }
}

- (BOOL)drawNextComponent
{
    if (self.shouldIncrementCurrentStrokeIndex) {
        self.currentStrokeIndex += 1;
    }

    CVSStroke *currentStroke = [self.drawing.strokes objectAtIndex:self.currentStrokeIndex];

    // Get the next component index
    // If it's not in bounds, increment the stroke, return;
    if (self.currentStrokeComponentIndex >= [currentStroke.components count]) {
        [self.cacheView enqueueAndRenderStrokes:[CVSStrokeArray newStrokeArrayWithStroke:[self.drawing.strokes objectAtIndex:self.currentStrokeIndex]]];
        if (self.trackingBrush) {
            [self.trackingBrush invalidateTrackingPathAndPathsRectInView:self];
        }

        self.trackingBrush = [[CVSTrackingBrush alloc] initWithBrushType:currentStroke.brushType];
        [self.trackingBrush beginTracking];

        self.incrementCurrentStrokeIndex = YES;
        self.currentStrokeComponentIndex = 0;
        return YES;
    }

    // Draw the next component
    CVSStrokeComponent *currentComponent = [currentStroke.components objectAtIndex:self.currentStrokeComponentIndex];
    [self drawComponent:currentComponent forStroke:currentStroke];

    // Increment the component;
    self.currentStrokeComponentIndex += 1;

    if (self.shouldIncrementCurrentStrokeIndex) {
        self.currentStrokeIndex -= 1;
    }

    return NO;
}

#pragma mark - UIView

- (void)fillBackgroundIfTemplateIsNotOpaque:(CGContextRef)pContext rect:(CGRect)pRect
{
    assert(self.templateImage);
    if (!self.templateImage.isOpaque) {
        CGContextSaveGState(pContext);
        // not really expecting the template to have alpha, but we need to fill it with white in the event the input is not opaque.
        CGContextSetFillColorWithColor(pContext, UIColor.whiteColor.CGColor);
        CGContextFillRect(pContext, pRect);
        CGContextRestoreGState(pContext);
    }
}

- (void)drawTemplateImage:(CGContextRef)pContext rect:(CGRect)pRect
{
    // draw the template image
    CGContextSaveGState(pContext);
    UIImage * const image = self.templateImage.image;
    assert(image);
    CGContextSetInterpolationQuality(pContext, [CVSEditorViewRenderOptions interpolationQualityForDrawnImages]);
    [image drawInRect:self.bounds];
    CGContextRestoreGState(pContext);
}

- (void)drawCachedStrokes:(CGContextRef)pContext rect:(CGRect)pRect
{
    CGContextSaveGState(pContext);
    CGContextSetInterpolationQuality(pContext, [CVSEditorViewRenderOptions interpolationQualityForDrawnImages]);
    [self.cacheView drawImageInRect:self.bounds context:pContext];
    CGContextRestoreGState(pContext);
}

- (void)drawTrackingBrush:(CGContextRef)pContext rect:(CGRect)pRect
{
    if (self.isAnimating && self.currentStrokeIndex < [self.drawing.strokes count]) {
        CVSStroke * currentStroke = [self.drawing.strokes objectAtIndex:self.currentStrokeIndex];
        CGContextSaveGState(pContext);
        [self configureContext:pContext withStroke:currentStroke];
        [self.trackingBrush addPathToContext:pContext];
        CGContextStrokePath(pContext);
        CGContextRestoreGState(pContext);
    }
}

- (void)drawCachedAndActiveStrokes:(CGContextRef)pContext rect:(CGRect)pRect
{
    if (self.shouldIncrementCurrentStrokeIndex) {
        self.currentStrokeIndex += 1;
        self.incrementCurrentStrokeIndex = NO;
    }

    [self drawCachedStrokes:pContext rect:pRect];
    if (self.trackingBrush && self.trackingBrush.isTracking && !self.trackingBrush.isEmpty) {
        [self drawTrackingBrush:pContext rect:pRect];
    }
}

- (void)drawCachedAndActiveStrokesInTransparencyLayer:(CGContextRef)pContext rect:(CGRect)pRect
{
    CGContextBeginTransparencyLayerWithRect(pContext, pRect, NULL);
    [self drawCachedAndActiveStrokes:pContext rect:pRect];
    CGContextEndTransparencyLayer(pContext);
}

- (void)drawRect:(CGRect)pRect
{
    assert(CGRectIntersectsRect(pRect, self.bounds));
    pRect = CGRectIntersection(pRect, self.bounds);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    CGContextClipToRect(context, CGRectIntersection(self.bounds, pRect));

    // fulfill our opacity contract if needed
    [self fillBackgroundIfTemplateIsNotOpaque:context rect:pRect];
    // draw the template image
    [self drawTemplateImage:context rect:pRect];
    // render the cache and active strokes
    [self drawCachedAndActiveStrokesInTransparencyLayer:context rect:pRect];
    CGContextRestoreGState(context);
}

@end

