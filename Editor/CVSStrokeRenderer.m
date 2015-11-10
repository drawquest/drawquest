//
//  CVSStrokeRenderer.m
//  DrawQuest
//
//  Created by Justin Carlson on 10/14/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVSStrokeRenderer.h"

#import "CVSStroke.h"
#import "CVSStrokeArray.h"
#import "CVSStrokeComponent.h"

#pragma mark - Rendering Options

// when enabled, this option uses the strokes' lazy-loaded CGPaths. when disabled, the implementation uses the context's path.
static const bool RenderOption_UseStrokesCGPath = false;

// if enabled and if RenderOption_UseStrokesCGPath is enabled, this option purges the stroke's path immediately after rendering.
// if RenderOption_UseStrokesCGPath is disabled, then the option has no effect because rendering will normally cause the path to
// load only when the path's bounding box has not been calculated.
static const bool RenderOption_PurgeStrokesCGPathImmediately = false;

// this is a diagnostic option to ensure rect invalidation and drawing is precise. it should not be enabled in normal circumstances.
static const bool RenderOption_UseStrictGeometry = false;


/*
 These options are the closest approximation to the original, which used UIBezierPath:
 - RenderOption_UseStrokesCGPath = true;
 - RenderOption_PurgeStrokesCGPathImmediately = false;

 These options were the fastest with async drawing enabled:
 Note: using the context's path was not much slower, and should probably be used instead because it consumes far less memory
 - RenderOption_UseStrokesCGPath = true;
 - RenderOption_PurgeStrokesCGPathImmediately = false;

 I'm keeping the options here for a little while, because rendering is still a work in progress.
 Ultimately:
 - merging should be removed
 - we should keep the render context component so that we can avoid unnecessary context updates
 Basically, that involves removing .hasOpenPath and the open/stroke/close actions related to it -- we can keep .activeStrokeColor and .activeBrush.
 */

#pragma mark - Rendering Functions/Variants

static bool RectIsEmpty(const CGRect pRect) {
    return (0 >= (pRect.size.width * pRect.size.height));
}

// this is a the state for rendering a stroke or set of strokes. may seem like overkill, but there are many variations to test.
struct CVSStrokeRendererContext {
    // invariants
    CGContextRef const context;
    const CGRect paintableSurface;
    const bool useStrokesCGPath;
    // fields which memo the active state of the CGContext between rendering of individual strokes
    CGColorRef activeStrokeColor;
    const CVSBrushAttributes* activeBrush;
    bool hasOpenPath;
};

// returns an initialized renderer context. use this to create the structure, rather than manual initializing it.
static struct CVSStrokeRendererContext CVSStrokeRendererContextInit(CGContextRef pContext, const CGRect pClippingRect, const CGRect pUnionOfStrokesBounds, const bool pUseStrokesCGPath) {
    assert(pContext);
    assert(!CGRectIsNull(pClippingRect));
    assert(!RectIsEmpty(pClippingRect));
    assert(!CGRectIsNull(pUnionOfStrokesBounds));
    // empty in this case is not accepted because stroke bounds calculation is expanded to accomodate brush width.
    assert(!CGRectIsEmpty(pUnionOfStrokesBounds));
    assert(CGRectIntersectsRect(pClippingRect, pUnionOfStrokesBounds));
    struct CVSStrokeRendererContext result = {
        .context = pContext,
        .paintableSurface = CGRectIntersection(pUnionOfStrokesBounds, CGRectIntersection(pClippingRect, CGContextGetClipBoundingBox(pContext))),
        .activeStrokeColor = NULL,
        .activeBrush = NULL,
        .useStrokesCGPath = pUseStrokesCGPath,
        .hasOpenPath = false
    };
    assert(!CGRectIsNull(result.paintableSurface));
    assert(!CGRectIsEmpty(result.paintableSurface));
    return result;
}

// returns the CGBlendMode for the CVSBrushType
static CGBlendMode BlendModeForBrushType(const CVSBrushType pBrushType) {
    return (pBrushType == CVSBrushTypeEraser) ? kCGBlendModeClear : kCGBlendModeNormal;
}

// configures the context's antialiasing settings for any renderer
static void ConfigAntialiasing(CGContextRef pContext) {
    // there's a measurable speedup when disabled, but it doesn't look good enough when disabled
    bool UseAntialiasedRendering = true;
    CGContextSetAllowsAntialiasing(pContext, UseAntialiasedRendering);
    CGContextSetShouldAntialias(pContext, UseAntialiasedRendering);
}

// configures the context's miter limit and flatness settings for any renderer
static void ConfigFlatnessAndMiterLimit(CGContextRef pContext) {
    // none of the brushes use miter - leave it. if one specifies it in the future, it would be better to make this a brush attribute.
    // CGContextSetMiterLimit(pContext, x);

    // note: UIBezierPath's default is 0.6 - which is more accurate than what we have here
    // assume: use the default for non-retina, and see if we can get away relaxing this on retina devices
    CGContextSetFlatness(pContext, 1.0);
}

