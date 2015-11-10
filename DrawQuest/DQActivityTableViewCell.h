//
//  DQActivityTableViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DQTimestampView.h"

@class DQActivityItem;
@class DQImageView;
@class DQCircularMaskImageView;
@class DQPhoneFollowButton;

@interface DQActivityTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *activityLabel;
@property (nonatomic, strong) DQTimestampView *timestampView;
@property (nonatomic, strong) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, strong) DQImageView *drawingImageView;
@property (nonatomic, strong) UITapGestureRecognizer *avatarImageViewTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *usernameLabelTapGestureRecognizer;
@property (nonatomic, strong) DQPhoneFollowButton *followButton;

@property (nonatomic, copy) dispatch_block_t avatarOrUserNameTappedBlock;

// subclasses must override this
- (void)initializeWithActivityItem:(DQActivityItem *)inActivityItem;

// template methods
- (void)initializeStarActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeRemixActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializePlaybackActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializePostActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeFollowActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeFacebookFriendJoinedActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeTwitterFriendJoinedActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeWelcomeActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeFeaturedInExploreActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeNewColorsActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeNewUGQActivityItem:(DQActivityItem *)inActivityItem;
- (void)initializeOtherOrUnknownActivityItem:(DQActivityItem *)inActivityItem;

@end
