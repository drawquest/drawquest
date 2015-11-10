//
//  DQColorPaletteTableViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQColorPaletteTableViewCell.h"

#import "DQButton.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIButton+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQColorPaletteView.h"
#import "DQCellCheckmarkView.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

@interface DQColorPaletteTableViewCell()

@property (nonatomic, assign) BOOL purchased;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) DQColorPaletteView *paletteView;
@property (nonatomic, weak) UILabel *saleLabel;
@property (nonatomic, weak) UIButton *purchaseButton;

@property (nonatomic, strong) UIView *purchasedView;

@end

@implementation DQColorPaletteTableViewCell

- (id)initWithDelegate:(id<DQColorPaletteTableViewCellDelegate>)delegate reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _delegate = delegate;

    UIView *contentView = self.contentView;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textColor = [UIColor colorWithRed:(151/255.0) green:(151/255.0) blue:(151/255.0) alpha:1];
    [contentView addSubview:titleLabel];
    
    UILabel *saleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    saleLabel.backgroundColor = [UIColor clearColor];
    saleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:14.0f];
    saleLabel.textColor = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
    [contentView addSubview:saleLabel];

    DQColorPaletteView *paletteView = [[DQColorPaletteView alloc] initWithFrame:CGRectZero];
    [contentView addSubview:paletteView];

    DQButton *purchaseButton = [DQButton buttonWithImage:[UIImage imageNamed:@"coin_shop_total_small"]];
    purchaseButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 10.0f);
    purchaseButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 5.0f, 0.0f, 0.0f);
    purchaseButton.layer.cornerRadius = 4.0f;
    purchaseButton.titleLabel.font = [UIFont dq_phoneCoinsFont];
    purchaseButton.tintColorForBackground = YES;
    [purchaseButton addTarget:self action:@selector(purchaseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    DQButton *purchasedView = [DQButton buttonWithImage:[[UIImage imageNamed:@"share_success_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    purchasedView.userInteractionEnabled = NO;
    purchasedView.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:11.0f];
    [purchasedView setTitle:DQLocalizedString(@"Purchased", @"Shop item has been purchased indicator label") forState:UIControlStateNormal];
    purchasedView.tintColorForTitle = YES;
    purchasedView.backgroundColor = [UIColor whiteColor];
    [purchasedView setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];

    self.accessoryView = purchaseButton;
    self.titleLabel = titleLabel;
    self.saleLabel = saleLabel;
    self.paletteView = paletteView;
    self.purchaseButton = purchaseButton;
    self.purchasedView = purchasedView;
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.delegate = nil;
}

- (void)purchaseButtonTapped:(UIButton *)sender
{
    [self.delegate colorPaletteTableViewCell:self purchaseButtonTapped:sender];
}

- (void)setTitle:(NSString *)title saleText:(NSString *)saleText colors:(NSArray *)colors purchaseCost:(NSString *)costString purchased:(BOOL)purchased
{
    self.purchased = purchased;
    self.saleLabel.text = saleText;
    self.titleLabel.text = title;
    self.paletteView.colors = colors;
    [self.purchaseButton setTitle:costString forState:UIControlStateNormal];
}

#pragma mark - Accessors

- (void)setPurchased:(BOOL)purchased
{
    _purchased = purchased;
    self.accessoryView = self.purchased ? self.purchasedView : self.purchaseButton;
    [self setNeedsLayout]; // the size of the contentView changed, so the titleLabel and paletteView need new frames
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.titleLabel sizeToFit];
    [self.purchaseButton sizeToFit];
    [self.purchasedView sizeToFit];
    [self.saleLabel sizeToFit];

    self.purchaseButton.frameWidth += 5.0f; // Because of the textInset?
    self.purchaseButton.frameMaxX = self.contentView.frameWidth + 20.0f;

    CGRect contentBounds = CGRectInset(self.contentView.bounds, 0.0f, 8.0f);
    CGRect titleRect, paletteRect;
    CGRectDivide(contentBounds, &titleRect, &paletteRect, CGRectGetHeight(self.titleLabel.frame), CGRectMinYEdge);
    
    self.titleLabel.frameOrigin = titleRect.origin; // if we used the titleRect it wouldn't be high enough for characters with descenders
    self.paletteView.frame = paletteRect;
    
    // Give the purchased label a little room so it's aligned with the buttons better
    self.purchasedView.frameMaxX = self.contentView.frameWidth + 27.0f;

    self.saleLabel.frameMaxX = self.purchaseButton.frameX - 20.0f;
    self.saleLabel.frameY = (int)((self.purchaseButton.frameHeight - self.saleLabel.frameHeight)/2 + self.purchaseButton.frameY);
}

@end
