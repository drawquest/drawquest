//
//  DQPhoneShopBrushCell.m
//  DrawQuest
//
//  Created by David Mauro on 11/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneShopBrushCell.h"

#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

static const CGFloat DQPhoneShopBrushCellImageWidth = 67.0f;

@interface DQPhoneShopBrushCell ()

@property (nonatomic, strong) UIView *purchasedView;
@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UIView *brushWrapperView;

@end

@implementation DQPhoneShopBrushCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _brushWrapperView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _brushWrapperView.frameWidth = DQPhoneShopBrushCellImageWidth;
        _brushWrapperView.clipsToBounds = YES;
        [self.contentView addSubview:_brushWrapperView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont dq_phoneShopItemTitleFont];
        _titleLabel.textColor = [UIColor dq_phoneDarkGrayTextColor];
        _titleLabel.numberOfLines = 1;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.5f;
        [self.contentView addSubview:_titleLabel];

        _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descriptionLabel.font = [UIFont dq_phoneShopItemDescriptionFont];
        _descriptionLabel.textColor = [UIColor dq_phoneGrayTextColor];
        _descriptionLabel.numberOfLines = 4;
        _descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _descriptionLabel.adjustsFontSizeToFitWidth = YES;
        _descriptionLabel.minimumScaleFactor = 0.75f;
        [self.contentView addSubview:_descriptionLabel];

        _purchaseButton = [DQButton buttonWithType:UIButtonTypeCustom];
        _purchaseButton.contentEdgeInsets = UIEdgeInsetsMake(6.0f, 12.0, 6.0f, 12.0);
        _purchaseButton.layer.cornerRadius = 4.0f;
        _purchaseButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
        _purchaseButton.tintColorForBackground = YES;
        [self.contentView addSubview:_purchaseButton];

        DQButton *purchasedView = [DQButton buttonWithImage:[[UIImage imageNamed:@"share_success_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        purchasedView.hidden = YES;
        purchasedView.userInteractionEnabled = NO;
        purchasedView.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:11.0f];
        [purchasedView setTitle:DQLocalizedString(@"Purchased", @"Shop item has been purchased indicator label") forState:UIControlStateNormal];
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

    CGFloat padding = (self.contentView.frameWidth > 320.0f) ? 15.0f : 6.0f;

    self.brushWrapperView.frameHeight = self.frameHeight - 10.0f;
    self.brushWrapperView.frameX = 15.0f;
    self.brushWrapperView.frameY = 10.0f;

    [self.titleLabel sizeToFit];
    self.titleLabel.frameX = 15.0f + DQPhoneShopBrushCellImageWidth + padding;
    self.titleLabel.frameWidth = self.contentView.frameWidth - self.titleLabel.frameX - 10.0f;
    self.titleLabel.frameY = 12.0f;

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

    self.descriptionLabel.frameX = 15.0f + DQPhoneShopBrushCellImageWidth + padding;
    self.descriptionLabel.frameWidth = self.purchasedView.frameX - self.descriptionLabel.frameX - 10.0f;
    [self.descriptionLabel sizeToFit];
    self.descriptionLabel.frameY = self.titleLabel.frameMaxY + 2.0f;

    self.divider.frameWidth = self.frameWidth - 15.0;
    self.divider.frameHeight = 0.5f;
    self.divider.frameMaxX = self.frameWidth;
    self.divider.frameMaxY = self.frameHeight;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.titleLabel.text = nil;
    self.descriptionLabel.text = nil;
    self.purchaseButton.tappedBlock = nil;
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
