//
//  CVSStrokeArray.h
//  DrawQuest
//
//  Created by Justin Carlson on 10/14/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"
#import "CVSStrokeRenderComplexity.h"

@class CVSStroke;

/**
 @brief abstraction which helps managing an array of strokes. only add CVSStrokes to this container.
 */
@interface CVSStrokeArray : NSObject <NSMutableCopying,NSFastEnumeration>

+ (instancetype)newStrokeArrayWithStroke:(CVSStroke *)pStroke;

- (NSArray *)strokes;

- (NSUInteger)count;

// common array operations
- (void)addStroke:(CVSStroke *)pStroke;
- (void)addStrokes:(CVSStrokeArray *)pStrokes;
- (void)addStrokesFromArray:(NSArray *)pStrokes;
- (void)removeStroke:(CVSStroke *)pStroke;
- (void)removeAllObjects;

/**
 @return an array with the number of elements requested. the strokes' order is preserved, and the strokes are removed from self.
 */
- (instancetype)dequeueLastNStrokes:(NSUInteger)pNStrokesToDequeue;
- (instancetype)dequeueAllStrokes;
- (CVSStroke *)dequeueZeroethStroke;
- (CVSStroke *)dequeueLastStroke;
- (CVSStrokeArray *)dequeueStrokesToFitBelowRenderComplexityThreshold:(CVSMultipleStrokeRenderComplexity)pThreshold;

- (BOOL)containsStroke:(CVSStroke *)stroke;
- (BOOL)containsStrokeWithBrushType:(CVSBrushType)pBrushType;

/**
 @brief renders all strokes into the context.
 @details the stroke renderer may require that @p pContext is the current UIKit context, if it uses UIBezierPaths (a private rendering option at this time).
 */
- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect;
- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect useStrokesCGPath:(bool)pUseStrokesCGPath;

/**
 @return the union of bounds of all strokes in the collection. self must contain strokes.
 @details the strokes expand to integral rects. it will exclude empty rects from the union (no brush has a width of 0).
 */
- (CGRect)unionOfStrokesBounds;

/**
 @return the sum of estimated render complexity of all strokes.
 */
- (CVSMultipleStrokeRenderComplexity)multipleStrokeRenderComplexity;
- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity;

/**
 @brief purges all CGPaths of all strokes
 */
- (void)purgeStrokesCachedPaths;

@end
