//
// CVSEditor.h
// DrawQuest
//
// Created by Justin Carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CVSDrawingTypes.h"

@class CVSDMEditorBitmapStore;
@class CVSDMImageSnapshotQueue;
@class CVSStrokeGenerator;
@class UIColor;
@class UIImage;

@protocol CVSBackedRenderer;
@protocol CVSStrokeManagerDelegate;
@protocol CVSStrokeRecorder;

/**
 @class this is a base model for an editor
 */
@interface CVSEditor : NSObject

// designated initializer
- (id)initWithRootPath:(NSString *)pRootPath strokeManagerDelegate:(id<CVSStrokeManagerDelegate>)pStrokeManagerDelegate;


// basic accessors of wrapped objects
- (id<CVSStrokeRecorder>)strokeRecorder;
- (CVSDMEditorBitmapStore *)editorBitmapStore;
- (CVSDMImageSnapshotQueue *)imageSnapshotQueue;

- (void)setRenderer:(id<CVSBackedRenderer>)pRenderer;
- (void)setStrokeColor:(UIColor *)pStrokeColor;

// loads the stroke manager's data
- (void)load;
- (void)initializeEditorBitmapStore:(uint32_t)pWidth height:(uint32_t)pHeight;

// Editor State/Updating
- (void)updateEditorForBrushType:(CVSBrushType)pBrushType strokeGeneratorColor:(UIColor *)pStrokeGeneratorColor;
- (void)clearCurrentStrokes;
- (void)clearTemplateImage;


// Undo/Redo
- (BOOL)undoAvailable;
- (void)undoStroke;

- (BOOL)redoAvailable;
- (void)redoStroke;


// Stroke Information
- (BOOL)strokeManagerHoldsRecordedStrokes;


// Publishing
- (void)publishImageAndInvalidateStrokeManager:(UIImage *)pImage;

@end
