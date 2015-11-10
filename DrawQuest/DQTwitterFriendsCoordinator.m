//
//  DQTwitterFriendsCoordinator.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/18/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTwitterFriendsCoordinator.h"

// Controllers
#import "DQPadTwitterFriendsCoordinator.h"
#import "DQPhoneTwitterFriendsCoordinator.h"
#import "DQTwitterController.h"
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"

// View Controllers
#import "DQFriendListViewController.h"

// Views
#import "DQCellCheckmarkView.h"
#import "DQButton.h"

// Additions
#import "UIButton+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"

NSString *DQTwitterFriendsCoordinatorErrorDomain = @"DQTwitterFriendsCoordinatorErrorDomain";
const NSInteger DQTwitterFriendsCoordinatorUnknownErrorCode = 1000;

@interface DQTwitterFriendsCoordinator ()

@property (nonatomic, strong) DQTwitterController *twitterController;
@property (nonatomic, strong, readwrite) DQPublicServiceController *publicServiceController;
@property (nonatomic, strong, readwrite) DQPrivateServiceController *privateServiceController;
@property (nonatomic, strong, readwrite) NSMutableIndexSet *selectedFriends;
@property (nonatomic, strong) NSString *invitationMessage;

@end

@implementation DQTwitterFriendsCoordinator

- (instancetype)initWithTwitterController:(DQTwitterController *)twitterController publicServiceController:(DQPublicServiceController *)publicServiceController privateServiceController:(DQPrivateServiceController *)privateServiceController
{
    if ([self class] == [DQTwitterFriendsCoordinator class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadTwitterFriendsCoordinator alloc] initWithTwitterController:twitterController publicServiceController:publicServiceController privateServiceController:privateServiceController];
        }
        else
        {
            self = [[DQPhoneTwitterFriendsCoordinator alloc] initWithTwitterController:twitterController publicServiceController:publicServiceController privateServiceController:privateServiceController];
        }
    }
    else
    {
        self = [super init];
        if (self)
        {
            _twitterController = twitterController;
            _privateServiceController = privateServiceController;
            _publicServiceController = publicServiceController;
            _followingOrInvitedFriends = [[NSMutableIndexSet alloc] init];
            _selectedFriends = [[NSMutableIndexSet alloc] init];
        }
    }
    return self;
}

#pragma mark - DQFriendListViewControllerDataSource

- (NSString *)emptyFriendListMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"It looks like you don't have any Twitter friends to invite.", @"The user has no Twitter friends available to invite display message");
}

- (NSString *)authorizationRequestMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"Connect with Twitter to see your list of friends.\nThen choose friends you'd like to add.", @"Prompt to connect with Twitter to invite friends display message");
}

- (NSString *)authorizationFailedMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"Authorization with Twitter failed. Please try again.", @"Twitter authorization failed, prompt to try again");
}

