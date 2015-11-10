//
//  DQTextField.m
//  DrawQuest
//
//  Created by David Mauro on 10/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTextField.h"

@interface DQTextField ()

@property (nonatomic, strong) UIColor *backupTextColor;

@end

@implementation DQTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect result = [super textRectForBounds:bounds];
    return UIEdgeInsetsInsetRect(result, self.textInset);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect result = [super editingRectForBounds:bounds];
    return UIEdgeInsetsInsetRect(result, self.textInset);
}

- (void)setTintColorForText:(BOOL)tintColorForText
{
    if (_tintColorForText)
    {
        if (!tintColorForText)
        {
            [super setTextColor:self.backupTextColor];
            self.backupTextColor = nil;
        }
    }
    else
    {
        if (tintColorForText)
        {
            self.backupTextColor = self.textColor;
            [super setTextColor:self.tintColor];
        }
    }
    _tintColorForText = tintColorForText;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    if (self.tintColorForText)
    {
        [super setTextColor:self.tintColor];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    if (self.tintColorForText)
    {
        self.backupTextColor = textColor;
    }
    else
    {
        [super setTextColor:textColor];
    }
}

@end
