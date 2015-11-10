//
//  CVSBrushView.m
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSBrushView.h"

static UIColor *strokeColor;
static UIColor *shading;
static UIColor *white;
static UIColor *gray;
static UIBezierPath *paintbrushPath1;
static UIBezierPath *paintbrushPath2;
static UIBezierPath *paintbrushPath3;
static UIBezierPath *paintbrushPath4;
static UIBezierPath *paintbrushPath5;
static UIBezierPath *paintbrushPath6;
static UIBezierPath *paintbrushPath7;
static UIBezierPath *paintbrushPath8;
static UIBezierPath *paintbrushPath9;
static UIBezierPath *paintbrushPath10;
static UIBezierPath *paintbrushPath11;
static UIBezierPath *paintbrushPath12;
static UIBezierPath *paintbrushPath13;
static UIBezierPath *paintbrushPath14;
static UIBezierPath *paintbrushPath15;
static UIBezierPath *paintbrushPath16;
static UIBezierPath *paintbrushPath17;
static UIBezierPath *markerPath1;
static UIBezierPath *markerPath2;
static UIBezierPath *markerPath3;
static UIBezierPath *markerPath4;
static UIBezierPath *markerPath5;
static UIBezierPath *markerPath6;
static UIBezierPath *markerPath7;
static UIBezierPath *markerPath8;
static UIBezierPath *markerPath9;
static UIBezierPath *markerPath10;
static UIBezierPath *markerPath11;
static UIBezierPath *markerPath12;
static UIBezierPath *markerPath13;
static UIBezierPath *markerPath14;
static UIBezierPath *markerPath15;
static UIBezierPath *markerPath16;
static UIBezierPath *pencilPath1;
static UIBezierPath *pencilPath2;
static UIBezierPath *pencilPath3;
static UIBezierPath *pencilPath4;
static UIBezierPath *pencilPath5;
static UIBezierPath *pencilPath6;
static UIBezierPath *pencilPath7;
static UIBezierPath *pencilPath8;
static UIBezierPath *pencilPath9;
static UIBezierPath *pencilPath10;
static UIBezierPath *pencilPath11;
static UIBezierPath *pencilPath12;
static UIBezierPath *pencilPath13;
static UIBezierPath *pencilPath14;
static UIBezierPath *pencilPath15;
static UIBezierPath *eraserPath1;
static UIBezierPath *eraserPath2;
static UIBezierPath *eraserPath3;
static UIBezierPath *eraserPath4;
static UIBezierPath *eraserPath5;
static UIBezierPath *eraserPath6;
static UIBezierPath *eraserPath7;
static UIBezierPath *spraypaintPath1;
static UIBezierPath *spraypaintPath2;
static UIBezierPath *spraypaintPath3;
static UIBezierPath *spraypaintPath4;
static UIBezierPath *spraypaintPath5;
static UIBezierPath *spraypaintPath6;
static UIBezierPath *spraypaintPath7;
static UIBezierPath *spraypaintPath8;
static UIBezierPath *spraypaintPath9;
static UIBezierPath *spraypaintPath10;
static UIBezierPath *spraypaintPath11;
static UIBezierPath *spraypaintPath12;
static UIBezierPath *spraypaintPath13;
static UIBezierPath *spraypaintPath14;
static UIBezierPath *spraypaintPath15;
static UIBezierPath *spraypaintPath16;
static UIBezierPath *spraypaintPath17;
static UIBezierPath *spraypaintPath18;
static UIBezierPath *spraypaintPath19;
static UIBezierPath *spraypaintPath20;
static UIBezierPath *crayonPath1;
static UIBezierPath *crayonPath2;
static UIBezierPath *crayonPath3;
static UIBezierPath *crayonPath4;
static UIBezierPath *crayonPath5;
static UIBezierPath *crayonPath6;
static UIBezierPath *crayonPath7;
static UIBezierPath *crayonPath8;
static UIBezierPath *crayonPath9;
static UIBezierPath *crayonPath10;
static UIBezierPath *crayonPath11;
static UIBezierPath *crayonPath12;
static UIBezierPath *crayonPath13;
static UIBezierPath *crayonPath14;
static UIBezierPath *crayonPath15;
static UIBezierPath *crayonPath16;
static UIBezierPath *paintbucketPath1;
static UIBezierPath *paintbucketPath2;
static UIBezierPath *paintbucketPath3;
static UIBezierPath *paintbucketPath4;
static UIBezierPath *paintbucketPath5;
static UIBezierPath *paintbucketPath6;
static UIBezierPath *paintbucketPath7;
static UIBezierPath *paintbucketPath8;
static UIBezierPath *paintbucketPath9;
static UIBezierPath *paintbucketPath10;
static UIBezierPath *paintbucketPath11;
static UIBezierPath *paintbucketPath12;
static UIBezierPath *paintbucketPath13;
static UIBezierPath *paintbucketPath14;
static UIBezierPath *paintbucketPath15;
static UIBezierPath *paintbucketPath16;
static UIBezierPath *paintbucketPath17;


@implementation CVSBrushView

- (id)initWithBrushType:(CVSBrushType)brushType activeColor:(UIColor *)activeColor hasSmile:(BOOL)hasSmile
{
    CGRect frame = CGRectZero;
    _scale = 1.0f;
    frame.size = [[self class] sizeForBrushType:brushType];
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setOpaque:NO];
        
        _brushType = brushType;
        _activeColor = (brushType != CVSBrushTypeEraser) ? activeColor : [UIColor colorWithRed: 0.885 green: 0.525 blue: 0.643 alpha: 1];
        self.tintColor = _activeColor;
        _hasSmile = hasSmile;
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    [self setNeedsDisplay];
}

- (void)setScale:(CGFloat)scale
{
    _scale = scale;
    if (scale != 1.0)
    {
        self.transform = CGAffineTransformMakeScale(scale, scale);
    }
    else
    {
        self.transform = CGAffineTransformIdentity;
    }
}

#pragma mark - Accessors

- (void)setBrushType:(CVSBrushType)brushType
{
    _brushType = brushType;
    CGRect frame = self.frame;
    frame.size = [self boundsSize];
    self.frame = frame;
    [self setNeedsDisplay];
}

- (void)setActiveColor:(UIColor *)activeColor
{
    // Eraser can safely ignore these calls as we always want it to be pink
    if (self.brushType != CVSBrushTypeEraser)
    {
        [self setTintColor:activeColor];
        _activeColor = activeColor;
    }
}

- (void)setHasSmile:(BOOL)hasSmile
{
    _hasSmile = hasSmile;
    [self setNeedsDisplay];
}

#pragma mark - Helper

+ (CGFloat)maxWidth
{
    CGFloat maxWidth = 0.0f;
    for (CVSBrushType i = 0; i < CVSBrushTypeCount; i++)
    {
        CGFloat width = [self sizeForBrushType:i].width;
        if (width > maxWidth)
        {
            maxWidth = width;
        }
    }
    return maxWidth;
}

+ (CGSize)sizeForBrushType:(CVSBrushType)brushType
{
    switch (brushType)
    {
        case CVSBrushTypePaintbrush:
            return (CGSize){.width = 38.0, .height = 210.0};
            break;
        case CVSBrushTypeMarker:
            return (CGSize){.width = 46.0, .height = 210.0};
            break;
        case CVSBrushTypePen:
            return (CGSize){.width = 37.0, .height = 210.0};
            break;
        case CVSBrushTypeSpraypaint:
            return (CGSize){.width = 60.0, .height = 172.0};
            break;
        case CVSBrushTypeCrayon:
            return (CGSize){.width = 36.0, .height = 210.0f};
            break;
        case CVSBrushTypePaintbucket:
            return (CGSize){.width = 67.0f, .height = 210.0f};
            break;
        case CVSBrushTypeEraser:
            return (CGSize){.width = 40.0, .height = 110.0};
            break;
        default:
            return CGSizeZero;
            break;
    }
}

#pragma mark - Drawing