// configures the context's interpolation settings for any renderer
static void ConfigInterpolation(CGContextRef pContext) {
    // lowering interpolation quality makes it faster (measurable)
    CGContextSetInterpolationQuality(pContext, kCGInterpolationDefault);
}

// updates the context for the specified brush attributes
static void ConfigBrushAttributes(CGContextRef pContext, const CVSBrushAttributes* const pBrushAttributes) {
    CGContextSetLineJoin(pContext, pBrushAttributes->lineJoin);
    CGContextSetLineCap(pContext, pBrushAttributes->lineCap);
    CGContextSetLineWidth(pContext, pBrushAttributes->lineWidth);
    const CGBlendMode blendMode = BlendModeForBrushType(pBrushAttributes->brushType);
    CGContextSetBlendMode(pContext, blendMode);
    CGContextSetAlpha(pContext, pBrushAttributes->alpha);
}

// returns true if the colors are equal. one day, the colors will all be properly deduplicated, and may just use a CLUT index.
static bool AreCGColorsEqual(CGColorRef pA, CGColorRef pB) {
    assert(pA);
    assert(pB);
    if (pA == pB) {
        return true;
    }
    return CGColorEqualToColor(pA, pB);
}

// call when a render will begin, before any stroke is rendered
static void CVSStrokeRendererContextBeginRender(struct CVSStrokeRendererContext* const pContext, CVSStrokeArray * const pStrokes) {
    assert(pStrokes.count);
    CGContextSaveGState(pContext->context);
    // JC: curious, clipping the intersection of the bounding box with the clipping rect results in drawing which is clipped more than it should be.
    // untested suspicion: maybe there is a bug in the bounding box expansion which does not accurately calculate the brush?

    const CGRect strokesBoundingBox = pStrokes.unionOfStrokesBounds;
    assert(CGRectIntersectsRect(strokesBoundingBox, pContext->paintableSurface));
    const CGRect intersection = CGRectIntersection(strokesBoundingBox, pContext->paintableSurface);
    CGContextClipToRect(pContext->context, intersection);
    ConfigAntialiasing(pContext->context);
    ConfigInterpolation(pContext->context);
    ConfigFlatnessAndMiterLimit(pContext->context);
}

// call when a render ends, after all strokes are rendered
static void CVSStrokeRendererContextEndRender(struct CVSStrokeRendererContext* const pContext) {
    assert(!pContext->hasOpenPath);
    CGContextRestoreGState(pContext->context);
}

// call before a stroke is rendered
static void CVSStrokeRendererContextWillRenderStroke(struct CVSStrokeRendererContext* const pContext, CVSStroke * const pStroke) {
    // update the stroke color
    CGColorRef color = pStroke.strokeColor.CGColor;
    assert(color);
    if (!pContext->activeStrokeColor || !AreCGColorsEqual(pContext->activeStrokeColor, color)) {
        CGContextSetStrokeColorWithColor(pContext->context, color);
        pContext->activeStrokeColor = color;
    }
    // update the brush attributes
    const CVSBrushAttributes* const brush = CVSBrushAttributesReferenceForBrushType(pStroke.brushType);
    assert(brush);
    if (pContext->activeBrush != brush) {
        ConfigBrushAttributes(pContext->context, brush);
        pContext->activeBrush = brush;
    }
}

// returns false if the stroke does not need to be rendered in this render invocation
static bool CVSStrokeRendererContextShouldRenderStroke(struct CVSStrokeRendererContext* const pContext, CVSStroke * const pStroke) {
    assert(pContext);
    assert(pStroke);
    const CGRect boundingBox = pStroke.bounds;
    if (CGRectIsEmpty(boundingBox)) {
        return false;
    }
    if (!CGRectIntersectsRect(boundingBox, pContext->paintableSurface)) {
        return false;
    }
    return true;
}

// RenderStroke_CGContext_ContextPath_* functions' individual component renderer, renders all components to the context's CGPath
static void RenderStroke_CGContext_ContextPath_RenderStrokesComponents(CGContextRef const pContext, CVSStroke * const pStroke) {
    for (CVSStrokeComponent * component in pStroke.components) {
        const CGPoint fromPoint = component.fromPoint;
        CGContextMoveToPoint(pContext, fromPoint.x, fromPoint.y);
        const CGPoint toPoint = component.toPoint;
        if (component.type == CVSStrokeComponentTypeCurve) {
            const CGPoint cp1 = component.controlPoint1;
            const CGPoint cp2 = component.controlPoint2;
            CGContextAddCurveToPoint(pContext, cp1.x, cp1.y, cp2.x, cp2.y, toPoint.x, toPoint.y);
        }
        else if (component.type == CVSStrokeComponentTypePoint) {
            CGContextAddLineToPoint(pContext, toPoint.x, toPoint.y);
        }
    }
}

