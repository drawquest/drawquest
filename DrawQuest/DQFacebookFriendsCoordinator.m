//
//  DQFacebookFriendsCoordinator.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/18/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFacebookFriendsCoordinator.h"

// Frameworks
#import <FacebookSDK/FacebookSDK.h>

// Controllers
#import "DQPadFacebookFriendsCoordinator.h"
#import "DQPhoneFacebookFriendsCoordinator.h"
#import "DQPrivateServiceController.h"
#import "DQPapertrailLogger.h"

// View Controllers
#import "DQFriendListViewController.h"

// Views
#import "DQButton.h"
#import "DQCellCheckmarkView.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIButton+DQAdditions.h"
#import "DQAnalyticsConstants.h"
#import "UIView+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

NSString *DQFacebookFriendsCoordinatorErrorDomain = @"DQFacebookFriendsCoordinatorErrorDomain";
const NSInteger DQFacebookFriendsCoordinatorUnknownErrorCode = 1000;

static const NSInteger kDQAddFriendsMaxSelectedFriends = 50;

@interface DQFacebookFriendsCoordinator ()

@property (nonatomic, strong) DQFacebookController *facebookController;
@property (nonatomic, strong, readwrite) DQPrivateServiceController *privateServiceController;
@property (nonatomic, strong, readwrite) NSMutableIndexSet *defaultToFollowFriends;
@property (nonatomic, strong) NSString *invitationMessage;

@end

@implementation DQFacebookFriendsCoordinator

- (id)initWithFacebookController:(DQFacebookController *)facebookController privateServiceController:(DQPrivateServiceController *)privateServiceController
{
    if ([self class] == [DQFacebookFriendsCoordinator class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadFacebookFriendsCoordinator alloc] initWithFacebookController:facebookController privateServiceController:privateServiceController];
        }
        else
        {
            self = [[DQPhoneFacebookFriendsCoordinator alloc] initWithFacebookController:facebookController privateServiceController:privateServiceController];
        }
    }
    else
    {
        self = [super init];
        if (self)
        {
            _facebookController = facebookController;
            _privateServiceController = privateServiceController;
            _selectedFriends = [[NSMutableIndexSet alloc] init];
            _followingOrInvitedFriends = [[NSMutableIndexSet alloc] init];
            _defaultToFollowFriends = [[NSMutableIndexSet alloc] init];
        }
    }
    return self;
}

#pragma mark - DQFriendListViewControllerDataSource

- (NSString *)emptyFriendListMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"It looks like you don't have any Facebook friends to invite.", @"The user has no Facebook friends message");
}

- (NSString *)authorizationRequestMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"Connect with Facebook to see your list of friends.\nThen choose friends you'd like to add.", @"Facebook authorization and invite prompt");
}

- (NSString *)authorizationFailedMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"Authorization with Facebook failed. Please try again.", @"Facebook authorization failed, retry prompt");
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
    NSNumber *friendID = [[self.friends objectAtIndex:index] numberForKey:@"id"];
    NSString *avatarImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal", friendID];
    return avatarImageURL;
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController dqUsernameAtIndex:(NSUInteger)index
{
    NSNumber *friendID = [[self.friends objectAtIndex:index] numberForKey:@"id"];
    return [[self.friendsOnDrawQuest objectForKey:[friendID stringValue]] objectForKey:@"username"];
}

- (NSUInteger)numberOfInvitesSentOrPendingForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    NSUInteger result = 0;
    NSUInteger numberOfFriendsOnDrawQuest = [self.friendsOnDrawQuest count];
    NSUInteger numberOfFriends = [self.friends count];
    if (numberOfFriends)
    {
        result = [self.selectedFriends countOfIndexesInRange:NSMakeRange(numberOfFriendsOnDrawQuest, numberOfFriends - numberOfFriendsOnDrawQuest)];
    }
    return result;
}

