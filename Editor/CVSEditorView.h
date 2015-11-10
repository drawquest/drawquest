//
//  CVSEditorView.h
//  Editor
//
//  Created by Phillip Bowden on 8/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CVSBackedRenderer.h"

@class CVSStrokeGenerator;
@class CVSDMEditorBitmapStore;
@class CVSEditorView;
@class CVSDMImageSnapshotQueue;

@protocol CVSStrokeRecorder;

@protocol CVSEditorViewDelegate <NSObject>

- (void)hideInterfaceForEditorView:(CVSEditorView *)view;
- (void)showInterfaceForEditorView:(CVSEditorView *)view;
- (BOOL)isPointBeyondThreshold:(CGPoint)point;

/**
 @brief call when a time consuming undo action will begin.
 @return the depth of the current undo actions (calls may be nested).
 */
- (NSUInteger)timeConsumingUndoWillBegin;

/**
 @brief call when a time consuming undo action has ended.
 @return the depth of the current undo actions (calls may be nested).
 */
- (NSUInteger)timeConsumingUndoDidEnd;

@end


@interface CVSEditorView : UIView <CVSBackedRenderer>

@property (weak, nonatomic) id <CVSEditorViewDelegate> delegate;
@property (strong, nonatomic) UIImage *templateImage;

@property (assign, nonatomic, getter = isInterfaceHiddenManually) BOOL interfaceHiddenManually;

- (void)setEditorBitmapStore:(CVSDMEditorBitmapStore *)pEditorBitmapStore imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue;
- (void)setStrokeRecorder:(id<CVSStrokeRecorder>)pStrokeRecorder;

- (void)clear;
- (void)clearTemplateImage;
- (UIImage *)imageRepresentation;

- (void)drawingDidFinishLoading;

- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale;

- (void)disposeActiveStroke;

@end
