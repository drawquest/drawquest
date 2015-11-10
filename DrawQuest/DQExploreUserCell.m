//
//  DQExploreUserCell.m
//  DrawQuest
//
//  Created by Dirk on 4/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQExploreUserCell.h"
#import "DQCircularMaskImageView.h"
#import "DQUser.h"
#import "UIColor+DQAdditions.h"
#import "DQAccount.h"
#import "DQPhoneFollowButton.h"
#import "DQViewMetricsConstants.h"
#import "UIView+STAdditions.h"

static const CGRect kAvatarRect = { { 20.0f, 10.0f }, { 40.0f, 40.0f } };
static const CGRect kUserNameRect = { { 71.0f, 20.0f }, { 140.0f, 20.0f } };
static const CGRect kFollowersValueRect = { { 75.0f, 40.0f }, { 70.0f, 12.0f } };
static const CGRect kFollowingsValueRect = { { 145.0f, 40.0f }, { 70.0f, 12.0f } };
static const CGRect kFollowersRect = { { 75.0f, 50.0f }, { 70.0f, 20.0f } };
static const CGRect kFollowingsRect = { { 145.0f, 50.0f }, { 70.0f, 20.0f } };

@interface DQExploreUserCell ()
@property (nonatomic, weak) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, weak) UILabel *userNameLabel;
@property (nonatomic, weak) UILabel *followersLabel;
@property (nonatomic, weak) UILabel *followersValueLabel;
@property (nonatomic, weak) UILabel *followingsLabel;
@property (nonatomic, weak) UILabel *followingsValueLabel;
@property (nonatomic, weak) DQPhoneFollowButton *followButton;
@property (nonatomic, weak) UIView *sideLine;
@property (nonatomic, weak) UIImageView *disclosureImageView;
@property (nonatomic, weak) UIView *rightBorder;
@end

@implementation DQExploreUserCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        DQCircularMaskImageView *avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:kAvatarRect];
        [self.contentView addSubview:avatarImageView];
        _avatarImageView = avatarImageView;
        
        self.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
        
        UILabel *userNameLabel = [[UILabel alloc] initWithFrame:kUserNameRect];
        [userNameLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:20.0f]];
        [userNameLabel setTextColor:[UIColor colorWithRed:(110/255.0) green:(207/255.0) blue:(218/255.0) alpha:1]];
        [userNameLabel setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:userNameLabel];
        _userNameLabel = userNameLabel;
        
        UILabel *followersLabel = [[UILabel alloc] initWithFrame:kFollowersRect];
        [followersLabel setTextAlignment:NSTextAlignmentCenter];
        [followersLabel setText:DQLocalizedString(@"Followers", @"Label for a collection of users a particular user is following")];
        [followersLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:12.0f]];
        [followersLabel setTextColor:[UIColor dq_userSearchFollowColor]];
        [followersLabel setBackgroundColor:[UIColor clearColor]];
       // [self.contentView addSubview:followersLabel];
        _followersLabel = followersLabel;
        
        UILabel *followingsLabel = [[UILabel alloc] initWithFrame:kFollowingsRect];
        [followingsLabel setTextAlignment:NSTextAlignmentCenter];
        [followingsLabel setText:DQLocalizedStringWithDefaultValue(@"FollowingStatusLabel", nil, nil, @"Following", @"Label that confirms a user is following another user")];
        [followingsLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:12.0f]];
        [followingsLabel setTextColor:[UIColor dq_userSearchFollowColor]];
        [followingsLabel setBackgroundColor:[UIColor clearColor]];
        //[self.contentView addSubview:followingsLabel];
        _followingsLabel = followingsLabel;
        
        UILabel *followersValueLabel = [[UILabel alloc] initWithFrame:kFollowersValueRect];
        [followersValueLabel setTextAlignment:NSTextAlignmentCenter];
        [followersValueLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:14.0f]];
        [followersValueLabel setTextColor:[UIColor dq_userSearchNumbersColor]];
        [followersValueLabel setBackgroundColor:[UIColor clearColor]];
        //[self.contentView addSubview:followersValueLabel];
        _followersValueLabel = followersValueLabel;

        UILabel *followingsValueLabel = [[UILabel alloc] initWithFrame:kFollowingsValueRect];
        [followingsValueLabel setTextAlignment:NSTextAlignmentCenter];
        [followingsValueLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:14.0f]];
        [followingsValueLabel setTextColor:[UIColor dq_userSearchNumbersColor]];
        [followingsValueLabel setBackgroundColor:[UIColor clearColor]];
        //[self.contentView addSubview:followingsValueLabel];
        _followingsValueLabel = followingsValueLabel;

        DQPhoneFollowButton *followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kDQFormPhoneAddFriendsAccessoryWidth, kDQFormPhoneAddFriendsAccessoryHeight)];
        followButton.tintColor = [UIColor dq_blueColor];
        [self.contentView addSubview:followButton];
        _followButton = followButton;

        UIImageView *disclosureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_phone"]];
        disclosureImageView.hidden = YES;
        [self.contentView addSubview:disclosureImageView];
        self.disclosureImageView = disclosureImageView;
        
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 59, 510, 1)];
        bottomLine.backgroundColor = [UIColor colorWithRed:(195/255.0) green:(195/255.0) blue:(195/255.0) alpha:1];
        [self.contentView addSubview:bottomLine];

        UIView *rightBorder = [[UIView alloc] initWithFrame:CGRectZero];
        rightBorder.backgroundColor = [UIColor colorWithRed:(195/255.0) green:(195/255.0) blue:(195/255.0) alpha:1];
        [self.contentView addSubview:rightBorder];
        self.rightBorder = rightBorder;
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.followButton.frameMaxX = self.contentView.frameWidth - 15.0;
    self.followButton.frameCenterY = self.contentView.boundsCenterY;

    self.disclosureImageView.frameCenterX = self.followButton.frameCenterX;
    self.disclosureImageView.frameCenterY = self.followButton.frameCenterY;

    self.rightBorder.frameWidth = 1.0f;
    self.rightBorder.frameHeight = self.contentView.frameHeight;
    self.rightBorder.frameMaxX = self.contentView.frameWidth;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.avatarImageView prepareForReuse];
    self.user = nil;
    self.followButton.username = nil;
    self.followButton.hidden = NO;
    self.disclosureImageView.hidden = YES;
}

- (void)setUser:(DQUser *)user loggedInUsername:(NSString *)loggedInUsername
{
    self.user = user;

    [self.avatarImageView setImageWithURL:user.galleryAvatarURL placeholderImage:nil completionBlock:nil failureBlock:nil];
    [self.followersValueLabel setText:user.followerCount];
    [self.followingsValueLabel setText:user.followingCount];
    [self.userNameLabel setText:user.userName];

    BOOL userIsViewer = [loggedInUsername isEqualToString:user.userName];
    self.followButton.hidden = userIsViewer;
    self.disclosureImageView.hidden = ! userIsViewer;
    if (!self.followButton.hidden)
    {
        self.followButton.username = user.userName;
    }
}

@end
