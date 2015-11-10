// CVSTrackingPath.h
// DrawQuest
// Created by Justin Carlson on 11/2/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"

@class CVSStrokeComponent;
@class UIView;

/**
 @class a reconstructible tracking path, often used as an editor's active stroke.
 */
@interface CVSTrackingPath : NSObject

// actions

/**
 @brief creates a new path using the attributes specified by the brush. this will dispose the existing path if present. you might call this at the beginning of a new stroke in an editor.
 */
- (void)beginTrackingUsingBrushType:(CVSBrushType)pBrushType;

/**
 @brief ends the tracking and invalidates the current path. you might call this after a view's stroke has completed.
 */
- (void)endTrackingAndInvalidatePath;

// identities

/**
 @brief this must be YES to perform general path operations and interactions, such as rendering and composition.
 */
- (BOOL)hasBezierPath;
- (void)invalidateBezierPath;

/**
 @return YES if the path is empty
 */
- (BOOL)isEmpty;

/**
 @return the bounding box for all points, including control points
 */
- (CGRect)boundingBox;

/**
 @return the bounding box as drawn.
 @details this is the integral rect of -boundingBox expanded using -lineWidth.
 */
- (CGRect)boundingBoxAsDrawn;

/**
 @return the bounding box for all points, excluding control points
 */
- (CGRect)pathBoundingBox;

/**
 @return the current point of an active path
 */
- (CGPoint)currentPoint;

// drawing properties

- (CGFloat)lineWidth;

// view interactions

/**
 @brief invalidates the path's rect in the view using the default path expansion offset.
 */
- (void)invalidatePathsRectInView:(UIView *)pView;

// composition
- (void)appendBezierPath:(UIBezierPath *)pBezierPath;
- (void)addLineToPoint:(CGPoint)pPoint;
- (void)addStrokeComponent:(CVSStrokeComponent *)pStrokeComponent;
- (void)closePath;

/**
 @brief appends the tracking path's path. the attributes of the other will not remain intact.
 */
- (void)appendPathOfTrackingPath:(CVSTrackingPath *)pTrackingPath;

// rendering
- (void)addPathToContext:(CGContextRef)pContext;
- (void)strokeWithBlendMode:(CGBlendMode)pBlendMode alpha:(CGFloat)pAlpha;

@end
