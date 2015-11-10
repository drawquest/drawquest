//
//  CVSUniqueUIColorCache.h
//  DrawQuest
//
//  Created by Justin Carlson on 10/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CVSUniqueObjectCache.h"

@class UIColor;

/**
 @class a collection of unique UIColors
 */
@interface CVSUniqueUIColorCache : CVSUniqueObjectCache <NSCopying>

- (instancetype)init;
- (instancetype)initWithColors:(id<NSFastEnumeration>)pColors;

/** @return an array containing the default editor colors (array is static/cached) */
+ (NSArray *)defaultEditorColors;

/** @return an instance initialized with the default editor colors */
+ (instancetype)uniqueUIColorCacheWithDefaultEditorColors;

/** @return the unique color instance, adding it if necessary */
- (UIColor *)uniqueUIColor:(UIColor *)pColor;

@end
