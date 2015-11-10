//
//  DQPhoneShopColorCell.m
//  DrawQuest
//
//  Created by David Mauro on 11/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneShopColorCell.h"

#import "CVSPhoneColorWell.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@interface DQPhoneShopColorCell ()

@property (nonatomic, strong) CVSPhoneColorWell *colorView;
@property (nonatomic, strong) UIImageView *purchasedView;
@property (nonatomic, strong) UILabel *labelForNew;

@end

@implementation DQPhoneShopColorCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tap];

        CGRect colorFrame = CGRectMake(0.0f, 0.0f, kDQFormPhoneShopColorSize, kDQFormPhoneShopColorSize);
        _colorView = [[CVSPhoneColorWell alloc] initWithFrame:colorFrame fillColor:nil strokeColor:[UIColor dq_modalTableSeperatorColor] forceOutline:NO];
        _colorView.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        [self.contentView addSubview:_colorView];

        _purchasedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"color_selected_checkmark"]];
        _purchasedView.hidden = YES;
        _purchasedView.center = _colorView.boundsCenter;
        [_colorView addSubview:_purchasedView];

        _labelForNew = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelForNew.hidden = YES;
        _labelForNew.text = DQLocalizedStringWithDefaultValue(@"NewShopItemIndicatorLabel", nil, nil, @"New", @"Shop item is new to the user indicator label");;
        _labelForNew.font = [UIFont dq_phoneShopItemSubTitleFont];
        _labelForNew.textColor = [UIColor dq_phoneLightGrayTextColor];
        [_labelForNew sizeToFit];
        [self.contentView addSubview:_labelForNew];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.colorView.center = self.boundsCenter;
    self.labelForNew.frameCenterX = self.boundsCenterX;
    self.labelForNew.frameMaxY = self.frameHeight;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.cellTappedBlock = nil;
    [self setColor:[UIColor clearColor]];
    self.isPurchased = NO;
    self.isNew = NO;
}

- (void)cellTapped:(id)sender
{
    if (self.cellTappedBlock)
    {
        self.cellTappedBlock(self);
    }
}

- (void)setColor:(UIColor *)color
{
    self.colorView.fillColor = color;
}

- (void)setIsPurchased:(BOOL)isPurchased
{
    _isPurchased = isPurchased;
    self.purchasedView.hidden = ! isPurchased;
}

- (void)setIsNew:(BOOL)isNew
{
    _isNew = isNew;
    self.labelForNew.hidden = ! isNew;
}

@end
