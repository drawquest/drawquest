//
//  CVSStrokeManager.h
//  Editor
//
//  Created by Phillip Bowden on 8/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "CVSStrokeGenerator.h"

@protocol CVSBackedRenderer;

extern NSString * const CVSStrokeManagerDataIdentifier;

@class CVSDrawing;

@protocol CVSStrokeManagerDelegate;
@protocol CVSStrokeCountChangeObserver;

@interface CVSStrokeManager : NSObject <CVSStrokeGeneratorConsumer>

@property (nonatomic, weak) id<CVSBackedRenderer> renderer;
@property (nonatomic, weak) id<CVSStrokeManagerDelegate> delegate;
@property (nonatomic, weak) id<CVSStrokeCountChangeObserver> strokeCountChangeObserver;


@property (nonatomic, readonly) NSString *rootPath;
@property (nonatomic, readonly, getter = isUndoAvailable) BOOL undoAvailable;
@property (nonatomic, readonly, getter = isRedoAvailable) BOOL redoAvailable;
@property (nonatomic, readonly, assign) NSUInteger numberOfStrokes;

// designated initializer
- (id)initWithRootPath:(NSString *)rootPath delegate:(id<CVSStrokeManagerDelegate>)delegate;
- (id)init MSDesignatedInitializer(initWithRootPath:delegate:);

- (void)load;

- (void)publishWithImageRepresentation:(UIImage *)editorImage;

- (void)clearTemplateImage;

- (void)undoStroke;
- (void)redoStroke;
- (void)clearCurrentStrokes;

- (CVSStroke *)newStroke;
- (CVSStrokeComponent *)newStrokeComponent;

@end


@protocol CVSStrokeManagerDelegate <NSObject>

- (void)strokeManagerUpdatedUndoStacks:(CVSStrokeManager *)strokeManager;

@end

/**
 @protocol object is messaged when the stroke count changes
 */
@protocol CVSStrokeCountChangeObserver <NSObject>
@required
/**
 @todo commit to snapshotting and remove the commit pending strokes parameter
 */
- (void)strokeCountDidChange:(NSUInteger)pCurrentStrokeCount commitPendingStrokes:(void(^)(void))pCommitPendingStrokes;

@end
