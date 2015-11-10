//
//  CVSBackedRenderer.h
//  Editor
//
//  Created by Phillip Bowden on 8/16/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"

@class CVSStroke;
@class CVSStrokeComponent;
@class CVSStrokeArray;
@class CVSStrokeGenerator;

@protocol CVSBackedRenderer <NSObject>

@required
- (void)rendererShouldRenderStrokeComponent:(CVSStrokeComponent *)pComponent strokeGenerator:(CVSStrokeGenerator *)pStrokeGenerator;
- (void)rendererShouldFinishRenderingStroke:(CVSStroke *)pStroke strokeGenerator:(CVSStrokeGenerator *)pStrokeGenerator;

- (void)rendererShouldUndoStrokes:(CVSStrokeArray *)pStrokes;
- (void)rendererShouldRedoStrokes:(CVSStrokeArray *)pStrokes;

// if not all, only some may be pushed onto the cache view to preserve undo history
- (void)transferActiveStrokesToCacheView:(BOOL)pTransferAll;

- (void)drawingDidFinishLoading;

@end
