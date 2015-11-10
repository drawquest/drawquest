//
//  CVSStrokeRenderer.h
//  DrawQuest
//
//  Created by Justin Carlson on 10/14/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"

@class CVSStroke;
@class CVSStrokeArray;

/**
 @brief basic CVSStroke renderer abstraction
 */
@interface CVSStrokeRenderer : NSObject

/**
 @brief renders a single stroke into the context. the clipping path is passed so that a stroke may not be rendered unnecessarily.
 */
+ (void)renderStroke:(CVSStroke *)pStroke clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext useStrokesCGPath:(bool)pUseStrokesCGPath;

/**
 @brief renders multiple strokes into the context. the clipping path is passed so that a stroke may not be rendered unnecessarily. strokes are rendered in a forward direction, so the last stroke in the array will be "on top".
 */
+ (void)renderStrokes:(CVSStrokeArray *)pStrokes clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext;

/**
 @brief as -renderStrokes:clippingRect:context:, but allows you to use the stroke's CGPath to render. the default implementation will generally avoid using paths to reduce memory pressure.
 */
+ (void)renderStrokes:(CVSStrokeArray *)pStrokes clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext useStrokesCGPath:(bool)pUseStrokesCGPath;

/**
 @brief the blend mode for the specified brush type
 */
+ (CGBlendMode)blendModeForBrushType:(CVSBrushType)pBrushType;

@end
