//
//  STDrawing.h
//
//  Created by Buzz Andersen on 5/17/11.
//  Copyright 2011 System of Touch. All rights reserved.
//

#import <UIKit/UIKit.h>

struct STRoundedCorners {
    CGFloat topLeft;
    CGFloat topRight;
    CGFloat bottomLeft;
    CGFloat bottomRight;
};
typedef struct STRoundedCorners STRoundedCorners;

extern const CGFloat STCornerRadiusAutomatic;
extern const STRoundedCorners STRoundedCornersZero;
extern const STRoundedCorners STRoundedCornersAutomatic;


void STContextDrawRect(CGContextRef context, CGRect rect, STRoundedCorners roundedCorners, CGColorRef *fillColors, NSUInteger fillColorCount, CGColorRef strokeColor, CGFloat strokeThickness);

void STContextAddRect(CGContextRef context, CGRect rect, STRoundedCorners roundedCorners, CGFloat inset, BOOL saveState);

void STContextFillRect(CGContextRef context, CGRect rect, CGColorRef *fillColors, NSUInteger fillColorCount);

CGGradientRef STCreateGradientWithColors(CGColorRef *colors, NSUInteger count, CGColorSpaceRef colorSpace);

CG_INLINE CGPoint STPointScale(CGFloat scale, CGPoint point)
{
    return CGPointMake(scale * point.x, scale * point.y);
}

CG_INLINE CGRect STRectExpand(CGRect rect, CGFloat dx, CGFloat dy)
{
    return CGRectMake(rect.origin.x - dx, rect.origin.y - dy, rect.size.width + dx + dx, rect.size.height + dy + dy);
}

CG_INLINE void STContextStrokePath(CGContextRef context, CGColorRef strokeColor, CGFloat strokeThickness)
{
    CGContextSetStrokeColorWithColor(context, strokeColor);
    CGContextSetLineWidth(context, strokeThickness);
    CGContextStrokePath(context);
}

CG_INLINE STRoundedCorners STRoundedCornersMake(CGFloat topLeft, CGFloat topRight, CGFloat bottomLeft, CGFloat bottomRight)
{
    STRoundedCorners corners;
    corners.topLeft = topLeft;
    corners.topRight = topRight;
    corners.bottomLeft = bottomLeft;
    corners.bottomRight = bottomRight;
    return corners;
}

CG_INLINE STRoundedCorners STRoundedCornersMakeWithRadius(CGFloat cornerRadius)
{
    return STRoundedCornersMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
}

CG_INLINE BOOL STRoundedCornersAreEqual(STRoundedCorners corners1, STRoundedCorners corners2)
{
    return (corners1.topLeft == corners2.topLeft) && (corners1.topRight == corners2.topRight) && (corners1.bottomLeft == corners2.bottomLeft) && (corners1.bottomRight == corners2.bottomRight); 
}
