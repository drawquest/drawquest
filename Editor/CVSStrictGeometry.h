// CVSStrictGeometry.h
// DrawQuest
// Created by Justin Carlson on 10/19/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

@class CVSStroke;
@class CVSStrokeArray;
@class UIBezierPath;
@class UIView;

/**
 @brief make sure our implementations' geometry is precise
 */
@interface CVSStrictGeometry : NSObject

/**
 @brief invalidates the intersection of @p pRect and @p pView.bounds.
 @details will not invalidate if the rects do not intersect.
 */
+ (void)setView:(UIView *)pView needsDisplayInRect:(CGRect)pRect;

/**
 @brief invalidates the intersection of the view's bounds and the stroke's rect as drawn.
 */
+ (void)invalidateRectOfStroke:(CVSStroke *)pStroke view:(UIView *)pView;

+ (void)invalidateRectOfStrokes:(CVSStrokeArray *)pStrokeArray view:(UIView *)pView;

+ (CGRect)rectOfUIBezierPathAsDrawn:(UIBezierPath *)pBezierPath;

+ (void)invalidateRectOfUIBezierPath:(UIBezierPath *)pBezierPath view:(UIView *)pView;
+ (void)invalidateRectOfCGPath:(CGPathRef)pPath view:(UIView *)pView pathExpansionOffset:(CGFloat)pPathExpansionOffset;

@end
