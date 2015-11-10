//
//  UIButton+DQAdditions.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "UIButton+DQAdditions.h"
#import "UIFont+DQAdditions.h"

CGFloat const kDrawQuestMainActionButtonWidth = 302.0;
CGFloat const kDrawQuestCellActionButtonWidth = 95.0;

@implementation UIButton (DQAdditions)

+ (instancetype)dq_actionButtonWithWidth:(CGFloat)width font:(UIFont *)font
{
    UIButton *result = [[self class] buttonWithType:UIButtonTypeCustom];
    result.frame = CGRectMake(0, 0, width, 30);
    [result setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    result.layer.cornerRadius = 5;
    result.backgroundColor = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
    result.titleLabel.font = font;
    return result;
}

+ (instancetype)dq_buttonForCellActionWithWidth:(CGFloat)width
{
    return [self dq_actionButtonWithWidth:width font:[UIFont dq_cellActionButtonTitleFont]];
}

+ (instancetype)dq_buttonForMainActionWithWidth:(CGFloat)width
{
    return [self dq_actionButtonWithWidth:width font:[UIFont dq_mainActionButtonTitleFont]];
}

+ (instancetype)dq_buttonForCellAction
{
    return [self dq_buttonForCellActionWithWidth:kDrawQuestCellActionButtonWidth];
}

+ (instancetype)dq_buttonForMainAction
{
    return [self dq_buttonForMainActionWithWidth:kDrawQuestMainActionButtonWidth];
}

@end
