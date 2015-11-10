//
//  DQFollowController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFollowController.h"
#import "DQDataStoreController.h"
#import "DQPrivateServiceController.h"
#import "DQActionSheet.h"
#import "STBasementViewController.h"

@interface DQFollowController ()

@property (nonatomic, strong) NSMutableDictionary *map;

@end

@implementation DQFollowController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQFollowStateRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQSetFollowStateRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQUpdateFollowStateRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQUpdateManyFollowStatesRequestNotification object:nil];
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _map = [NSMutableDictionary new];
        // [self.dataStoreController populateFollowStateMap:_map];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(followStateRequested:)
                                                     name:DQFollowStateRequestNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setFollowStateRequested:)
                                                     name:DQSetFollowStateRequestNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateFollowStateRequested:)
                                                     name:DQUpdateFollowStateRequestNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateManyFollowStatesRequested:)
                                                     name:DQUpdateManyFollowStatesRequestNotification
                                                   object:nil];
    }
    return self;
}

- (void)reset
{
    self.map = [NSMutableDictionary new];
}

#pragma mark -
#pragma mark Notification Handlers

- (void)followStateRequested:(NSNotification *)notification
{
    NSString *username = [notification object];
    DQFollowStateResponseBlock block = [notification userInfo][DQFollowStateRequestNotificationResponseBlockUserInfoKey];
    if (block)
    {
        if ([NSThread isMainThread])
        {
            DQFollowState result = [self __followStateForUsername:username];
            block(username, result);
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                DQFollowState result = [self __followStateForUsername:username];
                block(username, result);
            });
        }
    }
}

- (void)setFollowStateRequested:(NSNotification *)notification
{
    // assumes [username length] > 0
    NSString *username = [notification object];
    DQFollowState state = [[notification userInfo][DQFollowStateNotificationStateUserInfoKey] integerValue];
    if (state != DQFollowStateIndeterminate)
    {
        if (state == DQFollowStateNotFollowing)
        {
            [self __confirmUnfollowUsername:username confirmBlocked:^{
                [self __requestFollow:state forUsername:username];
            }];
        }
        else
        {
            [self __requestFollow:state forUsername:username];
        }
    }
}

- (void)updateFollowStateRequested:(NSNotification *)notification
{
    // assumes [username length] > 0
    NSString *username = [notification object];
    DQFollowState state = [[notification userInfo][DQFollowStateNotificationStateUserInfoKey] integerValue];
    if ([NSThread mainThread])
    {
        [self __takeFollowState:state forUsername:username];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __takeFollowState:state forUsername:username];
        });
    }
}

- (void)updateManyFollowStatesRequested:(NSNotification *)notification
{
    NSDictionary *updates = [notification userInfo][DQFollowStateNotificationManyStatesUserInfoKey];
    if ([updates count])
    {
        if ([NSThread mainThread])
        {
            [self __takeManyFollowStates:updates];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self __takeManyFollowStates:updates];
            });
        }
    }
}

#pragma mark -
#pragma mark Private API

// MUST BE CALLED FROM THE MAIN THREAD
- (DQFollowState)__followStateForUsername:(NSString *)username
{
    DQFollowState result = DQFollowStateIndeterminate;
    NSNumber *n = nil;
    n = username ? self.map[username] : nil;
    if (n)
    {
        result = [n boolValue] ? DQFollowStateFollowing : DQFollowStateNotFollowing;
    }
    else if (!self.loggedIn)
    {
        result = DQFollowStateNotFollowing;
    }
    // NSLog(@"READ: follow state:%ld for %@", (long)result, username);
    return result;
}

// MUST BE CALLED FROM THE MAIN THREAD
- (void)__takeFollowState:(DQFollowState)state forUsername:(NSString *)username
{
    // NSLog(@"given new follow state:%ld for %@", (long)state, username);
    NSNumber *old = self.map[username];
    if (!old || ([old integerValue] != state))
    {
        // NSLog(@"updating follow state:%ld for %@", (long)state, username);
        self.map[username] = @(state);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataStoreController setFollowState:state forUsername:username withTimestamp:nil];
        });
    }
}

