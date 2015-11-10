//
//  UIBezierPath+CVSAdditions.h
//  Editor
//
//  Created by Phillip Bowden on 10/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CVSStrokeComponent;

@interface UIBezierPath (CVSAdditions)

- (void)cvs_addStrokeComponent:(CVSStrokeComponent *)component;

@end
