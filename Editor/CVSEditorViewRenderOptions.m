// CVSEditorViewRenderOptions.m
// DrawQuest
// Created by Justin Carlson on 10/13/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <CoreGraphics/CoreGraphics.h>
#import "CVSEditorViewRenderOptions.h"

@implementation CVSEditorViewRenderOptions

+ (BOOL)drawsAsynchronously
{
    // JC nov.1.2013: now that a few rounds of optimizations have been made
    //
    // it's now fast using both approaches. i've not yet evaluated the
    // iPhone 4, or another single core device. it may be slower in the
    // single core devices when async.
    //
    // without graphics obstructions, the iPhone 5 has no problem rendering
    // complex strokes at 60 FPS.
    //
    // tested with an iPhone 5 and snapshot based undo.
    return NO;
}

+ (BOOL)useSelectiveRasterization
{
    // JC nov.1.2013: now that a few rounds of optimizations have been made…
    //
    // selective rasterization can reduce render times for long strokes,
    // and decrease speeds for short strokes. seems the main reason for using
    // it today would be to make the iPhone 4 render times more predictable -
    // at a performance cost for short strokes. would have to test/verify
    // those results.
    //
    // ultimately, the views and blending should be simpler, so this would be
    // integrated into the editor stack.
    //
    // tested with an iPhone 5 and snapshot based undo.
    return NO;
}

+ (CGInterpolationQuality)interpolationQualityForDrawnImages
{
    return kCGInterpolationHigh;
}

@end
