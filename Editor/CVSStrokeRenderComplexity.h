// CVSStrokeRenderComplexity.h
// DrawQuest
// Created by Justin Carlson on 10/21/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#ifndef DrawQuest_CVSStrokeRenderComplexity_h
#define DrawQuest_CVSStrokeRenderComplexity_h

/**
 @brief defines the render complexity of a single stroke. this is a value which is a linear distribution from [0...UINT8_MAX] which represents an estimation of complexity to render.
 */
typedef uint8_t CVSSingleStrokeRenderComplexity;

/**
 @brief defines the render complexity of multiple strokes -- i.e. the sum of multiple CVSSingleStrokeRenderComplexity values.
 */
typedef uint32_t CVSMultipleStrokeRenderComplexity;

#endif
