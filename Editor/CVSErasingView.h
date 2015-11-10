//
//  CVSErasingView.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CVSStrokeRenderComplexity.h"

@class CVSDMEditorBitmapStoreReference;
@class CVSStrokeComponent;
@class CVSStroke;
@class CVSStrokeArray;

/**
 @class this is the view which draws the erase events.
 @details the image this uses is created from the cache view's bitmap content.
 */
@interface CVSErasingView : UIView

- (id)initWithFrame:(CGRect)pFrame bitmapStoreReference:(CVSDMEditorBitmapStoreReference *)pBitmapStoreReference;

- (void)drawComponent:(CVSStrokeComponent *)component;

- (BOOL)hasStrokes;

- (void)addStroke:(CVSStroke *)stroke;
- (void)removeStroke:(CVSStroke *)stroke;
- (BOOL)containsStroke:(CVSStroke *)stroke;

- (void)finishRenderingStroke:(CVSStroke *)stroke;

- (void)disposeActiveStroke;

- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale;

- (CVSStrokeArray *)dequeueAllStrokes;

- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity;

@end