// renders a stroke to the CGContext using the CGContext's internal CGPath - non-merging specialization
static void RenderStroke_CGContext_ContextPath_NonMerged(struct CVSStrokeRendererContext* const pRendererContext, CVSStroke * const pStroke) {
    CGContextRef gtx = pRendererContext->context;
    CVSStrokeRendererContextWillRenderStroke(pRendererContext, pStroke);
    CGContextBeginPath(gtx);
    RenderStroke_CGContext_ContextPath_RenderStrokesComponents(gtx, pStroke);
    CGContextStrokePath(gtx);
}

// renders a stroke to the CGContext using the CGContext's internal CGPath
static void RenderStroke_CGContext_ContextPath(struct CVSStrokeRendererContext* const pRendererContext, CVSStroke * const pStroke) {
    RenderStroke_CGContext_ContextPath_NonMerged(pRendererContext, pStroke);
}

// specialization of RenderStroke_CGContext_CGPath for non-merged drawing option
static void RenderStroke_CGContext_CGPath_NonMerged(struct CVSStrokeRendererContext* const pRendererContext, CVSStroke * const pStroke) {
    CGPathRef path = pStroke.path;
    assert(path);
    CGContextRef gtx = pRendererContext->context;
    CVSStrokeRendererContextWillRenderStroke(pRendererContext, pStroke);
    CGContextAddPath(gtx, path);
    CGContextStrokePath(gtx);
}

// renders a stroke to the CGContext using the CGPath created by the stroke
static void RenderStroke_CGContext_CGPath(struct CVSStrokeRendererContext* const pRendererContext, CVSStroke * const pStroke) {
    RenderStroke_CGContext_CGPath_NonMerged(pRendererContext, pStroke);
    if (RenderOption_PurgeStrokesCGPathImmediately) {
        [pStroke purgeCachedPath];
    }
}

// renders an individual stroke into the context, using the active render options
static void RenderStroke(struct CVSStrokeRendererContext* const pRendererContext, CVSStroke * const pStroke) {
    if (!CVSStrokeRendererContextShouldRenderStroke(pRendererContext, pStroke)) {
        return;
    }
    if (RenderOption_UseStrokesCGPath || pRendererContext->useStrokesCGPath) {
        RenderStroke_CGContext_CGPath(pRendererContext, pStroke);
    }
    else {
        RenderStroke_CGContext_ContextPath(pRendererContext, pStroke);
    }
}

@implementation CVSStrokeRenderer

+ (void)renderStroke:(CVSStroke *)pStroke clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext useStrokesCGPath:(bool)pUseStrokesCGPath
{
    struct CVSStrokeRendererContext rendererContext = CVSStrokeRendererContextInit(pContext, pClippingRect, pStroke.bounds, pUseStrokesCGPath);
    CVSStrokeRendererContextBeginRender(&rendererContext, [CVSStrokeArray newStrokeArrayWithStroke:pStroke]);
    RenderStroke(&rendererContext, pStroke);
    CVSStrokeRendererContextEndRender(&rendererContext);
}

+ (void)renderStrokesUsingStrictGeometry:(CVSStrokeArray *)pStrokes clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext useStrokesCGPath:(bool)pUseStrokesCGPath
{
    for (CVSStroke * at in pStrokes) {
        const CGRect bounds = at.bounds;
        assert(!CGRectIsNull(bounds));
        assert(!CGRectIsEmpty(bounds));
        if (CGRectIntersectsRect(bounds, pClippingRect)) {
            const CGRect intersection = CGRectIntersection(bounds, pClippingRect);
            [self renderStroke:at clippingRect:intersection context:pContext useStrokesCGPath:pUseStrokesCGPath];
        }
    }
}

+ (void)renderStrokes:(CVSStrokeArray *)pStrokes clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext
{
    [self renderStrokes:pStrokes clippingRect:pClippingRect context:pContext useStrokesCGPath:false];
}

+ (void)renderStrokes:(CVSStrokeArray *)pStrokes clippingRect:(CGRect)pClippingRect context:(CGContextRef)pContext useStrokesCGPath:(bool)pUseStrokesCGPath
{
    if (!pStrokes.count) {
        assert(0 && "invalid parameter");
        return;
    }
    if (RenderOption_UseStrictGeometry) {
        [self renderStrokesUsingStrictGeometry:pStrokes clippingRect:pClippingRect context:pContext useStrokesCGPath:pUseStrokesCGPath];
    }
    else {
        struct CVSStrokeRendererContext rendererContext = CVSStrokeRendererContextInit(pContext, pClippingRect, pStrokes.unionOfStrokesBounds, pUseStrokesCGPath);
        CVSStrokeRendererContextBeginRender(&rendererContext, pStrokes);
        for (CVSStroke * at in pStrokes) {
            RenderStroke(&rendererContext, at);
        }
        CVSStrokeRendererContextEndRender(&rendererContext);
    }
}

+ (CGBlendMode)blendModeForBrushType:(CVSBrushType)pBrushType
{
    return BlendModeForBrushType(pBrushType);
}

@end
