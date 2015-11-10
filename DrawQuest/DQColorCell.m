//
//  DQColorCell.m
//  DrawQuest
//
//  Created by David Mauro on 7/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQColorCell.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIImage+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQColorCell ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *colorView;
@property (nonatomic, weak) UIImageView *colorImageView;

@end

@implementation DQColorCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Label for "New!"
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.backgroundColor = [UIColor clearColor];
        _label.font = [UIFont dq_modalNewColorFont];
        _label.textColor =  [UIColor colorWithRed:(151/255.0) green:(151/255.0) blue:(151/255.0) alpha:1];
        _label.textAlignment = NSTextAlignmentCenter;
        [_label setText:DQLocalizedString(@"New!", @"Shop item has been recently added indicator label")];
        [_label sizeToFit];
        _label.hidden = YES;
        [self addSubview:_label];
        
        // Wrapper for color and checkmarks to be centered within
        _colorView = [[UIView alloc] initWithFrame:CGRectZero];
        _colorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_colorView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.label.frameMaxY = CGRectGetMaxY(self.bounds) - 5.0f;
    self.label.frameWidth = CGRectGetWidth(self.bounds);
    
    self.colorView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.bounds), CGRectGetMinY(self.label.frame) + 10.0f);
    self.colorImageView.center = self.colorView.center;
    // Ensure the color image view is aligned to the pixel grid
    self.colorImageView.frameX = (int)self.colorImageView.frameX;
    self.colorImageView.frameY = (int)self.colorImageView.frameY;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.colorImageView removeFromSuperview];
    self.label.hidden = YES;
}

- (void)setColor:(UIColor *)inColor isNew:(BOOL)isNew isPurchased:(BOOL)isPurchased
{
    self.label.hidden = ! isNew;
    
    UIImageView *colorImageView = [[UIImageView alloc] initWithImage:[UIImage shopColorWithColor:inColor isPurchased:isPurchased]];
    self.colorImageView = colorImageView;
    colorImageView.center = self.colorView.center;
    [self.colorView addSubview:colorImageView];
}

@end
