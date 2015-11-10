// CVSViewsStrokeArray.m
// DrawQuest
// Created by Justin Carlson on 10/21/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSViewsStrokeArray.h"
#import "CVSStrokeArray.h"
#import "CVSStrictGeometry.h"

@interface CVSViewsStrokeArray ()

@property (nonatomic, readonly) CVSStrokeArray * strokes;

@end

@implementation CVSViewsStrokeArray

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _strokes = [CVSStrokeArray new];
    return self;
}

- (BOOL)hasStrokes
{
    return 0 != self.count;
}

- (NSUInteger)count
{
    return self.strokes.count;
}

- (void)addStroke:(CVSStroke *)pStroke toView:(UIView *)pView
{
    assert(pStroke);
    assert(pView);
    [self.strokes addStroke:pStroke];
    [CVSStrictGeometry invalidateRectOfStroke:pStroke view:pView];
}

- (void)addStrokes:(CVSStrokeArray *)pStrokes toView:(UIView *)pView
{
    assert(pStrokes);
    assert(pView);
    [self.strokes addStrokes:pStrokes];
    [CVSStrictGeometry invalidateRectOfStrokes:pStrokes view:pView];
}

- (void)removeStroke:(CVSStroke *)pStroke fromView:(UIView *)pView
{
    assert(pStroke);
    assert(pView);
    assert([self containsStroke:pStroke]);
    [self.strokes removeStroke:pStroke];
    [CVSStrictGeometry invalidateRectOfStroke:pStroke view:pView];
}

- (CVSStroke *)dequeueLastStroke:(UIView *)pView
{
    CVSStroke * dequeued = self.strokes.dequeueLastStroke;
    if (dequeued) {
        [CVSStrictGeometry invalidateRectOfStroke:dequeued view:pView];
    }
    return dequeued;
}

- (CVSStrokeArray *)dequeueAllStrokes:(UIView *)pView
{
    CVSStrokeArray * dequeued = self.strokes.dequeueAllStrokes;
    if (dequeued.count) {
        [CVSStrictGeometry invalidateRectOfStrokes:dequeued view:pView];
    }
    return dequeued;
}

- (CVSStrokeArray *)dequeueStrokesToFitBelowRenderComplexityThreshold:(CVSMultipleStrokeRenderComplexity)pThreshold view:(UIView *)pView
{
    assert(self.hasStrokes);
    CVSStrokeArray * dequeued = [self.strokes dequeueStrokesToFitBelowRenderComplexityThreshold:pThreshold];
    [CVSStrictGeometry invalidateRectOfStrokes:dequeued view:pView];
    assert(dequeued.count);
    return dequeued;
}

- (CVSStrokeArray *)copyStrokeArray
{
    return self.strokes.mutableCopy;
}

- (BOOL)containsStroke:(CVSStroke *)pStroke
{
    assert(pStroke);
    return [self.strokes containsStroke:pStroke];
}

- (BOOL)containsStrokeWithBrushType:(CVSBrushType)pBrushType
{
    return [self.strokes containsStrokeWithBrushType:pBrushType];
}

- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity
{
    return [self.strokes isMultipleStrokeRenderComplexityBelow:pRenderComplexity];
}

- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect
{
    [self.strokes renderInContext:pContext clippingRect:pClippingRect];
}

- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect useStrokesCGPath:(bool)pUseStrokesCGPath
{
    [self.strokes renderInContext:pContext clippingRect:pClippingRect useStrokesCGPath:pUseStrokesCGPath];
}

- (CGRect)unionOfStrokesBounds
{
    return self.strokes.unionOfStrokesBounds;
}

@end

