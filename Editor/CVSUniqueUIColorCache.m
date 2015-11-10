//
//  CVSUniqueUIColorCache.m
//  DrawQuest
//
//  Created by Justin Carlson on 10/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVSUniqueUIColorCache.h"
#import "UIColor+DQAdditions.h"

@implementation CVSUniqueUIColorCache

+ (NSArray *)defaultEditorColors
{
    static dispatch_once_t init;
    static NSArray * s_Colors = nil;
    dispatch_once(&init, ^{
        s_Colors = @[[UIColor dq_colorWithRed:74 green:74 blue:74],
                     [UIColor dq_colorWithRed:233 green:90 blue:92],
                     [UIColor dq_colorWithRed:248 green:172 blue:85],
                     [UIColor dq_colorWithRed:255 green:228 blue:92],
                     [UIColor dq_colorWithRed:108 green:214 blue:116],
                     [UIColor dq_colorWithRed:36 green:113 blue:247],
                     [UIColor dq_colorWithRed:134 green:213 blue:255],
                     [UIColor dq_colorWithRed:124 green:130 blue:255],
                     [UIColor dq_colorWithRed:156 green:103 blue:95],
                     [UIColor dq_colorWithRed:255 green:228 blue:177],
                     [UIColor dq_colorWithRed:255 green:255 blue:255],
                     [UIColor dq_colorWithRed:184 green:182 blue:181]];
    });
    return s_Colors;
}

- (instancetype)init
{
    return [self initWithColors:@[]];
}

- (instancetype)initWithColors:(id<NSFastEnumeration>)pColors
{
    self = [super initWithObjectType:[UIColor class] objectInsertionPolicy:CVSUniqueObjectCacheObjectInsertionPolicyCopy objects:pColors];
    if (self == nil) {
        return nil;
    }
    return self;
}

+ (instancetype)uniqueUIColorCacheWithDefaultEditorColors
{
    return [[[self class] alloc] initWithColors:[[self class] defaultEditorColors]];
}

- (UIColor *)uniqueUIColor:(UIColor *)pColor
{
    return [self uniqueObject:pColor];
}

@end
