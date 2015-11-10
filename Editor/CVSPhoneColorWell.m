//
//  CVSPhoneColorWell.m
//  DrawQuest
//
//  Created by David Mauro on 9/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPhoneColorWell.h"
#import "UIColor+DQAdditions.h"

@implementation CVSPhoneColorWell

- (id)initWithFrame:(CGRect)frame fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor forceOutline:(BOOL)forceOutline
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setOpaque:NO];
        _fillColor = fillColor;
        self.tintColor = _fillColor;
        _strokeColor = strokeColor;
        _forceOutline = forceOutline;
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    [self setNeedsDisplay];
}

- (BOOL)shouldDrawOutline
{
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    [self.fillColor getRed:&red green:&green blue:&blue alpha:nil];
    return (red + green + blue) >= 2.8;
}

- (void)setFillColor:(UIColor *)fillColor
{
    [super setTintColor:fillColor];
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

- (void)setForceOutline:(BOOL *)forceOutline
{
    _forceOutline = forceOutline;
    if ( ! [self shouldDrawOutline])
    {
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, 0.5f, 0.5f);
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:bounds];
    [self.tintColor setFill];
    [circle fill];
    if (self.forceOutline || [self shouldDrawOutline])
    {
        [self.strokeColor setStroke];
        circle.lineWidth = 1.0f;
        [circle stroke];
    }
    
    CGContextRestoreGState(context);
}

@end
