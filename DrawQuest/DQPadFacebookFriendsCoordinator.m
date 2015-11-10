//
//  DQPadFacebookFriendsCoordinator.m
//  DrawQuest
//
//  Created by David Mauro on 10/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadFacebookFriendsCoordinator.h"

#import "DQCellCheckmarkView.h"

#import "UIView+STAdditions.h"

@implementation DQPadFacebookFriendsCoordinator

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController AtIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    DQCellCheckmarkView *cellCheckmarkView = [[DQCellCheckmarkView alloc] initWithLabelText:DQLocalizedStringWithDefaultValue(@"FollowingStatusLabel", nil, nil, @"Following", @"Label that confirms a user is following another user")];
    cellCheckmarkView.tappedBlock = ^(DQCellCheckmarkView *checkmarkView) {
        [weakSelf.selectedFriends removeIndex:index];
        [weakSelf.defaultToFollowFriends removeIndex:index];
        [friendListViewController reloadAccessoryViewAtIndex:index];
    };
    return cellCheckmarkView;
}

- (UIView *)accessoryViewForFriendsInvitedAtIndex:(NSInteger)index
{
    NSString *text = nil;
    if (index < [self.friendsOnDrawQuest count])
    {
        text = DQLocalizedStringWithDefaultValue(@"FollowingStatusLabel", nil, nil, @"Following", @"Label that confirms a user is following another user");
    }
    else
    {
        text = DQLocalizedString(@"Invited", @"User has been invited to DrawQuest indicator label");
    }
    DQCellCheckmarkView *cellCheckmarkView = [[DQCellCheckmarkView alloc] initWithLabelText:text];
    return cellCheckmarkView;
}

- (UIControl *)accessoryViewForFriendsNotInvitedAtIndex:(NSInteger)index
{
    DQButton *checkbox = [DQButton buttonWithType:UIButtonTypeCustom];
    [checkbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty"] forState:UIControlStateNormal];
    [checkbox setBackgroundImage:[UIImage imageNamed:@"checkbox_checked"] forState:UIControlStateSelected];
    checkbox.boundsSize = [checkbox backgroundImageForState:UIControlStateNormal].size;
    __weak typeof(self) weakSelf = self;
    checkbox.tappedBlock = ^(DQButton *button) {
        [weakSelf tappedFriendAtIndex:index accessoryView:button];
    };
    checkbox.selected = [self.selectedFriends containsIndex:index];
    return checkbox;
}

- (DQButton *)friendListViewController:(DQFriendListViewController *)friendListViewController requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock
{
    DQButton *facebookButton = [DQButton buttonWithType:UIButtonTypeCustom];
    UIImage *facebookButtonImage = [UIImage imageNamed:@"button_facebook_long"];
    [facebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
    facebookButton.frame = CGRectMake(0.0, 0.0, facebookButtonImage.size.width, facebookButtonImage.size.height);
    facebookButton.tappedBlock = tappedBlock;
    return facebookButton;
}

@end
