//
//  CVSEditorView.m
//  Editor
//
//  Created by Phillip Bowden on 8/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSEditorView.h"

#import <QuartzCore/QuartzCore.h>

#import "CVSCacheView.h"
#import "CVSDrawingTypes.h"
#import "CVSErasingView.h"
#import "CVSStrokeGenerator.h"
#import "CVSStrokeView.h"
#import "CVSEditorViewRenderOptions.h"
#import "CVSStrokeArray.h"
#import "CVSStroke.h"
#import "CVSDrawingModel.h"
#import "CVSDMEditorBitmapStore.h"

/*
 Notes:
 - this is a bit of a mess, which represents multiple execution modes. we haven't really committed to transitioning to snapshotting or whether live strokes will be reduced to 0...1
 - see the playback view graph for how hierarchy and rendering could be represented more cleanly, using fewer views.
 - @todo this source will need a lot of cleanup once we commit to snapshotting. there is a bunch of code which would be dead once strokes are pushed to the cache view as soon as possible.
 */

//static const CVSMultipleStrokeRenderComplexity kCVSEditorViewEstimatedRenderComplexityThreshold = UINT8_MAX / 3U;
static const CVSMultipleStrokeRenderComplexity kCVSEditorViewEstimatedRenderComplexityThreshold = 2; // << 2 is an internal magic minimum. just push this work to the snapshotting and undo/redo.

/**
 @brief tracks the active editor state
 */
typedef NS_ENUM(uint8_t, CVSEditorViewEditMode) {
    /** @constant used for coloring/painting to the canvas */
    CVSEditorViewEditModeColor = 0,
    /** @constant used for erasing the canvas */
    CVSEditorViewEditModeErase
};

@interface CVSEditorView()

@property (strong, nonatomic) UIImageView *backgroundView;
@property (strong, nonatomic) CVSCacheView *cacheView;
@property (strong, nonatomic) CVSStrokeView *strokeView;
@property (strong, nonatomic) CVSErasingView *erasingView;
@property (strong, nonatomic) CVSDMEditorBitmapStore * editorBitmapStore;

@property (nonatomic, getter = isHidingInterface) BOOL hidingInterface;

@property (nonatomic, getter = isProcessingFirstPoint) BOOL processingFirstPoint;

@property (nonatomic, assign, readwrite) CVSEditorViewEditMode currentEditMode;
@property (strong, nonatomic, readwrite) id<CVSStrokeRecorder> strokeRecorder;

@property (nonatomic, assign) NSUInteger cacheRebuildWeightAccumulator;

@end

@implementation CVSEditorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInitForCVSEditorView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitForCVSEditorView];
    }
    return self;
}

- (void)commonInitForCVSEditorView
{
    _currentEditMode = CVSEditorViewEditModeColor;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];

    self.exclusiveTouch = YES;
    [self resetCacheRebuildWeightAccumulator];
    // JC: not a terrible problem -- would need a little work at present to swap out the bitmap store while the view graph has been constructed.
    assert(nil == _backgroundView);
    _backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    _backgroundView.image = [UIImage imageNamed:@"quest_with_no_template_image"];
}

- (void)setEditorBitmapStore:(CVSDMEditorBitmapStore *)pEditorBitmapStore imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
{
    assert(pEditorBitmapStore);
    assert(pImageSnapshotQueue);
    assert(nil == _editorBitmapStore && "one-time initialization is the the only supported initialization model at present");
    _editorBitmapStore = pEditorBitmapStore;
// JR: moved _backgroundView initialization out of this spot
    CVSDMEditorBitmapStoreReference * bitmapStoreReference = [self.editorBitmapStore createBitmapStoreReference:CVSEditorBitmapStoreIdentifier_CacheView];
    assert(bitmapStoreReference);
    _cacheView = [[CVSCacheView alloc] initWithFrame:self.bounds bitmapStoreReference:bitmapStoreReference imageSnapshotQueue:pImageSnapshotQueue enableSnapshotting:YES];
    self.cacheView.editorViewDelegate = self.delegate;
    _strokeView = [[CVSStrokeView alloc] initWithFrame:self.bounds];

    [self insertSubview:_backgroundView atIndex:0];
    [self insertSubview:_cacheView atIndex:1];
    [self insertSubview:_strokeView atIndex:2];
}

#pragma mark - Cache Rebuild Weight Accumulator

- (void)addCacheRebuildWeightAccumulator:(NSUInteger)pValue
{
    _cacheRebuildWeightAccumulator += pValue;
    const NSUInteger Limit = 2000;
    if (Limit > self.cacheRebuildWeightAccumulator) {
        return;
    }
    [self resetCacheRebuildWeightAccumulator];
    [self.cacheView rebuildSnapshotCache];
}