#pragma mark - DQFriendListViewControllerDelegate

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController hasPermissionsWithCompletionBlock:(void (^)(BOOL))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    if (completionBlock)
    {
        completionBlock([self.facebookController hasOpenFacebookSession]);
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController requestPermissionsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock fromView:(UIView *)view
{
    [self.facebookController requestFacebookAccessForFeature:@"fb-friends-coordinator" readPermissions:@[@"email"] publishPermissions:nil cancellationBlock:cancellationBlock completionBlock:^(NSString *facebookToken) {
        if (completionBlock)
        {
            completionBlock();
        }
    } failureBlock:failureBlock];
    if (accountSelectedBlock)
    {
        accountSelectedBlock();
    }
}

- (DQButton *)friendListViewController:(DQFriendListViewController *)friendListViewController requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock
{
    // Subclasses override
    return [DQButton new];
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController loadFriendsWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock noFriendsBlock:(dispatch_block_t)noFriendsBlock
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
        __weak __block FBRequestConnection *facebookFriendsConnection = nil;
        __weak __block DQHTTPRequest *facebookFriendsOnDrawQuestRequest = nil;

        __block NSError *facebookFriendsError = nil;
        __block NSError *facebookFriendsOnDrawQuestError = nil;

        dispatch_block_t errorBlock = ^{
            if ( ! (facebookFriendsConnection || facebookFriendsOnDrawQuestRequest))
            {
                // both requests have completed, and the second one failed, calling errorBlock
                // or, the first one failed and the second one completed but dataReceivedBlock
                // called errorBlock because it noticed that one of the errors was set
                if (failureBlock)
                {
                    if (facebookFriendsError)
                    {
                        failureBlock(facebookFriendsError);
                    }
                    else
                    {
                        // this really shouldn't happen because this is only called if one of those errors is
                        // set to a non-nil value, so this message should never see the user. Included for the
                        // sake of completeness and so that if you DO see this error, you can find it in the
                        // source and fix the bug
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
                        NSError *error = [NSError errorWithDomain:DQFacebookFriendsCoordinatorErrorDomain code:DQFacebookFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                        failureBlock(error);
                    }
                }
            }
        };

        dispatch_block_t dataReceivedBlock = ^{
            if ( ! (facebookFriendsConnection || facebookFriendsOnDrawQuestRequest))
            {
                // both requests have completed, and the second one to complete did not fail
                // but the first one might have, so check first
                if (facebookFriendsError)
                {
                    errorBlock();
                }
                else
                {
                    if ([weakSelf.friends count])
                    {
                        NSMutableArray *drawQuestFriends = [NSMutableArray new];
                        NSMutableArray *facebookFriends = [NSMutableArray new];
                        
                        NSMutableArray *alphaSortFriends = [NSMutableArray arrayWithArray:weakSelf.friends];
                        NSSortDescriptor *alphaSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                        [alphaSortFriends sortUsingDescriptors:[NSArray arrayWithObject:alphaSort]];
                        
                        for (NSDictionary *friend in alphaSortFriends)
                        {
                            if (weakSelf.friendsOnDrawQuest[[friend[@"id"] description]])
                            {
                                [drawQuestFriends addObject:friend];
                                NSUInteger index = [drawQuestFriends count] - 1;
                                [weakSelf.selectedFriends addIndex:index];
                                if ([weakSelf.friendsOnDrawQuest[friend[@"id"]] boolForKey:@"viewer_is_following"])
                                {
                                    [weakSelf.followingOrInvitedFriends addIndex:index];
                                }
                                else
                                {
                                    [weakSelf.defaultToFollowFriends addIndex:index];
                                }
                            }
                            else
                            {
                                [facebookFriends addObject:friend];
                            }
                        }

                        weakSelf.friends = [drawQuestFriends arrayByAddingObjectsFromArray:facebookFriends];
                        
                        if (completionBlock)
                        {
                            if (weakSelf.messageForInviteBlock)
                            {
                                weakSelf.messageForInviteBlock(DQAPIValueShareChannelTypeFacebook, ^void(NSString *message) {
                                    weakSelf.invitationMessage = message;
                                    completionBlock();
                                });
                            }
                            else
                            {
                                @throw [NSException exceptionWithName:NSGenericException reason:@"DQFacebookFriendsCoordinator: messageForInviteBlock not defined." userInfo:nil];
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

        // Friends on Facebook Request
        NSString *facebookToken = [self.facebookController openFacebookSessionAccessToken];
        [DQPapertrailLogger component:@"facebook-friends-coordinator" category:@"request-my-friends" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"token": facebookToken ?: [NSNull null]};
        }];
        facebookFriendsConnection = [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            // Just to be safe that we're on the main thread
            dispatch_async(dispatch_get_main_queue(), ^ {
                facebookFriendsConnection = nil;
                if (error)
                {
                    [DQPapertrailLogger component:@"facebook-friends-coordinator" category:@"request-my-friends-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                        return @{@"token": facebookToken ?: [NSNull null],
                                 @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                 @"category": @([error fberrorCategory])};
                    }];
                    facebookFriendsError = error;
                    errorBlock();
                }
                else
                {
                    weakSelf.friends = [(NSDictionary *)result objectForKey:@"data"];
                    dataReceivedBlock();
                }
            });
        }];

        // Facebook friends on DrawQuest Request
        facebookFriendsOnDrawQuestRequest = [self.privateServiceController requestFacebookFriendsOnDrawQuestWithFacebookToken:facebookToken completionBlock:^(DQHTTPRequest *request, id JSONObject, NSArray *userList) {
            facebookFriendsOnDrawQuestRequest = nil;
            if (userList)
            {
                NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:[userList count]];
                if ([userList count])
                {
                    for (NSDictionary *userDict in userList)
                    {
                        map[[userDict[@"fb_uid"] stringValue]] = userDict;
                    }
                }
                weakSelf.friendsOnDrawQuest = map;
                dataReceivedBlock();
            }
            else
            {
                if (request.error)
                {
                    facebookFriendsOnDrawQuestError = request.error;
                }
                else
                {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred communicating with DrawQuest", @"Unknown DrawQuest error message")};
                    facebookFriendsOnDrawQuestError = [NSError errorWithDomain:DQFacebookFriendsCoordinatorErrorDomain code:DQFacebookFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                }
                weakSelf.friendsOnDrawQuest = @{};
                dataReceivedBlock();
            }
        }];
    }
}

- (UIView *)friendListViewController:(DQFriendListViewController *)friendListViewController accessoryViewAtIndex:(NSUInteger)index
{
    // Default to following DQ friends get a checkmark view that can be deselected
    if ([self.defaultToFollowFriends containsIndex:index])
    {
        return [self accessoryViewForFriendsOnDrawQuestWithFriendListViewController:friendListViewController AtIndex:index];
    }
    // Users we've already followed or invited get a regular checkmark view
    else if ([self.followingOrInvitedFriends containsIndex:index])
    {
        return [self accessoryViewForFriendsInvitedAtIndex:index];
    }
    // Otherwise show the checkbox
    else
    {
        return [self accessoryViewForFriendsNotInvitedAtIndex:index];
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController didSelectFriendAtIndex:(NSUInteger)index accessoryView:(UIView *)accessoryView
{
    [self tappedFriendAtIndex:index accessoryView:accessoryView];
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController sendPendingRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{

    __weak typeof(self) weakSelf = self;
    __block BOOL fbWebDialog = YES;
    __weak __block DQHTTPRequest *followRequest = nil;

    __block NSError *facebookFollowUsersError = nil;
    __block NSError *facebookDialogError = nil;

    __block BOOL cancelled = NO;
    dispatch_block_t cancelledBlock = ^{
        if (cancellationBlock)
        {
            cancellationBlock();
        }
    };

    dispatch_block_t errorBlock = ^{
        if ( ! (cancelled || fbWebDialog || followRequest))
        {
            // both requests have completed, and the second one failed, calling errorBlock
            // or, the first one failed and the second one completed but finishedRequests
            // called errorBlock because it noticed that one of the errors was set
            if (failureBlock)
            {
                if (facebookFollowUsersError)
                {
                    failureBlock(facebookFollowUsersError);
                }
                else if (facebookDialogError)
                {
                    failureBlock(facebookDialogError);
                }
                else
                {
                    // this really shouldn't happen because this is only called if one of those errors is
                    // set to a non-nil value, so this message should never see the user. Included for the
                    // sake of completeness and so that if you DO see this error, you can find it in the
                    // source and fix the bug
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
                    NSError *error = [NSError errorWithDomain:DQFacebookFriendsCoordinatorErrorDomain code:DQFacebookFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                    failureBlock(error);
                }
            }
        }
    };

    dispatch_block_t finishedRequests = ^{
        if ( ! (cancelled || fbWebDialog || followRequest))
        {
            // both requests have completed, and the second one to complete did not fail
            // but the first one might have, so check first
            if (facebookFollowUsersError || facebookDialogError)
            {
                errorBlock();
            }
            else
            {
                weakSelf.followingOrInvitedFriends = weakSelf.selectedFriends;
                weakSelf.selectedFriends = [[NSMutableIndexSet alloc] init];

                if (completionBlock)
                {
                    completionBlock();
                }
            }
        }
    };

    // Follow on DrawQuest Request
    NSUInteger numberOfFriendsOnDrawQuest = [self.friendsOnDrawQuest count];
    if (numberOfFriendsOnDrawQuest)
    {
        NSIndexSet *set = [self.selectedFriends indexesInRange:NSMakeRange(0, numberOfFriendsOnDrawQuest) options:NSEnumerationConcurrent passingTest:^(NSUInteger idx, BOOL *stop) { return YES; }];
        NSArray *selectedFriendsToFollow = [[self.friends objectsAtIndexes:set] valueForKey:@"id"];
        NSArray *defaultFriendsToFollow = [[self.friends objectsAtIndexes:self.defaultToFollowFriends] valueForKey:@"id"];
        NSArray *facebookFriendIDsToFollow = [selectedFriendsToFollow arrayByAddingObjectsFromArray:defaultFriendsToFollow];

        if ([facebookFriendIDsToFollow count])
        {
            NSMutableArray *toFollow = [[NSMutableArray alloc] initWithCapacity:[facebookFriendIDsToFollow count]];
            for (NSString *facebookUserID in facebookFriendIDsToFollow)
            {
                [toFollow addObject:self.friendsOnDrawQuest[facebookUserID][@"username"]];
            }
            NSArray *drawQuestUsernamesToFollow = [NSArray arrayWithArray:toFollow];

            [self.facebookController logEvent:DQAnalyticsEventFollow withParameters:@{@"source": @"Add-Friends"}];
            followRequest = [self.privateServiceController requestFollowForUsersWithNames:drawQuestUsernamesToFollow completionBlock:^(DQHTTPRequest *request, id JSONObject) {
                followRequest = nil;
                if (JSONObject)
                {
                    finishedRequests();
                }
                else if (request.error)
                {
                    facebookFollowUsersError = request.error;
                    errorBlock();
                }
                else // in the strange case that userList is nil and request.error is too, we still need an error to trigger the failureBlock
                {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred communicating with DrawQuest", @"Unknown DrawQuest error message")};
                    facebookFollowUsersError = [NSError errorWithDomain:DQFacebookFriendsCoordinatorErrorDomain code:DQFacebookFriendsCoordinatorUnknownErrorCode userInfo:userInfo];
                    errorBlock();
                }
            }];
        }
        else
        {
            finishedRequests();
        }
    }
    else
    {
        finishedRequests();
    }

    // Invite Request
    NSArray *facebookFriendIDsToInvite = [self facebookFriendIDsToInvite];
    if ([facebookFriendIDsToInvite count])
    {
        NSDictionary *params = @{@"to": [facebookFriendIDsToInvite componentsJoinedByString:@","] ?: @""};

        NSString *facebookToken = [self.facebookController openFacebookSessionAccessToken];
        [DQPapertrailLogger component:@"facebook-friends-coordinator" category:@"present-requests-dialog" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"token": facebookToken ?: [NSNull null],
                     @"message": self.invitationMessage ?: [NSNull null],
                     @"params": params ?: [NSNull null]};
        }];
        __weak typeof(self) weakSelf = self;
        [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:self.invitationMessage title:DQLocalizedString(@"Invite your friends!", @"Invite friends prompt message") parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
            fbWebDialog = NO;
            if (error)
            {
                [DQPapertrailLogger component:@"facebook-friends-coordinator" category:@"present-requests-dialog-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"token": facebookToken ?: [NSNull null],
                             @"message": weakSelf.invitationMessage ?: [NSNull null],
                             @"params": params ?: [NSNull null],
                             @"result": @(result),
                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                             @"category": @([error fberrorCategory])};
                }];
                facebookDialogError = error;
                errorBlock();
            }
            else if (result == FBWebDialogResultDialogNotCompleted)
            {
                cancelled = YES;
                cancelledBlock();
            }
            else
            {
                // Handle the send request callback
                NSDictionary *urlParams = [self parseFBURLParams:[resultURL query]];
                if (![urlParams valueForKey:@"request"]) {
                    // FIXME: the other requests might not be complete yet!
                    cancelled = YES;
                    cancelledBlock();
                } else {
                    // User clicked the Send button
                    finishedRequests();
                }
            }
        }];
    }
    else
    {
        fbWebDialog = NO;
        finishedRequests();
    }
}

#pragma mark - Actions

- (NSArray *)facebookFriendIDsToInvite
{
    NSArray *result = [NSArray array];
    NSUInteger numberOfFriends = [self.friends count];
    if (numberOfFriends)
    {
        NSUInteger numberOfFriendsOnDrawQuest = [self.friendsOnDrawQuest count];
        NSIndexSet *set = [self.selectedFriends indexesInRange:NSMakeRange(numberOfFriendsOnDrawQuest, numberOfFriends - numberOfFriendsOnDrawQuest) options:NSEnumerationConcurrent passingTest:^(NSUInteger idx, BOOL *stop) { return YES; }];
        result = [[self.friends objectsAtIndexes:set] valueForKey:@"id"];
    }
    return result;
}

- (void)tappedFriendAtIndex:(NSUInteger)index accessoryView:(UIView *)accessoryView
{
    if ( ! [self.defaultToFollowFriends containsIndex:index] && ! [self.followingOrInvitedFriends containsIndex:index])
    {
        UIControl *checkbox = (UIControl *)accessoryView;
        if ([self.selectedFriends containsIndex:index])
        {
            [self.selectedFriends removeIndex:index];
            checkbox.selected = NO;
        }
        else if ([[self facebookFriendIDsToInvite] count] < kDQAddFriendsMaxSelectedFriends)
        {
            [self.selectedFriends addIndex:index];
            checkbox.selected = YES;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:DQLocalizedString(@"Sorry, but you can't select more than 50 friends to invite at once.", @"Message explaining that the user can only invite 50 or less friends at one time") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
        }
    }
}

#pragma mark - Helpers

- (NSDictionary*)parseFBURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

@end
