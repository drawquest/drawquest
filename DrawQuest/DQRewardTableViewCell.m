//
//  DQRewardTableViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/29/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQRewardTableViewCell.h"


#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

#import "DQCoinsLabel.h"

const static CGFloat kDQRewardTableViewCellIconSize = 33.0f;

@interface DQRewardTableViewCell ()

@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UIView *verticalSeparatorView;

@end

@implementation DQRewardTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }

    // TODO: Fix tintColor throughout the app
    self.tintColor = [UIColor dq_greenColor];
    
    self.backgroundColor = [UIColor whiteColor];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor dq_phoneDarkGrayTextColor];
    _titleLabel.font = [UIFont dq_modalTableCellFont];
    _titleLabel.numberOfLines = 1;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumScaleFactor = 0.5f;
    [self.contentView addSubview:_titleLabel];

    _coinsLabel = [[DQCoinsLabel alloc] init];
    [self.contentView addSubview:_coinsLabel];
    
    _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kDQRewardTableViewCellIconSize, kDQRewardTableViewCellIconSize)];
    _iconView.contentMode = UIViewContentModeScaleToFill;
    [self.contentView addSubview:_iconView];

    _verticalSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1.0f, 0.0f)];
    _verticalSeparatorView.backgroundColor = [UIColor dq_modalTableSeperatorColor];
    [self.contentView addSubview:_verticalSeparatorView];

    return self;
}

- (void)setIconType:(DQRewardTableViewCellIconType)icon
{
    _iconType = icon;
    if (icon == DQRewardTableViewCellIconTypeCheckmark) {
        self.iconView.image = [[UIImage imageNamed:@"icon_qotd_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (icon == DQRewardTableViewCellIconTypeFire) {
        self.iconView.image = [UIImage imageNamed:@"icon_fire"];
    } else {
        self.iconView.image = nil;
    }
}


#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 15.0f;
    
    CGRect contentRect = CGRectInset(self.contentView.bounds, padding, 0.0f);
    CGRect rightRect;
    CGRect leftRect;
    CGRectDivide(contentRect, &rightRect, &leftRect, 85.0f, CGRectMaxXEdge);

    self.iconView.frame = CGRectMake((int)CGRectGetMinX(contentRect),
                                     (int)(CGRectGetMidY(contentRect) - CGRectGetHeight(self.iconView.frame)/2),
                                     CGRectGetWidth(self.iconView.frame),
                                     CGRectGetHeight(self.iconView.frame));

    self.coinsLabel.frame = CGRectMake((int)(CGRectGetMaxX(contentRect) - CGRectGetWidth(self.coinsLabel.frame)),
                                       (int)(CGRectGetMidY(contentRect) - CGRectGetHeight(self.coinsLabel.frame)/2),
                                       CGRectGetWidth(rightRect),
                                       [self.coinsLabel height]);

    self.verticalSeparatorView.frame = CGRectMake((int)(CGRectGetMaxX(leftRect) - CGRectGetWidth(self.verticalSeparatorView.frame) - padding),
                                                  0.0f,
                                                  1.0f,
                                                  CGRectGetHeight(contentRect));

    int titleLabelOriginX = (int)(CGRectGetMaxX(self.iconView.frame) + padding);
    self.titleLabel.frame = CGRectMake(titleLabelOriginX,
                                       (int)(CGRectGetMidY(contentRect) - self.titleLabel.font.pointSize/2),
                                       (int)(CGRectGetMinX(self.verticalSeparatorView.frame) - titleLabelOriginX - padding),
                                       self.titleLabel.font.pointSize);
}

@end
