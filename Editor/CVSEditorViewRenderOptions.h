// CVSEditorViewRenderOptions.h
// DrawQuest
// Created by Justin Carlson on 10/13/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <Foundation/Foundation.h>

@interface CVSEditorViewRenderOptions : NSObject

/**
 @brief option enables/disables asynchronous drawing in the editor view
 */
+ (BOOL)drawsAsynchronously;

/**
 @brief option rasterizes some views in the editor view graph
 */
+ (BOOL)useSelectiveRasterization;

/**
 @return the default interpolation quality used when drawing images.
 */
+ (CGInterpolationQuality)interpolationQualityForDrawnImages;

@end
