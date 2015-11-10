//
//  DQPhoneCoinsLabel.m
//  DrawQuest
//
//  Created by David Mauro on 10/22/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneCoinsLabel.h"

#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

static CGFloat kDQPhoneCoinsLabelSpacing = 5.0f; // Space between coin and number

@interface DQPhoneCoinsLabel ()

@property (nonatomic, strong) UIImageView *coinImageView;

@end

@implementation DQPhoneCoinsLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = NSTextAlignmentLeft;
        self.font = [UIFont dq_phoneCoinsFont];
        self.textColor = [UIColor dq_activityTabColor];

        _coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"promote_coin"]];
        [self addSubview:_coinImageView];
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    CGRect textRect;
    CGRect imageRect;

    CGRectDivide(bounds, &imageRect, &textRect, self.coinImageView.image.size.width, CGRectMinXEdge);
    return CGRectInset(textRect, kDQPhoneCoinsLabelSpacing, 0.0f);
}

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:[self textRectForBounds:UIEdgeInsetsInsetRect(rect, UIEdgeInsetsZero) limitedToNumberOfLines:1]];
}

- (CGSize)intrinsicContentSize
{
    CGSize textSize = [self.text sizeWithAttributes:@{NSFontAttributeName: self.font}];
    CGFloat width = self.coinImageView.image.size.width + kDQPhoneCoinsLabelSpacing + textSize.width + 6.0f;
    CGFloat height = self.coinImageView.image.size.height;
    return CGSizeMake(width, height);
}

- (void)sizeToFit
{
    self.boundsSize = [self intrinsicContentSize];
}

@end
