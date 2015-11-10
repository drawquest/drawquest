//
//  DQPhoneProfileHeaderView.h
//  DrawQuest
//
//  Created by David Mauro on 10/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DQImageView.h"
#import "DQPhoneCoinsLabel.h"
#import "DQPhoneFollowButton.h"

extern NSString *const DQPhoneProfileHeaderViewSocialTypeFacebook;
extern NSString *const DQPhoneProfileHeaderViewSocialTypeTwitter;
extern NSString *const DQPhoneProfileHeaderViewSocialTypeDrawQuest;
extern NSString *const DQPhoneProfileHeaderViewSocialTypeTumblr;

@interface DQPhoneProfileHeaderView : UIView

@property (nonatomic, strong, readonly) DQImageView *avatarImageView;
@property (nonatomic, strong, readonly) UILabel *usernameLabel;
@property (nonatomic, strong, readonly) UILabel *bioLabel;
@property (nonatomic, strong, readonly) DQPhoneCoinsLabel *coinsLabel;
@property (nonatomic, strong, readonly) DQPhoneFollowButton *followButton;
@property (nonatomic, copy) void(^showShopBlock)(DQPhoneProfileHeaderView *headerView);

- (void)setURL:(NSString *)inURL forSocialType:(NSString *const)inType showWhenInactive:(BOOL)showWhenInactive;
- (void)displayFollowButton:(BOOL)displayFollowButton forUsername:(NSString *)username;

@end
