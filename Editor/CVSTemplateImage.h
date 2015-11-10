// CVSTemplateImage.h
// DrawQuest
// Created by Justin Carlson on 11/3/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <Foundation/Foundation.h>

/**
 @class represents a template image
 */
@interface CVSTemplateImage : NSObject

// designated initializer
- (instancetype)initWithUIImage:(UIImage *)pImage;
+ (instancetype)templateImageWithUIImage:(UIImage *)pImage;

/**
 @return a new template image which references the empty template image asset -- an opaque white 1024x768 image.
 */
+ (instancetype)templateImageWithEmptyTemplateImage;

/**
 @return the image self represents.
 */
- (UIImage *)image;
- (CGImageRef)CGImage NS_RETURNS_INNER_POINTER;

/**
 @return true if the image is opaue.
 @details this property is determined at initialization.
 */
- (BOOL)isOpaque;

@end
