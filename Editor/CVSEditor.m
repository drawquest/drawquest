//
// CVSEditor.m
// DrawQuest
//
// Created by Justin Carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVSEditor.h"
#import "CVSStrokeManager.h"
#import "CVSStrokeGenerator.h"
#import "CVSDrawingModel.h"
#import "CVSDMEditorBitmapStore.h"

@interface CVSEditor () <CVSStrokeRecorder,CVSStrokeCountChangeObserver>

@property (nonatomic, strong, readwrite) CVSStrokeManager * strokeManager;
@property (nonatomic, strong, readwrite) CVSStrokeGenerator * strokeGenerator;

@property (nonatomic, strong, readwrite) CVSDMImageSnapshotQueue * imageSnapshotQueue;
@property (nonatomic, strong, readwrite) CVSDMEditorBitmapStore * editorBitmapStore;

@end

@implementation CVSEditor

- (void)initializeSnapshotQueue
{
    const CVSDMBitmapDimensions templateDimensions = CVSDMBitmapDimensionsMake(1024, 768);
    const bool isRetina = 1.9 < [[UIScreen mainScreen] scale];
    const uint32_t scale = isRetina ? 2 : 1;
    const CVSDMBitmapDimensions dimensions = CVSDMBitmapDimensionsMake(scale * templateDimensions.width, scale * templateDimensions.height);
    assert(nil == _imageSnapshotQueue);
    _imageSnapshotQueue = [[CVSDMImageSnapshotQueue alloc] initWithFileSystemIOQueue:[CVSDMFileSystemIOQueue serialQueue] bitmapDimensions:dimensions];
    assert(_imageSnapshotQueue);
}

- (id)initWithRootPath:(NSString *)pRootPath strokeManagerDelegate:(id<CVSStrokeManagerDelegate>)pStrokeManagerDelegate
{
    self = [super init];
    if (!self) {
        return nil;
    }
    @autoreleasepool {
        _strokeManager = [[CVSStrokeManager alloc] initWithRootPath:pRootPath delegate:pStrokeManagerDelegate];
        _strokeGenerator = [CVSStrokeGenerator new];
        [self initializeSnapshotQueue];
        assert(_imageSnapshotQueue);
        if (!_strokeManager || !_strokeGenerator || !_imageSnapshotQueue) {
            return nil;
        }
        _strokeGenerator.strokeManager = _strokeManager;
        _strokeGenerator.consumer = _strokeManager;
        _strokeManager.strokeCountChangeObserver = self;
    }
    return self;
}

- (void)load
{
    @autoreleasepool {
        [self.strokeManager load];
    }
}

- (void)updateEditorForBrushType:(CVSBrushType)pBrushType strokeGeneratorColor:(UIColor *)pStrokeGeneratorColor
{
    self.strokeGenerator.brushType = pBrushType;
    self.strokeGenerator.strokeColor = pStrokeGeneratorColor;
}

- (void)publishImageAndInvalidateStrokeManager:(UIImage *)pImage
{
    @autoreleasepool {
        [self.strokeManager publishWithImageRepresentation:pImage];
        self.strokeManager.renderer = nil;
        self.strokeManager.delegate = nil;
        self.strokeManager = nil;
    }
}

#pragma mark - Editor Bitmap Store

- (void)initializeEditorBitmapStore:(uint32_t)pWidth height:(uint32_t)pHeight
{
    assert(nil == self.editorBitmapStore);
    const CVSDMBitmapDimensions dimensions = CVSDMBitmapDimensionsMake(pWidth, pHeight);
    self.editorBitmapStore = [[CVSDMEditorBitmapStore alloc] initWithBitmapDimensions:dimensions];
    assert(self.editorBitmapStore);
    // the backing bitmap dimensions must be equal. initialization could be improved
    assert(CVSDMBitmapDimensionsAreEqual(self.imageSnapshotQueue.bitmapDimensions, self.editorBitmapStore.bitmapDimensions));
}

#pragma mark - Basic Wrapped Accessors

- (void)setRenderer:(id<CVSBackedRenderer>)pRenderer
{
    self.strokeManager.renderer = pRenderer;
}

- (void)setStrokeColor:(UIColor *)pStrokeColor
{
    [self.strokeGenerator setStrokeColor:pStrokeColor];
}

- (void)clearCurrentStrokes
{
    [self.strokeManager clearCurrentStrokes];
}

- (void)clearTemplateImage
{
    [self.strokeManager clearTemplateImage];
}

- (BOOL)undoAvailable
{
    return self.strokeManager.undoAvailable;
}

- (void)undoStroke
{
    [self.strokeManager undoStroke];
}

- (BOOL)redoAvailable
{
    return self.strokeManager.redoAvailable;
}

- (void)redoStroke
{
    [self.strokeManager redoStroke];
}

- (BOOL)strokeManagerHoldsRecordedStrokes
{
    return [self.strokeManager numberOfStrokes] > 0;
}

#pragma mark - <CVSStrokeRecorder>

- (id<CVSStrokeRecorder>)strokeRecorder
{
    return self;
}

- (void)startStrokeWithTouch:(UITouch *)pTouch
{
    [self.strokeGenerator startStrokeWithTouch:pTouch];
}

- (void)addPointWithTouch:(UITouch *)pTouch
{
    [self.strokeGenerator addPointWithTouch:pTouch];
}

- (void)endStroke
{
    [self.strokeGenerator endStroke];
}

- (void)endStrokeForSinglePoint
{
    [self.strokeGenerator endStrokeForSinglePoint];
}

- (void)disposeOrCommitActiveStroke
{
    [self.strokeGenerator disposeOrCommitActiveStroke];
}

#pragma mark - <CVSStrokeCountChangeObserver>

- (void)strokeCountDidChange:(NSUInteger)pCurrentStrokeCount commitPendingStrokes:(void(^)(void))pCommitPendingStrokes
{
#pragma unused(pCommitPendingStrokes)
    CVSDMEditorBitmapStoreReference * const bitmapReference = [self.editorBitmapStore createBitmapStoreReference:CVSEditorBitmapStoreIdentifier_CacheView];
    assert(bitmapReference);
    CVSDMImageSnapshotQueue * const snapshotQueue = self.imageSnapshotQueue;
    assert(snapshotQueue);
    [snapshotQueue invalidateSnapshotsWithCountsGreaterThan:pCurrentStrokeCount];
}

@end
