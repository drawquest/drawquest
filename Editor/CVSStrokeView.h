//
//  CVSStrokeView.h
//  Editor
//
//  Created by Phillip Bowden on 10/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CVSDrawingTypes.h"
#import "CVSStrokeRenderComplexity.h"

@class CVSStroke;
@class CVSStrokeComponent;
@class CVSStrokeArray;

@interface CVSStrokeView : UIView

/**
 @return YES if this holds one or more strokes
 */
- (BOOL)hasStrokes;

- (BOOL)containsStroke:(CVSStroke *)stroke;

- (void)addStroke:(CVSStroke *)stroke;
- (void)addStrokes:(CVSStrokeArray *)strokes;
- (void)removeStroke:(CVSStroke *)stroke;
- (void)disposeActiveStroke;

- (CVSStrokeArray *)dequeueStrokesToFitBelowRenderComplexityThreshold:(CVSMultipleStrokeRenderComplexity)pThreshold;
- (CVSStrokeArray *)dequeueAllStrokesAndEraseView;

- (void)drawComponent:(CVSStrokeComponent *)component brushType:(CVSBrushType)brushType strokeColor:(UIColor *)strokeColor;
- (void)finishRenderingStroke:(CVSStroke *)stroke;

- (void)drawingDidFinishLoading;
- (void)synchronizeContentZoomScale:(CGFloat)pZoomScale;

- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity;

@end
