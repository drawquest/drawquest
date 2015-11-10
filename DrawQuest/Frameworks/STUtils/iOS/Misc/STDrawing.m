//
//  STDrawing.m
//
//  Created by Buzz Andersen on 5/17/11.
//  Copyright 2011 System of Touch. All rights reserved.
//

#import "STDrawing.h"

const CGFloat STCornerRadiusAutomatic = CGFLOAT_MAX;
const STRoundedCorners STRoundedCornersZero = { 0.0f };
const STRoundedCorners STRoundedCornersAutomatic = { CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX };


extern const CGFloat STCornerRadiusAutomatic;

extern const STRoundedCorners STRoundedCornersZero;
extern const STRoundedCorners STRoundedCornersAutomatic;


void STContextDrawRect(CGContextRef context, CGRect rect, STRoundedCorners roundedCorners, CGColorRef *fillColors, NSUInteger fillColorCount, CGColorRef strokeColor, CGFloat strokeThickness)
{
    CGFloat inset = strokeThickness / 2.0f;
    
    if (fillColors) {
        CGContextSaveGState(context); {
            STContextAddRect(context, rect, roundedCorners, inset, YES);
            STContextFillRect(context, rect, fillColors, fillColorCount);
        }
        CGContextRestoreGState(context);
    }
    
    if (strokeColor) {
        CGContextSaveGState(context); {
            STContextAddRect(context, rect, roundedCorners, inset, YES);
            STContextStrokePath(context, strokeColor, strokeThickness);
        }
        CGContextRestoreGState(context);
    }
}

void STContextAddRect(CGContextRef context, CGRect rect, STRoundedCorners roundedCorners, CGFloat inset, BOOL saveState)
{
    if (saveState) {
        CGContextBeginPath(context);
        CGContextSaveGState(context);
    }
    
    if (STRoundedCornersAreEqual(roundedCorners, STRoundedCornersZero)) {
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        rect.origin.x = 0.0f;
        rect.origin.y = 0.0f;
        
        CGContextAddRect(context, rect);
    } else {
        // the half-point insetting prevents the jaggies
        rect = CGRectOffset(CGRectInset(rect, inset, inset), inset, inset);
        CGContextTranslateCTM(context, CGRectGetMinX(rect) - inset, CGRectGetMinY(rect) - inset);
        
        CGFloat width = CGRectGetWidth(rect);
        CGFloat height = CGRectGetHeight(rect);
        
        CGFloat automaticRadius = rect.size.height / 2.0f;
        
        if (roundedCorners.topLeft == STCornerRadiusAutomatic) {
            CGContextMoveToPoint(context, automaticRadius, 0.0f);
        } else if (roundedCorners.topLeft) {
            CGContextMoveToPoint(context, roundedCorners.topLeft, 0.0f);
        } else {
            CGContextMoveToPoint(context, 0.0f, 0.0f);
        }
        
        if (roundedCorners.topRight == STCornerRadiusAutomatic) {
            CGContextAddArcToPoint(context, width, 0.0f, width, height, automaticRadius);            
        } else if (roundedCorners.topRight) {
            CGContextAddArcToPoint(context, width, 0.0f, width, height, roundedCorners.topRight);
        } else {
            CGContextAddLineToPoint(context, width, 0.0f);
        }

        if (roundedCorners.bottomRight == STCornerRadiusAutomatic) {
            CGContextAddArcToPoint(context, width, height, 0.0f, height, automaticRadius);
        } else if (roundedCorners.bottomRight) {
            CGContextAddArcToPoint(context, width, height, 0.0f, height, roundedCorners.bottomRight);
        } else {
            CGContextAddLineToPoint(context, width, height);
        }
        
        if (roundedCorners.bottomLeft == STCornerRadiusAutomatic) {
            CGContextAddArcToPoint(context, 0.0f, height, 0.0f, 0.0f, automaticRadius);        
        } else if (roundedCorners.bottomLeft) {
            CGContextAddArcToPoint(context, 0.0f, height, 0.0f, 0.0f, roundedCorners.bottomLeft);
        } else {
            CGContextAddLineToPoint(context, 0.0f, height);
        }

        if (roundedCorners.topLeft == STCornerRadiusAutomatic) {
            CGContextAddArcToPoint(context, 0.0f, 0.0f, width, 0.0f, automaticRadius);            
        } else if (roundedCorners.topLeft) {
            CGContextAddArcToPoint(context, 0.0f, 0.0f, width, 0.0f, roundedCorners.topLeft);
        } else {
            CGContextAddLineToPoint(context, 0.0f, 0.0f);
        }
    }
    
    if (saveState) {
        CGContextClosePath(context);
        CGContextRestoreGState(context);
    }
}

void STContextFillRect(CGContextRef context, CGRect rect, CGColorRef *fillColors, NSUInteger fillColorCount)
{
    CGColorSpaceRef space = CGBitmapContextGetColorSpace(context);
    
    if (fillColorCount > 1) {
        CGContextClip(context);
        CGGradientRef gradient = STCreateGradientWithColors(fillColors, fillColorCount, space);
        CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0.0f, rect.size.height), kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    } else {
        CGContextSetFillColorWithColor(context, *fillColors);
        CGContextFillPath(context);
    }
}

CGGradientRef STCreateGradientWithColors(CGColorRef *colors, NSUInteger count, CGColorSpaceRef colorSpace)
{
    if (!colors) {
        return NULL;
    }
    
    size_t numberOfComponents = CGColorGetNumberOfComponents(*colors);
    CGFloat *components = (CGFloat *)malloc(sizeof(CGFloat) * numberOfComponents * count);
    CGFloat *locations = nil;
    
    for (NSUInteger index = 0; index < count; ++index) {
        CGColorRef color = colors[index];
        const CGFloat *colorComponents = CGColorGetComponents(color);
        
        if (numberOfComponents == 1) {
            // CGGradientCreateWithColorComponents requires an alpha value, so we hard-code it to 1.0
            components[index * 2] = colorComponents[0];
            components[index * 2 + 1] = 1.0f;
        } else if (numberOfComponents == 2) {
            components[index * 2] = colorComponents[0];
            components[index * 2 + 1] = colorComponents[1];
        } else if (numberOfComponents == 3) {
            // CGGradientCreateWithColorComponents requires an alpha value, so we hard-code it to 1.0
            components[index * 4] = colorComponents[0];
            components[index * 4 + 1] = colorComponents[1];
            components[index * 4 + 2] = colorComponents[2];
            components[index * 4 + 3] = 1.0f;
        } else if (numberOfComponents == 4) {
            components[index * 4] = colorComponents[0];
            components[index * 4 + 1] = colorComponents[1];
            components[index * 4 + 2] = colorComponents[2];
            components[index * 4 + 3] = colorComponents[3];
        }
    }
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, count);
    free(components);
    
    return gradient;
}