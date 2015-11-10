//
//  DQPhoneFacebookFriendsCoordinator.m
//  DrawQuest
//
//  Created by David Mauro on 10/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneFacebookFriendsCoordinator.h"

#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@implementation DQPhoneFacebookFriendsCoordinator

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController AtIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    DQButton *followButton = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_following"]];
    followButton.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
    followButton.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    followButton.tappedBlock = ^(DQButton *button) {
        [weakSelf.selectedFriends removeIndex:index];
        [weakSelf.defaultToFollowFriends removeIndex:index];
        // This will be replace by a checkmark so no need to restyle it.
        [friendListViewController reloadAccessoryViewAtIndex:index];
    };
    followButton.layer.cornerRadius = 5.0f;
    followButton.tintColorForBackground = YES;
    return followButton;
}

- (UIView *)accessoryViewForFriendsInvitedAtIndex:(NSInteger)index
{
    DQButton *followButton = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_following"]];
    followButton.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
    followButton.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    followButton.layer.cornerRadius = 4.0f;
    followButton.tintColorForBackground = YES;
    return followButton;
}

- (UIControl *)accessoryViewForFriendsNotInvitedAtIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    DQButton *checkbox = [DQButton buttonWithImage:nil selectedImage:[UIImage imageNamed:@"add_friends_facebook_checkmark"]];
    checkbox.layer.cornerRadius = 4.0f;
    checkbox.frameWidth = kDQFormPhoneAddFriendsAccessoryHeight;
    checkbox.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    checkbox.tappedBlock = ^(DQButton *button) {
        [weakSelf tappedFriendAtIndex:index accessoryView:button];
    };
    checkbox.selectedBlock = ^(DQButton *button, BOOL isSelected) {
        button.tintColorForBackground = isSelected;
        if ( ! isSelected)
        {
            button.backgroundColor = [UIColor dq_phoneButtonOffColor];
        }
    };
    checkbox.selected = [self.selectedFriends containsIndex:index];
    return checkbox;
}

- (DQButton *)friendListViewController:(DQFriendListViewController *)friendListViewController requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock
{
    DQButton *facebookButton = [DQButton buttonWithImage:[UIImage imageNamed:@"button_facebook_long"]];
    facebookButton.tappedBlock = tappedBlock;
    return facebookButton;
}

@end
