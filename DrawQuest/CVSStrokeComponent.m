//
//  CVSStrokeComponent.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "CVSStrokeComponent.h"

static bool IsFPComponent(const char p) {
    return '-' == p || '.' == p || isnumber(p);
}

// 'handmade' replacement (beware) for CGPointFromString. Because these members below are strings
// and not values, we end up creating a ton of temporary strings using CGPointFromString.
static CGPoint CVSMakeCGPointFromNSString(NSString * const pString) {
    // reference implementation:
    // return CGPointFromString(pString);

    if (nil == pString) {
        return CGPointZero;
    }
    const size_t length = pString.length;
    enum { BufferSize = 64 };

    if (!length) {
        return CGPointZero;
    }
    if (length > BufferSize) {
        assert(0 && "was not expecting a point to be this long");
        return CGPointZero;
    }

    unichar unichars[BufferSize] = {0};
    [pString getCharacters:unichars range:(NSRange){0, length}];
    char chars[BufferSize] = {0};
    for (size_t i = 0; i < BufferSize; ++i) {
        const unichar at = unichars[i];
        if (CHAR_MAX < at) {
            assert(0 && "weird point-string?");
            return CGPointZero;
        }
        assert(CHAR_MAX >= at);
        chars[i] = (char)at;
    }
    CGPoint result = CGPointZero;
    const char* at = chars;
    while (*at && false == IsFPComponent(*at)) {
        ++at;
    }
    if (!(*at)) return CGPointZero;
    char* outEnd = NULL;
    result.x = (CGFloat)strtod(at, &outEnd);
    at = outEnd;
    while (*at && false == IsFPComponent(*at)) {
        ++at;
    }
    if (!(*at)) return CGPointZero;
    result.y = (CGFloat)strtod(at, NULL);
    return result;
}

@implementation CVSStrokeComponent

@dynamic typeNumber;
@dynamic fromPointString;
@dynamic toPointString;
@dynamic controlPoint1String;
@dynamic controlPoint2String;
@dynamic stroke;

#pragma mark - Accessors

- (CVSStrokeComponentType)type
{
    return (CVSStrokeComponentType)[self.typeNumber intValue];
}

- (void)setType:(CVSStrokeComponentType)type
{
    self.typeNumber = @((int)type);
}

- (CGPoint)toPoint
{
    return CVSMakeCGPointFromNSString(self.toPointString);
}

- (void)setToPoint:(CGPoint)toPoint
{
    self.toPointString = NSStringFromCGPoint(toPoint);
}

- (CGPoint)fromPoint
{
    return CVSMakeCGPointFromNSString(self.fromPointString);
}

- (void)setFromPoint:(CGPoint)fromPoint
{
    self.fromPointString = NSStringFromCGPoint(fromPoint);
}

- (CGPoint)controlPoint1
{
    return CVSMakeCGPointFromNSString(self.controlPoint1String);
}

- (void)setControlPoint1:(CGPoint)controlPoint1
{
    self.controlPoint1String = NSStringFromCGPoint(controlPoint1);
}

- (CGPoint)controlPoint2
{
    return CVSMakeCGPointFromNSString(self.controlPoint2String);
}

- (void)setControlPoint2:(CGPoint)controlPoint2
{
    self.controlPoint2String = NSStringFromCGPoint(controlPoint2);
}

- (NSDictionary *)componentRepresentation
{
    if (self.type == CVSStrokeComponentTypeCurve){
        return @{
                 @"type" : self.typeNumber,
                 @"fromPoint" : self.fromPointString,
                 @"toPoint" : self.toPointString,
                 @"controlPoint1" : self.controlPoint1String,
                 @"controlPoint2" : self.controlPoint2String
                 };
    } else if (self.type == CVSStrokeComponentTypePoint) {
        return @{
                 @"type" : self.typeNumber,
                 @"fromPoint" : self.fromPointString,
                 @"toPoint" : self.toPointString,
                 };
    } else {
        return @{};
    }
}

@end
