//
//  DQCoinsLabel.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCoinsLabel.h"

#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

static CGFloat kDQCoinsLabelSpacing = 5.0f; // Space between coin and number

@interface DQCoinsLabel()

@property (nonatomic, assign) DQCoinsLabelCoinPosition coinPosition;

@end

@implementation DQCoinsLabel

- (id)init
{
    self = [self initWithFrame:CGRectZero];
    if (self)
    {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame coinPosition:DQCoinsLabelCoinPositionRight];
    if (self)
    {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame coinPosition:(DQCoinsLabelCoinPosition)coinPosition
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.font = [UIFont dq_coinsFont];

        _coinPosition = coinPosition;
        self.textAlignment = (coinPosition == DQCoinsLabelCoinPositionRight) ? NSTextAlignmentRight : NSTextAlignmentLeft;

        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_coin"]];
        [self addSubview:_imageView];

        self.selected = YES;
    }
    return self;
}

#pragma mark - Getters

- (CGFloat)height
{
    return self.imageView.image.size.height;
}

#pragma mark - UILabel

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    CGRect textRect;
    CGRect imageRect;
    
    CGRectEdge imageEdge = (self.coinPosition == DQCoinsLabelCoinPositionRight) ? CGRectMaxXEdge : CGRectMinXEdge;
    CGRectDivide(bounds, &imageRect, &textRect, self.imageView.image.size.width, imageEdge);
    return CGRectInset(textRect, kDQCoinsLabelSpacing, 0.0f);
}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:[self textRectForBounds:UIEdgeInsetsInsetRect(rect, UIEdgeInsetsZero) limitedToNumberOfLines:1]];
}

- (void)setSelected:(BOOL)selected
{
    if (selected)
    {
        self.imageView.image = [UIImage imageNamed:@"icon_coin"];
        self.textColor = [UIColor dq_coinTextColor];
    }
    else
    {
        self.imageView.image = [UIImage imageNamed:@"icon_coin_deactivated"];
        self.textColor = [UIColor dq_phoneProfileSocialLinkInactiveButtonColor];
    }
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat imageViewOriginX = 0.0;
    if (self.coinPosition == DQCoinsLabelCoinPositionRight)
    {
        imageViewOriginX = CGRectGetWidth(self.bounds) - self.imageView.image.size.width;
    }
    [self.imageView setFrameX:trunc(imageViewOriginX)];
    [self.imageView setFrameCenterY:trunc(CGRectGetHeight(self.bounds)/2.0)];
}

- (void)sizeToFit
{
    CGSize textSize = [self.text sizeWithAttributes:@{NSFontAttributeName: self.font}];
    CGFloat width = self.imageView.image.size.width + kDQCoinsLabelSpacing + textSize.width + 5.0f;
    CGFloat height = MAX(self.imageView.image.size.height, textSize.height);
    self.bounds = CGRectMake(0.0f, 0.0f, width, height);
}

@end
