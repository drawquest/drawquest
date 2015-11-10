//
//  CVSGeometry.m
//  Editor
//
//  Created by Phillip Bowden on 9/17/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSGeometry.h"

CGPoint CVSPolarCoordinate(CGFloat theta, CGFloat radius)
{
    return CGPointMake(cosf(theta) * radius, sinf(theta) * radius);
}

CGFloat CVSLineDistance(CGPoint p1, CGPoint p2)
{
    CGFloat xDistance = p2.x - p1.x;
    CGFloat yDistance = p2.y - p1.y;
    return sqrt((xDistance * xDistance) + (yDistance * yDistance));
}
