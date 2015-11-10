//
//  UIBezierPath+CVSAdditions.m
//  Editor
//
//  Created by Phillip Bowden on 10/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "UIBezierPath+CVSAdditions.h"

#import "CVSStrokeComponent.h"

@implementation UIBezierPath (CVSAdditions)

- (void)cvs_addStrokeComponent:(CVSStrokeComponent *)component
{
    if(component.type == CVSStrokeComponentTypeCurve) {
        [self moveToPoint:component.fromPoint];
        [self addCurveToPoint:component.toPoint controlPoint1:component.controlPoint1 controlPoint2:component.controlPoint2];
    } else if (component.type == CVSStrokeComponentTypePoint) {
        [self moveToPoint:component.fromPoint];
        [self addLineToPoint:component.toPoint];
    }
}

@end
