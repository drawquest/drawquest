//
//  CVSBrushView.h
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVSDrawingTypes.h"

@interface CVSBrushView : UIView

@property (nonatomic, strong) UIColor *activeColor;
@property (nonatomic, assign) CVSBrushType brushType;
@property (nonatomic, assign) BOOL hasSmile;
@property (nonatomic, assign) CGFloat scale;

+ (CGFloat)maxWidth;
+ (CGSize)sizeForBrushType:(CVSBrushType)brushType;

- (CGSize)boundsSize;
- (id)initWithBrushType:(CVSBrushType)brushType activeColor:(UIColor *)activeColor hasSmile:(BOOL)hasSmile;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithBrushType:activeColor:hasSmile:);

@end
