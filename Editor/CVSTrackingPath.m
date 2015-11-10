// CVSTrackingPath.m
// DrawQuest
// Created by Justin Carlson on 11/2/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSTrackingPath.h"

#import "UIBezierPath+CVSAdditions.h"
#import "CVSStrictGeometry.h"

@interface CVSTrackingPath ()

@property (nonatomic, strong, readwrite) UIBezierPath * bezierPath;

@end

@implementation CVSTrackingPath

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _bezierPath = nil;
    return self;
}

#pragma mark - Properties/Accessors

- (UIBezierPath *)bezierPath
{
    assert(self.hasBezierPath);
    return _bezierPath;
}

- (CGPathRef)CGPath
{
    CGPathRef result = self.bezierPath.CGPath;
    assert(result);
    return result;
}

#pragma mark - Actions

- (void)beginTrackingUsingBrushType:(CVSBrushType)pBrushType
{
    assert(!self.hasBezierPath && "presently tracking");
    self.bezierPath = CVSBrushTypeCreateUIBezierPathWithType(pBrushType);
    assert(self.hasBezierPath);
}

- (void)endTrackingAndInvalidatePath
{
    [self invalidateBezierPath];
}

#pragma mark - Identities

- (BOOL)hasBezierPath
{
    return nil != _bezierPath;
}

- (void)invalidateBezierPath
{
    self.bezierPath = nil;
}

- (BOOL)isEmpty
{
    return self.bezierPath.isEmpty;
}

- (CGRect)boundingBox
{
    return CGPathGetBoundingBox(self.CGPath);
}

- (CGRect)boundingBoxAsDrawn
{
    return [CVSStrictGeometry rectOfUIBezierPathAsDrawn:self.bezierPath];
}

- (CGRect)pathBoundingBox
{
    return CGPathGetPathBoundingBox(self.CGPath);
}

- (CGPoint)currentPoint
{
    return self.bezierPath.currentPoint;
}

#pragma mark - Composition

- (void)appendBezierPath:(UIBezierPath *)pBezierPath
{
    assert(pBezierPath);
    assert(!pBezierPath.isEmpty);
    [self.bezierPath appendPath:pBezierPath];
}

- (void)addLineToPoint:(CGPoint)pPoint
{
    [self.bezierPath addLineToPoint:pPoint];
}

- (void)addStrokeComponent:(CVSStrokeComponent *)pStrokeComponent
{
    [self.bezierPath cvs_addStrokeComponent:pStrokeComponent];
}

- (void)closePath
{
    [self.bezierPath closePath];
}

- (void)appendPathOfTrackingPath:(CVSTrackingPath *)pTrackingPath
{
    assert(self.hasBezierPath);
    [self appendBezierPath:pTrackingPath.bezierPath];
}

#pragma mark - Drawing Properties

- (CGFloat)lineWidth
{
    assert(self.hasBezierPath);
    return self.bezierPath.lineWidth;
}

#pragma mark - View Interactions

- (void)invalidatePathsRectInView:(UIView *)pView
{
    assert(pView);
    assert(!self.isEmpty);
    [CVSStrictGeometry invalidateRectOfUIBezierPath:self.bezierPath view:pView];
}

#pragma mark - Rendering

- (void)addPathToContext:(CGContextRef)pContext
{
    assert(pContext);
    CGContextAddPath(pContext, self.bezierPath.CGPath);
}

- (void)strokeWithBlendMode:(CGBlendMode)pBlendMode alpha:(CGFloat)pAlpha
{
    [self.bezierPath strokeWithBlendMode:pBlendMode alpha:pAlpha];
}

@end