- (void)resetCacheRebuildWeightAccumulator
{
    self.cacheRebuildWeightAccumulator = 0;
}

- (void)addCacheRebuildWeightAccumulator_StrokeAdded
{
    const NSUInteger Weight = 1;
    [self addCacheRebuildWeightAccumulator:Weight];
}

- (void)addCacheRebuildWeightAccumulator_UndoPerformed
{
    const NSUInteger Weight = 20;
    [self addCacheRebuildWeightAccumulator:Weight];
}

#pragma mark - Erasing View (dynamic availability)

- (CVSErasingView *)erasingView
{
    assert(_erasingView);
    return _erasingView;
}

static const NSUInteger SubviewPositionForEraserView = 3;
- (void)displayErasingViewWithCurrentContentImage
{
    @autoreleasepool {
        assert(nil == _erasingView && "did not dispose previous erasing view");
        [self transferActiveColorStrokesToCacheView:YES];
        CVSDMEditorBitmapStoreReference * bitmapStoreReference = [self.editorBitmapStore createBitmapStoreReference:CVSEditorBitmapStoreIdentifier_CacheView];
        assert(bitmapStoreReference);
        _erasingView = [[CVSErasingView alloc] initWithFrame:self.bounds bitmapStoreReference:bitmapStoreReference];
        [self insertSubview:_erasingView atIndex:SubviewPositionForEraserView];
    }
}

- (void)disposeErasingView
{
    @autoreleasepool {
        assert(_erasingView);
        [_erasingView removeFromSuperview];
        _erasingView = nil;
    }
}

#pragma mark - Editor Subview Support

- (void)drawingDidFinishLoading
{
	_backgroundView.layer.shouldRasterize = [CVSEditorViewRenderOptions useSelectiveRasterization];
    self.layer.drawsAsynchronously = [CVSEditorViewRenderOptions drawsAsynchronously];
    [self transferActiveStrokesToCacheView:NO];
    [self.cacheView drawingDidFinishLoading];
    [self.strokeView drawingDidFinishLoading];
    // priming attempt -- to avoid initial stroke delay
    [self setNeedsDisplay];
}

- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale
{
    // JC: we probably don't need rasterization anymore
    [self.cacheView synchronizeContentZoomScale:pZoomScale];
    [self.strokeView synchronizeContentZoomScale:pZoomScale];
    if (CVSEditorViewEditModeErase == self.currentEditMode) {
        [self.erasingView synchronizeContentZoomScale:pZoomScale];
    }
}

- (void)disposeActiveStroke
{
    if (self.isHidingInterface && !self.isInterfaceHiddenManually) {
        [self showInterface];
    }
    
    if (CVSEditorViewEditModeColor == self.currentEditMode) {
        [self.strokeView disposeActiveStroke];
    }
    else {
        [self.erasingView disposeActiveStroke];
    }
}

#pragma mark -

- (UIImage *)imageRepresentation
{
    UIImage *image = nil;

    // consider making this an async operation. this could take some time to complete
    [self transferActiveStrokesToCacheView:YES];

    const CGFloat DeviceScale = 0.0f;
    const CGRect bounds = self.bounds;

    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, DeviceScale);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, [CVSEditorViewRenderOptions interpolationQualityForDrawnImages]);

    CGImageRef templateImage = self.backgroundView.image.CGImage ?: [UIImage imageNamed:@"quest_with_no_template_image"].CGImage;
    assert(templateImage);

    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextTranslateCTM(context, 0.0f, -bounds.size.height);
    CGContextDrawImage(context, bounds, templateImage);
    CGContextTranslateCTM(context, 0.0f, bounds.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);

    [self.cacheView drawImageInRect:bounds context:context];

    // don't need to render the tracking view (stroke/eraser) because strokes are pushed back to the cache immediately
    // note that this behavior relies on the fact that cached strokes are immediately pushed to the cache. this behavior
    // could still be re-enabled in the editor view hierarchy implementation because there are some remains of the
    // previous form. @todo remains of the previous form should be deleted.

    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void)clear
{
    [self.cacheView clearAllStrokesAndEraseView];
    if (CVSEditorViewEditModeColor == self.currentEditMode) {
        if (self.strokeView.hasStrokes) {
            [self.strokeView dequeueAllStrokesAndEraseView];
        }
    }
    else {
        [self endErasingMode];
    }
    [self resetCacheRebuildWeightAccumulator];
}

// NEVER CALL THIS
- (void)clearTemplateImage
{
    self.backgroundView.image = nil;
}

#pragma mark - Accessors

- (void)setTemplateImage:(UIImage *)templateImage
{
    self.backgroundView.image = templateImage ?: [UIImage imageNamed:@"quest_with_no_template_image"];
}

