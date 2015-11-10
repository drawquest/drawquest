// CVSDMBitmapDimensions.h
// CVSDrawingModel
// Created by J on 10/27/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief integral dimensions for a bitmap.
 */
typedef struct {
    uint32_t width;
    uint32_t height;
} CVSDMBitmapDimensions;

/**
 @return an initialized value using the parameters specified
 */
extern CVSDMBitmapDimensions CVSDMBitmapDimensionsMake(const uint32_t pWidth, const uint32_t pHeight);

/**
 @return true if the width and height are equal
 */
extern bool CVSDMBitmapDimensionsAreEqual(const CVSDMBitmapDimensions a, const CVSDMBitmapDimensions b);
