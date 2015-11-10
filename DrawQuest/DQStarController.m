//
//  DQStarController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQStarController.h"
#import "DQDataStoreController.h"
#import "DQPrivateServiceController.h"
#import "DQActionSheet.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"
#import "STBasementViewController.h"

@interface DQStarController ()

@property (nonatomic, strong) NSMutableDictionary *map;

@end

@implementation DQStarController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQStarStateRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQSetStarStateRequestNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQUpdateStarStateRequestNotification object:nil];
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _map = [NSMutableDictionary new];
        // [self.dataStoreController populateStarStateMap:_map];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(starStateRequested:)
                                                     name:DQStarStateRequestNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setStarStateRequested:)
                                                     name:DQSetStarStateRequestNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateStarStateRequested:)
                                                     name:DQUpdateStarStateRequestNotification
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

- (void)starStateRequested:(NSNotification *)notification
{
    NSString *commentID = [notification object];
    DQStarStateResponseBlock block = [notification userInfo][DQStarStateRequestNotificationResponseBlockUserInfoKey];
    if (block)
    {
        if ([NSThread isMainThread])
        {
            DQStarState result = [self __starStateForCommentWithServerID:commentID];
            block(commentID, result);
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                DQStarState result = [self __starStateForCommentWithServerID:commentID];
                block(commentID, result);
            });
        }
    }
}

- (void)setStarStateRequested:(NSNotification *)notification
{
    // assumes [commentID length] > 0
    NSString *commentID = [notification object];
    DQStarState state = [[notification userInfo][DQStarStateNotificationStateUserInfoKey] integerValue];
    NSDictionary *eventLoggingParameters = [notification userInfo][DQStarStateNotificationEventLoggingParametersUserInfoKey];
    if (state != DQStarStateIndeterminate)
    {
        [self __requestStar:state forCommentWithServerID:commentID withEventLoggingParameters:eventLoggingParameters];
    }
}

- (void)updateStarStateRequested:(NSNotification *)notification
{
    // assumes [commentID length] > 0
    NSString *commentID = [notification object];
    DQStarState state = [[notification userInfo][DQStarStateNotificationStateUserInfoKey] integerValue];
    if ([NSThread mainThread])
    {
        [self __takeStarState:state forCommentWithServerID:commentID];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __takeStarState:state forCommentWithServerID:commentID];
        });
    }
}

#pragma mark -
#pragma mark Private API

// MUST BE CALLED FROM THE MAIN THREAD
- (DQStarState)__starStateForCommentWithServerID:(NSString *)commentID
{
    DQStarState result = DQStarStateIndeterminate;
    NSNumber *n = nil;
    n = commentID ? self.map[commentID] : nil;
    if (n)
    {
        result = [n boolValue] ? DQStarStateStarred : DQStarStateNotStarred;
    }
    else if (!self.loggedIn)
    {
        result = DQStarStateNotStarred;
    }
    // NSLog(@"READ: star state:%ld for %@", (long)result, commentID);
    return result;
}

// MUST BE CALLED FROM THE MAIN THREAD
- (void)__takeStarState:(DQStarState)state forCommentWithServerID:(NSString *)commentID
{
    // NSLog(@"given new star state:%ld for %@", (long)state, commentID);
    NSNumber *old = self.map[commentID];
    if (!old || ([old integerValue] != state))
    {
        // NSLog(@"updating star state:%ld for %@", (long)state, commentID);
        self.map[commentID] = @(state);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataStoreController setStarState:state forCommentWithServerID:commentID withTimestamp:nil];
        });
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
            @throw [NSException exceptionWithName:NSGenericException reason:@"DQStarController: basementViewController not provided." userInfo:nil];
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
            @throw [NSException exceptionWithName:NSGenericException reason:@"DQStarController: tabBarController not provided." userInfo:nil];
        }
    }
    return result;
}

- (void)__requestStar:(DQStarState)state forCommentWithServerID:(NSString *)commentID withEventLoggingParameters:(NSDictionary *)eventLoggingParameters
{
    // NSLog(@"requesting star:%ld for %@", (long)state, commentID);
    UIViewController *vc = [self __activeViewController];
    __weak typeof(self) weakSelf = self;
    dispatch_block_t revert = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            DQStarState state = [weakSelf __starStateForCommentWithServerID:commentID];
            NSDictionary *userInfo = @{DQStarStateNotificationStateUserInfoKey: @(state)};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQStarStateChangedNotification object:commentID userInfo:userInfo];
        });
    };
    [self requestAuthenticationFromViewController:vc withCancellationBlock:^{
        revert();
    } completionBlock:^(DQAuthenticationSignupService service, DQNavigationController *modalNavigationController) {
        DQServiceStatusBlock completionBlock = ^(DQHTTPRequest *request) {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:responseDictionary.dq_comments inBackground:YES resultsBlock:^(NSArray *objects) {
                // initializing the comment from JSON will cause it to request the
                // star state be updated, so nothing more needs to be done here
            }];
        };
        DQServiceStatusBlock failureBlock = ^(DQHTTPRequest *request) {
            revert();
        };
        if (state == DQStarStateNotStarred)
        {
            [weakSelf logEvent:DQAnalyticsEventUnstar withParameters:eventLoggingParameters];
            [weakSelf.privateServiceController requestUnstarOfCommentWithServerID:commentID completionBlock:completionBlock failureBlock:failureBlock];
        }
        else if (state == DQStarStateStarred)
        {
            [weakSelf logEvent:DQAnalyticsEventStar withParameters:eventLoggingParameters];
            [weakSelf.privateServiceController requestStarOfCommentWithServerID:commentID completionBlock:completionBlock failureBlock:failureBlock];
        }
    } failureBlock:^(NSError *error) {
        // FIXME: handle failure
        revert();
    }];
}

@end