- (void)setDelegate:(id<CVSEditorViewDelegate>)pDelegate
{
    _delegate = pDelegate;
    self.cacheView.editorViewDelegate = pDelegate;
}

#pragma mark -
#pragma mark CVSBackedRenderer

- (void)rendererShouldRenderStrokeComponent:(CVSStrokeComponent *)inComponent strokeGenerator:(CVSStrokeGenerator *)pStrokeGenerator
{
    assert(pStrokeGenerator);
    const CVSBrushType brushType = pStrokeGenerator.brushType;
    if (brushType == CVSBrushTypeEraser) {
        if (CVSEditorViewEditModeErase != self.currentEditMode) {
            [self beginErasingMode];
        }

        [self.erasingView drawComponent:inComponent];

    } else {
        if (CVSEditorViewEditModeErase == self.currentEditMode) {
            [self endErasingMode];
        }

        UIColor * const strokeColor = pStrokeGenerator.strokeColor;
        [self.strokeView drawComponent:inComponent brushType:brushType strokeColor:strokeColor];
    }
}

- (void)transferActiveEraserStrokesToCacheView
{
    assert(CVSEditorViewEditModeErase == self.currentEditMode);
    CVSStrokeArray * strokes = self.erasingView.dequeueAllStrokes;
    if (strokes.count) {
        [self sendStrokesToCacheView:strokes];
    }
}

- (void)transferActiveColorStrokesToCacheView:(BOOL)pTransferAll
{
    if (!self.strokeView.hasStrokes) {
        return;
    }
    if (pTransferAll) {
        [self sendStrokesToCacheView:self.strokeView.dequeueAllStrokesAndEraseView];
        return;
    }
    if ([self.strokeView isMultipleStrokeRenderComplexityBelow:kCVSEditorViewEstimatedRenderComplexityThreshold]) {
        return;
    }
    CVSStrokeArray * strokes = [self.strokeView dequeueStrokesToFitBelowRenderComplexityThreshold:kCVSEditorViewEstimatedRenderComplexityThreshold/2U];
    [self sendStrokesToCacheView:strokes];
}

- (void)transferActiveStrokesToCacheView:(BOOL)pTransferAll
{
    if (CVSEditorViewEditModeErase == self.currentEditMode) {
        // in this case, the eraser strokes are all transferred
        [self transferActiveEraserStrokesToCacheView];
    }
    else {
        [self transferActiveColorStrokesToCacheView:pTransferAll];
    }
}

- (void)maintainEditorCacheBalance
{
    // TransferAllAlways is a snapshot trial
    const bool TransferAllAlways = true;
    if (TransferAllAlways) {
        [self transferActiveStrokesToCacheView:YES];
    }
    else {
        [self transferActiveStrokesToCacheView:NO];
    }
}

- (void)rendererShouldFinishRenderingStroke:(CVSStroke *)pStroke strokeGenerator:(CVSStrokeGenerator *)pStrokeGenerator
{
    assert(pStroke);
    assert(pStrokeGenerator);
    if (CVSEditorViewEditModeErase == self.currentEditMode) {
        [self.erasingView finishRenderingStroke:pStroke];
    } else {
        [self.strokeView finishRenderingStroke:pStroke];
    }
    [self maintainEditorCacheBalance];
}

- (void)sendStrokesToCacheView:(CVSStrokeArray *)pStrokes
{
    assert(pStrokes.count);
    // true for snapshotting
    const bool OneAtATime = true;
    if (OneAtATime) {
        for (CVSStroke * at in pStrokes) {
            [self addCacheRebuildWeightAccumulator_StrokeAdded];
            [self.cacheView enqueueAndRenderStrokes:[CVSStrokeArray newStrokeArrayWithStroke:at]];
        }
    }
    else {
        [self.cacheView enqueueAndRenderStrokes:pStrokes];
    }
}

- (void)rendererShouldUndoStrokes:(CVSStrokeArray *)strokes
{
    if (!strokes.count) {
        assert(0 && "invalid parameter");
        return;
    }

    const CVSEditorViewEditMode mode = self.currentEditMode;
    bool restoreErasingView = false;
    // knee jerk? input should be one
    while (strokes.count) {
        CVSStroke * at = strokes.dequeueLastStroke;
        if ([self.strokeView containsStroke:at]) {
            // If stroke is in the stroke view, remove it.
            [self.strokeView removeStroke:at];
        }
        else if (CVSEditorViewEditModeErase == mode && [self.erasingView containsStroke:at]) {
            // If stroke is in the erasing view, remove it.
            [self.erasingView removeStroke:at];
        }
        else {
            if (CVSEditorViewEditModeErase == mode) {
                // need to pop the erase view so it does not obscure the changes
                [self endErasingMode];
                restoreErasingView = true;
            }
            [self transferActiveStrokesToCacheView:YES];
            [self addCacheRebuildWeightAccumulator_UndoPerformed];
            CVSStroke * dequeuedStroke = self.cacheView.dequeueTopStroke;
            assert(dequeuedStroke == at);
            // a dequeue is all that is needed
        }
    }
    [self maintainEditorCacheBalance];
    if (restoreErasingView) {
        [self beginErasingMode];
    }
}

