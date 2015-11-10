// CVSDMBitmapDimensions.c
// CVSDrawingModel
// Created by J on 10/27/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#include <stdbool.h>
#include <stdint.h>
#include "CVSDMBitmapDimensions.h"

CVSDMBitmapDimensions CVSDMBitmapDimensionsMake(const uint32_t pWidth, const uint32_t pHeight) {
    return (CVSDMBitmapDimensions){pWidth, pHeight};
}

bool CVSDMBitmapDimensionsAreEqual(const CVSDMBitmapDimensions a, const CVSDMBitmapDimensions b) {
    return a.width == b.width && a.height == b.height;
}
