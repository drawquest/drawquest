// CVSViewsStrokeArray.h
// DrawQuest
// Created by Justin Carlson on 10/21/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"
#import "CVSStrokeRenderComplexity.h"

@class CVSStroke;
@class CVSStrokeArray;
@class UIView;

/**
 @class handles interactions between view and its CVSStrokeArray.
 */
@interface CVSViewsStrokeArray : NSObject

/**
 @return YES if this array contains strokes
 */
- (BOOL)hasStrokes;

/**
 @return the number of strokes self contains
 */
- (NSUInteger)count;

/**
 @return YES if this array contains @p pStroke
 */
- (BOOL)containsStroke:(CVSStroke *)pStroke;

/**
 @return YES if this array contains one or more strokes with @p pBrushType
 */
- (BOOL)containsStrokeWithBrushType:(CVSBrushType)pBrushType;

/**
 @brief adds @p pStroke to the array and invalidates the rect of @p pView
 */
- (void)addStroke:(CVSStroke *)pStroke toView:(UIView *)pView;

/**
 @brief adds @p pStrokes to the array and invalidates the rect of @p pView
 */
- (void)addStrokes:(CVSStrokeArray *)pStrokes toView:(UIView *)pView;

/**
 @brief removes @p pStroke from the array and invalidates the rect of @p pView
 */
- (void)removeStroke:(CVSStroke *)pStroke fromView:(UIView *)pView;

/**
 @return an array of strokes at the bottom of the stack -- enough that the render complexity of self's strokes is below @p pThreshold. it invalidates the rect of @p pView containing the dequeued strokes.
 */
- (CVSStrokeArray *)dequeueStrokesToFitBelowRenderComplexityThreshold:(CVSMultipleStrokeRenderComplexity)pThreshold view:(UIView *)pView;

/**
 @return all strokes self represents. it invalidates the rect of @p pView containing the dequeued strokes.
 */
- (CVSStrokeArray *)dequeueAllStrokes:(UIView *)pView;

/**
 @return the top stroke on the stack. it invalidates the rect of @p pView containing the dequeued strokes.
 */
- (CVSStroke *)dequeueLastStroke:(UIView *)pView;

/**
 @return a copy of self's CVSStrokeArray.
 */
- (CVSStrokeArray *)copyStrokeArray;

/**
 @return YES if the render complexity is below the specified threshold.
 */
- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity;

/**
 @brief render all strokes self represents within @p pClippingRect using the context @p pContext.
 */
- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect;

- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect useStrokesCGPath:(bool)pUseStrokesCGPath;

/**
 @return the smallest (integral) rect which fits all strokes as drawn.
 */
- (CGRect)unionOfStrokesBounds;

@end

