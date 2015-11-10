//
//  DQPhoneTwitterFriendsCoordinator.m
//  DrawQuest
//
//  Created by David Mauro on 10/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneTwitterFriendsCoordinator.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@implementation DQPhoneTwitterFriendsCoordinator

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    DQButton *followButton = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_following"]];
    followButton.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
    followButton.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    followButton.tappedBlock = ^(DQButton *button) {
        [weakSelf.selectedFriends removeIndex:index];
        // Reload accessory instead of updating button
        [friendListViewController reloadAccessoryViewAtIndex:index];
    };
    followButton.layer.cornerRadius = 5.0f;
    followButton.tintColorForBackground = YES;
    return followButton;
}

- (UIView *)accessoryViewForFriendsInvitedWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
{
    DQButton *followButton = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_following"]];
    followButton.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
    followButton.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    followButton.layer.cornerRadius = 4.0f;
    followButton.tintColorForBackground = YES;
    return followButton;
}

- (UIControl *)accessoryViewForFriendsNotInvitedWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    DQButton *button = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_follow"]];;
    button.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
    button.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    button.layer.cornerRadius = 4.0f;
    button.backgroundColor = [UIColor dq_phoneButtonOffColor];
    void (^buttonTappedBlock)(DQButton *button, UIActivityIndicatorView *spinner) = NULL;

    // Follow Button
    if (index < [self.friendsOnDrawQuest count])
    {
        buttonTappedBlock = ^(DQButton *button, UIActivityIndicatorView *spinner) {
            [weakSelf followUserAtIndex:index withCompletionBlock:^(DQHTTPRequest *request) {
                [spinner removeFromSuperview];
                DQButton *button = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_following"]];;
                button.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
                button.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
                button.layer.cornerRadius = 4.0f;
                button.tintColorForBackground = YES;
                [friendListViewController replaceAccessoryViewAtIndex:index withView:button];
            }];
        };
    }
    // Invite Button
    else
    {
        buttonTappedBlock = ^(DQButton *button, UIActivityIndicatorView *spinner) {
            [weakSelf inviteUserAtIndex:index withCompletionBlock:^(DQHTTPRequest *request) {
                [spinner removeFromSuperview];
                weakSelf.invitesSent += 1;
                DQButton *button = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_following"]];;
                button.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
                button.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
                button.layer.cornerRadius = 4.0f;
                button.tintColorForBackground = YES;
                [friendListViewController replaceAccessoryViewAtIndex:index withView:button];
            } failureBlock:^(NSError *error) {
                // Flip back to not invited so we can invite again, and put button back
                [self.followingOrInvitedFriends removeIndex:index];
                [friendListViewController replaceAccessoryViewAtIndex:index withView:button];
                [spinner removeFromSuperview];
                button.enabled = YES;
                NSString *twitterUsername = [[weakSelf.friends objectAtIndex:index] valueForKey:@"screen_name"];
                NSString *title = [NSString stringWithFormat:@"%@ %@", DQLocalizedString(@"Error sending invite to:", @"Invite error to user error title prefix"), twitterUsername];
                NSString *message = [NSString stringWithFormat:@"%@: %@", DQLocalizedString(@"There was a problem sending your invitation via Twitter. Error code:", @"Invite error to user error message prefix"), error];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alertView show];
            }];
        };
    }

    button.tappedBlock = ^(DQButton *button) {
        [self.followingOrInvitedFriends addIndex:index];

        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.backgroundColor = [UIColor clearColor];
        spinner.frame = button.frame;
        spinner.hidden = NO;
        [spinner startAnimating];
        button.enabled = NO;
        [button.superview addSubview:spinner];

        buttonTappedBlock(button, spinner);
    };

    return button;
}

@end
