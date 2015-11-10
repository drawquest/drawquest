// CVSStrictGeometry.m
// DrawQuest
// Created by Justin Carlson on 10/19/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <UIKit/UIKit.h>
#import "CVSStrictGeometry.h"

#import "CVSStroke.h"
#import "CVSStrokeArray.h"
#import "DQPapertrailLogger.h"

@implementation CVSStrictGeometry

+ (void)setView:(UIView *)pView needsDisplayInRect:(CGRect)pRect
{
    assert(pView);
    assert(!CGRectIsNull(pRect));
    assert(!CGRectIsEmpty(pRect));
    const CGRect bounds = CGRectIntegral(pView.bounds);
    const CGRect intersection = CGRectIntersection(bounds, pRect);
    if (CGRectIsNull(intersection)) {
        return;
    }
    // printf("%s invalidating rect: %s\n", object_getClassName(pView), NSStringFromCGRect(intersection).UTF8String);
    [pView setNeedsDisplayInRect:intersection];
}

+ (void)invalidateRectOfStroke:(CVSStroke *)pStroke view:(UIView *)pView
{
    assert(pStroke);
    if ([pStroke.components count])
    {
        const CGRect bounds = pStroke.bounds;
        if (CGRectIsNull(bounds) || CGRectIsEmpty(bounds)) {
            assert(0 && "invalid stroke");
            return;
        }
        [self setView:pView needsDisplayInRect:bounds];
    }
    else
    {
        [DQPapertrailLogger component:@"strict-geometry" category:@"invalidate-rect-of-stroke-bad-stroke" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"brush": pStroke.brushTypeNumber ?: [NSNull null]};
        }];
    }
}

+ (void)invalidateRectOfStrokes:(CVSStrokeArray *)pStrokeArray view:(UIView *)pView
{
    assert(pStrokeArray.count);
    // the union will probably be faster, but invalidating individual regions can help diagnose invalidation issues.
    const bool Individually = true;
    if (Individually) {
        for (CVSStroke * at in pStrokeArray) {
            [self invalidateRectOfStroke:at view:pView];
        }
    }
    else {
        [self setView:pView needsDisplayInRect:pStrokeArray.unionOfStrokesBounds];
    }
}

+ (CGRect)rectOfUIBezierPathAsDrawn:(UIBezierPath *)pBezierPath
{
    if (!pBezierPath || pBezierPath.isEmpty) {
        assert(0 && "invalid parameter");
        return CGRectNull;
    }
    const CGRect bounds = pBezierPath.bounds;
    if (CGRectIsNull(bounds)) {
        return CGRectNull;
    }
    const CGFloat pathExpansionOffset = 0.5f * pBezierPath.lineWidth;
    assert(0.0f <= pathExpansionOffset);
    const CGRect expanded = CGRectInset(bounds, -pathExpansionOffset, -pathExpansionOffset);
    const CGRect integral = CGRectIntegral(expanded);
    return integral;
}

+ (void)invalidateRectOfUIBezierPath:(UIBezierPath *)pBezierPath view:(UIView *)pView
{
    assert(pBezierPath);
    assert(!pBezierPath.isEmpty);
    const CGFloat pathExpansionOffset = 0.5f * pBezierPath.lineWidth;
    [self invalidateRectOfUIBezierPath:pBezierPath view:pView pathExpansionOffset:pathExpansionOffset];
}

+ (void)invalidateRectOfUIBezierPath:(UIBezierPath *)pBezierPath view:(UIView *)pView pathExpansionOffset:(CGFloat)pPathExpansionOffset
{
    assert(pBezierPath);
    assert(!pBezierPath.isEmpty);
    assert(0 <= pPathExpansionOffset);
    [self invalidateRectOfCGPath:pBezierPath.CGPath view:pView pathExpansionOffset:pPathExpansionOffset];
}

+ (void)invalidateRectOfCGPath:(CGPathRef)pPath view:(UIView *)pView pathExpansionOffset:(CGFloat)pPathExpansionOffset
{
    assert(pPath);
    assert(pView);
    assert(0 <= pPathExpansionOffset);
    assert(!CGPathIsEmpty(pPath));
    const CGRect bounds = CGPathGetBoundingBox(pPath);
    if (CGRectIsNull(bounds)) {
        assert(0 && "reachable?");
        return;
    }
    const CGRect expanded = CGRectInset(bounds, -pPathExpansionOffset, -pPathExpansionOffset);
    const CGRect integral = CGRectIntegral(expanded);
    [self setView:pView needsDisplayInRect:integral];
}

@end
