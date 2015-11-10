//
//  DQPhoneShopCoinCell.m
//  DrawQuest
//
//  Created by David Mauro on 11/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneShopCoinCell.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQPhoneShopCoinCell ()

@property (nonatomic, strong) UIImageView *coinImageView;
@property (nonatomic, strong) UIView *purchasedView;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UILabel *amountLabel;

@end

@implementation DQPhoneShopCoinCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coin_shop_large"]];
        [self.contentView addSubview:_coinImageView];

        _amountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _amountLabel.font = [UIFont fontWithName:@"Vanilla" size:28.0f];
        _amountLabel.textColor = [UIColor dq_activityTabColor];
        _amountLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_amountLabel];

        _purchaseButton = [DQButton buttonWithType:UIButtonTypeCustom];
        _purchaseButton.contentEdgeInsets = UIEdgeInsetsMake(6.0f, 12.0, 6.0f, 12.0);
        _purchaseButton.layer.cornerRadius = 4.0f;
        _purchaseButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
        _purchaseButton.tintColorForBackground = YES;
        [self.contentView addSubview:_purchaseButton];

        DQButton *purchasedView = [DQButton buttonWithImage:[[UIImage imageNamed:@"share_success_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        purchasedView.hidden = YES;
        purchasedView.userInteractionEnabled = NO;
        purchasedView.titleLabel.font = [UIFont dq_shareTitleFont];
        [purchasedView setTitle:DQLocalizedString(@"Success", @"Successful request indicator label") forState:UIControlStateNormal];
        purchasedView.tintColorForTitle = YES;
        purchasedView.backgroundColor = [UIColor dq_phoneBackgroundColor];
        [purchasedView setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [self.contentView addSubview:purchasedView];
        self.purchasedView = purchasedView;

        _divider = [[UIView alloc] initWithFrame:CGRectZero];
        _divider.translatesAutoresizingMaskIntoConstraints = NO;
        _divider.backgroundColor = [UIColor dq_phoneTableSeperatorColor];
        [self.contentView addSubview:_divider];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.coinImageView.frameX = 15.0f;
    self.coinImageView.frameCenterY = self.boundsCenterY;

    [self.purchaseButton sizeToFit];
    self.purchaseButton.frameMaxX = self.frameWidth - 10.0f;
    self.purchaseButton.frameCenterY = self.boundsCenterY;

    // Make sure purchased view overlays purchase button
    [self.purchasedView sizeToFit];
    self.purchasedView.frameHeight = self.purchaseButton.frameHeight;
    if (self.purchasedView.frameWidth < self.purchaseButton.frameWidth)
    {
        self.purchasedView.frameWidth = self.purchaseButton.frameWidth;
    }
    self.purchasedView.frameMaxX = self.purchaseButton.frameMaxX;
    self.purchasedView.frameCenterY = self.boundsCenterY;

    [self.amountLabel sizeToFit];
    self.amountLabel.frameX = self.coinImageView.frameMaxX + 6.0f;
    self.amountLabel.frameCenterY = self.boundsCenterY;

    self.divider.frameWidth = self.frameWidth - 15.0;
    self.divider.frameHeight = 0.5f;
    self.divider.frameMaxX = self.frameWidth;
    self.divider.frameMaxY = self.frameHeight;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.purchaseButton.tappedBlock = nil;
    [self.purchaseButton setTitle:nil forState:UIControlStateNormal];
    self.amountLabel.text = @"";
}

- (void)setAmount:(NSString *)amount
{
    self.amountLabel.text = amount;
    [self.amountLabel sizeToFit];
}

- (void)flashSuccessView
{
    self.purchasedView.alpha = 0.0f;
    self.purchasedView.hidden = NO;
    [UIView animateWithDuration:0.2f animations:^{
        self.purchasedView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.7f delay:0.8f options:0 animations:^{
            self.purchasedView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.purchasedView.hidden = YES;
        }];
    }];
}

@end
