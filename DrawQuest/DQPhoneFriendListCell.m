//
//  DQPhoneFriendListCell.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneFriendListCell.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

static const CGFloat kDQPhoneFriendListCellPadding = 15.0f;

@interface DQPhoneFriendListCell ()

@end

@implementation DQPhoneFriendListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_avatarImageView];

        self.textLabel.font = [UIFont dq_phoneUserCellUsernameFont];
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        self.detailTextLabel.textColor = [UIColor dq_phoneGrayTextColor];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.avatarImageView.frame = CGRectMake(kDQPhoneFriendListCellPadding, 0.0f, 32.0f, 32.0f);
    self.avatarImageView.frameCenterY = self.contentView.boundsCenterY;

    [self.textLabel sizeToFit];
    [self.detailTextLabel sizeToFit];
    CGFloat xOffset = self.avatarImageView.frameMaxX + 10.0f;

    if ([self.detailTextLabel.text length])
    {
        CGFloat combinedHeight = self.textLabel.frameHeight + self.detailTextLabel.frameHeight + 2.0f;
        CGFloat vPadding = (self.frameHeight - combinedHeight)/2;
        self.textLabel.frameX = xOffset;
        self.textLabel.frameY = vPadding;
        self.textLabel.frameWidth = self.contentView.frameWidth - xOffset - 5.0f;
        self.detailTextLabel.frameX = xOffset;
        self.detailTextLabel.frameMaxY = self.contentView.frameHeight - vPadding;
        self.detailTextLabel.frameWidth = self.contentView.frameWidth - xOffset - 5.0f;
    }
    else
    {
        self.textLabel.frameX = xOffset;
        self.textLabel.frameCenterY = self.contentView.boundsCenterY;
        self.textLabel.frameWidth = self.contentView.frameWidth - xOffset - 5.0f;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.textLabel.text = nil;
    self.detailTextLabel.attributedText = nil;
    self.avatarImageView.imageURL = nil;
    self.accessoryView = nil;
}

#pragma mark -

- (void)setDisplayName:(NSString *)displayName
{
    self.textLabel.text = displayName;
}

- (void)setUserName:(NSString *)userName
{
    if (userName)
    {
        NSString *subTitle = DQLocalizedString(@"%@ on DrawQuest", @"Label displaying the DrawQuest username for a friend from another social service");
        NSUInteger usernameStartLocation = [subTitle rangeOfString:@"%@"].location;
        subTitle = [NSString stringWithFormat:subTitle, userName];
        NSMutableAttributedString *attributedSubTitle = [[NSMutableAttributedString alloc] initWithString:subTitle];
        [attributedSubTitle setAttributes:@{NSFontAttributeName : [UIFont dq_phoneUserCellDetailFont]} range:NSMakeRange(0, [subTitle length])];
        [attributedSubTitle setAttributes:@{NSFontAttributeName : [UIFont dq_phoneUserCellDetailBoldFont]} range:NSMakeRange(usernameStartLocation, [userName length])];
        self.detailTextLabel.attributedText = attributedSubTitle;
    }
    else
    {
        self.detailTextLabel.attributedText = nil;
    }
}

@end
