//
//  CVSCacheView.h
//  Editor
//
//  Created by Phillip Bowden on 10/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CVSCacheViewCompletionBlock)(void);

@class CVSStroke;
@class CVSStrokeArray;
@class CVSDMEditorBitmapStoreReference;
@class CVSDMImageSnapshotQueue;

@protocol CVSEditorViewDelegate;

/**
 @class a view which displays strokes which have occurred -- avoiding rendering the strokes unnecessarily
 */
@interface CVSCacheView : UIView

@property (nonatomic, weak, readwrite) id<CVSEditorViewDelegate> editorViewDelegate;

- (id)initWithFrame:(CGRect)pFrame bitmapStoreReference:(CVSDMEditorBitmapStoreReference *)pBitmapStoreReference imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue enableSnapshotting:(BOOL)pEnableSnapshotting;

- (BOOL)hasStrokes;

- (void)enqueueAndRenderStrokes:(CVSStrokeArray *)strokes;
- (CVSStroke *)dequeueTopStroke;
- (CVSStrokeArray *)dequeueStrokesAndClearCache;
- (void)clearAllStrokesAndEraseView;

- (void)drawingDidFinishLoading;
- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale;

/**
 @brief draws the bitmap into the context. the context must be configured by the client.
 */
- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext;

- (void)rebuildSnapshotCache;

@end
