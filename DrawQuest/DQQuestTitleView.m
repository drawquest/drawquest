//
//  DQQuestTitleView.m
//  DrawQuest
//
//  Created by David Mauro on 10/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestTitleView.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

static const CGFloat kDQQuestTitleViewMaxWidth = 200.0f;

@interface DQQuestTitleView ()

@property (nonatomic, strong, readwrite) UILabel *titleLabel;

@end

@implementation DQQuestTitleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.numberOfLines = 2;
        _titleLabel.font = [UIFont dq_questTitleFont];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    self.titleLabel.frameWidth = kDQQuestTitleViewMaxWidth;
    [self.titleLabel sizeToFit];
    self.titleLabel.frameCenterY = self.boundsCenterY;
    // Make sure this is horizontally centered regardless of UIBarButtonItems
    self.titleLabel.frameCenterX = self.superview.superview.frameCenterX - self.frameX;
}

- (void)setText:(NSString *)text
{
    self.titleLabel.text = text;
    [self setNeedsLayout];
}

@end
