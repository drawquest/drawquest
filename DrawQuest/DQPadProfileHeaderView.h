//
//  DQPadProfileHeaderView.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQFollowConstants.h"

@class DQImageView;
@class DQProfileInfoView;
@class DQPhoneFollowButton;

@interface DQPadProfileHeaderView : UIView

@property (nonatomic, strong) DQImageView *userImageView;
@property (nonatomic, strong) DQProfileInfoView *nameView;
@property (nonatomic, strong) DQProfileInfoView *followersView;
@property (nonatomic, strong) DQProfileInfoView *followingView;
@property (nonatomic, strong) UIImageView *bioBackgroundView;

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *coinImageView;
@property (nonatomic, strong) UILabel *coinsLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UIView *bio;
@property (nonatomic, strong) NSString *bioText;
@property (nonatomic, strong) UIButton *drawingsButton;
@property (nonatomic, strong) UIButton *followersButton;
@property (nonatomic, strong) UIButton *followingButton;

@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *inviteFriendsButton;
@property (nonatomic, strong) DQPhoneFollowButton *followButton;

@property (nonatomic, strong) UIView *socialButtonsView;

@property (nonatomic, copy) void(^showShopBlock)(DQPadProfileHeaderView *headerView);

@property (nonatomic) BOOL isForLoggedInUser;

@end
