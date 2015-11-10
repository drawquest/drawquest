// CVSTrackingBrush.m
// DrawQuest
// Created by Justin Carlson on 11/2/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSTrackingBrush.h"
#import "CVSTrackingPath.h"
#import "CVSStrictGeometry.h"

@interface CVSTrackingBrush ()
@property (nonatomic, strong, readwrite) CVSTrackingPath * trackingPath;
@property (nonatomic, assign, readwrite) CVSBrushType brushType;
@end

@implementation CVSTrackingBrush

- (instancetype)initWithBrushType:(CVSBrushType)pBrushType
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _brushType = pBrushType;
    _trackingPath = [CVSTrackingPath new];
    if (!_trackingPath) {
        return nil;
    }
    return self;
}

- (CVSTrackingPath *)trackingPath
{
    assert(self.hasTrackingPath);
    return _trackingPath;
}

- (BOOL)isTracking
{
    return self.trackingPath.hasBezierPath;
}

- (BOOL)hasTrackingPath
{
    return nil != _trackingPath;
}

- (void)invalidateTrackingPath
{
    [self.trackingPath invalidateBezierPath];
}

- (BOOL)isEmpty
{
    return self.trackingPath.isEmpty;
}

- (CGRect)boundingBox
{
    return self.trackingPath.boundingBox;
}

- (CGRect)boundingBoxAsDrawn
{
    return self.trackingPath.boundingBoxAsDrawn;
}

- (CGRect)pathBoundingBox
{
    return self.trackingPath.pathBoundingBox;
}

- (CGPoint)currentPoint
{
    return self.trackingPath.currentPoint;
}

- (void)beginTracking
{
    [self.trackingPath beginTrackingUsingBrushType:self.brushType];
}

- (void)endTracking
{
    [self.trackingPath endTrackingAndInvalidatePath];
}

- (void)endTracking:(UIView *)pView
{
    assert(pView);
    if (!self.isEmpty) {
        [self invalidatePathsRectInView:pView];
    }
    [self endTracking];
}

- (void)ifTrackingEndTracking:(UIView *)pView
{
    assert(pView);
    if (!self.isTracking) {
        return;
    }
    [self endTracking:pView];
}

- (void)invalidateTrackingPathAndPathsRectInView:(UIView *)pView
{
    assert(pView);
    [self invalidatePathsRectInView:pView];
    [self invalidateTrackingPath];
}

- (void)invalidatePathsRectInView:(UIView *)pView
{
    assert(pView);
    [self.trackingPath invalidatePathsRectInView:pView];
}

- (void)appendBezierPath:(UIBezierPath *)pBezierPath
{
    assert(pBezierPath);
    [self.trackingPath appendBezierPath:pBezierPath];
}

- (void)appendPathOfTrackingBrush:(CVSTrackingBrush *)pTrackingBrush
{
    assert(pTrackingBrush);
    CVSTrackingPath * const path = pTrackingBrush.trackingPath;
    assert(path);
    assert(path.hasBezierPath);
    [self.trackingPath appendPathOfTrackingPath:path];
}

- (void)addLineToPoint:(CGPoint)pPoint
{
    [self.trackingPath addLineToPoint:pPoint];
}

- (void)addStrokeComponent:(CVSStrokeComponent *)pStrokeComponent
{
    assert(pStrokeComponent);
    [self.trackingPath addStrokeComponent:pStrokeComponent];
}

- (void)closePath
{
    [self.trackingPath closePath];
}

- (void)addPathToContext:(CGContextRef)pContext
{
    assert(pContext);
    [self.trackingPath addPathToContext:pContext];
}

- (void)strokeWithBlendMode:(CGBlendMode)pBlendMode alpha:(CGFloat)pAlpha
{
    [self.trackingPath strokeWithBlendMode:pBlendMode alpha:pAlpha];
}

@end