+ (void)initialize
{
    if (self == [CVSBrushView class])
    {
        // Shared colors
        strokeColor = [UIColor colorWithRed: 0.229 green: 0.229 blue: 0.229 alpha: 1];
        shading = [UIColor colorWithRed: 0.229 green: 0.229 blue: 0.229 alpha: 0.1];
        white = [UIColor whiteColor];
        gray = [UIColor colorWithRed: 0.66 green: 0.651 blue: 0.647 alpha: 1];
        
        // Paintbrush Paths
        paintbrushPath1 = [UIBezierPath bezierPath];
        [paintbrushPath1 moveToPoint: CGPointMake(11.88, 50.31)];
        [paintbrushPath1 addCurveToPoint: CGPointMake(13.27, 58.73) controlPoint1: CGPointMake(12.09, 51.92) controlPoint2: CGPointMake(12.33, 57.7)];
        [paintbrushPath1 addCurveToPoint: CGPointMake(23.83, 58.68) controlPoint1: CGPointMake(14.21, 59.76) controlPoint2: CGPointMake(22.99, 59.7)];
        [paintbrushPath1 addCurveToPoint: CGPointMake(25.19, 50.63) controlPoint1: CGPointMake(24.88, 57.65) controlPoint2: CGPointMake(24.88, 52.39)];
        paintbrushPath1.miterLimit = 4;
        paintbrushPath2 = [UIBezierPath bezierPath];
        [paintbrushPath2 moveToPoint: CGPointMake(36.78, 23.88)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(32.71, 24.83) controlPoint1: CGPointMake(36.19, 25.76) controlPoint2: CGPointMake(34.37, 27.04)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(27.39, 18.96) controlPoint1: CGPointMake(31.46, 23.16) controlPoint2: CGPointMake(30.39, 17.22)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(23.04, 22.54) controlPoint1: CGPointMake(25.5, 20.06) controlPoint2: CGPointMake(25.7, 22.8)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(18.85, 17.67) controlPoint1: CGPointMake(19.59, 22.2) controlPoint2: CGPointMake(20.91, 19.27)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(15.28, 15.27) controlPoint1: CGPointMake(17.11, 16.32) controlPoint2: CGPointMake(17.07, 17.43)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(14.96, 14.64) controlPoint1: CGPointMake(15.11, 15.06) controlPoint2: CGPointMake(15.01, 14.85)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(14.4, 14.97) controlPoint1: CGPointMake(14.77, 14.76) controlPoint2: CGPointMake(14.59, 14.87)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(1.15, 35.61) controlPoint1: CGPointMake(6.66, 19.21) controlPoint2: CGPointMake(0.39, 26.37)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(15.43, 51.26) controlPoint1: CGPointMake(1.86, 44.35) controlPoint2: CGPointMake(6.99, 49.73)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(32.64, 44.48) controlPoint1: CGPointMake(22.1, 52.46) controlPoint2: CGPointMake(28.62, 49.95)];
        [paintbrushPath2 addCurveToPoint: CGPointMake(36.78, 23.88) controlPoint1: CGPointMake(36.57, 39.14) controlPoint2: CGPointMake(38.08, 31.1)];
        [paintbrushPath2 closePath];
        paintbrushPath2.miterLimit = 4;
        paintbrushPath3 = [UIBezierPath bezierPath];
        [paintbrushPath3 moveToPoint: CGPointMake(22.27, 59.14)];
        [paintbrushPath3 addCurveToPoint: CGPointMake(21.65, 206.88) controlPoint1: CGPointMake(21.81, 68.82) controlPoint2: CGPointMake(21.87, 189.98)];
        [paintbrushPath3 addCurveToPoint: CGPointMake(14.09, 206.76) controlPoint1: CGPointMake(21.62, 209.45) controlPoint2: CGPointMake(14.17, 208.99)];
        [paintbrushPath3 addCurveToPoint: CGPointMake(13.97, 59.16) controlPoint1: CGPointMake(13.35, 186.34) controlPoint2: CGPointMake(13.72, 69.33)];
        [paintbrushPath3 addLineToPoint: CGPointMake(22.27, 59.14)];
        [paintbrushPath3 closePath];
        paintbrushPath3.miterLimit = 4;
        paintbrushPath4 = [UIBezierPath bezierPath];
        [paintbrushPath4 moveToPoint: CGPointMake(32.81, 8.49)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(30.22, 3.69) controlPoint1: CGPointMake(32.12, 6.8) controlPoint2: CGPointMake(31.22, 5.19)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(26.49, 1.94) controlPoint1: CGPointMake(29.32, 2.35) controlPoint2: CGPointMake(27.77, 0.19)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(25.44, 5.72) controlPoint1: CGPointMake(26.02, 2.59) controlPoint2: CGPointMake(26.42, 4.13)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(16.98, 12.05) controlPoint1: CGPointMake(23.52, 8.81) controlPoint2: CGPointMake(19.97, 10.56)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(15.29, 15.27) controlPoint1: CGPointMake(15.55, 12.75) controlPoint2: CGPointMake(14.25, 14.02)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(18.85, 17.67) controlPoint1: CGPointMake(17.08, 17.44) controlPoint2: CGPointMake(17.11, 16.32)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(23.04, 22.54) controlPoint1: CGPointMake(20.91, 19.27) controlPoint2: CGPointMake(19.59, 22.21)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(27.39, 18.96) controlPoint1: CGPointMake(25.7, 22.81) controlPoint2: CGPointMake(25.5, 20.06)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(32.72, 24.83) controlPoint1: CGPointMake(30.39, 17.22) controlPoint2: CGPointMake(31.46, 23.16)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(36.98, 22.64) controlPoint1: CGPointMake(34.72, 27.51) controlPoint2: CGPointMake(36.97, 25.06)];
        [paintbrushPath4 addCurveToPoint: CGPointMake(32.81, 8.49) controlPoint1: CGPointMake(37, 17.18) controlPoint2: CGPointMake(33.01, 8.97)];
        [paintbrushPath4 closePath];
        paintbrushPath4.miterLimit = 4;
        paintbrushPath5 = [UIBezierPath bezierPath];
        [paintbrushPath5 moveToPoint: CGPointMake(22.43, 59.14)];
        [paintbrushPath5 addCurveToPoint: CGPointMake(21.81, 206.88) controlPoint1: CGPointMake(21.97, 68.82) controlPoint2: CGPointMake(22.03, 189.98)];
        [paintbrushPath5 addCurveToPoint: CGPointMake(14.25, 206.76) controlPoint1: CGPointMake(21.78, 209.45) controlPoint2: CGPointMake(14.33, 208.99)];
        [paintbrushPath5 addCurveToPoint: CGPointMake(14.13, 59.16) controlPoint1: CGPointMake(13.51, 186.34) controlPoint2: CGPointMake(13.88, 69.33)];
        [paintbrushPath5 addLineToPoint: CGPointMake(22.43, 59.14)];
        [paintbrushPath5 closePath];
        paintbrushPath5.lineCapStyle = kCGLineCapRound;
        paintbrushPath5.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath5.lineWidth = 1.5;
        paintbrushPath6 = [UIBezierPath bezierPath];
        [paintbrushPath6 moveToPoint: CGPointMake(11.66, 50.31)];
        [paintbrushPath6 addCurveToPoint: CGPointMake(13.05, 58.73) controlPoint1: CGPointMake(11.87, 51.92) controlPoint2: CGPointMake(12.1, 57.7)];
        [paintbrushPath6 addCurveToPoint: CGPointMake(23.6, 58.68) controlPoint1: CGPointMake(13.98, 59.76) controlPoint2: CGPointMake(22.76, 59.7)];
        [paintbrushPath6 addCurveToPoint: CGPointMake(24.97, 50.63) controlPoint1: CGPointMake(24.65, 57.65) controlPoint2: CGPointMake(24.65, 52.39)];
        paintbrushPath6.lineCapStyle = kCGLineCapRound;
        paintbrushPath6.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath6.lineWidth = 1.5;
        paintbrushPath7 = [UIBezierPath bezierPath];
        [paintbrushPath7 moveToPoint: CGPointMake(17.07, 17.2)];
        [paintbrushPath7 addCurveToPoint: CGPointMake(8.34, 31.8) controlPoint1: CGPointMake(13.24, 21.53) controlPoint2: CGPointMake(8.98, 24.48)];
        paintbrushPath7.lineCapStyle = kCGLineCapRound;
        paintbrushPath7.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath7.lineWidth = 1.5;
        paintbrushPath8 = [UIBezierPath bezierPath];
        [paintbrushPath8 moveToPoint: CGPointMake(19.97, 19.25)];
        [paintbrushPath8 addCurveToPoint: CGPointMake(16.8, 25.74) controlPoint1: CGPointMake(18.71, 21.33) controlPoint2: CGPointMake(17.53, 23.44)];
        paintbrushPath8.lineCapStyle = kCGLineCapRound;
        paintbrushPath8.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath8.lineWidth = 1.5;
        paintbrushPath9 = [UIBezierPath bezierPath];
        [paintbrushPath9 moveToPoint: CGPointMake(32, 23.47)];
        [paintbrushPath9 addCurveToPoint: CGPointMake(29.3, 33.87) controlPoint1: CGPointMake(31.68, 26.98) controlPoint2: CGPointMake(30.95, 30.43)];
        paintbrushPath9.lineCapStyle = kCGLineCapRound;
        paintbrushPath9.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath9.lineWidth = 1.5;
        paintbrushPath10 = [UIBezierPath bezierPath];
        [paintbrushPath10 moveToPoint: CGPointMake(36.78, 23.88)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(32.71, 24.83) controlPoint1: CGPointMake(36.19, 25.76) controlPoint2: CGPointMake(34.37, 27.04)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(27.39, 18.96) controlPoint1: CGPointMake(31.46, 23.16) controlPoint2: CGPointMake(30.39, 17.22)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(23.04, 22.54) controlPoint1: CGPointMake(25.5, 20.06) controlPoint2: CGPointMake(25.7, 22.8)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(18.85, 17.67) controlPoint1: CGPointMake(19.59, 22.2) controlPoint2: CGPointMake(20.91, 19.27)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(15.28, 15.27) controlPoint1: CGPointMake(17.11, 16.32) controlPoint2: CGPointMake(17.07, 17.43)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(14.96, 14.64) controlPoint1: CGPointMake(15.11, 15.06) controlPoint2: CGPointMake(15.01, 14.85)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(14.4, 14.97) controlPoint1: CGPointMake(14.77, 14.76) controlPoint2: CGPointMake(14.59, 14.87)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(1.15, 35.61) controlPoint1: CGPointMake(6.66, 19.21) controlPoint2: CGPointMake(0.39, 26.37)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(15.43, 51.26) controlPoint1: CGPointMake(1.86, 44.35) controlPoint2: CGPointMake(6.99, 49.73)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(32.64, 44.48) controlPoint1: CGPointMake(22.1, 52.46) controlPoint2: CGPointMake(28.62, 49.95)];
        [paintbrushPath10 addCurveToPoint: CGPointMake(36.78, 23.88) controlPoint1: CGPointMake(36.57, 39.14) controlPoint2: CGPointMake(38.08, 31.1)];
        [paintbrushPath10 closePath];
        paintbrushPath10.lineCapStyle = kCGLineCapRound;
        paintbrushPath10.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath10.lineWidth = 1.5;
        paintbrushPath11 = [UIBezierPath bezierPath];
        [paintbrushPath11 moveToPoint: CGPointMake(32.81, 8.48)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(30.22, 3.69) controlPoint1: CGPointMake(32.11, 6.8) controlPoint2: CGPointMake(31.21, 5.19)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(26.49, 1.94) controlPoint1: CGPointMake(29.32, 2.35) controlPoint2: CGPointMake(27.77, 0.19)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(25.43, 5.71) controlPoint1: CGPointMake(26.02, 2.59) controlPoint2: CGPointMake(26.42, 4.12)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(16.97, 12.04) controlPoint1: CGPointMake(23.52, 8.81) controlPoint2: CGPointMake(19.97, 10.56)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(14.95, 14.64) controlPoint1: CGPointMake(15.79, 12.63) controlPoint2: CGPointMake(14.69, 13.61)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(15.28, 15.27) controlPoint1: CGPointMake(15.01, 14.85) controlPoint2: CGPointMake(15.11, 15.06)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(18.85, 17.67) controlPoint1: CGPointMake(17.07, 17.43) controlPoint2: CGPointMake(17.11, 16.32)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(23.04, 22.54) controlPoint1: CGPointMake(20.91, 19.27) controlPoint2: CGPointMake(19.59, 22.2)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(27.38, 18.96) controlPoint1: CGPointMake(25.69, 22.8) controlPoint2: CGPointMake(25.5, 20.06)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(32.71, 24.83) controlPoint1: CGPointMake(30.38, 17.22) controlPoint2: CGPointMake(31.46, 23.15)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(36.78, 23.88) controlPoint1: CGPointMake(34.37, 27.04) controlPoint2: CGPointMake(36.19, 25.76)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(36.98, 22.63) controlPoint1: CGPointMake(36.9, 23.48) controlPoint2: CGPointMake(36.97, 23.06)];
        [paintbrushPath11 addCurveToPoint: CGPointMake(32.81, 8.48) controlPoint1: CGPointMake(37, 17.18) controlPoint2: CGPointMake(33.01, 8.97)];
        [paintbrushPath11 closePath];
        paintbrushPath11.lineCapStyle = kCGLineCapRound;
        paintbrushPath11.lineJoinStyle = kCGLineJoinRound;
        paintbrushPath11.lineWidth = 1.5;
        paintbrushPath12 = [UIBezierPath bezierPath];
        [paintbrushPath12 moveToPoint: CGPointMake(22.43, 59.65)];
        [paintbrushPath12 addCurveToPoint: CGPointMake(21.92, 206.88) controlPoint1: CGPointMake(22.43, 59.65) controlPoint2: CGPointMake(22.14, 189.98)];
        [paintbrushPath12 addCurveToPoint: CGPointMake(18.85, 208.39) controlPoint1: CGPointMake(21.89, 209.45) controlPoint2: CGPointMake(18.85, 208.39)];
        [paintbrushPath12 addLineToPoint: CGPointMake(18.85, 59.34)];
        [paintbrushPath12 addLineToPoint: CGPointMake(22.43, 59.65)];
        [paintbrushPath12 closePath];
        paintbrushPath12.miterLimit = 4;
        paintbrushPath13 = [UIBezierPath bezierPath];
        [paintbrushPath13 moveToPoint: CGPointMake(18.64, 50.65)];
        [paintbrushPath13 addLineToPoint: CGPointMake(18.54, 59.65)];
        [paintbrushPath13 addCurveToPoint: CGPointMake(23.6, 58.85) controlPoint1: CGPointMake(20.89, 59.62) controlPoint2: CGPointMake(23.19, 59.35)];
        [paintbrushPath13 addCurveToPoint: CGPointMake(24.97, 50.8) controlPoint1: CGPointMake(24.65, 57.82) controlPoint2: CGPointMake(24.65, 52.56)];
        [paintbrushPath13 addLineToPoint: CGPointMake(18.64, 50.65)];
        [paintbrushPath13 closePath];
        paintbrushPath13.miterLimit = 4;
        paintbrushPath14 = [UIBezierPath bezierPath];
        [paintbrushPath14 moveToPoint: CGPointMake(15.17, 51.02)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(32.38, 44.25) controlPoint1: CGPointMake(21.84, 52.23) controlPoint2: CGPointMake(28.36, 49.72)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(36.67, 33.1) controlPoint1: CGPointMake(34.77, 41) controlPoint2: CGPointMake(36.11, 37.06)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(36.33, 24.85) controlPoint1: CGPointMake(37.24, 29.16) controlPoint2: CGPointMake(37.22, 28)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(32.32, 24.17) controlPoint1: CGPointMake(34.45, 27.19) controlPoint2: CGPointMake(33.68, 25.74)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(31.2, 30.34) controlPoint1: CGPointMake(32.12, 26.86) controlPoint2: CGPointMake(31.77, 27.21)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(22.69, 44.37) controlPoint1: CGPointMake(30.76, 32.76) controlPoint2: CGPointMake(27.72, 40.2)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(10.89, 49.65) controlPoint1: CGPointMake(21.21, 45.59) controlPoint2: CGPointMake(17.36, 48.83)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(12.75, 50.41) controlPoint1: CGPointMake(11.41, 49.48) controlPoint2: CGPointMake(12.28, 50.24)];
        [paintbrushPath14 addCurveToPoint: CGPointMake(15.17, 51.02) controlPoint1: CGPointMake(13.51, 50.7) controlPoint2: CGPointMake(14.37, 50.88)];
        [paintbrushPath14 closePath];
        paintbrushPath14.miterLimit = 4;
        paintbrushPath15 = [UIBezierPath bezierPath];
        [paintbrushPath15 moveToPoint: CGPointMake(8.63, 41.01)];
        [paintbrushPath15 addCurveToPoint: CGPointMake(8.63, 38.73) controlPoint1: CGPointMake(10.11, 41.01) controlPoint2: CGPointMake(10.11, 38.73)];
        [paintbrushPath15 addCurveToPoint: CGPointMake(8.63, 41.01) controlPoint1: CGPointMake(7.16, 38.73) controlPoint2: CGPointMake(7.16, 41.01)];
        [paintbrushPath15 addLineToPoint: CGPointMake(8.63, 41.01)];
        [paintbrushPath15 closePath];
        paintbrushPath15.miterLimit = 4;
        paintbrushPath16 = [UIBezierPath bezierPath];
        [paintbrushPath16 moveToPoint: CGPointMake(28.12, 41.79)];
        [paintbrushPath16 addCurveToPoint: CGPointMake(28.12, 39.5) controlPoint1: CGPointMake(29.59, 41.79) controlPoint2: CGPointMake(29.59, 39.5)];
        [paintbrushPath16 addCurveToPoint: CGPointMake(28.12, 41.79) controlPoint1: CGPointMake(26.65, 39.5) controlPoint2: CGPointMake(26.65, 41.79)];
        [paintbrushPath16 addLineToPoint: CGPointMake(28.12, 41.79)];
        [paintbrushPath16 closePath];
        paintbrushPath16.miterLimit = 4;
        paintbrushPath17 = [UIBezierPath bezierPath];
        [paintbrushPath17 moveToPoint: CGPointMake(15.62, 41.77)];
        [paintbrushPath17 addCurveToPoint: CGPointMake(17.82, 44.26) controlPoint1: CGPointMake(15.55, 43.13) controlPoint2: CGPointMake(16.49, 44.11)];
        [paintbrushPath17 addCurveToPoint: CGPointMake(20.31, 41.78) controlPoint1: CGPointMake(19.31, 44.42) controlPoint2: CGPointMake(20.27, 43.15)];
        [paintbrushPath17 addCurveToPoint: CGPointMake(19.59, 41.78) controlPoint1: CGPointMake(20.33, 41.31) controlPoint2: CGPointMake(19.61, 41.32)];
        [paintbrushPath17 addCurveToPoint: CGPointMake(17.95, 43.55) controlPoint1: CGPointMake(19.56, 42.78) controlPoint2: CGPointMake(18.99, 43.54)];
        [paintbrushPath17 addCurveToPoint: CGPointMake(16.34, 41.77) controlPoint1: CGPointMake(16.94, 43.55) controlPoint2: CGPointMake(16.29, 42.72)];
        [paintbrushPath17 addCurveToPoint: CGPointMake(15.62, 41.77) controlPoint1: CGPointMake(16.37, 41.31) controlPoint2: CGPointMake(15.65, 41.31)];
        [paintbrushPath17 addLineToPoint: CGPointMake(15.62, 41.77)];
        [paintbrushPath17 closePath];
        paintbrushPath17.miterLimit = 4;
        
        // Marker Paths
        markerPath1 = [UIBezierPath bezierPath];
        [markerPath1 moveToPoint: CGPointMake(44.84, 52.75)];
        [markerPath1 addCurveToPoint: CGPointMake(1.3, 53.15) controlPoint1: CGPointMake(33.77, 54.8) controlPoint2: CGPointMake(12.07, 54.97)];
        [markerPath1 addCurveToPoint: CGPointMake(0.77, 202.03) controlPoint1: CGPointMake(1.1, 96.32) controlPoint2: CGPointMake(0.64, 201.01)];
        [markerPath1 addCurveToPoint: CGPointMake(2.34, 203.52) controlPoint1: CGPointMake(0.77, 202.03) controlPoint2: CGPointMake(1.44, 203.35)];
        [markerPath1 addCurveToPoint: CGPointMake(2.85, 203.61) controlPoint1: CGPointMake(2.52, 203.55) controlPoint2: CGPointMake(2.68, 203.58)];
        [markerPath1 addCurveToPoint: CGPointMake(9.67, 203.88) controlPoint1: CGPointMake(5.59, 204.07) controlPoint2: CGPointMake(6.68, 203.8)];
        [markerPath1 addCurveToPoint: CGPointMake(28.25, 204.18) controlPoint1: CGPointMake(15.86, 204.03) controlPoint2: CGPointMake(22.06, 204.14)];
        [markerPath1 addCurveToPoint: CGPointMake(42.8, 203.98) controlPoint1: CGPointMake(31.86, 204.2) controlPoint2: CGPointMake(41.59, 203.96)];
        [markerPath1 addCurveToPoint: CGPointMake(43.03, 203.97) controlPoint1: CGPointMake(42.89, 203.99) controlPoint2: CGPointMake(42.96, 203.97)];
        [markerPath1 addCurveToPoint: CGPointMake(44.75, 202.5) controlPoint1: CGPointMake(44.16, 203.89) controlPoint2: CGPointMake(44.67, 203.07)];
        [markerPath1 addCurveToPoint: CGPointMake(44.84, 52.75) controlPoint1: CGPointMake(45.13, 199.54) controlPoint2: CGPointMake(44.93, 95.55)];
        [markerPath1 closePath];
        markerPath1.miterLimit = 4;
        markerPath2 = [UIBezierPath bezierPath];
        [markerPath2 moveToPoint: CGPointMake(44.59, 40.73)];
        [markerPath2 addCurveToPoint: CGPointMake(44.57, 34.63) controlPoint1: CGPointMake(44.58, 36.9) controlPoint2: CGPointMake(44.57, 34.7)];
        [markerPath2 addLineToPoint: CGPointMake(42.68, 28.96)];
        [markerPath2 addCurveToPoint: CGPointMake(42.54, 24.56) controlPoint1: CGPointMake(42.68, 28.96) controlPoint2: CGPointMake(42.53, 26.03)];
        [markerPath2 addCurveToPoint: CGPointMake(16.83, 24.65) controlPoint1: CGPointMake(42.54, 24.56) controlPoint2: CGPointMake(25.42, 24.48)];
        [markerPath2 addCurveToPoint: CGPointMake(7.62, 24.78) controlPoint1: CGPointMake(13.76, 24.71) controlPoint2: CGPointMake(10.69, 24.76)];
        [markerPath2 addCurveToPoint: CGPointMake(5.28, 24.79) controlPoint1: CGPointMake(6.84, 24.79) controlPoint2: CGPointMake(6.06, 24.79)];
        [markerPath2 addCurveToPoint: CGPointMake(3.34, 24.91) controlPoint1: CGPointMake(4.84, 24.79) controlPoint2: CGPointMake(3.34, 24.91)];
        [markerPath2 addCurveToPoint: CGPointMake(3.07, 29.35) controlPoint1: CGPointMake(3.34, 24.91) controlPoint2: CGPointMake(3.07, 28.58)];
        [markerPath2 addLineToPoint: CGPointMake(1.16, 34.84)];
        [markerPath2 addCurveToPoint: CGPointMake(1.13, 41.06) controlPoint1: CGPointMake(1.16, 34.84) controlPoint2: CGPointMake(1.15, 37.09)];
        [markerPath2 addCurveToPoint: CGPointMake(44.59, 40.73) controlPoint1: CGPointMake(11.94, 42.86) controlPoint2: CGPointMake(33.52, 42.73)];
        [markerPath2 closePath];
        markerPath2.miterLimit = 4;
        markerPath3 = [UIBezierPath bezierPath];
        [markerPath3 moveToPoint: CGPointMake(28.25, 204.18)];
        [markerPath3 addCurveToPoint: CGPointMake(9.67, 203.88) controlPoint1: CGPointMake(22.06, 204.14) controlPoint2: CGPointMake(15.86, 204.03)];
        [markerPath3 addCurveToPoint: CGPointMake(2.85, 203.61) controlPoint1: CGPointMake(6.68, 203.8) controlPoint2: CGPointMake(5.59, 204.07)];
        [markerPath3 addCurveToPoint: CGPointMake(3.57, 207.97) controlPoint1: CGPointMake(2.75, 205.6) controlPoint2: CGPointMake(2.92, 207.77)];
        [markerPath3 addCurveToPoint: CGPointMake(42.2, 208.2) controlPoint1: CGPointMake(6.19, 208.78) controlPoint2: CGPointMake(41.17, 208.24)];
        [markerPath3 addCurveToPoint: CGPointMake(43.04, 203.97) controlPoint1: CGPointMake(42.85, 208.17) controlPoint2: CGPointMake(43.06, 206.25)];
        [markerPath3 addCurveToPoint: CGPointMake(42.8, 203.98) controlPoint1: CGPointMake(42.96, 203.97) controlPoint2: CGPointMake(42.89, 203.98)];
        [markerPath3 addCurveToPoint: CGPointMake(28.25, 204.18) controlPoint1: CGPointMake(41.59, 203.96) controlPoint2: CGPointMake(31.87, 204.2)];
        [markerPath3 closePath];
        markerPath3.miterLimit = 4;
        markerPath4 = [UIBezierPath bezierPath];
        [markerPath4 moveToPoint: CGPointMake(1.15, 41.06)];
        [markerPath4 addCurveToPoint: CGPointMake(1.09, 53.15) controlPoint1: CGPointMake(1.13, 44.14) controlPoint2: CGPointMake(1.11, 48.25)];
        [markerPath4 addCurveToPoint: CGPointMake(44.63, 52.75) controlPoint1: CGPointMake(11.86, 54.97) controlPoint2: CGPointMake(33.56, 54.8)];
        [markerPath4 addCurveToPoint: CGPointMake(44.6, 40.74) controlPoint1: CGPointMake(44.62, 47.87) controlPoint2: CGPointMake(44.61, 43.78)];
        [markerPath4 addCurveToPoint: CGPointMake(1.15, 41.06) controlPoint1: CGPointMake(33.53, 42.74) controlPoint2: CGPointMake(14.03, 42.33)];
        [markerPath4 closePath];
        markerPath4.miterLimit = 4;
        markerPath5 = [UIBezierPath bezierPath];
        [markerPath5 moveToPoint: CGPointMake(4.49, 24.92)];
        [markerPath5 addCurveToPoint: CGPointMake(6.57, 1.26) controlPoint1: CGPointMake(4.5, 18.97) controlPoint2: CGPointMake(3.81, 2.32)];
        [markerPath5 addCurveToPoint: CGPointMake(37.24, 12.78) controlPoint1: CGPointMake(10.32, -0.19) controlPoint2: CGPointMake(31.32, 10.63)];
        [markerPath5 addCurveToPoint: CGPointMake(42.1, 20.29) controlPoint1: CGPointMake(41.47, 14.31) controlPoint2: CGPointMake(42.1, 16.93)];
        [markerPath5 addCurveToPoint: CGPointMake(42.09, 24.85) controlPoint1: CGPointMake(42.09, 22.58) controlPoint2: CGPointMake(42.09, 22.56)];
        markerPath5.miterLimit = 4;
        markerPath6 = [UIBezierPath bezierPath];
        [markerPath6 moveToPoint: CGPointMake(28.25, 204.18)];
        [markerPath6 addCurveToPoint: CGPointMake(9.67, 203.88) controlPoint1: CGPointMake(22.06, 204.14) controlPoint2: CGPointMake(15.86, 204.03)];
        [markerPath6 addCurveToPoint: CGPointMake(2.85, 203.61) controlPoint1: CGPointMake(6.68, 203.81) controlPoint2: CGPointMake(5.6, 204.07)];
        [markerPath6 addCurveToPoint: CGPointMake(3.57, 207.97) controlPoint1: CGPointMake(2.75, 205.6) controlPoint2: CGPointMake(2.92, 207.77)];
        [markerPath6 addCurveToPoint: CGPointMake(42.2, 208.2) controlPoint1: CGPointMake(6.19, 208.78) controlPoint2: CGPointMake(41.17, 208.25)];
        [markerPath6 addCurveToPoint: CGPointMake(43.04, 203.97) controlPoint1: CGPointMake(42.85, 208.18) controlPoint2: CGPointMake(43.07, 206.25)];
        [markerPath6 addCurveToPoint: CGPointMake(42.8, 203.99) controlPoint1: CGPointMake(42.96, 203.97) controlPoint2: CGPointMake(42.89, 203.99)];
        [markerPath6 addCurveToPoint: CGPointMake(28.25, 204.18) controlPoint1: CGPointMake(41.59, 203.96) controlPoint2: CGPointMake(31.87, 204.2)];
        [markerPath6 closePath];
        markerPath6.lineWidth = 1.5;
        markerPath7 = [UIBezierPath bezierPath];
        [markerPath7 moveToPoint: CGPointMake(4.49, 24.54)];
        [markerPath7 addCurveToPoint: CGPointMake(6.57, 0.88) controlPoint1: CGPointMake(4.5, 18.59) controlPoint2: CGPointMake(3.81, 1.95)];
        [markerPath7 addCurveToPoint: CGPointMake(37.24, 12.4) controlPoint1: CGPointMake(10.32, -0.56) controlPoint2: CGPointMake(31.32, 10.25)];
        [markerPath7 addCurveToPoint: CGPointMake(42.1, 19.91) controlPoint1: CGPointMake(41.47, 13.94) controlPoint2: CGPointMake(42.1, 16.55)];
        [markerPath7 addCurveToPoint: CGPointMake(42.09, 24.47) controlPoint1: CGPointMake(42.09, 22.2) controlPoint2: CGPointMake(42.09, 22.18)];
        markerPath7.lineCapStyle = kCGLineCapRound;
        markerPath7.lineJoinStyle = kCGLineJoinRound;
        markerPath7.lineWidth = 1.5;
        markerPath8 = [UIBezierPath bezierPath];
        [markerPath8 moveToPoint: CGPointMake(44.84, 52.75)];
        [markerPath8 addCurveToPoint: CGPointMake(1.3, 53.15) controlPoint1: CGPointMake(33.77, 54.8) controlPoint2: CGPointMake(12.07, 54.97)];
        [markerPath8 addCurveToPoint: CGPointMake(0.77, 202.03) controlPoint1: CGPointMake(1.1, 96.32) controlPoint2: CGPointMake(0.64, 201.01)];
        [markerPath8 addCurveToPoint: CGPointMake(2.34, 203.52) controlPoint1: CGPointMake(0.77, 202.03) controlPoint2: CGPointMake(1.44, 203.35)];
        [markerPath8 addCurveToPoint: CGPointMake(2.85, 203.61) controlPoint1: CGPointMake(2.52, 203.55) controlPoint2: CGPointMake(2.68, 203.58)];
        [markerPath8 addCurveToPoint: CGPointMake(9.67, 203.88) controlPoint1: CGPointMake(5.59, 204.07) controlPoint2: CGPointMake(6.68, 203.8)];
        [markerPath8 addCurveToPoint: CGPointMake(28.25, 204.18) controlPoint1: CGPointMake(15.86, 204.03) controlPoint2: CGPointMake(22.06, 204.14)];
        [markerPath8 addCurveToPoint: CGPointMake(42.8, 203.98) controlPoint1: CGPointMake(31.86, 204.2) controlPoint2: CGPointMake(41.59, 203.96)];
        [markerPath8 addCurveToPoint: CGPointMake(43.03, 203.97) controlPoint1: CGPointMake(42.89, 203.99) controlPoint2: CGPointMake(42.96, 203.97)];
        [markerPath8 addCurveToPoint: CGPointMake(44.75, 202.5) controlPoint1: CGPointMake(44.16, 203.89) controlPoint2: CGPointMake(44.67, 203.07)];
        [markerPath8 addCurveToPoint: CGPointMake(44.84, 52.75) controlPoint1: CGPointMake(45.13, 199.54) controlPoint2: CGPointMake(44.93, 95.55)];
        [markerPath8 closePath];
        markerPath8.lineWidth = 1.5;
        markerPath9 = [UIBezierPath bezierPath];
        [markerPath9 moveToPoint: CGPointMake(44.81, 40.74)];
        [markerPath9 addCurveToPoint: CGPointMake(44.8, 34.64) controlPoint1: CGPointMake(44.8, 36.91) controlPoint2: CGPointMake(44.8, 34.71)];
        [markerPath9 addLineToPoint: CGPointMake(42.91, 28.97)];
        [markerPath9 addCurveToPoint: CGPointMake(42.76, 24.57) controlPoint1: CGPointMake(42.91, 28.97) controlPoint2: CGPointMake(42.76, 26.03)];
        [markerPath9 addCurveToPoint: CGPointMake(17.05, 24.66) controlPoint1: CGPointMake(42.76, 24.57) controlPoint2: CGPointMake(25.64, 24.49)];
        [markerPath9 addCurveToPoint: CGPointMake(7.84, 24.79) controlPoint1: CGPointMake(13.98, 24.72) controlPoint2: CGPointMake(10.91, 24.77)];
        [markerPath9 addCurveToPoint: CGPointMake(5.5, 24.8) controlPoint1: CGPointMake(7.06, 24.8) controlPoint2: CGPointMake(6.28, 24.8)];
        [markerPath9 addCurveToPoint: CGPointMake(3.56, 24.92) controlPoint1: CGPointMake(5.06, 24.8) controlPoint2: CGPointMake(3.56, 24.92)];
        [markerPath9 addCurveToPoint: CGPointMake(3.3, 29.36) controlPoint1: CGPointMake(3.56, 24.92) controlPoint2: CGPointMake(3.3, 28.59)];
        [markerPath9 addLineToPoint: CGPointMake(1.38, 34.85)];
        [markerPath9 addCurveToPoint: CGPointMake(1.35, 41.06) controlPoint1: CGPointMake(1.38, 34.85) controlPoint2: CGPointMake(1.37, 37.1)];
        [markerPath9 addCurveToPoint: CGPointMake(44.81, 40.74) controlPoint1: CGPointMake(12.16, 42.87) controlPoint2: CGPointMake(33.74, 42.74)];
        [markerPath9 closePath];
        markerPath9.lineCapStyle = kCGLineCapRound;
        markerPath9.lineJoinStyle = kCGLineJoinRound;
        markerPath9.lineWidth = 1.5;
        markerPath10 = [UIBezierPath bezierPath];
        [markerPath10 moveToPoint: CGPointMake(1.35, 41.06)];
        [markerPath10 addCurveToPoint: CGPointMake(1.3, 53.15) controlPoint1: CGPointMake(1.34, 44.14) controlPoint2: CGPointMake(1.32, 48.25)];
        [markerPath10 addCurveToPoint: CGPointMake(44.84, 52.75) controlPoint1: CGPointMake(12.07, 54.97) controlPoint2: CGPointMake(33.77, 54.8)];
        [markerPath10 addCurveToPoint: CGPointMake(44.81, 40.74) controlPoint1: CGPointMake(44.83, 47.87) controlPoint2: CGPointMake(44.82, 43.78)];
        [markerPath10 addCurveToPoint: CGPointMake(1.35, 41.06) controlPoint1: CGPointMake(33.74, 42.74) controlPoint2: CGPointMake(14.24, 42.33)];
        [markerPath10 closePath];
        markerPath10.lineCapStyle = kCGLineCapRound;
        markerPath10.lineJoinStyle = kCGLineJoinRound;
        markerPath10.lineWidth = 1.5;
        markerPath11 = [UIBezierPath bezierPath];
        [markerPath11 moveToPoint: CGPointMake(1.7, 34.9)];
        [markerPath11 addCurveToPoint: CGPointMake(44.53, 35) controlPoint1: CGPointMake(13.15, 35.63) controlPoint2: CGPointMake(32.53, 35.93)];
        markerPath11.lineCapStyle = kCGLineCapRound;
        markerPath11.lineJoinStyle = kCGLineJoinRound;
        markerPath11.lineWidth = 1.5;
        markerPath12 = [UIBezierPath bezierPath];
        [markerPath12 moveToPoint: CGPointMake(3.56, 29.41)];
        [markerPath12 addCurveToPoint: CGPointMake(36.04, 29.48) controlPoint1: CGPointMake(4.29, 29.52) controlPoint2: CGPointMake(30.96, 29.48)];
        markerPath12.lineCapStyle = kCGLineCapRound;
        markerPath12.lineJoinStyle = kCGLineJoinRound;
        markerPath12.lineWidth = 1.5;
        markerPath13 = [UIBezierPath bezierPath];
        [markerPath13 moveToPoint: CGPointMake(44.86, 52.75)];
        [markerPath13 addCurveToPoint: CGPointMake(44.84, 40.74) controlPoint1: CGPointMake(44.85, 47.87) controlPoint2: CGPointMake(44.84, 43.78)];
        [markerPath13 addCurveToPoint: CGPointMake(44.82, 34.64) controlPoint1: CGPointMake(44.83, 36.91) controlPoint2: CGPointMake(44.82, 34.71)];
        [markerPath13 addLineToPoint: CGPointMake(43.2, 28.97)];
        [markerPath13 addCurveToPoint: CGPointMake(43.08, 24.57) controlPoint1: CGPointMake(43.2, 28.97) controlPoint2: CGPointMake(43.07, 26.03)];
        [markerPath13 addLineToPoint: CGPointMake(41.94, 24.54)];
        [markerPath13 addCurveToPoint: CGPointMake(41.94, 19.91) controlPoint1: CGPointMake(41.95, 22.25) controlPoint2: CGPointMake(41.93, 22.2)];
        [markerPath13 addCurveToPoint: CGPointMake(38.14, 13.03) controlPoint1: CGPointMake(41.94, 17.47) controlPoint2: CGPointMake(41.35, 13.38)];
        [markerPath13 addCurveToPoint: CGPointMake(35.45, 19.94) controlPoint1: CGPointMake(38.04, 15.37) controlPoint2: CGPointMake(36.84, 18.3)];
        [markerPath13 addCurveToPoint: CGPointMake(29.28, 24.54) controlPoint1: CGPointMake(33.83, 21.82) controlPoint2: CGPointMake(31.97, 24.54)];
        [markerPath13 addLineToPoint: CGPointMake(29.23, 29.41)];
        [markerPath13 addLineToPoint: CGPointMake(29.24, 208.37)];
        [markerPath13 addCurveToPoint: CGPointMake(42.65, 208.2) controlPoint1: CGPointMake(36.74, 208.33) controlPoint2: CGPointMake(42.23, 208.22)];
        [markerPath13 addCurveToPoint: CGPointMake(43.34, 203.97) controlPoint1: CGPointMake(43.21, 208.18) controlPoint2: CGPointMake(43.37, 206.25)];
        [markerPath13 addCurveToPoint: CGPointMake(44.79, 202.5) controlPoint1: CGPointMake(44.31, 203.89) controlPoint2: CGPointMake(44.73, 203.07)];
        [markerPath13 addCurveToPoint: CGPointMake(44.86, 52.75) controlPoint1: CGPointMake(45.12, 199.54) controlPoint2: CGPointMake(44.94, 95.55)];
        [markerPath13 closePath];
        markerPath13.miterLimit = 4;
        markerPath14 = [UIBezierPath bezierPath];
        [markerPath14 moveToPoint: CGPointMake(13.88, 16.76)];
        [markerPath14 addCurveToPoint: CGPointMake(13.88, 14.48) controlPoint1: CGPointMake(15.35, 16.76) controlPoint2: CGPointMake(15.35, 14.48)];
        [markerPath14 addCurveToPoint: CGPointMake(13.88, 16.76) controlPoint1: CGPointMake(12.4, 14.48) controlPoint2: CGPointMake(12.4, 16.76)];
        [markerPath14 addLineToPoint: CGPointMake(13.88, 16.76)];
        [markerPath14 closePath];
        markerPath14.miterLimit = 4;
        markerPath15 = [UIBezierPath bezierPath];
        [markerPath15 moveToPoint: CGPointMake(33.37, 17.24)];
        [markerPath15 addCurveToPoint: CGPointMake(33.37, 14.95) controlPoint1: CGPointMake(34.84, 17.24) controlPoint2: CGPointMake(34.84, 14.95)];
        [markerPath15 addCurveToPoint: CGPointMake(33.37, 17.24) controlPoint1: CGPointMake(31.9, 14.95) controlPoint2: CGPointMake(31.9, 17.24)];
        [markerPath15 addLineToPoint: CGPointMake(33.37, 17.24)];
        [markerPath15 closePath];
        markerPath15.miterLimit = 4;
        markerPath16 = [UIBezierPath bezierPath];
        [markerPath16 moveToPoint: CGPointMake(21.23, 17.18)];
        [markerPath16 addCurveToPoint: CGPointMake(23.5, 19.76) controlPoint1: CGPointMake(21.22, 18.49) controlPoint2: CGPointMake(22.15, 19.66)];
        [markerPath16 addCurveToPoint: CGPointMake(25.91, 17.33) controlPoint1: CGPointMake(24.99, 19.87) controlPoint2: CGPointMake(25.84, 18.71)];
        [markerPath16 addCurveToPoint: CGPointMake(25.2, 17.33) controlPoint1: CGPointMake(25.94, 16.87) controlPoint2: CGPointMake(25.22, 16.87)];
        [markerPath16 addCurveToPoint: CGPointMake(23.47, 19.04) controlPoint1: CGPointMake(25.14, 18.32) controlPoint2: CGPointMake(24.56, 19.18)];
        [markerPath16 addCurveToPoint: CGPointMake(21.95, 17.18) controlPoint1: CGPointMake(22.53, 18.91) controlPoint2: CGPointMake(21.94, 18.1)];
        [markerPath16 addCurveToPoint: CGPointMake(21.23, 17.18) controlPoint1: CGPointMake(21.95, 16.72) controlPoint2: CGPointMake(21.23, 16.72)];
        [markerPath16 addLineToPoint: CGPointMake(21.23, 17.18)];
        [markerPath16 closePath];
        markerPath16.miterLimit = 4;
        
        // Pen paths
        pencilPath1 = [UIBezierPath bezierPath];
        [pencilPath1 moveToPoint: CGPointMake(24.81, 14.62)];
        [pencilPath1 addCurveToPoint: CGPointMake(18.49, 1.56) controlPoint1: CGPointMake(23.45, 11.72) controlPoint2: CGPointMake(19.53, 2.09)];
        [pencilPath1 addCurveToPoint: CGPointMake(12.18, 13.77) controlPoint1: CGPointMake(16.95, 0.76) controlPoint2: CGPointMake(13.11, 11.48)];
        [pencilPath1 addCurveToPoint: CGPointMake(16.17, 14.29) controlPoint1: CGPointMake(13.51, 13.86) controlPoint2: CGPointMake(14.84, 14.07)];
        [pencilPath1 addCurveToPoint: CGPointMake(24.81, 14.62) controlPoint1: CGPointMake(19.09, 14.75) controlPoint2: CGPointMake(22, 15.25)];
        [pencilPath1 closePath];
        pencilPath1.miterLimit = 4;
        pencilPath2 = [UIBezierPath bezierPath];
        [pencilPath2 moveToPoint: CGPointMake(27.41, 42.02)];
        [pencilPath2 addCurveToPoint: CGPointMake(19.96, 42.97) controlPoint1: CGPointMake(23.19, 38.72) controlPoint2: CGPointMake(22.99, 40.84)];
        [pencilPath2 addCurveToPoint: CGPointMake(11.18, 40.22) controlPoint1: CGPointMake(15.61, 46.03) controlPoint2: CGPointMake(15.88, 39.97)];
        [pencilPath2 addCurveToPoint: CGPointMake(6.01, 43) controlPoint1: CGPointMake(9.36, 40.22) controlPoint2: CGPointMake(7.84, 43)];
        [pencilPath2 addCurveToPoint: CGPointMake(2.18, 40.4) controlPoint1: CGPointMake(4.6, 43) controlPoint2: CGPointMake(3.2, 41.31)];
        [pencilPath2 addLineToPoint: CGPointMake(1.94, 40.48)];
        [pencilPath2 addCurveToPoint: CGPointMake(1.72, 208.12) controlPoint1: CGPointMake(1.93, 42.89) controlPoint2: CGPointMake(1.72, 208.12)];
        [pencilPath2 addCurveToPoint: CGPointMake(35.49, 208.33) controlPoint1: CGPointMake(11.43, 210.54) controlPoint2: CGPointMake(35.07, 208.38)];
        [pencilPath2 addCurveToPoint: CGPointMake(35.68, 40.55) controlPoint1: CGPointMake(35.49, 208.33) controlPoint2: CGPointMake(35.67, 42.96)];
        [pencilPath2 addLineToPoint: CGPointMake(35.52, 40.5)];
        [pencilPath2 addCurveToPoint: CGPointMake(27.41, 42.02) controlPoint1: CGPointMake(32.29, 44.47) controlPoint2: CGPointMake(31.74, 45.41)];
        [pencilPath2 closePath];
        pencilPath2.miterLimit = 4;
        pencilPath3 = [UIBezierPath bezierPath];
        [pencilPath3 moveToPoint: CGPointMake(24.81, 14.62)];
        [pencilPath3 addCurveToPoint: CGPointMake(16.17, 14.29) controlPoint1: CGPointMake(22, 15.25) controlPoint2: CGPointMake(19.09, 14.76)];
        [pencilPath3 addCurveToPoint: CGPointMake(12.18, 13.77) controlPoint1: CGPointMake(14.84, 14.07) controlPoint2: CGPointMake(13.5, 13.87)];
        [pencilPath3 addCurveToPoint: CGPointMake(1.84, 40.12) controlPoint1: CGPointMake(7.59, 25.07) controlPoint2: CGPointMake(1.84, 40.12)];
        [pencilPath3 addCurveToPoint: CGPointMake(2.18, 40.4) controlPoint1: CGPointMake(1.95, 40.2) controlPoint2: CGPointMake(2.06, 40.3)];
        [pencilPath3 addCurveToPoint: CGPointMake(6.01, 43) controlPoint1: CGPointMake(3.2, 41.31) controlPoint2: CGPointMake(4.6, 43)];
        [pencilPath3 addCurveToPoint: CGPointMake(11.18, 40.22) controlPoint1: CGPointMake(7.84, 43) controlPoint2: CGPointMake(9.36, 40.22)];
        [pencilPath3 addCurveToPoint: CGPointMake(19.96, 42.97) controlPoint1: CGPointMake(15.88, 39.97) controlPoint2: CGPointMake(15.61, 46.03)];
        [pencilPath3 addCurveToPoint: CGPointMake(27.41, 42.02) controlPoint1: CGPointMake(22.99, 40.84) controlPoint2: CGPointMake(23.19, 38.72)];
        [pencilPath3 addCurveToPoint: CGPointMake(35.52, 40.5) controlPoint1: CGPointMake(31.74, 45.41) controlPoint2: CGPointMake(32.29, 44.47)];
        [pencilPath3 addCurveToPoint: CGPointMake(35.7, 40.27) controlPoint1: CGPointMake(35.58, 40.42) controlPoint2: CGPointMake(35.64, 40.35)];
        [pencilPath3 addCurveToPoint: CGPointMake(24.81, 14.62) controlPoint1: CGPointMake(34.93, 37.33) controlPoint2: CGPointMake(29.52, 24.68)];
        [pencilPath3 closePath];
        pencilPath3.miterLimit = 4;
        pencilPath4 = [UIBezierPath bezierPath];
        [pencilPath4 moveToPoint: CGPointMake(35.46, 40.55)];
        [pencilPath4 addCurveToPoint: CGPointMake(35.27, 208.33) controlPoint1: CGPointMake(35.45, 42.96) controlPoint2: CGPointMake(35.27, 208.33)];
        [pencilPath4 addCurveToPoint: CGPointMake(1.5, 208.12) controlPoint1: CGPointMake(34.85, 208.38) controlPoint2: CGPointMake(11.21, 210.54)];
        [pencilPath4 addCurveToPoint: CGPointMake(1.72, 40.48) controlPoint1: CGPointMake(1.5, 208.12) controlPoint2: CGPointMake(1.72, 42.89)];
        pencilPath4.lineCapStyle = kCGLineCapRound;
        pencilPath4.lineJoinStyle = kCGLineJoinRound;
        pencilPath4.lineWidth = 1.5;
        pencilPath5 = [UIBezierPath bezierPath];
        [pencilPath5 moveToPoint: CGPointMake(6.3, 43.17)];
        [pencilPath5 addCurveToPoint: CGPointMake(6.53, 82.44) controlPoint1: CGPointMake(6.4, 45.58) controlPoint2: CGPointMake(6.48, 78.08)];
        pencilPath5.lineCapStyle = kCGLineCapRound;
        pencilPath5.lineWidth = 1.5;
        pencilPath6 = [UIBezierPath bezierPath];
        [pencilPath6 moveToPoint: CGPointMake(23.9, 40.5)];
        [pencilPath6 addCurveToPoint: CGPointMake(24.65, 135.39) controlPoint1: CGPointMake(24, 42.91) controlPoint2: CGPointMake(24.6, 131.03)];
        pencilPath6.lineCapStyle = kCGLineCapRound;
        pencilPath6.lineWidth = 1.5;
        pencilPath7 = [UIBezierPath bezierPath];
        [pencilPath7 moveToPoint: CGPointMake(11.55, 40.64)];
        [pencilPath7 addCurveToPoint: CGPointMake(12.28, 145.03) controlPoint1: CGPointMake(11.65, 43.05) controlPoint2: CGPointMake(12.23, 140.67)];
        pencilPath7.lineCapStyle = kCGLineCapRound;
        pencilPath7.lineWidth = 1.5;
        pencilPath8 = [UIBezierPath bezierPath];
        [pencilPath8 moveToPoint: CGPointMake(17.46, 44.21)];
        [pencilPath8 addCurveToPoint: CGPointMake(18.34, 174.29) controlPoint1: CGPointMake(17.56, 46.62) controlPoint2: CGPointMake(18.21, 169.13)];
        pencilPath8.lineCapStyle = kCGLineCapRound;
        pencilPath8.lineWidth = 1.5;
        pencilPath9 = [UIBezierPath bezierPath];
        [pencilPath9 moveToPoint: CGPointMake(31, 44.23)];
        [pencilPath9 addCurveToPoint: CGPointMake(30.8, 170.46) controlPoint1: CGPointMake(31.06, 45.88) controlPoint2: CGPointMake(31.04, 110.75)];
        pencilPath9.lineCapStyle = kCGLineCapRound;
        pencilPath9.lineWidth = 1.5;
        pencilPath10 = [UIBezierPath bezierPath];
        [pencilPath10 moveToPoint: CGPointMake(24.59, 14.62)];
        [pencilPath10 addCurveToPoint: CGPointMake(11.96, 13.77) controlPoint1: CGPointMake(20.51, 15.53) controlPoint2: CGPointMake(16.21, 14.08)];
        [pencilPath10 addCurveToPoint: CGPointMake(1.62, 40.12) controlPoint1: CGPointMake(7.38, 25.07) controlPoint2: CGPointMake(1.62, 40.12)];
        [pencilPath10 addCurveToPoint: CGPointMake(5.79, 43) controlPoint1: CGPointMake(2.66, 40.9) controlPoint2: CGPointMake(4.23, 43)];
        [pencilPath10 addCurveToPoint: CGPointMake(10.97, 40.22) controlPoint1: CGPointMake(7.62, 43) controlPoint2: CGPointMake(9.14, 40.22)];
        [pencilPath10 addCurveToPoint: CGPointMake(19.74, 42.97) controlPoint1: CGPointMake(15.66, 39.97) controlPoint2: CGPointMake(15.39, 46.03)];
        [pencilPath10 addCurveToPoint: CGPointMake(27.2, 42.02) controlPoint1: CGPointMake(22.77, 40.84) controlPoint2: CGPointMake(22.97, 38.72)];
        [pencilPath10 addCurveToPoint: CGPointMake(35.49, 40.27) controlPoint1: CGPointMake(31.61, 45.47) controlPoint2: CGPointMake(32.09, 44.44)];
        [pencilPath10 addCurveToPoint: CGPointMake(24.59, 14.62) controlPoint1: CGPointMake(34.71, 37.33) controlPoint2: CGPointMake(29.31, 24.68)];
        [pencilPath10 closePath];
        pencilPath10.lineCapStyle = kCGLineCapRound;
        pencilPath10.lineJoinStyle = kCGLineJoinRound;
        pencilPath10.lineWidth = 1.5;
        pencilPath11 = [UIBezierPath bezierPath];
        [pencilPath11 moveToPoint: CGPointMake(24.59, 14.62)];
        [pencilPath11 addCurveToPoint: CGPointMake(18.27, 1.56) controlPoint1: CGPointMake(23.23, 11.72) controlPoint2: CGPointMake(19.31, 2.09)];
        [pencilPath11 addCurveToPoint: CGPointMake(11.96, 13.77) controlPoint1: CGPointMake(16.73, 0.76) controlPoint2: CGPointMake(12.89, 11.48)];
        [pencilPath11 addCurveToPoint: CGPointMake(24.59, 14.62) controlPoint1: CGPointMake(16.2, 14.08) controlPoint2: CGPointMake(20.51, 15.53)];
        [pencilPath11 closePath];
        pencilPath11.lineCapStyle = kCGLineCapRound;
        pencilPath11.lineJoinStyle = kCGLineJoinRound;
        pencilPath11.lineWidth = 1.5;
        pencilPath12 = [UIBezierPath bezierPath];
        [pencilPath12 moveToPoint: CGPointMake(36.05, 40.25)];
        [pencilPath12 addCurveToPoint: CGPointMake(25.23, 14.78) controlPoint1: CGPointMake(35.27, 37.33) controlPoint2: CGPointMake(29.93, 24.81)];
        [pencilPath12 addCurveToPoint: CGPointMake(25.37, 14.75) controlPoint1: CGPointMake(25.28, 14.77) controlPoint2: CGPointMake(25.32, 14.76)];
        [pencilPath12 addCurveToPoint: CGPointMake(18.83, 1.54) controlPoint1: CGPointMake(24.01, 11.85) controlPoint2: CGPointMake(19.87, 2.07)];
        [pencilPath12 addCurveToPoint: CGPointMake(18.54, 2.48) controlPoint1: CGPointMake(18.49, 1.37) controlPoint2: CGPointMake(19.04, 1.75)];
        [pencilPath12 addCurveToPoint: CGPointMake(20.85, 15.29) controlPoint1: CGPointMake(19.2, 6.58) controlPoint2: CGPointMake(20.07, 11.21)];
        [pencilPath12 addCurveToPoint: CGPointMake(25.43, 39.97) controlPoint1: CGPointMake(21.61, 19.34) controlPoint2: CGPointMake(25.43, 39.97)];
        [pencilPath12 addLineToPoint: CGPointMake(25.43, 209.26)];
        [pencilPath12 addCurveToPoint: CGPointMake(35.83, 208.31) controlPoint1: CGPointMake(33.27, 209.05) controlPoint2: CGPointMake(35.61, 208.34)];
        [pencilPath12 addCurveToPoint: CGPointMake(36.02, 40.53) controlPoint1: CGPointMake(35.83, 208.31) controlPoint2: CGPointMake(36.02, 42.94)];
        [pencilPath12 addLineToPoint: CGPointMake(35.82, 40.53)];
        [pencilPath12 addCurveToPoint: CGPointMake(36.05, 40.25) controlPoint1: CGPointMake(35.9, 40.44) controlPoint2: CGPointMake(35.97, 40.35)];
        [pencilPath12 closePath];
        pencilPath12.miterLimit = 4;
        pencilPath13 = [UIBezierPath bezierPath];
        [pencilPath13 moveToPoint: CGPointMake(8.97, 34.83)];
        [pencilPath13 addCurveToPoint: CGPointMake(8.97, 32.55) controlPoint1: CGPointMake(10.44, 34.83) controlPoint2: CGPointMake(10.44, 32.55)];
        [pencilPath13 addCurveToPoint: CGPointMake(8.97, 34.83) controlPoint1: CGPointMake(7.5, 32.55) controlPoint2: CGPointMake(7.5, 34.83)];
        [pencilPath13 addLineToPoint: CGPointMake(8.97, 34.83)];
        [pencilPath13 closePath];
        pencilPath13.miterLimit = 4;
        pencilPath14 = [UIBezierPath bezierPath];
        [pencilPath14 moveToPoint: CGPointMake(28.47, 34.63)];
        [pencilPath14 addCurveToPoint: CGPointMake(28.47, 32.35) controlPoint1: CGPointMake(29.95, 34.63) controlPoint2: CGPointMake(29.95, 32.35)];
        [pencilPath14 addCurveToPoint: CGPointMake(28.47, 34.63) controlPoint1: CGPointMake(27, 32.35) controlPoint2: CGPointMake(27, 34.63)];
        [pencilPath14 addLineToPoint: CGPointMake(28.47, 34.63)];
        [pencilPath14 closePath];
        pencilPath14.miterLimit = 4;
        pencilPath15 = [UIBezierPath bezierPath];
        [pencilPath15 moveToPoint: CGPointMake(16.38, 34.99)];
        [pencilPath15 addCurveToPoint: CGPointMake(18.72, 37.5) controlPoint1: CGPointMake(16.41, 36.35) controlPoint2: CGPointMake(17.37, 37.36)];
        [pencilPath15 addCurveToPoint: CGPointMake(21.06, 35) controlPoint1: CGPointMake(20.2, 37.64) controlPoint2: CGPointMake(21.03, 36.31)];
        [pencilPath15 addCurveToPoint: CGPointMake(20.35, 35) controlPoint1: CGPointMake(21.07, 34.53) controlPoint2: CGPointMake(20.36, 34.53)];
        [pencilPath15 addCurveToPoint: CGPointMake(18.72, 36.78) controlPoint1: CGPointMake(20.32, 36.01) controlPoint2: CGPointMake(19.81, 36.82)];
        [pencilPath15 addCurveToPoint: CGPointMake(17.09, 34.99) controlPoint1: CGPointMake(17.77, 36.74) controlPoint2: CGPointMake(17.12, 35.89)];
        [pencilPath15 addCurveToPoint: CGPointMake(16.38, 34.99) controlPoint1: CGPointMake(17.08, 34.53) controlPoint2: CGPointMake(16.36, 34.52)];
        [pencilPath15 addLineToPoint: CGPointMake(16.38, 34.99)];
        [pencilPath15 closePath];
        pencilPath15.miterLimit = 4;
        
        // Eraser paths
        eraserPath1 = [UIBezierPath bezierPath];
        [eraserPath1 moveToPoint: CGPointMake(1.8, 15.72)];
        [eraserPath1 addCurveToPoint: CGPointMake(2.65, 107.65) controlPoint1: CGPointMake(1.72, 17.52) controlPoint2: CGPointMake(0.8, 107.26)];
        [eraserPath1 addCurveToPoint: CGPointMake(38.16, 107.78) controlPoint1: CGPointMake(8.84, 108.94) controlPoint2: CGPointMake(37.09, 108.94)];
        [eraserPath1 addCurveToPoint: CGPointMake(39.1, 16.71) controlPoint1: CGPointMake(39.01, 106.86) controlPoint2: CGPointMake(38.91, 30.13)];
        [eraserPath1 addCurveToPoint: CGPointMake(32.17, 2.62) controlPoint1: CGPointMake(39.14, 14.28) controlPoint2: CGPointMake(33.85, 3.24)];
        [eraserPath1 addCurveToPoint: CGPointMake(7.43, 3.42) controlPoint1: CGPointMake(28.18, 1.13) controlPoint2: CGPointMake(9.8, 0.96)];
        [eraserPath1 addCurveToPoint: CGPointMake(1.8, 15.72) controlPoint1: CGPointMake(5.56, 5.36) controlPoint2: CGPointMake(1.83, 14.98)];
        [eraserPath1 closePath];
        eraserPath1.miterLimit = 4;
        eraserPath2 = [UIBezierPath bezierPath];
        [eraserPath2 moveToPoint: CGPointMake(1.8, 15.69)];
        [eraserPath2 addCurveToPoint: CGPointMake(2.65, 107.62) controlPoint1: CGPointMake(1.72, 17.49) controlPoint2: CGPointMake(0.8, 107.23)];
        [eraserPath2 addCurveToPoint: CGPointMake(38.16, 107.75) controlPoint1: CGPointMake(8.84, 108.91) controlPoint2: CGPointMake(37.09, 108.92)];
        [eraserPath2 addCurveToPoint: CGPointMake(39.1, 16.68) controlPoint1: CGPointMake(39.01, 106.83) controlPoint2: CGPointMake(38.91, 30.1)];
        [eraserPath2 addCurveToPoint: CGPointMake(32.17, 2.59) controlPoint1: CGPointMake(39.14, 14.25) controlPoint2: CGPointMake(33.85, 3.21)];
        [eraserPath2 addCurveToPoint: CGPointMake(7.43, 3.39) controlPoint1: CGPointMake(28.18, 1.1) controlPoint2: CGPointMake(9.8, 0.93)];
        [eraserPath2 addCurveToPoint: CGPointMake(1.8, 15.69) controlPoint1: CGPointMake(5.56, 5.33) controlPoint2: CGPointMake(1.83, 14.95)];
        [eraserPath2 closePath];
        eraserPath2.lineCapStyle = kCGLineCapRound;
        eraserPath2.lineJoinStyle = kCGLineJoinRound;
        eraserPath2.lineWidth = 1.5;
        eraserPath3 = [UIBezierPath bezierPath];
        [eraserPath3 moveToPoint: CGPointMake(4.73, 14.88)];
        [eraserPath3 addCurveToPoint: CGPointMake(7.23, 14.94) controlPoint1: CGPointMake(5.88, 14.76) controlPoint2: CGPointMake(6.14, 14.94)];
        [eraserPath3 addCurveToPoint: CGPointMake(36.17, 15.02) controlPoint1: CGPointMake(10.2, 14.95) controlPoint2: CGPointMake(33.27, 14.89)];
        eraserPath3.lineCapStyle = kCGLineCapRound;
        eraserPath3.lineJoinStyle = kCGLineJoinRound;
        eraserPath3.lineWidth = 1.5;
        eraserPath4 = [UIBezierPath bezierPath];
        [eraserPath4 moveToPoint: CGPointMake(32.15, 2.59)];
        [eraserPath4 addCurveToPoint: CGPointMake(25.92, 1.56) controlPoint1: CGPointMake(30.69, 1.96) controlPoint2: CGPointMake(29.82, 1.62)];
        [eraserPath4 addCurveToPoint: CGPointMake(29.16, 15.02) controlPoint1: CGPointMake(25.92, 1.56) controlPoint2: CGPointMake(27.95, 10.87)];
        [eraserPath4 addCurveToPoint: CGPointMake(29.16, 108.61) controlPoint1: CGPointMake(29.16, 15.02) controlPoint2: CGPointMake(29.18, 103.01)];
        [eraserPath4 addCurveToPoint: CGPointMake(38.29, 107.75) controlPoint1: CGPointMake(35.31, 108.57) controlPoint2: CGPointMake(37.87, 108.29)];
        [eraserPath4 addCurveToPoint: CGPointMake(39.1, 16.68) controlPoint1: CGPointMake(39.02, 106.83) controlPoint2: CGPointMake(38.94, 30.09)];
        [eraserPath4 addCurveToPoint: CGPointMake(32.15, 2.59) controlPoint1: CGPointMake(39.13, 14.25) controlPoint2: CGPointMake(33.59, 3.21)];
        [eraserPath4 closePath];
        eraserPath4.miterLimit = 4;
        eraserPath5 = [UIBezierPath bezierPath];
        [eraserPath5 moveToPoint: CGPointMake(10.64, 26.48)];
        [eraserPath5 addCurveToPoint: CGPointMake(10.64, 24.19) controlPoint1: CGPointMake(12.11, 26.48) controlPoint2: CGPointMake(12.11, 24.19)];
        [eraserPath5 addCurveToPoint: CGPointMake(10.64, 26.48) controlPoint1: CGPointMake(9.17, 24.19) controlPoint2: CGPointMake(9.17, 26.48)];
        [eraserPath5 addLineToPoint: CGPointMake(10.64, 26.48)];
        [eraserPath5 closePath];
        eraserPath5.miterLimit = 4;
        eraserPath6 = [UIBezierPath bezierPath];
        [eraserPath6 moveToPoint: CGPointMake(30.14, 26.16)];
        [eraserPath6 addCurveToPoint: CGPointMake(30.14, 23.88) controlPoint1: CGPointMake(31.61, 26.16) controlPoint2: CGPointMake(31.61, 23.88)];
        [eraserPath6 addCurveToPoint: CGPointMake(30.14, 26.16) controlPoint1: CGPointMake(28.67, 23.88) controlPoint2: CGPointMake(28.67, 26.16)];
        [eraserPath6 addLineToPoint: CGPointMake(30.14, 26.16)];
        [eraserPath6 closePath];
        eraserPath6.miterLimit = 4;
        eraserPath7 = [UIBezierPath bezierPath];
        [eraserPath7 moveToPoint: CGPointMake(18.62, 26.95)];
        [eraserPath7 addCurveToPoint: CGPointMake(20.87, 29.54) controlPoint1: CGPointMake(18.6, 28.25) controlPoint2: CGPointMake(19.52, 29.43)];
        [eraserPath7 addCurveToPoint: CGPointMake(23.3, 27.12) controlPoint1: CGPointMake(22.36, 29.66) controlPoint2: CGPointMake(23.21, 28.5)];
        [eraserPath7 addCurveToPoint: CGPointMake(22.58, 27.12) controlPoint1: CGPointMake(23.33, 26.66) controlPoint2: CGPointMake(22.61, 26.66)];
        [eraserPath7 addCurveToPoint: CGPointMake(20.84, 28.81) controlPoint1: CGPointMake(22.52, 28.11) controlPoint2: CGPointMake(21.93, 28.97)];
        [eraserPath7 addCurveToPoint: CGPointMake(19.33, 26.95) controlPoint1: CGPointMake(19.9, 28.68) controlPoint2: CGPointMake(19.32, 27.86)];
        [eraserPath7 addCurveToPoint: CGPointMake(18.62, 26.95) controlPoint1: CGPointMake(19.34, 26.48) controlPoint2: CGPointMake(18.62, 26.48)];
        [eraserPath7 addLineToPoint: CGPointMake(18.62, 26.95)];
        [eraserPath7 closePath];
        eraserPath7.miterLimit = 4;

        // Spraypaint Paths
        spraypaintPath1 = [UIBezierPath bezierPath];
        [spraypaintPath1 moveToPoint: CGPointMake(1.59, 54.21)];
        [spraypaintPath1 addLineToPoint: CGPointMake(1.37, 134.16)];
        [spraypaintPath1 addCurveToPoint: CGPointMake(58.76, 134.28) controlPoint1: CGPointMake(12.6, 137.01) controlPoint2: CGPointMake(49.89, 137.99)];
        [spraypaintPath1 addLineToPoint: CGPointMake(59.1, 54.13)];
        [spraypaintPath1 addCurveToPoint: CGPointMake(1.59, 54.21) controlPoint1: CGPointMake(50.92, 57.99) controlPoint2: CGPointMake(13.23, 57.06)];
        [spraypaintPath1 closePath];
        spraypaintPath1.miterLimit = 4;
        spraypaintPath2 = [UIBezierPath bezierPath];
        [spraypaintPath2 moveToPoint: CGPointMake(22.56, 14.77)];
        [spraypaintPath2 addLineToPoint: CGPointMake(22.56, 1.85)];
        [spraypaintPath2 addCurveToPoint: CGPointMake(36.91, 1.77) controlPoint1: CGPointMake(24.56, 0.99) controlPoint2: CGPointMake(31.83, -0.08)];
        [spraypaintPath2 addCurveToPoint: CGPointMake(36.8, 14.91) controlPoint1: CGPointMake(36.91, 1.77) controlPoint2: CGPointMake(36.82, 14.5)];
        spraypaintPath2.miterLimit = 4;
        spraypaintPath3 = [UIBezierPath bezierPath];
        [spraypaintPath3 moveToPoint: CGPointMake(1.57, 134.16)];
        [spraypaintPath3 addLineToPoint: CGPointMake(1.48, 168)];
        [spraypaintPath3 addCurveToPoint: CGPointMake(58.83, 167.76) controlPoint1: CGPointMake(12.07, 171.1) controlPoint2: CGPointMake(52.37, 172.15)];
        [spraypaintPath3 addLineToPoint: CGPointMake(58.97, 134.28)];
        [spraypaintPath3 addCurveToPoint: CGPointMake(1.57, 134.16) controlPoint1: CGPointMake(50.09, 137.99) controlPoint2: CGPointMake(12.8, 137.01)];
        [spraypaintPath3 closePath];
        spraypaintPath3.miterLimit = 4;
        spraypaintPath4 = [UIBezierPath bezierPath];
        [spraypaintPath4 moveToPoint: CGPointMake(58.69, 37.15)];
        [spraypaintPath4 addCurveToPoint: CGPointMake(30.96, 16.4) controlPoint1: CGPointMake(57.64, 28.94) controlPoint2: CGPointMake(50.34, 16.4)];
        [spraypaintPath4 addLineToPoint: CGPointMake(30.69, 16.4)];
        [spraypaintPath4 addCurveToPoint: CGPointMake(1.58, 37.53) controlPoint1: CGPointMake(10.96, 16.4) controlPoint2: CGPointMake(2.66, 29.34)];
        [spraypaintPath4 addCurveToPoint: CGPointMake(58.69, 37.15) controlPoint1: CGPointMake(13.11, 40.3) controlPoint2: CGPointMake(49.39, 39.84)];
        [spraypaintPath4 closePath];
        spraypaintPath4.miterLimit = 4;
        spraypaintPath5 = [UIBezierPath bezierPath];
        [spraypaintPath5 moveToPoint: CGPointMake(1.49, 41.68)];
        [spraypaintPath5 addLineToPoint: CGPointMake(1.46, 53.88)];
        [spraypaintPath5 addCurveToPoint: CGPointMake(58.96, 53.74) controlPoint1: CGPointMake(13.09, 56.72) controlPoint2: CGPointMake(50.79, 57.6)];
        [spraypaintPath5 addLineToPoint: CGPointMake(59.02, 41.32)];
        [spraypaintPath5 addCurveToPoint: CGPointMake(1.49, 41.68) controlPoint1: CGPointMake(50.26, 44.1) controlPoint2: CGPointMake(13.06, 44.51)];
        [spraypaintPath5 closePath];
        spraypaintPath5.miterLimit = 4;
        spraypaintPath6 = [UIBezierPath bezierPath];
        [spraypaintPath6 moveToPoint: CGPointMake(0.98, 37.03)];
        [spraypaintPath6 addLineToPoint: CGPointMake(0.98, 41.99)];
        [spraypaintPath6 addCurveToPoint: CGPointMake(59.48, 41.75) controlPoint1: CGPointMake(11.71, 45.05) controlPoint2: CGPointMake(50.98, 44.66)];
        [spraypaintPath6 addLineToPoint: CGPointMake(59.48, 36.79)];
        [spraypaintPath6 addCurveToPoint: CGPointMake(0.98, 37.03) controlPoint1: CGPointMake(50.98, 39.7) controlPoint2: CGPointMake(11.71, 40.1)];
        [spraypaintPath6 closePath];
        spraypaintPath6.miterLimit = 4;
        spraypaintPath7 = [UIBezierPath bezierPath];
        [spraypaintPath7 moveToPoint: CGPointMake(31.1, 5.35)];
        [spraypaintPath7 addCurveToPoint: CGPointMake(28.71, 8.39) controlPoint1: CGPointMake(29.3, 4.22) controlPoint2: CGPointMake(27.13, 6.81)];
        [spraypaintPath7 addCurveToPoint: CGPointMake(31.1, 5.35) controlPoint1: CGPointMake(31.02, 10.4) controlPoint2: CGPointMake(33.57, 6.9)];
        [spraypaintPath7 closePath];
        spraypaintPath7.miterLimit = 4;
        spraypaintPath8 = [UIBezierPath bezierPath];
        [spraypaintPath8 moveToPoint: CGPointMake(39.75, 13.72)];
        [spraypaintPath8 addLineToPoint: CGPointMake(40.4, 17.23)];
        [spraypaintPath8 addCurveToPoint: CGPointMake(20.15, 16.97) controlPoint1: CGPointMake(37.87, 18.57) controlPoint2: CGPointMake(24.99, 19.68)];
        [spraypaintPath8 addLineToPoint: CGPointMake(20.52, 13.76)];
        [spraypaintPath8 addCurveToPoint: CGPointMake(39.75, 13.72) controlPoint1: CGPointMake(20.79, 13.71) controlPoint2: CGPointMake(39.75, 13.72)];
        [spraypaintPath8 closePath];
        spraypaintPath8.miterLimit = 4;
        spraypaintPath9 = [UIBezierPath bezierPath];
        [spraypaintPath9 moveToPoint: CGPointMake(1.46, 54.21)];
        [spraypaintPath9 addLineToPoint: CGPointMake(1.23, 134.16)];
        [spraypaintPath9 addCurveToPoint: CGPointMake(58.63, 134.28) controlPoint1: CGPointMake(12.46, 137.01) controlPoint2: CGPointMake(49.75, 137.99)];
        [spraypaintPath9 addLineToPoint: CGPointMake(58.96, 54.13)];
        [spraypaintPath9 addCurveToPoint: CGPointMake(1.46, 54.21) controlPoint1: CGPointMake(50.79, 57.99) controlPoint2: CGPointMake(13.09, 57.06)];
        [spraypaintPath9 closePath];
        spraypaintPath9.lineCapStyle = kCGLineCapRound;
        spraypaintPath9.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath9.lineWidth = 1.5;
        spraypaintPath10 = [UIBezierPath bezierPath];
        [spraypaintPath10 moveToPoint: CGPointMake(1.23, 134.16)];
        [spraypaintPath10 addLineToPoint: CGPointMake(1.14, 168)];
        [spraypaintPath10 addCurveToPoint: CGPointMake(58.49, 167.76) controlPoint1: CGPointMake(11.73, 171.1) controlPoint2: CGPointMake(52.03, 172.15)];
        [spraypaintPath10 addLineToPoint: CGPointMake(58.63, 134.28)];
        [spraypaintPath10 addCurveToPoint: CGPointMake(1.23, 134.16) controlPoint1: CGPointMake(49.75, 137.99) controlPoint2: CGPointMake(12.46, 137.01)];
        [spraypaintPath10 closePath];
        spraypaintPath10.lineCapStyle = kCGLineCapRound;
        spraypaintPath10.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath10.lineWidth = 1.5;
        spraypaintPath11 = [UIBezierPath bezierPath];
        [spraypaintPath11 moveToPoint: CGPointMake(1.49, 42.18)];
        [spraypaintPath11 addLineToPoint: CGPointMake(1.46, 54.38)];
        [spraypaintPath11 addCurveToPoint: CGPointMake(58.96, 54.24) controlPoint1: CGPointMake(13.09, 57.22) controlPoint2: CGPointMake(50.79, 58.1)];
        [spraypaintPath11 addLineToPoint: CGPointMake(59.02, 41.82)];
        [spraypaintPath11 addCurveToPoint: CGPointMake(1.49, 42.18) controlPoint1: CGPointMake(50.26, 44.6) controlPoint2: CGPointMake(13.06, 45.01)];
        [spraypaintPath11 closePath];
        spraypaintPath11.lineCapStyle = kCGLineCapRound;
        spraypaintPath11.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath11.lineWidth = 1.5;
        spraypaintPath12 = [UIBezierPath bezierPath];
        [spraypaintPath12 moveToPoint: CGPointMake(58.69, 36.97)];
        [spraypaintPath12 addCurveToPoint: CGPointMake(1.58, 37.25) controlPoint1: CGPointMake(49.39, 39.65) controlPoint2: CGPointMake(13.11, 40.02)];
        [spraypaintPath12 addCurveToPoint: CGPointMake(0.75, 37.03) controlPoint1: CGPointMake(1.29, 37.18) controlPoint2: CGPointMake(1.01, 37.1)];
        [spraypaintPath12 addLineToPoint: CGPointMake(0.75, 41.98)];
        [spraypaintPath12 addCurveToPoint: CGPointMake(1.49, 42.18) controlPoint1: CGPointMake(0.98, 42.05) controlPoint2: CGPointMake(1.23, 42.12)];
        [spraypaintPath12 addCurveToPoint: CGPointMake(59.02, 41.82) controlPoint1: CGPointMake(13.06, 45.01) controlPoint2: CGPointMake(50.26, 44.6)];
        [spraypaintPath12 addCurveToPoint: CGPointMake(59.25, 41.75) controlPoint1: CGPointMake(59.09, 41.79) controlPoint2: CGPointMake(59.18, 41.77)];
        [spraypaintPath12 addLineToPoint: CGPointMake(59.25, 36.79)];
        [spraypaintPath12 addCurveToPoint: CGPointMake(58.69, 36.97) controlPoint1: CGPointMake(59.08, 36.85) controlPoint2: CGPointMake(58.89, 36.91)];
        [spraypaintPath12 closePath];
        spraypaintPath12.lineCapStyle = kCGLineCapRound;
        spraypaintPath12.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath12.lineWidth = 1.5;
        spraypaintPath13 = [UIBezierPath bezierPath];
        [spraypaintPath13 moveToPoint: CGPointMake(22.75, 13.27)];
        [spraypaintPath13 addLineToPoint: CGPointMake(22.75, 1.85)];
        [spraypaintPath13 addCurveToPoint: CGPointMake(37.1, 1.77) controlPoint1: CGPointMake(24.75, 0.99) controlPoint2: CGPointMake(32.02, -0.08)];
        [spraypaintPath13 addCurveToPoint: CGPointMake(36.99, 13.41) controlPoint1: CGPointMake(37.1, 1.77) controlPoint2: CGPointMake(37.01, 13)];
        spraypaintPath13.lineCapStyle = kCGLineCapRound;
        spraypaintPath13.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath13.lineWidth = 1.5;
        spraypaintPath14 = [UIBezierPath bezierPath];
        [spraypaintPath14 moveToPoint: CGPointMake(31.06, 5.35)];
        [spraypaintPath14 addCurveToPoint: CGPointMake(28.67, 8.39) controlPoint1: CGPointMake(29.26, 4.22) controlPoint2: CGPointMake(27.09, 6.81)];
        [spraypaintPath14 addCurveToPoint: CGPointMake(31.06, 5.35) controlPoint1: CGPointMake(30.97, 10.4) controlPoint2: CGPointMake(33.53, 6.9)];
        [spraypaintPath14 closePath];
        spraypaintPath14.lineCapStyle = kCGLineCapRound;
        spraypaintPath14.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath14.lineWidth = 1.5;
        spraypaintPath15 = [UIBezierPath bezierPath];
        [spraypaintPath15 moveToPoint: CGPointMake(40.39, 17.19)];
        [spraypaintPath15 addLineToPoint: CGPointMake(40.4, 17.23)];
        [spraypaintPath15 addCurveToPoint: CGPointMake(20.78, 17.28) controlPoint1: CGPointMake(37.97, 18.52) controlPoint2: CGPointMake(26.01, 19.59)];
        [spraypaintPath15 addCurveToPoint: CGPointMake(1.58, 37.25) controlPoint1: CGPointMake(8.1, 20.74) controlPoint2: CGPointMake(2.46, 30.59)];
        [spraypaintPath15 addCurveToPoint: CGPointMake(58.69, 36.97) controlPoint1: CGPointMake(13.1, 40.02) controlPoint2: CGPointMake(49.39, 39.65)];
        [spraypaintPath15 addCurveToPoint: CGPointMake(40.39, 17.19) controlPoint1: CGPointMake(57.83, 30.25) controlPoint2: CGPointMake(52.79, 20.52)];
        [spraypaintPath15 closePath];
        spraypaintPath15.lineCapStyle = kCGLineCapRound;
        spraypaintPath15.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath15.lineWidth = 1.5;
        spraypaintPath16 = [UIBezierPath bezierPath];
        [spraypaintPath16 moveToPoint: CGPointMake(40.39, 17.19)];
        [spraypaintPath16 addLineToPoint: CGPointMake(39.75, 13.72)];
        [spraypaintPath16 addCurveToPoint: CGPointMake(20.52, 13.76) controlPoint1: CGPointMake(39.75, 13.72) controlPoint2: CGPointMake(20.79, 13.71)];
        [spraypaintPath16 addLineToPoint: CGPointMake(20.15, 16.97)];
        [spraypaintPath16 addCurveToPoint: CGPointMake(20.77, 17.28) controlPoint1: CGPointMake(20.35, 17.08) controlPoint2: CGPointMake(20.56, 17.18)];
        [spraypaintPath16 addCurveToPoint: CGPointMake(40.4, 17.23) controlPoint1: CGPointMake(26.01, 19.59) controlPoint2: CGPointMake(37.97, 18.52)];
        [spraypaintPath16 addLineToPoint: CGPointMake(40.39, 17.19)];
        [spraypaintPath16 closePath];
        spraypaintPath16.lineCapStyle = kCGLineCapRound;
        spraypaintPath16.lineJoinStyle = kCGLineJoinRound;
        spraypaintPath16.lineWidth = 1.5;
        spraypaintPath17 = [UIBezierPath bezierPath];
        [spraypaintPath17 moveToPoint: CGPointMake(58.9, 42.41)];
        [spraypaintPath17 addLineToPoint: CGPointMake(58.56, 36.38)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(40.36, 17.41) controlPoint1: CGPointMake(57.91, 31.47) controlPoint2: CGPointMake(53.23, 20.57)];
        [spraypaintPath17 addLineToPoint: CGPointMake(39.75, 13.77)];
        [spraypaintPath17 addLineToPoint: CGPointMake(36.98, 13.77)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(36.98, 1.79) controlPoint1: CGPointMake(36.99, 13.27) controlPoint2: CGPointMake(36.98, 1.79)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(33.32, 1.35) controlPoint1: CGPointMake(35.69, 1.33) controlPoint2: CGPointMake(34.77, 1.49)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(33.5, 13.73) controlPoint1: CGPointMake(33.3, 1.2) controlPoint2: CGPointMake(33.5, 13.73)];
        [spraypaintPath17 addLineToPoint: CGPointMake(34.72, 17.76)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(43.62, 27) controlPoint1: CGPointMake(39.89, 19.34) controlPoint2: CGPointMake(42.35, 24.63)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(46.77, 38.3) controlPoint1: CGPointMake(45.42, 30.36) controlPoint2: CGPointMake(46.37, 34.17)];
        [spraypaintPath17 addLineToPoint: CGPointMake(47, 44.49)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(47.11, 170.74) controlPoint1: CGPointMake(47.09, 64.41) controlPoint2: CGPointMake(47.11, 170.74)];
        [spraypaintPath17 addCurveToPoint: CGPointMake(58.48, 167.45) controlPoint1: CGPointMake(55.06, 170.39) controlPoint2: CGPointMake(56.2, 169.01)];
        [spraypaintPath17 addLineToPoint: CGPointMake(58.63, 134.14)];
        [spraypaintPath17 addLineToPoint: CGPointMake(58.97, 54.27)];
        [spraypaintPath17 addLineToPoint: CGPointMake(58.97, 54.27)];
        [spraypaintPath17 addLineToPoint: CGPointMake(58.9, 42.41)];
        [spraypaintPath17 closePath];
        spraypaintPath17.miterLimit = 4;
        spraypaintPath18 = [UIBezierPath bezierPath];
        [spraypaintPath18 moveToPoint: CGPointMake(20.39, 28.39)];
        [spraypaintPath18 addCurveToPoint: CGPointMake(20.39, 26.11) controlPoint1: CGPointMake(21.86, 28.39) controlPoint2: CGPointMake(21.86, 26.11)];
        [spraypaintPath18 addCurveToPoint: CGPointMake(20.39, 28.39) controlPoint1: CGPointMake(18.92, 26.11) controlPoint2: CGPointMake(18.92, 28.39)];
        [spraypaintPath18 addLineToPoint: CGPointMake(20.39, 28.39)];
        [spraypaintPath18 closePath];
        spraypaintPath18.miterLimit = 4;
        spraypaintPath19 = [UIBezierPath bezierPath];
        [spraypaintPath19 moveToPoint: CGPointMake(39.89, 28.07)];
        [spraypaintPath19 addCurveToPoint: CGPointMake(39.89, 25.79) controlPoint1: CGPointMake(41.36, 28.07) controlPoint2: CGPointMake(41.36, 25.79)];
        [spraypaintPath19 addCurveToPoint: CGPointMake(39.89, 28.07) controlPoint1: CGPointMake(38.42, 25.79) controlPoint2: CGPointMake(38.42, 28.07)];
        [spraypaintPath19 addLineToPoint: CGPointMake(39.89, 28.07)];
        [spraypaintPath19 closePath];
        spraypaintPath19.miterLimit = 4;
        spraypaintPath20 = [UIBezierPath bezierPath];
        [spraypaintPath20 moveToPoint: CGPointMake(28.37, 28.86)];
        [spraypaintPath20 addCurveToPoint: CGPointMake(30.62, 31.45) controlPoint1: CGPointMake(28.35, 30.17) controlPoint2: CGPointMake(29.27, 31.34)];
        [spraypaintPath20 addCurveToPoint: CGPointMake(33.05, 29.04) controlPoint1: CGPointMake(32.11, 31.58) controlPoint2: CGPointMake(32.96, 30.41)];
        [spraypaintPath20 addCurveToPoint: CGPointMake(32.33, 29.04) controlPoint1: CGPointMake(33.08, 28.58) controlPoint2: CGPointMake(32.36, 28.58)];
        [spraypaintPath20 addCurveToPoint: CGPointMake(30.59, 30.73) controlPoint1: CGPointMake(32.27, 30.03) controlPoint2: CGPointMake(31.68, 30.89)];
        [spraypaintPath20 addCurveToPoint: CGPointMake(29.08, 28.86) controlPoint1: CGPointMake(29.65, 30.6) controlPoint2: CGPointMake(29.07, 29.78)];
        [spraypaintPath20 addCurveToPoint: CGPointMake(28.37, 28.86) controlPoint1: CGPointMake(29.09, 28.4) controlPoint2: CGPointMake(28.37, 28.4)];
        [spraypaintPath20 addLineToPoint: CGPointMake(28.37, 28.86)];
        [spraypaintPath20 closePath];
        spraypaintPath20.miterLimit = 4;

        // Crayon Paths
        crayonPath1 = [UIBezierPath bezierPath];
        [crayonPath1 moveToPoint: CGPointMake(34.48, 55.99)];
        [crayonPath1 addCurveToPoint: CGPointMake(34.46, 50.1) controlPoint1: CGPointMake(34.47, 53.9) controlPoint2: CGPointMake(34.46, 51.93)];
        [crayonPath1 addCurveToPoint: CGPointMake(0.79, 49.86) controlPoint1: CGPointMake(25.29, 52.12) controlPoint2: CGPointMake(9.1, 52.04)];
        [crayonPath1 addLineToPoint: CGPointMake(0.8, 55.99)];
        [crayonPath1 addCurveToPoint: CGPointMake(34.48, 55.99) controlPoint1: CGPointMake(9.41, 58.09) controlPoint2: CGPointMake(25.59, 58.09)];
        [crayonPath1 closePath];
        crayonPath1.miterLimit = 4;
        crayonPath2 = [UIBezierPath bezierPath];
        [crayonPath2 moveToPoint: CGPointMake(0.81, 67.49)];
        [crayonPath2 addLineToPoint: CGPointMake(0.95, 199.52)];
        [crayonPath2 addCurveToPoint: CGPointMake(34.55, 199.47) controlPoint1: CGPointMake(9.63, 201.59) controlPoint2: CGPointMake(25.73, 201.57)];
        [crayonPath2 addCurveToPoint: CGPointMake(34.51, 67.48) controlPoint1: CGPointMake(34.56, 177.55) controlPoint2: CGPointMake(34.59, 107.31)];
        [crayonPath2 addCurveToPoint: CGPointMake(0.81, 67.49) controlPoint1: CGPointMake(25.63, 69.58) controlPoint2: CGPointMake(9.44, 69.59)];
        [crayonPath2 closePath];
        crayonPath2.miterLimit = 4;
        crayonPath3 = [UIBezierPath bezierPath];
        [crayonPath3 moveToPoint: CGPointMake(0.82, 199.83)];
        [crayonPath3 addLineToPoint: CGPointMake(0.83, 207.31)];
        [crayonPath3 addCurveToPoint: CGPointMake(34.41, 207.31) controlPoint1: CGPointMake(11.16, 210.31) controlPoint2: CGPointMake(24.08, 209.97)];
        [crayonPath3 addCurveToPoint: CGPointMake(34.42, 199.77) controlPoint1: CGPointMake(34.41, 207.31) controlPoint2: CGPointMake(34.42, 204.56)];
        [crayonPath3 addCurveToPoint: CGPointMake(0.82, 199.83) controlPoint1: CGPointMake(25.6, 201.88) controlPoint2: CGPointMake(9.5, 201.9)];
        [crayonPath3 closePath];
        crayonPath3.miterLimit = 4;
        crayonPath4 = [UIBezierPath bezierPath];
        [crayonPath4 moveToPoint: CGPointMake(30.51, 33.68)];
        [crayonPath4 addCurveToPoint: CGPointMake(19.49, 1.56) controlPoint1: CGPointMake(30.11, 32.88) controlPoint2: CGPointMake(19.91, 3.06)];
        [crayonPath4 addCurveToPoint: CGPointMake(17.63, 1.06) controlPoint1: CGPointMake(19.49, 1.56) controlPoint2: CGPointMake(18.37, 1.06)];
        [crayonPath4 addCurveToPoint: CGPointMake(15.56, 1.56) controlPoint1: CGPointMake(16.7, 1.06) controlPoint2: CGPointMake(15.56, 1.56)];
        [crayonPath4 addCurveToPoint: CGPointMake(4.53, 33.68) controlPoint1: CGPointMake(15.13, 3.06) controlPoint2: CGPointMake(4.93, 32.88)];
        crayonPath4.lineWidth = 0.5;
        crayonPath5 = [UIBezierPath bezierPath];
        [crayonPath5 moveToPoint: CGPointMake(17.95, 34.06)];
        [crayonPath5 addCurveToPoint: CGPointMake(1.74, 35.55) controlPoint1: CGPointMake(14.64, 33.9) controlPoint2: CGPointMake(2.04, 34.83)];
        [crayonPath5 addCurveToPoint: CGPointMake(1.53, 46.35) controlPoint1: CGPointMake(1.39, 36.39) controlPoint2: CGPointMake(1.53, 46.35)];
        [crayonPath5 addLineToPoint: CGPointMake(1.54, 49.14)];
        [crayonPath5 addCurveToPoint: CGPointMake(33.54, 49.33) controlPoint1: CGPointMake(9.44, 51.13) controlPoint2: CGPointMake(24.82, 51.17)];
        [crayonPath5 addCurveToPoint: CGPointMake(33.39, 35.42) controlPoint1: CGPointMake(33.5, 40.85) controlPoint2: CGPointMake(33.49, 35.56)];
        [crayonPath5 addCurveToPoint: CGPointMake(17.95, 34.06) controlPoint1: CGPointMake(32.91, 34.79) controlPoint2: CGPointMake(24.58, 34.12)];
        crayonPath5.lineWidth = 0.5;
        [crayonPath5 closePath];
        crayonPath6 = [UIBezierPath bezierPath];
        [crayonPath6 moveToPoint: CGPointMake(0.67, 56.29)];
        [crayonPath6 addLineToPoint: CGPointMake(0.68, 67.8)];
        [crayonPath6 addCurveToPoint: CGPointMake(34.38, 67.78) controlPoint1: CGPointMake(9.31, 69.89) controlPoint2: CGPointMake(25.5, 69.89)];
        [crayonPath6 addCurveToPoint: CGPointMake(34.35, 56.29) controlPoint1: CGPointMake(34.37, 63.66) controlPoint2: CGPointMake(34.36, 59.8)];
        [crayonPath6 addCurveToPoint: CGPointMake(0.67, 56.29) controlPoint1: CGPointMake(25.46, 58.39) controlPoint2: CGPointMake(9.28, 58.39)];
        [crayonPath6 closePath];
        crayonPath6.miterLimit = 4;
        crayonPath7 = [UIBezierPath bezierPath];
        [crayonPath7 moveToPoint: CGPointMake(0.94, 199.52)];
        [crayonPath7 addLineToPoint: CGPointMake(0.95, 207)];
        [crayonPath7 addCurveToPoint: CGPointMake(34.54, 207) controlPoint1: CGPointMake(11.29, 210) controlPoint2: CGPointMake(24.2, 209.67)];
        [crayonPath7 addCurveToPoint: CGPointMake(34.54, 199.47) controlPoint1: CGPointMake(34.54, 207) controlPoint2: CGPointMake(34.54, 204.25)];
        [crayonPath7 addCurveToPoint: CGPointMake(0.94, 199.52) controlPoint1: CGPointMake(25.72, 201.57) controlPoint2: CGPointMake(9.62, 201.59)];
        [crayonPath7 closePath];
        crayonPath7.lineCapStyle = kCGLineCapRound;
        crayonPath7.lineJoinStyle = kCGLineJoinRound;
        crayonPath7.lineWidth = 1.5;
        crayonPath8 = [UIBezierPath bezierPath];
        [crayonPath8 moveToPoint: CGPointMake(30.64, 33.87)];
        [crayonPath8 addCurveToPoint: CGPointMake(19.61, 1.25) controlPoint1: CGPointMake(30.24, 33.07) controlPoint2: CGPointMake(20.03, 2.75)];
        [crayonPath8 addCurveToPoint: CGPointMake(17.75, 0.75) controlPoint1: CGPointMake(19.61, 1.25) controlPoint2: CGPointMake(18.5, 0.75)];
        [crayonPath8 addCurveToPoint: CGPointMake(15.68, 1.25) controlPoint1: CGPointMake(16.82, 0.75) controlPoint2: CGPointMake(15.68, 1.25)];
        [crayonPath8 addCurveToPoint: CGPointMake(4.65, 33.87) controlPoint1: CGPointMake(15.25, 2.75) controlPoint2: CGPointMake(5.05, 33.07)];
        crayonPath8.lineCapStyle = kCGLineCapRound;
        crayonPath8.lineJoinStyle = kCGLineJoinRound;
        crayonPath8.lineWidth = 1.5;
        crayonPath9 = [UIBezierPath bezierPath];
        [crayonPath9 moveToPoint: CGPointMake(18.04, 33.34)];
        [crayonPath9 addCurveToPoint: CGPointMake(1, 34.97) controlPoint1: CGPointMake(14.56, 33.17) controlPoint2: CGPointMake(1.31, 34.18)];
        [crayonPath9 addCurveToPoint: CGPointMake(0.78, 46.83) controlPoint1: CGPointMake(0.63, 35.9) controlPoint2: CGPointMake(0.78, 46.83)];
        [crayonPath9 addLineToPoint: CGPointMake(0.78, 49.89)];
        [crayonPath9 addCurveToPoint: CGPointMake(34.45, 50.1) controlPoint1: CGPointMake(9.09, 52.08) controlPoint2: CGPointMake(25.28, 52.12)];
        [crayonPath9 addCurveToPoint: CGPointMake(34.29, 34.83) controlPoint1: CGPointMake(34.41, 40.79) controlPoint2: CGPointMake(34.4, 34.98)];
        [crayonPath9 addCurveToPoint: CGPointMake(18.04, 33.34) controlPoint1: CGPointMake(33.79, 34.14) controlPoint2: CGPointMake(25.03, 33.4)];
        [crayonPath9 closePath];
        crayonPath9.lineCapStyle = kCGLineCapRound;
        crayonPath9.lineJoinStyle = kCGLineJoinRound;
        crayonPath9.lineWidth = 1.5;
        crayonPath10 = [UIBezierPath bezierPath];
        [crayonPath10 moveToPoint: CGPointMake(34.47, 55.99)];
        [crayonPath10 addCurveToPoint: CGPointMake(34.45, 50.1) controlPoint1: CGPointMake(34.46, 53.9) controlPoint2: CGPointMake(34.45, 51.93)];
        [crayonPath10 addCurveToPoint: CGPointMake(0.78, 49.86) controlPoint1: CGPointMake(25.28, 52.12) controlPoint2: CGPointMake(9.09, 52.04)];
        [crayonPath10 addLineToPoint: CGPointMake(0.79, 55.99)];
        [crayonPath10 addCurveToPoint: CGPointMake(34.47, 55.99) controlPoint1: CGPointMake(9.4, 58.09) controlPoint2: CGPointMake(25.58, 58.09)];
        [crayonPath10 closePath];
        crayonPath10.lineCapStyle = kCGLineCapRound;
        crayonPath10.lineJoinStyle = kCGLineJoinRound;
        crayonPath10.lineWidth = 1.5;
        crayonPath11 = [UIBezierPath bezierPath];
        [crayonPath11 moveToPoint: CGPointMake(0.79, 55.99)];
        [crayonPath11 addLineToPoint: CGPointMake(0.8, 67.49)];
        [crayonPath11 addCurveToPoint: CGPointMake(34.5, 67.48) controlPoint1: CGPointMake(9.43, 69.59) controlPoint2: CGPointMake(25.62, 69.58)];
        [crayonPath11 addCurveToPoint: CGPointMake(34.47, 55.98) controlPoint1: CGPointMake(34.49, 63.35) controlPoint2: CGPointMake(34.48, 59.5)];
        [crayonPath11 addCurveToPoint: CGPointMake(0.79, 55.99) controlPoint1: CGPointMake(25.58, 58.09) controlPoint2: CGPointMake(9.4, 58.09)];
        [crayonPath11 closePath];
        crayonPath11.lineCapStyle = kCGLineCapRound;
        crayonPath11.lineJoinStyle = kCGLineJoinRound;
        crayonPath11.lineWidth = 1.5;
        crayonPath12 = [UIBezierPath bezierPath];
        [crayonPath12 moveToPoint: CGPointMake(0.8, 67.49)];
        [crayonPath12 addLineToPoint: CGPointMake(0.94, 199.52)];
        [crayonPath12 addCurveToPoint: CGPointMake(34.54, 199.47) controlPoint1: CGPointMake(9.62, 201.59) controlPoint2: CGPointMake(25.72, 201.57)];
        [crayonPath12 addCurveToPoint: CGPointMake(34.5, 67.48) controlPoint1: CGPointMake(34.55, 177.55) controlPoint2: CGPointMake(34.58, 107.31)];
        [crayonPath12 addCurveToPoint: CGPointMake(0.8, 67.49) controlPoint1: CGPointMake(25.62, 69.58) controlPoint2: CGPointMake(9.43, 69.59)];
        [crayonPath12 closePath];
        crayonPath12.lineCapStyle = kCGLineCapRound;
        crayonPath12.lineJoinStyle = kCGLineJoinRound;
        crayonPath12.lineWidth = 1.5;
        crayonPath13 = [UIBezierPath bezierPath];
        [crayonPath13 moveToPoint: CGPointMake(34.5, 67.48)];
        [crayonPath13 addCurveToPoint: CGPointMake(34.47, 55.98) controlPoint1: CGPointMake(34.49, 63.35) controlPoint2: CGPointMake(34.48, 59.5)];
        [crayonPath13 addCurveToPoint: CGPointMake(34.45, 50.1) controlPoint1: CGPointMake(34.46, 53.9) controlPoint2: CGPointMake(34.45, 51.93)];
        [crayonPath13 addCurveToPoint: CGPointMake(34.29, 34.83) controlPoint1: CGPointMake(34.41, 40.79) controlPoint2: CGPointMake(34.4, 34.98)];
        [crayonPath13 addCurveToPoint: CGPointMake(30.51, 34.04) controlPoint1: CGPointMake(34.1, 34.56) controlPoint2: CGPointMake(32.63, 34.28)];
        [crayonPath13 addCurveToPoint: CGPointMake(19.61, 1.75) controlPoint1: CGPointMake(29.25, 30.66) controlPoint2: CGPointMake(20.01, 3.18)];
        [crayonPath13 addCurveToPoint: CGPointMake(17.75, 1.25) controlPoint1: CGPointMake(19.61, 1.75) controlPoint2: CGPointMake(18.49, 1.25)];
        [crayonPath13 addCurveToPoint: CGPointMake(16.88, 1.36) controlPoint1: CGPointMake(17.47, 1.25) controlPoint2: CGPointMake(17.16, 1.3)];
        [crayonPath13 addCurveToPoint: CGPointMake(16.91, 2.05) controlPoint1: CGPointMake(16.89, 1.59) controlPoint2: CGPointMake(16.9, 1.82)];
        [crayonPath13 addLineToPoint: CGPointMake(23.9, 33.32)];
        [crayonPath13 addLineToPoint: CGPointMake(23.9, 208.81)];
        [crayonPath13 addCurveToPoint: CGPointMake(34.54, 207) controlPoint1: CGPointMake(27.6, 208.47) controlPoint2: CGPointMake(31.2, 207.86)];
        [crayonPath13 addCurveToPoint: CGPointMake(34.54, 199.47) controlPoint1: CGPointMake(34.54, 207) controlPoint2: CGPointMake(34.54, 204.25)];
        [crayonPath13 addCurveToPoint: CGPointMake(34.5, 67.48) controlPoint1: CGPointMake(34.55, 177.55) controlPoint2: CGPointMake(34.58, 107.31)];
        [crayonPath13 closePath];
        crayonPath13.miterLimit = 4;
        crayonPath14 = [UIBezierPath bezierPath];
        [crayonPath14 moveToPoint: CGPointMake(7.73, 41.62)];
        [crayonPath14 addCurveToPoint: CGPointMake(7.73, 39.34) controlPoint1: CGPointMake(9.2, 41.62) controlPoint2: CGPointMake(9.2, 39.34)];
        [crayonPath14 addCurveToPoint: CGPointMake(7.73, 41.62) controlPoint1: CGPointMake(6.25, 39.34) controlPoint2: CGPointMake(6.25, 41.62)];
        [crayonPath14 addLineToPoint: CGPointMake(7.73, 41.62)];
        [crayonPath14 closePath];
        crayonPath14.miterLimit = 4;
        crayonPath15 = [UIBezierPath bezierPath];
        [crayonPath15 moveToPoint: CGPointMake(27.23, 41.3)];
        [crayonPath15 addCurveToPoint: CGPointMake(27.23, 39.02) controlPoint1: CGPointMake(28.7, 41.3) controlPoint2: CGPointMake(28.7, 39.02)];
        [crayonPath15 addCurveToPoint: CGPointMake(27.23, 41.3) controlPoint1: CGPointMake(25.75, 39.02) controlPoint2: CGPointMake(25.75, 41.3)];
        [crayonPath15 addLineToPoint: CGPointMake(27.23, 41.3)];
        [crayonPath15 closePath];
        crayonPath15.miterLimit = 4;
        crayonPath16 = [UIBezierPath bezierPath];
        [crayonPath16 moveToPoint: CGPointMake(15.7, 42.09)];
        [crayonPath16 addCurveToPoint: CGPointMake(17.96, 44.68) controlPoint1: CGPointMake(15.69, 43.4) controlPoint2: CGPointMake(16.61, 44.57)];
        [crayonPath16 addCurveToPoint: CGPointMake(20.39, 42.26) controlPoint1: CGPointMake(19.45, 44.8) controlPoint2: CGPointMake(20.3, 43.64)];
        [crayonPath16 addCurveToPoint: CGPointMake(19.67, 42.26) controlPoint1: CGPointMake(20.42, 41.8) controlPoint2: CGPointMake(19.7, 41.8)];
        [crayonPath16 addCurveToPoint: CGPointMake(17.93, 43.96) controlPoint1: CGPointMake(19.61, 43.25) controlPoint2: CGPointMake(19.02, 44.11)];
        [crayonPath16 addCurveToPoint: CGPointMake(16.42, 42.09) controlPoint1: CGPointMake(16.99, 43.82) controlPoint2: CGPointMake(16.41, 43)];
        [crayonPath16 addCurveToPoint: CGPointMake(15.7, 42.09) controlPoint1: CGPointMake(16.43, 41.63) controlPoint2: CGPointMake(15.71, 41.63)];
        [crayonPath16 addLineToPoint: CGPointMake(15.7, 42.09)];
        [crayonPath16 closePath];
        crayonPath16.miterLimit = 4;

        // Paintbucket paths
        paintbucketPath1 = [UIBezierPath bezierPath];
        [paintbucketPath1 moveToPoint: CGPointMake(0.5, 90.7)];
        [paintbucketPath1 addLineToPoint: CGPointMake(0.5, 116)];
        [paintbucketPath1 addCurveToPoint: CGPointMake(33.25, 118.04) controlPoint1: CGPointMake(0.5, 116) controlPoint2: CGPointMake(13.1, 118.04)];
        [paintbucketPath1 addCurveToPoint: CGPointMake(66, 116) controlPoint1: CGPointMake(53.4, 118.04) controlPoint2: CGPointMake(66, 116)];
        [paintbucketPath1 addLineToPoint: CGPointMake(66, 90.75)];
        [paintbucketPath1 addCurveToPoint: CGPointMake(33.25, 92.54) controlPoint1: CGPointMake(61.5, 91.3) controlPoint2: CGPointMake(49, 92.54)];
        [paintbucketPath1 addCurveToPoint: CGPointMake(0.5, 90.7) controlPoint1: CGPointMake(16.96, 92.54) controlPoint2: CGPointMake(5, 91.21)];
        [paintbucketPath1 closePath];
        paintbucketPath1.miterLimit = 4;
        paintbucketPath2 = [UIBezierPath bezierPath];
        [paintbucketPath2 moveToPoint: CGPointMake(33.25, 46.54)];
        [paintbucketPath2 addCurveToPoint: CGPointMake(0.5, 44.7) controlPoint1: CGPointMake(16.96, 46.54) controlPoint2: CGPointMake(5, 45.21)];
        [paintbucketPath2 addLineToPoint: CGPointMake(0.5, 90.7)];
        [paintbucketPath2 addCurveToPoint: CGPointMake(33.25, 92.54) controlPoint1: CGPointMake(5, 91.21) controlPoint2: CGPointMake(16.96, 92.54)];
        [paintbucketPath2 addCurveToPoint: CGPointMake(66, 90.75) controlPoint1: CGPointMake(49, 92.54) controlPoint2: CGPointMake(61.5, 91.3)];
        [paintbucketPath2 addLineToPoint: CGPointMake(66, 44.75)];
        [paintbucketPath2 addCurveToPoint: CGPointMake(33.25, 46.54) controlPoint1: CGPointMake(61.5, 45.3) controlPoint2: CGPointMake(49, 46.54)];
        [paintbucketPath2 closePath];
        paintbucketPath2.miterLimit = 4;
        paintbucketPath3 = [UIBezierPath bezierPath];
        [paintbucketPath3 moveToPoint: CGPointMake(66, 44.75)];
        [paintbucketPath3 addLineToPoint: CGPointMake(66, 30)];
        [paintbucketPath3 addLineToPoint: CGPointMake(0.5, 30)];
        [paintbucketPath3 addLineToPoint: CGPointMake(0.5, 44.7)];
        [paintbucketPath3 addCurveToPoint: CGPointMake(33.25, 46.54) controlPoint1: CGPointMake(5, 45.21) controlPoint2: CGPointMake(16.96, 46.54)];
        [paintbucketPath3 addCurveToPoint: CGPointMake(66, 44.75) controlPoint1: CGPointMake(49, 46.54) controlPoint2: CGPointMake(61.5, 45.3)];
        [paintbucketPath3 closePath];
        paintbucketPath3.miterLimit = 4;
        paintbucketPath4 = [UIBezierPath bezierPath];
        [paintbucketPath4 moveToPoint: CGPointMake(66.25, 44.75)];
        [paintbucketPath4 addLineToPoint: CGPointMake(66.25, 29.75)];
        [paintbucketPath4 addLineToPoint: CGPointMake(0.75, 29.75)];
        [paintbucketPath4 addLineToPoint: CGPointMake(0.75, 44.7)];
        [paintbucketPath4 addCurveToPoint: CGPointMake(33.5, 46.54) controlPoint1: CGPointMake(4.88, 45.21) controlPoint2: CGPointMake(17.21, 46.54)];
        [paintbucketPath4 addCurveToPoint: CGPointMake(66.25, 44.75) controlPoint1: CGPointMake(49.25, 46.54) controlPoint2: CGPointMake(61.6, 45.3)];
        [paintbucketPath4 closePath];
        paintbucketPath4.lineCapStyle = kCGLineCapRound;
        paintbucketPath4.lineJoinStyle = kCGLineJoinRound;
        paintbucketPath4.lineWidth = 1.5;
        paintbucketPath5 = [UIBezierPath bezierPath];
        [paintbucketPath5 moveToPoint: CGPointMake(0.75, 90.7)];
        [paintbucketPath5 addLineToPoint: CGPointMake(0.75, 116)];
        [paintbucketPath5 addCurveToPoint: CGPointMake(33.5, 118.04) controlPoint1: CGPointMake(0.75, 116) controlPoint2: CGPointMake(13.35, 118.04)];
        [paintbucketPath5 addCurveToPoint: CGPointMake(66.25, 116) controlPoint1: CGPointMake(53.65, 118.04) controlPoint2: CGPointMake(66.25, 116)];
        [paintbucketPath5 addLineToPoint: CGPointMake(66.25, 90.75)];
        [paintbucketPath5 addCurveToPoint: CGPointMake(33.5, 92.54) controlPoint1: CGPointMake(61.6, 91.3) controlPoint2: CGPointMake(49.25, 92.54)];
        [paintbucketPath5 addCurveToPoint: CGPointMake(0.75, 90.7) controlPoint1: CGPointMake(17.21, 92.54) controlPoint2: CGPointMake(4.88, 91.21)];
        [paintbucketPath5 closePath];
        paintbucketPath5.lineCapStyle = kCGLineCapRound;
        paintbucketPath5.lineJoinStyle = kCGLineJoinRound;
        paintbucketPath5.lineWidth = 1.5;
        paintbucketPath6 = [UIBezierPath bezierPath];
        [paintbucketPath6 moveToPoint: CGPointMake(33.5, 46.54)];
        [paintbucketPath6 addCurveToPoint: CGPointMake(0.75, 44.7) controlPoint1: CGPointMake(17.21, 46.54) controlPoint2: CGPointMake(4.88, 45.21)];
        [paintbucketPath6 addLineToPoint: CGPointMake(0.75, 90.7)];
        [paintbucketPath6 addCurveToPoint: CGPointMake(33.5, 92.54) controlPoint1: CGPointMake(4.88, 91.21) controlPoint2: CGPointMake(17.21, 92.54)];
        [paintbucketPath6 addCurveToPoint: CGPointMake(66.25, 90.75) controlPoint1: CGPointMake(49.25, 92.54) controlPoint2: CGPointMake(61.6, 91.3)];
        [paintbucketPath6 addLineToPoint: CGPointMake(66.25, 44.75)];
        [paintbucketPath6 addCurveToPoint: CGPointMake(33.5, 46.54) controlPoint1: CGPointMake(61.6, 45.3) controlPoint2: CGPointMake(49.25, 46.54)];
        [paintbucketPath6 closePath];
        paintbucketPath6.lineCapStyle = kCGLineCapRound;
        paintbucketPath6.lineJoinStyle = kCGLineJoinRound;
        paintbucketPath6.lineWidth = 1.5;
        paintbucketPath7 = [UIBezierPath bezierPath];
        [paintbucketPath7 moveToPoint: CGPointMake(47.49, 29.88)];
        [paintbucketPath7 addCurveToPoint: CGPointMake(47.7, 117.63) controlPoint1: CGPointMake(47.52, 30.12) controlPoint2: CGPointMake(47.7, 114.16)];
        [paintbucketPath7 addCurveToPoint: CGPointMake(66, 115.88) controlPoint1: CGPointMake(60.15, 117.06) controlPoint2: CGPointMake(66, 115.88)];
        [paintbucketPath7 addLineToPoint: CGPointMake(66, 29.88)];
        [paintbucketPath7 addLineToPoint: CGPointMake(47.49, 29.88)];
        [paintbucketPath7 closePath];
        paintbucketPath7.miterLimit = 4;
        paintbucketPath8 = [UIBezierPath bezierPath];
        [paintbucketPath8 moveToPoint: CGPointMake(62.47, 30.93)];
        [paintbucketPath8 addCurveToPoint: CGPointMake(33.93, 29.32) controlPoint1: CGPointMake(56.92, 29.97) controlPoint2: CGPointMake(46.23, 29.32)];
        [paintbucketPath8 addCurveToPoint: CGPointMake(5.4, 30.93) controlPoint1: CGPointMake(21.64, 29.32) controlPoint2: CGPointMake(10.94, 29.97)];
        [paintbucketPath8 addCurveToPoint: CGPointMake(33.93, 32.54) controlPoint1: CGPointMake(10.94, 31.89) controlPoint2: CGPointMake(21.64, 32.54)];
        [paintbucketPath8 addCurveToPoint: CGPointMake(62.47, 30.93) controlPoint1: CGPointMake(46.23, 32.54) controlPoint2: CGPointMake(56.92, 31.89)];
        [paintbucketPath8 closePath];
        paintbucketPath8.miterLimit = 4;
        paintbucketPath9 = [UIBezierPath bezierPath];
        [paintbucketPath9 moveToPoint: CGPointMake(61.97, 30.93)];
        [paintbucketPath9 addCurveToPoint: CGPointMake(66.01, 29.43) controlPoint1: CGPointMake(64.54, 30.49) controlPoint2: CGPointMake(66.01, 29.98)];
        [paintbucketPath9 addCurveToPoint: CGPointMake(33.43, 26.32) controlPoint1: CGPointMake(66.01, 27.72) controlPoint2: CGPointMake(51.42, 26.32)];
        [paintbucketPath9 addCurveToPoint: CGPointMake(0.86, 29.43) controlPoint1: CGPointMake(15.44, 26.32) controlPoint2: CGPointMake(0.86, 27.72)];
        [paintbucketPath9 addCurveToPoint: CGPointMake(4.9, 30.93) controlPoint1: CGPointMake(0.86, 29.98) controlPoint2: CGPointMake(2.33, 30.49)];
        [paintbucketPath9 addCurveToPoint: CGPointMake(33.43, 29.32) controlPoint1: CGPointMake(10.44, 29.97) controlPoint2: CGPointMake(21.14, 29.32)];
        [paintbucketPath9 addCurveToPoint: CGPointMake(61.97, 30.93) controlPoint1: CGPointMake(45.73, 29.32) controlPoint2: CGPointMake(56.42, 29.97)];
        [paintbucketPath9 closePath];
        paintbucketPath9.miterLimit = 4;
        paintbucketPath10 = [UIBezierPath bezierPath];
        [paintbucketPath10 moveToPoint: CGPointMake(61.97, 30.93)];
        [paintbucketPath10 addCurveToPoint: CGPointMake(66.01, 29.43) controlPoint1: CGPointMake(64.54, 30.49) controlPoint2: CGPointMake(66.01, 29.98)];
        [paintbucketPath10 addCurveToPoint: CGPointMake(33.43, 26.32) controlPoint1: CGPointMake(66.01, 27.72) controlPoint2: CGPointMake(51.42, 26.32)];
        [paintbucketPath10 addCurveToPoint: CGPointMake(0.86, 29.43) controlPoint1: CGPointMake(15.44, 26.32) controlPoint2: CGPointMake(0.86, 27.72)];
        [paintbucketPath10 addCurveToPoint: CGPointMake(4.9, 30.93) controlPoint1: CGPointMake(0.86, 29.98) controlPoint2: CGPointMake(2.33, 30.49)];
        [paintbucketPath10 addCurveToPoint: CGPointMake(33.43, 29.32) controlPoint1: CGPointMake(10.44, 29.97) controlPoint2: CGPointMake(21.14, 29.32)];
        [paintbucketPath10 addCurveToPoint: CGPointMake(61.97, 30.93) controlPoint1: CGPointMake(45.73, 29.32) controlPoint2: CGPointMake(56.42, 29.97)];
        [paintbucketPath10 closePath];
        paintbucketPath10.lineWidth = 1.5;
        paintbucketPath11 = [UIBezierPath bezierPath];
        [paintbucketPath11 moveToPoint: CGPointMake(61.97, 30.93)];
        [paintbucketPath11 addCurveToPoint: CGPointMake(33.43, 29.32) controlPoint1: CGPointMake(56.42, 29.97) controlPoint2: CGPointMake(45.73, 29.32)];
        [paintbucketPath11 addCurveToPoint: CGPointMake(4.9, 30.93) controlPoint1: CGPointMake(21.14, 29.32) controlPoint2: CGPointMake(10.44, 29.97)];
        [paintbucketPath11 addCurveToPoint: CGPointMake(33.43, 32.54) controlPoint1: CGPointMake(10.44, 31.89) controlPoint2: CGPointMake(21.14, 32.54)];
        [paintbucketPath11 addCurveToPoint: CGPointMake(61.97, 30.93) controlPoint1: CGPointMake(45.73, 32.54) controlPoint2: CGPointMake(56.42, 31.89)];
        [paintbucketPath11 closePath];
        paintbucketPath11.lineCapStyle = kCGLineCapRound;
        paintbucketPath11.lineJoinStyle = kCGLineJoinRound;
        paintbucketPath11.lineWidth = 1.5;
        paintbucketPath12 = [UIBezierPath bezierPath];
        [paintbucketPath12 moveToPoint: CGPointMake(66.21, 29.26)];
        [paintbucketPath12 addCurveToPoint: CGPointMake(33.82, 2.75) controlPoint1: CGPointMake(66.21, 13.12) controlPoint2: CGPointMake(53.97, 2.75)];
        [paintbucketPath12 addLineToPoint: CGPointMake(32.89, 2.75)];
        [paintbucketPath12 addCurveToPoint: CGPointMake(1, 29.29) controlPoint1: CGPointMake(12.74, 2.75) controlPoint2: CGPointMake(1, 13.12)];
        paintbucketPath12.lineCapStyle = kCGLineCapRound;
        paintbucketPath12.lineJoinStyle = kCGLineJoinRound;
        paintbucketPath12.lineWidth = 1.5;
        paintbucketPath13 = [UIBezierPath bezierPath];
        [paintbucketPath13 moveToPoint: CGPointMake(40.64, 0.5)];
        [paintbucketPath13 addCurveToPoint: CGPointMake(40.64, 4.5) controlPoint1: CGPointMake(41.37, 1.03) controlPoint2: CGPointMake(41.69, 3.5)];
        [paintbucketPath13 addLineToPoint: CGPointMake(27.31, 4.5)];
        [paintbucketPath13 addCurveToPoint: CGPointMake(27.31, 0.5) controlPoint1: CGPointMake(26.26, 3.5) controlPoint2: CGPointMake(26.59, 1.02)];
        [paintbucketPath13 addLineToPoint: CGPointMake(40.64, 0.5)];
        [paintbucketPath13 closePath];
        paintbucketPath13.miterLimit = 4;
        paintbucketPath14 = [UIBezierPath bezierPath];
        [paintbucketPath14 moveToPoint: CGPointMake(40.64, 0.75)];
        [paintbucketPath14 addCurveToPoint: CGPointMake(40.64, 4.75) controlPoint1: CGPointMake(41.37, 1.25) controlPoint2: CGPointMake(41.69, 3.75)];
        [paintbucketPath14 addLineToPoint: CGPointMake(27.31, 4.75)];
        [paintbucketPath14 addCurveToPoint: CGPointMake(27.31, 0.75) controlPoint1: CGPointMake(26.26, 3.75) controlPoint2: CGPointMake(26.59, 1.25)];
        [paintbucketPath14 addLineToPoint: CGPointMake(40.64, 0.75)];
        [paintbucketPath14 closePath];
        paintbucketPath14.lineCapStyle = kCGLineCapRound;
        paintbucketPath14.lineJoinStyle = kCGLineJoinRound;
        paintbucketPath14.lineWidth = 1.5;
        paintbucketPath15 = [UIBezierPath bezierPath];
        [paintbucketPath15 moveToPoint: CGPointMake(21.51, 54.88)];
        [paintbucketPath15 addCurveToPoint: CGPointMake(21.51, 51.88) controlPoint1: CGPointMake(23.44, 54.88) controlPoint2: CGPointMake(23.44, 51.88)];
        [paintbucketPath15 addCurveToPoint: CGPointMake(21.51, 54.88) controlPoint1: CGPointMake(19.57, 51.88) controlPoint2: CGPointMake(19.57, 54.88)];
        [paintbucketPath15 addLineToPoint: CGPointMake(21.51, 54.88)];
        [paintbucketPath15 closePath];
        paintbucketPath15.miterLimit = 4;
        paintbucketPath16 = [UIBezierPath bezierPath];
        [paintbucketPath16 moveToPoint: CGPointMake(43.49, 54.88)];
        [paintbucketPath16 addCurveToPoint: CGPointMake(43.49, 51.88) controlPoint1: CGPointMake(45.43, 54.88) controlPoint2: CGPointMake(45.43, 51.88)];
        [paintbucketPath16 addCurveToPoint: CGPointMake(43.49, 54.88) controlPoint1: CGPointMake(41.56, 51.88) controlPoint2: CGPointMake(41.56, 54.88)];
        [paintbucketPath16 addLineToPoint: CGPointMake(43.49, 54.88)];
        [paintbucketPath16 closePath];
        paintbucketPath16.miterLimit = 4;
        paintbucketPath17 = [UIBezierPath bezierPath];
        [paintbucketPath17 moveToPoint: CGPointMake(30.5, 56)];
        [paintbucketPath17 addCurveToPoint: CGPointMake(32.69, 58.49) controlPoint1: CGPointMake(30.42, 57.36) controlPoint2: CGPointMake(31.37, 58.35)];
        [paintbucketPath17 addCurveToPoint: CGPointMake(35.19, 56.01) controlPoint1: CGPointMake(34.19, 58.65) controlPoint2: CGPointMake(35.14, 57.38)];
        [paintbucketPath17 addCurveToPoint: CGPointMake(34.47, 56.01) controlPoint1: CGPointMake(35.2, 55.55) controlPoint2: CGPointMake(34.48, 55.55)];
        [paintbucketPath17 addCurveToPoint: CGPointMake(32.82, 57.78) controlPoint1: CGPointMake(34.44, 57.01) controlPoint2: CGPointMake(33.86, 57.77)];
        [paintbucketPath17 addCurveToPoint: CGPointMake(31.21, 56) controlPoint1: CGPointMake(31.81, 57.78) controlPoint2: CGPointMake(31.16, 56.96)];
        [paintbucketPath17 addCurveToPoint: CGPointMake(30.5, 56) controlPoint1: CGPointMake(31.24, 55.54) controlPoint2: CGPointMake(30.52, 55.54)];
        [paintbucketPath17 addLineToPoint: CGPointMake(30.5, 56)];
        [paintbucketPath17 closePath];
        paintbucketPath17.miterLimit = 4;
    }
}

