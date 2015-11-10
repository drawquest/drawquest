//
//  DQSharingTableViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQSharingTableViewCell.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQCoinsLabel.h"

const int kDQSharingTableViewCellDefaultCoinValue = 3;

@interface DQSharingTableViewCell ()

@property (nonatomic, strong) DQCoinsLabel *coinsLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIView *iconViewWrapper;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong) UIView *verticalSeparatorView;
@property (nonatomic, assign) BOOL facebook;
@property (nonatomic, assign) BOOL twitter;

@end

@implementation DQSharingTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }

    // TODO: Fix tintColor throughout the app
    self.tintColor = [UIColor dq_greenColor];

    self.accessoryView = nil;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor whiteColor];
    _sharing = NO;
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor dq_phoneDarkGrayTextColor];
    _titleLabel.font = [UIFont dq_modalTableCellFont];
    [self.contentView addSubview:_titleLabel];

    _iconViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
    _iconViewWrapper.layer.cornerRadius = 16.0f;
    [self.contentView addSubview:_iconViewWrapper];

    _iconView = [[UIImageView alloc] init];
    [_iconViewWrapper addSubview:_iconView];

    _coinsLabel = [[DQCoinsLabel alloc] init];
    [self.contentView addSubview:_coinsLabel];

    _toggleSwitch = [[UISwitch alloc] init];
    [_toggleSwitch addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:_toggleSwitch];

    _verticalSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1.0f, 0.0f)];
    _verticalSeparatorView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self.contentView addSubview:_verticalSeparatorView];

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.facebook = NO;
    self.twitter = NO;
    self.titleLabel.text = nil;
}

- (void)configureForFacebookIsSharing:(BOOL)sharing
{
    self.facebook = YES;
    self.sharing = sharing;
}

- (void)configureForTwitterIsSharing:(BOOL)sharing
{
    self.twitter = YES;
    self.sharing = sharing;
}

- (void)configureAppearanceForSharing:(BOOL)animated
{
    if (self.facebook)
    {
        self.iconView.image = [UIImage imageNamed:@"button_icon_facebook"];
        self.titleLabel.text = DQLocalizedString(@"Facebook", @"Facebook");
    }
    else if (self.twitter)
    {
        self.iconView.image = [UIImage imageNamed:@"button_icon_twitter"];
        self.titleLabel.text = DQLocalizedString(@"Twitter", @"Twitter");
    }
    self.iconView.frameWidth = self.iconView.image.size.width;
    self.iconView.frameHeight = self.iconView.image.size.height;
    self.iconViewWrapper.backgroundColor = (self.isSharing) ? self.tintColor : [UIColor dq_phoneProfileSocialLinkInactiveButtonColor];

    self.coinsLabel.selected = self.isSharing;
    [self.toggleSwitch setOn:self.isSharing animated:animated];
}

#pragma mark - Public Accessors

- (void)setRewardAmount:(NSString *)rewardAmount
{
    self.coinsLabel.text = rewardAmount;
}

- (void)setSharing:(BOOL)sharing
{
    [self setSharing:sharing animated:NO];
}

- (void)setSharing:(BOOL)sharing animated:(BOOL)animated
{
    _sharing = sharing;
    [self configureAppearanceForSharing:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat padding = 15.0f;

    CGRect contentRect = CGRectInset(self.contentView.bounds, padding, 0.0f);
    CGRect rightRect;
    CGRect leftRect;
    CGRectDivide(contentRect, &rightRect, &leftRect, 85.0f, CGRectMaxXEdge);

    self.iconViewWrapper.frameX = (int)CGRectGetMinX(contentRect);
    self.iconViewWrapper.frameY = (int)(CGRectGetMidY(contentRect) - CGRectGetHeight(self.iconView.frame)/2);

    self.iconView.frameCenterX = self.iconViewWrapper.boundsCenterX + 0.5f;
    self.iconView.frameCenterY = self.iconViewWrapper.boundsCenterY + 0.5f;

    self.coinsLabel.frame = CGRectMake((int)(CGRectGetMaxX(contentRect) - CGRectGetWidth(self.coinsLabel.frame)),
                                       (int)(CGRectGetMidY(contentRect) - CGRectGetHeight(self.coinsLabel.frame)/2),
                                       CGRectGetWidth(rightRect),
                                       [self.coinsLabel height]);

    self.verticalSeparatorView.frame = CGRectMake((int)(CGRectGetMaxX(leftRect) - CGRectGetWidth(self.verticalSeparatorView.frame) - padding),
                                                  6.0f,
                                                  1.0f,
                                                  41);

    self.toggleSwitch.frame = CGRectMake((int)(CGRectGetMinX(self.verticalSeparatorView.frame) - CGRectGetWidth(self.toggleSwitch.frame) - 15.0f),
                                         (int)(CGRectGetMidY(contentRect) - CGRectGetHeight(self.toggleSwitch.frame)/2),
                                         CGRectGetWidth(self.toggleSwitch.frame),
                                         CGRectGetHeight(self.toggleSwitch.frame));

    int titleLabelOriginX = (int)(CGRectGetMaxX(self.iconViewWrapper.frame) + padding);
    self.titleLabel.frame = CGRectMake(titleLabelOriginX,
                                       (int)(CGRectGetMidY(contentRect) - self.titleLabel.font.pointSize/2),
                                       (int)(CGRectGetMinX(self.toggleSwitch.frame) - titleLabelOriginX - padding),
                                       self.titleLabel.font.pointSize);
}

#pragma mark - Actions

- (void)toggled:(UISwitch *)sender
{
    if (self.toggledBlock)
    {
        self.toggledBlock(self, sender.on);
    }
}

@end