- (NSUInteger)numberOfRowsInFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return [self.friends count];
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController displayNameAtIndex:(NSUInteger)index
{
    return [[self.friends objectAtIndex:index] valueForKey:@"name"];
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController avatarImageURLAtIndex:(NSUInteger)index
{
    return [[self.friends objectAtIndex:index] valueForKey:@"profile_image_url"];
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController dqUsernameAtIndex:(NSUInteger)index
{
    NSNumber *friendID = [[self.friends objectAtIndex:index] valueForKey:@"id"];
    return [[self.friendsOnDrawQuest objectForKey:friendID] objectForKey:@"username"];
}

- (NSUInteger)numberOfInvitesSentOrPendingForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return self.invitesSent;
}

#pragma mark - DQFriendListViewControllerDelegate

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController hasPermissionsWithCompletionBlock:(void (^)(BOOL))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.twitterController hasTwitterAccess:completionBlock failureBlock:failureBlock];
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController requestPermissionsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock fromView:(UIView *)view
{
    [self.twitterController requestTwitterAccessInView:view cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (DQButton *)friendListViewController:(DQFriendListViewController *)friendListViewController requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        DQButton *twitterButton = [DQButton buttonWithType:UIButtonTypeCustom];
        UIImage *twitterButtonImage = [UIImage imageNamed:@"button_twitter_long"];
        [twitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
        twitterButton.frame = CGRectMake(0.0, 0.0, twitterButtonImage.size.width, twitterButtonImage.size.height);
        twitterButton.tappedBlock = tappedBlock;
        return twitterButton;
    }
    else
    {
        DQButton *twitterButton = [DQButton buttonWithImage:[UIImage imageNamed:@"button_twitter_long"]];
        twitterButton.tappedBlock = tappedBlock;
        return twitterButton;
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController loadFriendsWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock noFriendsBlock:(dispatch_block_t)noFriendsBlock
{
    if ([self.friends count])
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        __block BOOL twitterFriendsRequestActive = YES;
        __weak __block DQHTTPRequest *twitterFollowersOnDrawQuestRequest = nil;

        __block NSError *twitterFriendsRequestError = nil;
        __block NSError * twitterFollowersOnDrawQuestError = nil;

        dispatch_block_t errorBlock = ^{
            if ( ! (twitterFriendsRequestActive || twitterFollowersOnDrawQuestRequest))
            {
                // both requests have completed, and the second one failed, calling errorBlock
                // or, the first one failed and the second one completed but dataReceivedBlock
                // called errorBlock because it noticed that one of the errors was set
                if (failureBlock)
                {
                    if (twitterFriendsRequestError)
                    {
                        failureBlock(twitterFriendsRequestError);
                    }
                    else
                    {
                        // this really shouldn't happen because this is only called if one of those errors is
                        // set to a non-nil value, so this message should never see the user. Included for the
                        // sake of completeness and so that if you DO see this error, you can find it in the
                        // source and fix the bug
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
                        NSError *error = [NSError errorWithDomain:DQTwitterFriendsCoordinatorErrorDomain code:DQTwitterFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                        failureBlock(error);
                    }
                }
            }
        };

        dispatch_block_t dataReceivedBlock = ^{
            if ( ! (twitterFriendsRequestActive || twitterFollowersOnDrawQuestRequest))
            {
                if (twitterFriendsRequestError)
                {
                    errorBlock();
                }
                else
                {
                    if ([weakSelf.friends count])
                    {
                        NSMutableArray *drawQuestFriends = [NSMutableArray new];
                        NSMutableArray *twitterFriends = [NSMutableArray new];
                        NSMutableDictionary *twitterFriendsOnDrawQuest = [NSMutableDictionary dictionary];

                        NSMutableArray *alphaSortFriends = [NSMutableArray arrayWithArray:weakSelf.friends];
                        NSSortDescriptor *alphaSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                        [alphaSortFriends sortUsingDescriptors:[NSArray arrayWithObject:alphaSort]];
                        
                        for (NSDictionary *friend in alphaSortFriends)
                        {
                            // We don't need the whole thing
                            NSDictionary *smallerFriend = [NSDictionary dictionaryWithObjectsAndKeys:friend[@"id"], @"id", friend[@"screen_name"], @"screen_name", friend[@"name"], @"name", friend[@"profile_image_url"], @"profile_image_url", nil];
                            if (weakSelf.followersOnDrawQuest[friend[@"id"]])
                            {
                                [drawQuestFriends addObject:smallerFriend];
                                twitterFriendsOnDrawQuest[friend[@"id"]] = weakSelf.followersOnDrawQuest[friend[@"id"]];
                                NSUInteger index = [drawQuestFriends count] - 1;
                                if ([weakSelf.followersOnDrawQuest[friend[@"id"]] boolForKey:@"viewer_is_following"])
                                {
                                    [weakSelf.followingOrInvitedFriends addIndex:index];
                                }
                                else
                                {
                                    [weakSelf.selectedFriends addIndex:index];
                                }
                            }
                            else
                            {
                                [twitterFriends addObject:smallerFriend];
                            }
                        }

                        weakSelf.friends = [drawQuestFriends arrayByAddingObjectsFromArray:twitterFriends];
                        weakSelf.followersOnDrawQuest = nil;
                        weakSelf.friendsOnDrawQuest = twitterFriendsOnDrawQuest;

                        if (completionBlock)
                        {
                            if (completionBlock)
                            {
                                if (weakSelf.messageForInviteBlock)
                                {
                                    weakSelf.messageForInviteBlock(DQAPIValueShareChannelTypeTwitter, ^void(NSString *message) {
                                        weakSelf.invitationMessage = message;
                                        completionBlock();
                                    });
                                }
                                else
                                {
                                    @throw [NSException exceptionWithName:NSGenericException reason:@"DQTwitterFriendsCoordinator: messageForInviteBlock not defined." userInfo:nil];
                                }
                            }
                        }
                    }
                    else
                    {
                        if (noFriendsBlock)
                        {
                            noFriendsBlock();
                        }
                    }
                }
            }
        };

        // Friends from Twitter Request
        [self.twitterController requestFriendsListForTwitterAccount:^(NSArray *friendsArray) {
            twitterFriendsRequestActive = NO;
            weakSelf.friends = friendsArray;
            dataReceivedBlock();
        } cancellationBlock:^{
            // Do nothing if canceled.
        } failureBlock:^(NSError *error) {
            if (error)
            {
                twitterFriendsRequestError = error;
                errorBlock();
            }
            else // in the strange case that userList is nil and request.error is too, we still need an error to trigger the failureBlock
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred communicating with Twitter", @"Unknown Twitter error alert message")};
                twitterFriendsRequestError = [NSError errorWithDomain:DQTwitterFriendsCoordinatorErrorDomain code:DQTwitterFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                errorBlock();
            }
        }];

        // Twitter friends on DrawQuest Request
        NSString *twitterToken = self.twitterController.twitterAccessToken;
        NSString *twitterSecret = self.twitterController.twitterAccessTokenSecret;

        twitterFollowersOnDrawQuestRequest = [self.privateServiceController requestTwitterFollowersOnDrawQuestWithTwitterToken:twitterToken twitterSecret:twitterSecret completionBlock:^(DQHTTPRequest *request, id JSONObject, NSArray *userList) {
            twitterFollowersOnDrawQuestRequest = nil;
            if (userList)
            {
                NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:[userList count]];
                if ([userList count])
                {
                    for (NSDictionary *userDict in userList)
                    {
                        map[userDict[@"twitter_uid"]] = userDict;
                    }
                }
                weakSelf.followersOnDrawQuest = map;
                dataReceivedBlock();
            }
            else
            {
                if (request.error)
                {
                    twitterFollowersOnDrawQuestError = request.error;
                }
                else // in the strange case that userList is nil and request.error is too, we still need an error to trigger the failureBlock
                {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred communicating with Twitter", @"Unknown Twitter error alert message")};
                    twitterFollowersOnDrawQuestError = [NSError errorWithDomain:DQTwitterFriendsCoordinatorErrorDomain code:DQTwitterFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                }
                weakSelf.followersOnDrawQuest = @{};
                dataReceivedBlock();
            }
        }];
    }
}

- (UIView *)friendListViewController:(DQFriendListViewController *)friendListViewController accessoryViewAtIndex:(NSUInteger)index
{
    // Default to following DQ friends get a checkmark view that can be deselected
    if ([self.selectedFriends containsIndex:index])
    {
        return [self accessoryViewForFriendsOnDrawQuestWithFriendListViewController:friendListViewController atIndex:index];
    }
    // If we're already following or have invited them, show a checkmark view
    else if ([self.followingOrInvitedFriends containsIndex:index])
    {
        return [self accessoryViewForFriendsInvitedWithFriendListViewController:friendListViewController atIndex:index];
    }
    // Otherwise show a follow or invite button
    else
    {
        return [self accessoryViewForFriendsNotInvitedWithFriendListViewController:friendListViewController atIndex:index];
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController didSelectFriendAtIndex:(NSUInteger)index accessoryView:(UIView *)accessoryView
{
    // Don't do anything when tapping a Twitter cell
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController sendPendingRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    // We only need to send follow requests for selected people
    if ([self.selectedFriends count])
    {
        NSArray *friendIDsToFollow = [[self.friends objectsAtIndexes:self.selectedFriends] valueForKey:@"id"];
        NSMutableArray *toFollow = [[NSMutableArray alloc] initWithCapacity:[friendIDsToFollow count]];
        for (NSString *userID in friendIDsToFollow)
        {
            [toFollow addObject:self.friendsOnDrawQuest[userID][@"username"]];
        }
        NSArray *drawQuestUsernamesToFollow = [NSArray arrayWithArray:toFollow];

        __weak typeof(self) weakSelf = self;
        [self.twitterController logEvent:DQAnalyticsEventFollow withParameters:@{@"source": @"Add-Friends"}];
        [self.privateServiceController requestFollowForUsersWithNames:drawQuestUsernamesToFollow completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            weakSelf.followingOrInvitedFriends = weakSelf.selectedFriends;
            weakSelf.selectedFriends = [[NSMutableIndexSet alloc] init];
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
    else if (completionBlock)
    {
        completionBlock();
    }
}

- (void)followUserAtIndex:(NSInteger)index withCompletionBlock:(void (^)(DQHTTPRequest *request))completionBlock
{
    NSNumber *friendID = [[self.friends objectAtIndex:index] valueForKey:@"id"];

    NSString *dqUsername = [[self.friendsOnDrawQuest objectForKey:friendID] objectForKey:@"username"];
    [self.twitterController logEvent:DQAnalyticsEventFollow withParameters:@{@"source": @"Add-Friends"}];
    [self.privateServiceController requestFollow:YES forUserWithName:dqUsername completionBlock:^(DQHTTPRequest *request, id JSONObject) {
        if (completionBlock)
        {
            completionBlock(request);
        }
    }];
}

- (void)inviteUserAtIndex:(NSInteger)index withCompletionBlock:(void (^)(DQHTTPRequest *request))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    NSNumber *friendID = [[self.friends objectAtIndex:index] valueForKey:@"id"];

    [self.twitterController sendDirectMessageForTwitterAccount:self.invitationMessage toUserID:[friendID stringValue] cancellationBlock:^{
        // We don't need to do anything here
    } completionBlock:^{
        [weakSelf.privateServiceController requestAddInvitedTwitterFriends:@[[friendID stringValue]] completionBlock:^(DQHTTPRequest *request) {
            if (completionBlock)
            {
                completionBlock(request);
            }
        }];
    } failureBlock:^(NSError *error) {
        if (failureBlock)
        {
            failureBlock(error);
        }
    }];
}

@end
