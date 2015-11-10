//
//  UIButton+DQAdditions.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kDrawQuestMainActionButtonWidth;
extern CGFloat const kDrawQuestCellActionButtonWidth;

@interface UIButton (DQAdditions)

+ (instancetype)dq_buttonForCellActionWithWidth:(CGFloat)width;
+ (instancetype)dq_buttonForMainActionWithWidth:(CGFloat)width;

+ (instancetype)dq_buttonForCellAction; // uses standard width
+ (instancetype)dq_buttonForMainAction; // uses standard width

@end
