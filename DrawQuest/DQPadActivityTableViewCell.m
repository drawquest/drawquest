//
//  DQPadActivityTableViewCell.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-10-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//


//!! Heads up, there will be some 'da fuck' logic in here, I hope to tidy this up later, but quick hacks for deadline

#import "DQPadActivityTableViewCell.h"
#import "DQActivityItem.h"
#import "STUtils.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "DQCircularMaskImageView.h"
#import "DQPhoneFollowButton.h"

static const CGFloat kDQActivityTableViewCellIconDimension = 30.0f;
static const CGFloat kDQActivityTableViewCellDrawingFrameWidth = 65.0f;
static const CGFloat kDQActivityTableViewCellMargin = 15.0f;

@interface DQPadActivityTableViewCell ()

@property (nonatomic, strong) UIImageView *specialIconView;
@property (nonatomic, strong) UIImageView *activityIconView;
@property (nonatomic, assign) BOOL isStarred;

@end

@implementation DQPadActivityTableViewCell

- (void)prepareForReuse
{
    self.activityIconView.hidden = TRUE;
    self.specialIconView.image = nil;

    _isStarred = NO;
    
    [super prepareForReuse];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        
        self.usernameLabel.textColor = [UIColor colorWithRed:(253/255.0) green:(213/255.0) blue:(118/255.0) alpha:1];
        self.usernameLabel.font = [UIFont dq_activityItemUserNameFont];

        self.activityLabel.textColor = [UIColor dq_activityItemActivityTypeFontColor];
        self.activityLabel.font = [UIFont systemFontOfSize:10];

        self.timestampView.tintColor = [UIColor dq_timestampColor];

        self.drawingImageView.layer.borderWidth = 1;
        self.drawingImageView.layer.borderColor = [UIColor colorWithRed:(201/255.0) green:(201/255.0) blue:(201/255.0) alpha:1].CGColor;

        _specialIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_specialIconView];

        _activityIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _activityIconView.image = [UIImage imageNamed:@"star"];
        _activityIconView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:_activityIconView];
    }
    return self;
}

- (void)initializeWithActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeWithActivityItem:inActivityItem];
}

- (void)initializeStarActivityItem:(DQActivityItem *)inActivityItem
{
    _isStarred = TRUE;
    [super initializeStarActivityItem:inActivityItem];
}

- (void)initializeRemixActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeRemixActivityItem:inActivityItem];
}

- (void)initializePlaybackActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializePlaybackActivityItem:inActivityItem];
}

- (void)initializePostActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializePostActivityItem:inActivityItem];
}

- (void)initializeFollowActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeFollowActivityItem:inActivityItem];
}

- (void)initializeFacebookFriendJoinedActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeFacebookFriendJoinedActivityItem:inActivityItem];
}

- (void)initializeTwitterFriendJoinedActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeTwitterFriendJoinedActivityItem:inActivityItem];
}

- (void)initializeWelcomeActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeWelcomeActivityItem:inActivityItem];
    
}

- (void)initializeFeaturedInExploreActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeFeaturedInExploreActivityItem:inActivityItem];
    self.specialIconView.image = [UIImage imageNamed:@"explore_notification_knight"];
}

- (void)initializeNewColorsActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeNewColorsActivityItem:inActivityItem];
    self.specialIconView.image = [UIImage imageNamed:@"explore_notification_knight"];
}

- (void)initializeNewUGQActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeNewUGQActivityItem:inActivityItem];
}

- (void)initializeOtherOrUnknownActivityItem:(DQActivityItem *)inActivityItem
{
    [super initializeOtherOrUnknownActivityItem:inActivityItem];
    self.specialIconView.image = [UIImage imageNamed:@"explore_notification_knight"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;

    // Divide between left image views and the rest of the content
    CGRect leftContainer;
    CGRect rightContainer;
    CGRectDivide(bounds, &leftContainer, &rightContainer, 120.0f, CGRectMinXEdge);

    // Divide the left container between the avatar and icon
    CGRect avatarRect;
    CGRect iconRect;
    CGRectDivide(leftContainer, &avatarRect, &iconRect, 70.0f, CGRectMinXEdge);

    
    self.avatarImageView.frame = CGRectMake(15, 12, 36, 36);
    
    // Prevent sub-pixel blurriness
    self.avatarImageView.center = CGPointMake((int)self.avatarImageView.center.x, (int)self.avatarImageView.center.y);

    self.specialIconView.frame = CGRectMake(0.0f, 0.0f, self.specialIconView.image.size.width, self.specialIconView.image.size.height);
    self.specialIconView.center = self.avatarImageView.center;

    self.drawingImageView.frame = CGRectMake(253, 8, 58, 43);
    
    //Position the activity Icon appropriately if is sta
    if (_isStarred ) {
        iconRect.size = CGSizeMake(kDQActivityTableViewCellIconDimension, kDQActivityTableViewCellIconDimension);
        self.activityIconView.frame = iconRect;
        self.activityIconView.hidden = FALSE;
        self.activityIconView.center = CGPointMake(self.drawingImageView.frameX, self.drawingImageView.frameY + 4);
    }
    else if (self.followButton)
    {
        self.followButton.tintColor = [UIColor dq_activityTabColor];
        self.followButton.frame = CGRectMake(252, 14, 58, 32);
        self.activityIconView.hidden = TRUE;
        self.drawingImageView.hidden = FALSE;
        self.drawingImageView.layer.borderWidth = 0;
    }
    else //we (shaun) decided to kill other icons
        self.activityIconView.hidden = TRUE;
    
    // Divide the right container between the labels and the drawing image view
    CGRect labelsContainer;
    CGRect drawingRect;
    CGRectDivide(rightContainer, &drawingRect, &labelsContainer, kDQActivityTableViewCellDrawingFrameWidth + kDQActivityTableViewCellMargin, CGRectMaxXEdge);

    // Layout labels
    CGFloat usernameWidth = [self.usernameLabel.text sizeWithAttributes:@{NSFontAttributeName: self.usernameLabel.font}].width;
    self.usernameLabel.frame = CGRectMake(64, 10, usernameWidth, self.usernameLabel.font.pointSize);
    [self.usernameLabel sizeToFit];

    // Wrap activity label text as needed
    CGFloat activityTextWidth = [self.activityLabel.text sizeWithAttributes:@{NSFontAttributeName: self.activityLabel.font}].width;
    self.activityLabel.frame = CGRectMake(64, CGRectGetMaxY(self.usernameLabel.frame), activityTextWidth, self.activityLabel.font.pointSize);
    [self.activityLabel sizeToFit];

    [self.timestampView sizeToFit];
    self.timestampView.frameX = self.usernameLabel.frameX;
    self.timestampView.frameY = self.activityLabel.frameMaxY + 3.0f;
}

@end
