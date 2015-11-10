//
//  DQPadTwitterFriendsCoordinator.m
//  DrawQuest
//
//  Created by David Mauro on 10/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadTwitterFriendsCoordinator.h"

// Controllers
#import "DQPublicServiceController.h"

// Views
#import "DQCellCheckmarkView.h"

// Additions
#import "UIButton+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

@implementation DQPadTwitterFriendsCoordinator

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    DQCellCheckmarkView *cellCheckmarkView = [[DQCellCheckmarkView alloc] initWithLabelText:DQLocalizedStringWithDefaultValue(@"FollowingStatusLabel", nil, nil, @"Following", @"Label that confirms a user is following another user")];
    cellCheckmarkView.tappedBlock = ^(DQCellCheckmarkView *checkmarkView) {
        [weakSelf.selectedFriends removeIndex:index];
        [friendListViewController reloadAccessoryViewAtIndex:index];
    };
    return cellCheckmarkView;
}

- (UIView *)accessoryViewForFriendsInvitedWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
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

- (UIControl *)accessoryViewForFriendsNotInvitedWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
{
    DQButton *button = [DQButton dq_buttonForCellAction];
    NSString *buttonLabel = nil;
    void (^buttonTappedBlock)(DQButton *button, UIActivityIndicatorView *spinner) = NULL;

    __weak typeof(self) weakSelf = self;

    // Follow Button
    if (index < [self.friendsOnDrawQuest count])
    {
        buttonLabel = DQLocalizedString(@"Follow", @"Prompt to follow a user button title");

        buttonTappedBlock = ^(DQButton *button, UIActivityIndicatorView *spinner) {
            [weakSelf followUserAtIndex:index withCompletionBlock:^(DQHTTPRequest *request) {
                [spinner removeFromSuperview];
                DQCellCheckmarkView *checkmarkView = [[DQCellCheckmarkView alloc] initWithLabelText:DQLocalizedStringWithDefaultValue(@"FollowingStatusLabel", nil, nil, @"Following", @"Label that confirms a user is following another user")];
                [friendListViewController replaceAccessoryViewAtIndex:index withView:checkmarkView];
            }];
        };
    }
    // Invite Button
    else
    {
        buttonLabel = DQLocalizedString(@"Invite", @"Invite others to DrawQuest button title");

        buttonTappedBlock = ^(DQButton *button, UIActivityIndicatorView *spinner) {
            [weakSelf inviteUserAtIndex:index withCompletionBlock:^(DQHTTPRequest *request) {
                [spinner removeFromSuperview];
                weakSelf.invitesSent += 1;
                DQCellCheckmarkView *checkmarkView = [[DQCellCheckmarkView alloc] initWithLabelText:DQLocalizedString(@"Invited", @"User has been invited to DrawQuest indicator label")];
                [friendListViewController replaceAccessoryViewAtIndex:index withView:checkmarkView];
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

    [button setTitle:buttonLabel forState:UIControlStateNormal];
    return button;
}

@end
