// CVSTrackingBrush.h
// DrawQuest
// Created by Justin Carlson on 11/2/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <Foundation/Foundation.h>
#import "CVSDrawingTypes.h"

@class CVSStrokeComponent;
@class UIView;

/**
 @class type represents a tracking path with an associated "brush".
 */
@interface CVSTrackingBrush : NSObject

// designated initializer
- (instancetype)initWithBrushType:(CVSBrushType)pBrushType;

- (CVSBrushType)brushType;

// actions
/**
 @brief creates a new path using the attributes specified by the active brush. you might call this at the beginning of a new stroke in an editor.
 */
- (void)beginTracking;

/**
 @brief ends the tracking and invalidates the current path. you might call this after a view's stroke has completed.
 */
- (void)endTracking;

/**
 @brief like -endTracking, but will invalidate the rect of the view if tracking and not empty.
 */
- (void)endTracking:(UIView *)pView;

/**
 @brief like -endTracking: but it is not an error if self is not tracking.
 */
- (void)ifTrackingEndTracking:(UIView *)pView;

// identities

/**
 @brief this must be YES to perform general path operations and interactions, such as rendering and composition.
 */
- (BOOL)isTracking;

/**
 @return YES if the path is empty
 */
- (BOOL)isEmpty;

/**
 @return the bounding box for all points, including control points
 */
- (CGRect)boundingBox;
- (CGRect)boundingBoxAsDrawn;

/**
 @return the bounding box for all points, excluding control points
 */
- (CGRect)pathBoundingBox;

/**
 @return the current point of an active path
 */
- (CGPoint)currentPoint;

// view interactions

/**
 @brief invalidates self's tracking path.
 */
- (void)invalidatePathsRectInView:(UIView *)pView;
- (void)invalidateTrackingPathAndPathsRectInView:(UIView *)pView;

// composition
- (void)appendBezierPath:(UIBezierPath *)pBezierPath;
- (void)appendPathOfTrackingBrush:(CVSTrackingBrush *)pTrackingBrush;
- (void)addLineToPoint:(CGPoint)pPoint;
- (void)addStrokeComponent:(CVSStrokeComponent *)pStrokeComponent;
- (void)closePath;

// rendering
- (void)addPathToContext:(CGContextRef)pContext;
- (void)strokeWithBlendMode:(CGBlendMode)pBlendMode alpha:(CGFloat)pAlpha;

@end
