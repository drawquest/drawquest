//
//  DQPhoneActivityTableViewCell.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-10-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneActivityTableViewCell.h"

#import "DQCircularMaskImageView.h"

#import "STUtils.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQPhoneFollowButton.h"

NSString *const DQPhoneActivityTableViewCellMarkAsReadNotification = @"DQPhoneActivityTableViewCellMarkAsReadNotification";

@interface DQPhoneActivityTableViewCell ()

@property (nonatomic, strong) UIImageView *starImageView;

@end

@implementation DQPhoneActivityTableViewCell

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPhoneActivityTableViewCellMarkAsReadNotification object:nil];
}

- (void)prepareForReuse
{
    self.isUnread = NO;
    self.activityType = DQActivityItemTypeUnknown;
    [self.starImageView removeFromSuperview];
    self.starImageView = nil;
    [super prepareForReuse];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor dq_phoneBackgroundColor];

        self.timestampView.tintColor = [UIColor dq_timestampColor];

        self.usernameLabel.textColor = self.tintColor;
        self.usernameLabel.font = [UIFont dq_phoneActivityUsername];

        self.activityLabel.textColor = [UIColor dq_modalPrimaryTextColor];
        self.activityLabel.font = [UIFont dq_phoneActivityActivity];
        self.activityLabel.adjustsFontSizeToFitWidth = YES;
        self.activityLabel.minimumScaleFactor = 0.5f;

        self.drawingImageView.layer.borderColor = [[UIColor dq_drawingThumbStrokeColor] CGColor];
        self.drawingImageView.layer.borderWidth = 0.5f;
    }
    return self;
}

- (void)initializeWithActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeWithActivityItem:inActivityItem];

    self.avatarImageView.imageURL = inActivityItem.phoneAvatarURL;
    self.activityType = inActivityItem.activityType;
    self.timestampView.timestamp = inActivityItem.timestamp;

    switch (self.activityType)
    {
        case DQActivityItemTypeStar:
            self.starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star"]];
            [self.drawingImageView.superview addSubview:self.starImageView];
            break;

        default:
            break;
    }
    [self setNeedsLayout];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.usernameLabel.textColor = self.tintColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.avatarImageView.frame = CGRectMake(12, 10, 39, 39);
    self.drawingImageView.frame = CGRectMake(252, 8, 56, 42);
    if (self.starImageView)
    {
        self.starImageView.frameOrigin = CGPointMake(252 - self.starImageView.image.size.width / 2, 2);
    }
    else if (self.followButton)
    {
        self.followButton.frame = CGRectMake(252, 14, 58, 32);
    }

    self.usernameLabel.frame = CGRectMake(61, 9, 0, 0);
    [self.usernameLabel sizeToFit];
    self.activityLabel.frame = CGRectMake(61, self.usernameLabel.frameMaxY - 2, 0, 0);
    [self.activityLabel sizeToFit];
    self.activityLabel.frameWidth = self.drawingImageView.frameX - 10.0f - self.activityLabel.frameX;
    self.timestampView.frameOrigin = CGPointMake(61, self.activityLabel.frameMaxY + 3);
}

- (NSString *)activityLabelTextForActivityItem:(DQActivityItem *)inActivityItem withText:(NSString *)additionalText
{
    return additionalText;
}

- (NSString *)timestampLabelTextForActivityItem:(DQActivityItem *)inActivityItem
{
    return [inActivityItem.timestamp phoneRelativeDateString];
}

- (void)setIsUnread:(BOOL)isUnread
{
    if (_isUnread && !isUnread)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPhoneActivityTableViewCellMarkAsReadNotification object:nil];
    }
    else if (!_isUnread && isUnread)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markAsRead:) name:DQPhoneActivityTableViewCellMarkAsReadNotification object:nil];
    }
    _isUnread = isUnread;
    self.contentView.backgroundColor = isUnread ? [UIColor whiteColor] : [UIColor clearColor];
}

- (void)markAsRead:(NSNotification *)_
{
    self.isUnread = NO;
}

@end
