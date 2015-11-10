//
//  DQPlaybackView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/24/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQPlaybackView.h"

#import "UIBezierPath+CVSAdditions.h"

#import "CVSCacheView.h"
#import "CVSDrawingTypes.h"
#import "CVSDrawing.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "CVSStrokeArray.h"
#import "CVSDrawingModel.h"
#import "DQPlaybackStrokeView.h"
#import "CVSTemplateImage.h"

@interface DQPlaybackView () <UIScrollViewDelegate>

/*
 JC: so we are planning on some larger changes to the view graph. use of the cache view in this context is deceptive.
 Here's what's actually happening:
 - cacheView is created
 - cacheView is passed to stroke view
 - cacheView is NOT added to the view graph. it is just a render destination for completed strokes.
 - strokeView does all the rendering and invalidation. in its -drawRect: it asks the cache view to render the cache view's cached image into the current graphics context.

 Just documenting this because this may confuse somebody who reads this later. This approach is very similar to the way
 the live eraser view renders. So the intention is after DQ3 ships, we will continue to remove live views, rely more on
 bitmaps, and may use more layers rather than views. So this cache view would not even need to be a proper UIView. This
 could all be stuffed into the playback view -- if it were the final design. That would be cleaner, but the transition
 from views to bitmaps is not yet complete. The present expectation is that the migration would be completed shortly
 after DQ3 ships.
 */
@property (nonatomic, strong) CVSCacheView *cacheView;
@property (nonatomic, strong) DQPlaybackStrokeView *strokeView;
@property (nonatomic, strong) CVSDMEditorBitmapStore * bitmapStore;
@property (nonatomic, strong) CVSDMImageSnapshotQueue * imageSnapshotQueue;

@property (nonatomic, strong) UIScrollView * scrollView;

@end

@implementation DQPlaybackView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.strokeView;
}

- (id)initWithFrame:(CGRect)frame
{
    assert(0 && "invalid initializer");
}

- (id)initWithFrame:(CGRect)pFrame templateImage:(CVSTemplateImage *)pTemplateImage
{
    self = [super initWithFrame:pFrame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = [UIColor whiteColor];
    self.opaque = YES;
    self.clipsToBounds = YES;

    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:_scrollView];

    // const CGRect bounds = self.bounds;
    const CVSDMBitmapDimensions templateDimensions = CVSDMBitmapDimensionsMake(1024, 768);
    const bool isRetina = 1.9 < [[UIScreen mainScreen] scale];
    const uint32_t scale = isRetina ? 2 : 1;
    const CVSDMBitmapDimensions dimensions = CVSDMBitmapDimensionsMake(scale * templateDimensions.width, scale * templateDimensions.height);

    _bitmapStore = [[CVSDMEditorBitmapStore alloc] initWithBitmapDimensions:dimensions];
    _imageSnapshotQueue = [[CVSDMImageSnapshotQueue alloc] initWithFileSystemIOQueue:[CVSDMFileSystemIOQueue serialQueue] bitmapDimensions:dimensions];

    const CGRect contentFrame = CGRectMake(0.0, 0.0, templateDimensions.width, templateDimensions.height);
    _scrollView.contentSize = contentFrame.size;

    _cacheView = [[CVSCacheView alloc] initWithFrame:contentFrame bitmapStoreReference:[_bitmapStore createBitmapStoreReference:CVSEditorBitmapStoreIdentifier_CacheView] imageSnapshotQueue:self.imageSnapshotQueue enableSnapshotting:NO];
    // CVSCacheView is used here for its ability to render to a bitmap -- it is no longer part of the view graph
    // NO [self addSubview:_cacheView];
    [_cacheView drawingDidFinishLoading];

    _strokeView = [[DQPlaybackStrokeView alloc] initWithFrame:contentFrame templateImage:pTemplateImage cacheView:_cacheView];
    _strokeView.playbackView = self;
    [_scrollView addSubview:_strokeView];

    _scrollView.delegate = self;
    const CGFloat zoom = pFrame.size.width/templateDimensions.width;
    _scrollView.minimumZoomScale = zoom;
    _scrollView.maximumZoomScale = zoom;
    _scrollView.clipsToBounds = YES;

    [_scrollView zoomToRect:contentFrame animated:NO];

    return self;
}

#pragma mark - Accessors

- (void)setDrawing:(CVSDrawing *)drawing
{
    self.strokeView.drawing = drawing;
}

#pragma mark -

- (void)startPlayback
{
    [self.strokeView startPlayback];
}

- (void)pausePlayback
{
    [self.strokeView pausePlayback];
}

- (void)stopPlayback
{
    [self.strokeView stopPlayback];
}

- (void)clear
{
    [self.strokeView clearAllStrokesAndEraseView];
    [self.cacheView clearAllStrokesAndEraseView];
}

@end