// there's so much commonality between the two edit views, but this source just does not handle things right anymore.
// i'm working to make the two views more consistent, then they can just be swapped and share the same interface.
// so the current design is to have two very distinct view types. ideally, there would be little/no distinction, and
// potentially no need to use separate types.
// UPDATE: not present when strokes are immediately pushed to the cache, as they are now. #warning @todo JC: so there is a rendering bug when switching editors, and erasing gets off.
- (void)rendererShouldRedoStroke:(CVSStroke *)stroke
{
    assert(stroke);
    bool restoreErasingView = false;
    const bool isEraserStroke = CVSBrushTypeEraser == stroke.brushType;
    switch (self.currentEditMode) {
        case CVSEditorViewEditModeColor :
            if (isEraserStroke) {
                CVSStrokeArray * strokeArray = [CVSStrokeArray newStrokeArrayWithStroke:stroke];
                [self transferActiveColorStrokesToCacheView:YES];
                [self sendStrokesToCacheView:strokeArray];
            }
            else {
                [self.strokeView addStroke:stroke];
            }
            break;
        case CVSEditorViewEditModeErase :
            if (isEraserStroke) {
                [self.erasingView addStroke:stroke];
            }
            else {
                [self endErasingMode];
                restoreErasingView = true;
                [self sendStrokesToCacheView:[CVSStrokeArray newStrokeArrayWithStroke:stroke]];
            }
            break;
    }
    [self maintainEditorCacheBalance];
    if (restoreErasingView) {
        [self beginErasingMode];
    }
}

- (void)rendererShouldRedoStrokes:(CVSStrokeArray *)strokes
{
    if (!strokes.count) {
        assert(0 && "invalid parameter");
        return;
    }
    for (CVSStroke * at in strokes) {
        [self rendererShouldRedoStroke:at];
    }
}

#pragma mark - Editor State

- (void)beginErasingMode
{
    [self transferActiveStrokesToCacheView:YES];
    [self displayErasingViewWithCurrentContentImage];
    self.currentEditMode = CVSEditorViewEditModeErase;

    self.cacheView.hidden = YES;
    self.strokeView.hidden = YES;
}

- (void)endErasingMode
{
    // Finished erasing, move erase strokes into cache, re-render the cache, clear the erasing view
    [self transferActiveEraserStrokesToCacheView];
    [self disposeErasingView];
    self.currentEditMode = CVSEditorViewEditModeColor;

    self.cacheView.hidden = NO;
    self.strokeView.hidden = NO;
}

- (void)hideInterfaceIfPointIsBeyondThreshold:(CGPoint)point
{
    if ([self.delegate isPointBeyondThreshold:point])
    {
        self.hidingInterface = YES;
        [self.delegate hideInterfaceForEditorView:self];
    }
}

- (void)showInterface
{
    self.hidingInterface = NO;
    [self.delegate showInterfaceForEditorView:self];
}

#pragma mark -
#pragma mark UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
#pragma unused(event)
    [self disposeActiveStroke];
    UITouch *touch = [touches anyObject];

    CGPoint touchPoint = [touch locationInView:self];

    [self hideInterfaceIfPointIsBeyondThreshold:touchPoint];
    self.processingFirstPoint = YES;

    [self.strokeRecorder startStrokeWithTouch:touch];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
#pragma unused(event)
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    [self hideInterfaceIfPointIsBeyondThreshold:touchPoint];

    if (self.isProcessingFirstPoint) {
        self.processingFirstPoint = NO;
    } else {
        [self.strokeRecorder addPointWithTouch:touch];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
#pragma unused(touches)
#pragma unused(event)
    // NSLog(@"touches ended: %@ | %@", touches, event);
    if (self.isHidingInterface && !self.isInterfaceHiddenManually) {
        [self showInterface];
    }

    if (self.isProcessingFirstPoint) {
        [self.strokeRecorder endStrokeForSinglePoint];
    } else {
        [self.strokeRecorder endStroke];
    }
    if (CVSEditorViewEditModeColor == self.currentEditMode) {
        // maintain the stroke/cache balance -- erase not supported at the moment
        [self transferActiveColorStrokesToCacheView:NO];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
#pragma unused(touches)
#pragma unused(event)
    self.processingFirstPoint = NO;
}

@end