// MUST BE CALLED FROM THE MAIN THREAD
- (void)__takeManyFollowStates:(NSDictionary *)updates
{
    if ([updates count])
    {
        [self.map addEntriesFromDictionary:updates];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataStoreController setManyFollowStates:updates withTimestamp:nil];
        });
    }
}

- (void)__confirmUnfollowUsername:(NSString *)username confirmBlocked:(dispatch_block_t)confirmBlock
{
    __weak typeof(self) weakSelf = self;
    DQActionSheet *sheet = [[DQActionSheet alloc] initWithTitle:DQLocalizedString(@"Are you sure?", @"Destructive request alert confirmation title")
                                                       delegate:nil
                                              cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view")
                                         destructiveButtonTitle:[DQLocalizedString(@"Stop Following ", @"Stop following user alert confirmation button title") stringByAppendingString:username]
                                              otherButtonTitles:nil];
    sheet.dq_cancellationBlock = ^(DQActionSheet *sheet) {
        DQFollowState state = [weakSelf __followStateForUsername:username];
        NSDictionary *userInfo = @{DQFollowStateNotificationStateUserInfoKey: @(state)};
        [[NSNotificationCenter defaultCenter] postNotificationName:DQFollowStateChangedNotification object:username userInfo:userInfo];
    };
    sheet.dq_completionBlock = ^(DQActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == sheet.cancelButtonIndex)
        {
            DQFollowState state = [weakSelf __followStateForUsername:username];
            NSDictionary *userInfo = @{DQFollowStateNotificationStateUserInfoKey: @(state)};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQFollowStateChangedNotification object:username userInfo:userInfo];
        }
        else if (buttonIndex == sheet.destructiveButtonIndex)
        {
            if (confirmBlock)
            {
                confirmBlock();
            }
        }
    };
    if (self.tabBarController)
    {
        [sheet showFromTabBar:self.tabBarController.tabBar];
    }
    else
    {
        // FIXME: iPad support has not been tested as
        // we aren't using the follow button on iPad yet
        [sheet showInView:[self __activeViewController].view];
    }
}

- (UIViewController *)__activeViewController
{
    UIViewController *result = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (self.basementViewController)
        {
            result = self.basementViewController.topViewController;
            if ([result isKindOfClass:[UINavigationController class]])
            {
                UINavigationController *navigationController = (UINavigationController *)result;
                result = navigationController.topViewController;
                // you cannot star anything in a modal right now so we're good at this level
            }
        }
        else
        {
            @throw [NSException exceptionWithName:NSGenericException reason:@"DQFollowController: basementViewController not provided." userInfo:nil];
        }
    }
    else
    {
        if (self.tabBarController)
        {
            result = self.tabBarController.selectedViewController;
            if ([result isKindOfClass:[UINavigationController class]])
            {
                result = ((UINavigationController *)result).topViewController;
                NSUInteger max = 1000;
                while (--max && result.presentedViewController)
                {
                    result = result.presentedViewController;
                }
            }
        }
        else
        {
            @throw [NSException exceptionWithName:NSGenericException reason:@"DQFollowController: tabBarController not provided." userInfo:nil];
        }
    }
    return result;
}

- (void)__requestFollow:(DQFollowState)state forUsername:(NSString *)username
{
    // NSLog(@"requesting follow:%ld for %@", (long)state, username);
    UIViewController *vc = [self __activeViewController];
    __weak typeof(self) weakSelf = self;
    dispatch_block_t revert = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            DQFollowState state = [weakSelf __followStateForUsername:username];
            NSDictionary *userInfo = @{DQFollowStateNotificationStateUserInfoKey: @(state)};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQFollowStateChangedNotification object:username userInfo:userInfo];
        });
    };
    [self requestAuthenticationFromViewController:vc withCancellationBlock:^{
        revert();
    } completionBlock:^(DQAuthenticationSignupService service, DQNavigationController *modalNavigationController) {
        [weakSelf.privateServiceController requestFollow:state forUserWithName:username completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            if (JSONObject)
            {
                [weakSelf __takeFollowState:state forUsername:username];
            }
            else
            {
                // FIXME: show an alert?
                revert();
            }
        }];
    } failureBlock:^(NSError *error) {
        // FIXME: handle failure
        revert();
    }];
}

@end
