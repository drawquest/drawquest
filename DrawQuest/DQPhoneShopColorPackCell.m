//
//  DQPhoneShopColorPackCell.m
//  DrawQuest
//
//  Created by David Mauro on 11/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneShopColorPackCell.h"

#import "CVSPhoneColorWell.h"

#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "UIImage+DQAdditions.h"
#import "DQViewMetricsConstants.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQPhoneShopColorPackCell ()

@property (nonatomic, strong) UIView *paletteWrapperView;
@property (nonatomic, strong) UIView *purchaseWrapperView;
@property (nonatomic, strong) UIView *purchasedView;
@property (nonatomic, strong) UIView *divider;

@end

@implementation DQPhoneShopColorPackCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        _titleLabel.font = [UIFont dq_phoneShopItemTitleFont];
        _titleLabel.textColor = [UIColor dq_phoneDarkGrayTextColor];
        [self.contentView addSubview:_titleLabel];

        _saleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _saleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _saleLabel.font = [UIFont dq_phoneShopItemSubTitleFont];
        _saleLabel.textColor = [UIColor dq_phoneLightGrayTextColor];
        [self.contentView addSubview:_saleLabel];

        _purchaseWrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        _purchaseWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_purchaseWrapperView];

        _purchaseButton = [DQButton buttonWithImage:[UIImage imageNamed:@"coin_shop_total_small"]];
        _purchaseButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 10.0f);
        _purchaseButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 5.0f, 0.0f, 0.0f);
        _purchaseButton.layer.cornerRadius = 4.0f;
        _purchaseButton.titleLabel.font = [UIFont dq_phoneCoinsFont];
        _purchaseButton.tintColorForBackground = YES;
        [_purchaseWrapperView addSubview:_purchaseButton];

        DQButton *purchasedView = [DQButton buttonWithImage:[[UIImage imageNamed:@"share_success_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        purchasedView.hidden = YES;
        purchasedView.userInteractionEnabled = NO;
        purchasedView.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:11.0f];
        [purchasedView setTitle:DQLocalizedString(@"Purchased", @"Shop item has been purchased indicator label") forState:UIControlStateNormal];
        purchasedView.tintColorForTitle = YES;
        purchasedView.backgroundColor = [UIColor dq_phoneBackgroundColor];
        [purchasedView setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [_purchaseWrapperView addSubview:purchasedView];
        self.purchasedView = purchasedView;

        _paletteWrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        _paletteWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_paletteWrapperView];

        _divider = [[UIView alloc] initWithFrame:CGRectZero];
        _divider.translatesAutoresizingMaskIntoConstraints = NO;
        _divider.backgroundColor = [UIColor dq_phoneTableSeperatorColor];
        [self.contentView addSubview:_divider];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_titleLabel, _saleLabel, _purchaseWrapperView, _paletteWrapperView, _divider);
        NSDictionary *metrics = @{@"priority": @(UILayoutPriorityDefaultHigh)};

        DQVisualConstraintsWithOptions(self.contentView, @"H:|-15@priority-[_titleLabel]-5@priority-[_saleLabel]-10@priority-|", NSLayoutFormatAlignAllBaseline);
        DQVisualConstraintsWithOptions(self.contentView, @"H:|-15@priority-[_paletteWrapperView]-5@priority-[_purchaseWrapperView(90@priority)]-10@priority-|", NSLayoutFormatAlignAllCenterY);
        DQVisualConstraints(self.contentView, @"H:|-15@priority-[_divider]|");
        DQVisualConstraints(self.contentView, @"V:|-12@priority-[_titleLabel]-10@priority-[_paletteWrapperView]-25@priority-[_divider(0.5@priority)]|");
        DQVisualConstraints(self.contentView, @"V:[_purchaseWrapperView(30@priority)]");

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.purchaseWrapperView.bounds = CGRectMake(0.0f, 0.0f, 90.0f, 30.0f);

    [self.purchaseButton sizeToFit];
    [self.purchasedView sizeToFit];
    self.purchaseButton.frameWidth += 5.0f; // Because of the textInset?
    self.purchaseButton.frameMaxX = self.purchaseWrapperView.frameWidth;
    self.purchasedView.frameMaxX = self.purchaseWrapperView.frameWidth;
    self.purchaseButton.frameCenterY = self.purchaseWrapperView.boundsCenterY;
    self.purchasedView.frameCenterY = self.purchaseWrapperView.boundsCenterY;

    UIView *previousView;
    for (UIView *view in self.paletteWrapperView.subviews)
    {
        view.frameHeight = kDQFormPhoneShopColorSize;
        view.frameWidth = kDQFormPhoneShopColorSize;
        view.frameY = 0.0f;
        view.layer.cornerRadius = kDQFormPhoneShopColorSize/2.0f;
        if (previousView)
        {
            view.frameX = previousView.frameMaxX + 10.0f;
        }
        previousView = view;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.purchaseButton.tappedBlock = nil;
    self.isPurchased = NO;
    self.titleLabel.text = nil;
    self.saleLabel.text = nil;
    [self.purchaseButton setTitle:@"" forState:UIControlStateNormal];
    [self setColors:@[]];
}

- (void)setIsPurchased:(BOOL)isPurchased
{
    _isPurchased = isPurchased;
    self.purchaseButton.hidden = isPurchased;
    self.purchasedView.hidden = ! isPurchased;
}

- (void)setColors:(NSArray *)colors
{
    [[self.paletteWrapperView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    for (NSDictionary *color in colors)
    {
        CGRect frame = CGRectMake(0.0f, 0.0f, kDQFormPhoneShopColorSize, kDQFormPhoneShopColorSize);
        CVSPhoneColorWell *colorView = [[CVSPhoneColorWell alloc] initWithFrame:frame fillColor:[UIColor dq_colorWithRGBArray:color.dq_colorRGBInfo] strokeColor:[UIColor dq_modalTableSeperatorColor] forceOutline:NO];
        colorView.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        if (color.dq_colorIsPurchased)
        {
            UIImageView *checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"color_selected_checkmark"]];
            [colorView addSubview:checkmark];
            checkmark.center = colorView.boundsCenter;
        }
        [self.paletteWrapperView addSubview:colorView];
    }
    [self setNeedsLayout];
}

@end
