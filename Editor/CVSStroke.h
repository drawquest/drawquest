//
//  CVSStroke.h
//  Editor
//
//  Created by Phillip Bowden on 10/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"
#import "CVSStrokeRenderComplexity.h"

@class CVSDrawing;
@class CVSUniqueUIColorCache;
@class UIColor;

@interface CVSStroke : NSManagedObject

@property (strong, nonatomic) NSNumber *brushTypeNumber;
@property (strong, nonatomic) NSOrderedSet *components;
@property (strong, nonatomic) UIColor *strokeColor;
@property (strong, nonatomic) CVSDrawing *drawing;

@property (nonatomic, assign, readwrite) CVSBrushType brushType;
@property (nonatomic, readonly) CGPathRef path;
/**
  @return the smallest rect that fits the stroke as it is rendered.
 */
@property (nonatomic, readonly) CGRect bounds;

- (NSDictionary *)strokeRepresentation;

- (void)deduplicateObjectStateUsingUIColorCache:(CVSUniqueUIColorCache *)colorCache;

/**
 @return a value which is a linear distribution from [0...UINT8_MAX] which represents an estimation of complexity to render.
 */
- (CVSSingleStrokeRenderComplexity)singleStrokeRenderComplexity;

/**
 @brief the path is transient. it may be purged and rebuilt on demand. this method purges that cached path.
 */
- (void)purgeCachedPath;

@end
