//
//  DQBrushTableViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 7/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQBrushTableViewCell.h"
#import "DQButton.h"
#import "DQCellCheckmarkView.h"
#import "UIButton+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

static const CGFloat DQPhoneShopBrushCellImageWidth = 67.0f;

@interface DQBrushTableViewCell ()

@property (nonatomic, strong) UIView *purchasedView;
@property (nonatomic, strong) UIView *brushWrapperView;

@end

@implementation DQBrushTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _brushWrapperView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _brushWrapperView.frameWidth = DQPhoneShopBrushCellImageWidth;
        _brushWrapperView.clipsToBounds = YES;
        [self.contentView addSubview:_brushWrapperView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont dq_phoneShopItemTitleFont];
        _titleLabel.textColor = [UIColor dq_phoneDarkGrayTextColor];
        [self.contentView addSubview:_titleLabel];

        _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descriptionLabel.font = [UIFont fontWithName:@"Arial" size:16.0f];
        _descriptionLabel.textColor = [UIColor dq_phoneGrayTextColor];
        _descriptionLabel.numberOfLines = 3;
        _descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_descriptionLabel];

        _purchaseButton = [DQButton buttonWithType:UIButtonTypeCustom];
        _purchaseButton.contentEdgeInsets = UIEdgeInsetsMake(6.0f, 12.0, 6.0f, 12.0);
        _purchaseButton.layer.cornerRadius = 4.0f;
        _purchaseButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
        _purchaseButton.tintColorForBackground = YES;
        __weak typeof(self) weakSelf = self;
        _purchaseButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.purchaseButtonTappedBlock)
            {
                weakSelf.purchaseButtonTappedBlock(button);
            }
        };
        [self.contentView addSubview:_purchaseButton];

        DQButton *purchasedView = [DQButton buttonWithImage:[[UIImage imageNamed:@"share_success_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        purchasedView.hidden = YES;
        purchasedView.userInteractionEnabled = NO;
        purchasedView.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:11.0f];
        [purchasedView setTitle:DQLocalizedString(@"Purchased", @"Shop item has been purchased indicator label") forState:UIControlStateNormal];
        purchasedView.tintColorForTitle = YES;
        purchasedView.backgroundColor = [UIColor whiteColor];
        [purchasedView setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [self.contentView addSubview:purchasedView];
        self.purchasedView = purchasedView;
    }
    return self;
}



- (void)layoutSubviews
{
    [super layoutSubviews];

    self.brushWrapperView.frameHeight = self.frameHeight - 10.0f;
    self.brushWrapperView.frameX = 15.0f;
    self.brushWrapperView.frameY = 10.0f;

    [self.titleLabel sizeToFit];
    self.titleLabel.frameX = 15.0f + DQPhoneShopBrushCellImageWidth + 6.0f;
    self.titleLabel.frameY = 12.0f;

    self.descriptionLabel.frameWidth = 290.0f;
    [self.descriptionLabel sizeToFit];
    self.descriptionLabel.frameX = 15.0f + DQPhoneShopBrushCellImageWidth + 6.0f;
    self.descriptionLabel.frameY = self.titleLabel.frameMaxY + 2.0f;

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
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.titleLabel.text = nil;
    self.descriptionLabel.text = nil;
    self.purchaseButtonTappedBlock = nil;
    [[self.brushWrapperView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.purchaseButton setTitle:nil forState:UIControlStateNormal];
}

- (void)setBrushView:(UIView *)brushView
{
    [self.brushWrapperView addSubview:brushView];
    brushView.frameCenterX = self.brushWrapperView.boundsCenterX;
}

- (void)setIsPurchased:(BOOL)isPurchased
{
    self.purchasedView.hidden = ! isPurchased;
    self.purchaseButton.hidden = isPurchased;
}

@end