- (CGSize)boundsSize
{
    CGSize size = [[self class] sizeForBrushType:self.brushType];
    size.width *= self.scale;
    size.height *= self.scale;
    return size;
}

- (void)drawRect:(CGRect)rect
{
    UIColor *activeColor = self.tintColor;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    switch (self.brushType)
    {
        case CVSBrushTypePaintbrush:
        {
            //// white_and_grey_1_
            [gray setFill];
            [paintbrushPath1 fill];
            [white setFill];
            [paintbrushPath2 fill];

            //// colour_4_
            [activeColor setFill];
            [paintbrushPath3 fill];
            [activeColor setFill];
            [paintbrushPath4 fill];

            //// outline_4_
            [strokeColor setStroke];
            [paintbrushPath5 stroke];
            [strokeColor setStroke];
            [paintbrushPath6 stroke];

            [strokeColor setStroke];
            [paintbrushPath7 stroke];
            [strokeColor setStroke];
            [paintbrushPath8 stroke];
            [strokeColor setStroke];
            [paintbrushPath9 stroke];

            [strokeColor setStroke];
            [paintbrushPath10 stroke];
            [strokeColor setStroke];
            [paintbrushPath11 stroke];

            //// shadow
            [shading setFill];
            [paintbrushPath12 fill];
            [shading setFill];
            [paintbrushPath13 fill];
            [shading setFill];
            [paintbrushPath14 fill];

            // Smile
            // NOTE: There is a a bug causing hasSmile to sometimes be false when it shouldn't.
            // We never actually turn the smiles off, so disabling this for now. -dave
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [paintbrushPath15 fill];
            [strokeColor setFill];
            [paintbrushPath16 fill];
            [strokeColor setFill];
            [paintbrushPath17 fill];
            //}
            break;
        }
        case CVSBrushTypeMarker:
        {
            //// white_2_
            [white setFill];
            [markerPath1 fill];
            [white setFill];
            [markerPath2 fill];

            //// colour_5_
            [activeColor setFill];
            [markerPath3 fill];
            [activeColor setFill];
            [markerPath4 fill];
            [activeColor setFill];
            [markerPath5 fill];


            //// Outlines
            [strokeColor setStroke];
            [markerPath6 stroke];
            [strokeColor setStroke];
            [markerPath7 stroke];
            [strokeColor setStroke];
            [markerPath8 stroke];
            [strokeColor setStroke];
            [markerPath9 stroke];
            [strokeColor setStroke];
            [markerPath10 stroke];
            [strokeColor setStroke];
            [markerPath11 stroke];
            [white setFill];
            [markerPath12 fill];
            [strokeColor setStroke];
            [markerPath12 stroke];

            // Shading
            [shading setFill];
            [markerPath13 fill];

            // Smile
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [markerPath14 fill];
            [strokeColor setFill];
            [markerPath15 fill];
            [strokeColor setFill];
            [markerPath16 fill];
            //}
            break;
        }
        case CVSBrushTypePen:
        {
            //// colour_3_
            [activeColor setFill];
            [pencilPath1 fill];
            [activeColor setFill];
            [pencilPath2 fill];
            [white setFill];
            [pencilPath3 fill];

            //// outline_3_
            [strokeColor setStroke];
            [pencilPath4 stroke];

            //// Group 3
            [strokeColor setStroke];
            [pencilPath5 stroke];
            [strokeColor setStroke];
            [pencilPath6 stroke];
            [strokeColor setStroke];
            [pencilPath7 stroke];
            [strokeColor setStroke];
            [pencilPath8 stroke];
            [strokeColor setStroke];
            [pencilPath9 stroke];
            [strokeColor setStroke];
            [pencilPath10 stroke];
            [strokeColor setStroke];
            [pencilPath11 stroke];

            [shading setFill];
            [pencilPath12 fill];

            // Smile
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [pencilPath13 fill];
            [strokeColor setFill];
            [pencilPath14 fill];
            [strokeColor setFill];
            [pencilPath15 fill];
            //}
            break;
        }
        case CVSBrushTypeSpraypaint:
        {
            //// Color
            [activeColor setFill];
            [spraypaintPath1 fill];
            [activeColor setFill];
            [spraypaintPath2 fill];

            //// Gray
            [white setFill];
            [spraypaintPath3 fill];
            [white setFill];
            [spraypaintPath4 fill];
            [white setFill];
            [spraypaintPath5 fill];
            [gray setFill];
            [spraypaintPath6 fill];
            [white setFill];
            [spraypaintPath7 fill];
            [gray setFill];
            [spraypaintPath8 fill];

            //// Outlines
            [strokeColor setStroke];
            [spraypaintPath9 stroke];
            [strokeColor setStroke];
            [spraypaintPath10 stroke];
            [strokeColor setStroke];
            [spraypaintPath11 stroke];
            [strokeColor setStroke];
            [spraypaintPath12 stroke];
            [strokeColor setStroke];
            [spraypaintPath13 stroke];
            [strokeColor setStroke];
            [spraypaintPath14 stroke];
            [strokeColor setStroke];
            [spraypaintPath15 stroke];
            [strokeColor setStroke];
            [spraypaintPath16 stroke];

            //// Shading
            [shading setFill];
            [spraypaintPath17 fill];

            //// Smile
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [spraypaintPath18 fill];
            [strokeColor setFill];
            [spraypaintPath19 fill];
            [strokeColor setFill];
            [spraypaintPath20 fill];
            //}

            break;
        }
        case CVSBrushTypeCrayon:
        {
            //// white
            [white setFill];
            [crayonPath1 fill];
            [white setFill];
            [crayonPath2 fill];

            //// color
            [activeColor setFill];
            [crayonPath3 fill];
            [activeColor setFill];
            [crayonPath4 fill];
            [activeColor setStroke];
            [crayonPath4 stroke];
            [activeColor setFill];
            [crayonPath5 fill];
            [activeColor setStroke];
            [crayonPath5 stroke];
            [activeColor setFill];
            [crayonPath6 fill];

            //// outline
            [strokeColor setStroke];
            [crayonPath7 stroke];
            [strokeColor setStroke];
            [crayonPath8 stroke];
            [strokeColor setStroke];
            [crayonPath9 stroke];
            [strokeColor setStroke];
            [crayonPath10 stroke];
            [strokeColor setStroke];
            [crayonPath11 stroke];
            [strokeColor setStroke];
            [crayonPath12 stroke];

            //// Shading
            [shading setFill];
            [crayonPath13 fill];

            //// Face
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [crayonPath14 fill];
            [strokeColor setFill];
            [crayonPath15 fill];
            [strokeColor setFill];
            [crayonPath16 fill];
            //}

            break;
        }
        case CVSBrushTypePaintbucket:
        {
            //// Paintbucket_1_
            [white setFill];
            [paintbucketPath1 fill];
            [activeColor setFill];
            [paintbucketPath2 fill];
            [white setFill];
            [paintbucketPath3 fill];
            [strokeColor setStroke];
            [paintbucketPath4 stroke];
            [strokeColor setStroke];
            [paintbucketPath5 stroke];
            [strokeColor setStroke];
            [paintbucketPath6 stroke];
            [shading setFill];
            [paintbucketPath7 fill];

            //// Opening
            [activeColor setFill];
            [paintbucketPath8 fill];
            [white setFill];
            [paintbucketPath9 fill];
            [strokeColor setStroke];
            [paintbucketPath10 stroke];
            [strokeColor setStroke];
            [paintbucketPath11 stroke];

            //// Handle
            [strokeColor setStroke];
            [paintbucketPath12 stroke];
            [activeColor setFill];
            [paintbucketPath13 fill];
            [strokeColor setStroke];
            [paintbucketPath14 stroke];

            //// Face
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [paintbucketPath15 fill];
            [strokeColor setFill];
            [paintbucketPath16 fill];
            [strokeColor setFill];
            [paintbucketPath17 fill];
            //}


            break;
        }
        case CVSBrushTypeEraser:
        {
            //// colour_2_
            [activeColor setFill];
            [eraserPath1 fill];

            //// outline_2_
            [strokeColor setStroke];
            [eraserPath2 stroke];
            [strokeColor setStroke];
            [eraserPath3 stroke];

            // shading
            [shading setFill];
            [eraserPath4 fill];

            // Smile
            //if (self.hasSmile)
            //{
            [strokeColor setFill];
            [eraserPath5 fill];
            [strokeColor setFill];
            [eraserPath6 fill];
            [strokeColor setFill];
            [eraserPath7 fill];
            //}
            break;
        }
        default:
            break;
    }
    CGContextRestoreGState(context);
}

@end
