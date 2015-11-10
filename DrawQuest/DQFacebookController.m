//
//  DQFacebookController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-11.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFacebookController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "DQPapertrailLogger.h"
#import "DQPrivateServiceController.h"
#import "DQAccount.h"

NSString *DQFacebookErrorDomain = @"DQFacebookErrorDomain";
NSInteger DQFacebookErrorCodeCancelled = 1000;

@implementation DQFacebookController

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        /* From https://developers.facebook.com/docs/technical-guides/iossdk/session/
         The first time the app is launched, the FBSession class method,
         openActiveSessionWithPermissions:allowLoginUI:completionHandler: is called.
         The allowLoginUI is set to NO so that if a cached token is not found, then
         the login UI is not shown. However, if a cached token is found the session
         is opened without displaying the login UI. Any of the other openActiveSession*
         methods will trigger the same flow, as long as allowLoginUI is set to NO.
         */
        [FBSession openActiveSessionWithReadPermissions:@[@"email"] allowLoginUI:NO completionHandler:nil];

        /* Note: to support having multiple accounts signed in down the road...
         From https://developers.facebook.com/docs/technical-guides/iossdk/session/
         When the Facebook SDK manages the token data cache, it stores it in
         NSUserDefaults under a key named ''FBAccessTokenInformationKey''. You can
         modify they key where the data is stored by creating an instance of the
         FBSessionTokenCachingStrategy class using the initWithUserDefaultTokenInformationKeyName:
         method. You would pass in the key name that you wish to use and the Facebook SDK
         stores the token data under that key. Scenarios where this can be used is if
         you want to implement support for multiple logins to your app. This is typically
         the case with tablet apps. The SwitchUserSample app showcases this scenario
         where it shows how you can allow a certain number of users to log in to the
         app and stores each user's session data under a different key in NSUserDefaults.
         */
    }
    return self;
}

- (void)reset
{
    [[FBSession activeSession] closeAndClearTokenInformation];
    [FBSession.activeSession close];
    [FBSession setActiveSession:nil];
}

- (BOOL)hasOpenFacebookSession
{
    return [FBSession activeSession].isOpen;
}

- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions
{
    BOOL result = NO;
    if ([self hasOpenFacebookSession])
    {
        result = [[self openFacebookSessionPermissionsMissingFromPermissions:permissions] count] == 0;
    }
    return result;
}

- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
{
    NSArray *result = permissions;
    if ([self hasOpenFacebookSession])
    {
        NSSet *currentSet = [NSSet setWithArray:[FBSession activeSession].accessTokenData.permissions];
        NSMutableSet *remainderSet = [[NSMutableSet alloc] initWithArray:permissions];
        [remainderSet minusSet:currentSet];
        result = [remainderSet allObjects];
    }
    return result;
}

- (NSString *)openFacebookSessionAccessToken
{
    NSString *result = nil;
    if ([self hasOpenFacebookSession])
    {
        result = [FBSession activeSession].accessTokenData.accessToken;
    }
    return result;
}

- (NSError *)niceErrorForFacebookError:(NSError *)error
{
    NSError *result = error;
    if (result)
    {
        if ([self facebookErrorSignifiesCancellation:error])
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"The operation was cancelled.", @"User cancelled Facebook authorization message"),
                                       NSUnderlyingErrorKey: error};
            result = [NSError errorWithDomain:DQFacebookErrorDomain code:DQFacebookErrorCodeCancelled userInfo:userInfo];
        }
        else
        {
            NSDictionary *userInfo = [error userInfo];
            NSString *reason = userInfo[FBErrorLoginFailedReason];
            if ([reason length])
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [error fberrorUserMessage] ?: DQLocalizedString(@"An unknown error occurred communicating with Facebook. Please try again.", @"Unknown Facebook authorization error message"),
                                           NSUnderlyingErrorKey: error};
                result = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfo];
            }
        }
    }
    return result;
}

- (BOOL)facebookErrorSignifiesCancellation:(NSError *)error
{
    BOOL result = NO;
    if (error)
    {
        NSDictionary *userInfo = [error userInfo];
        NSString *reason = userInfo[FBErrorLoginFailedReason];
        return ([reason isEqualToString:FBErrorReauthorizeFailedReasonSessionClosed] ||
                ([error fberrorCategory] == FBErrorCategoryUserCancelled));
    }
    return result;
}

- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock;
{
    __weak typeof(self) weakSelf = self;
    void (^sessionOpenBlock)(BOOL) = ^(BOOL tokenChanged) { // only send token to the server if it has actually changed
        if (tokenChanged)
        {
            if (weakSelf.loggedIn)
            {
                NSString *facebookToken = [weakSelf openFacebookSessionAccessToken];
                [weakSelf.privateServiceController requestAssociateFacebookToken:facebookToken completionBlock:^(DQHTTPRequest *request, id JSONObject) {
                    if (completionBlock)
                    {
                        completionBlock(facebookToken);
                    }
                } failureBlock:^(DQHTTPRequest *request) {
                    if (failureBlock)
                    {
                        failureBlock(request.error);
                    }
                }];
            }
            else if (completionBlock)
            {
                NSString *facebookToken = [weakSelf openFacebookSessionAccessToken];
                completionBlock(facebookToken);
            }
        }
        else if (completionBlock)
        {
            NSString *facebookToken = [weakSelf openFacebookSessionAccessToken];
            completionBlock(facebookToken);
        }
    };

    void (^requestPublishPermissions)(BOOL) = ^(BOOL tokenChanged) {
        NSString *facebookToken = [self openFacebookSessionAccessToken];
        NSArray *missing = [self openFacebookSessionPermissionsMissingFromPermissions:publishPermissions];
        if ([missing count]) // need to extend the token
        {
            // dispatch_async because because the FacebookSDK may not have cleared some state yet in previous work in this iteration of the runloop
            dispatch_async(dispatch_get_main_queue(), ^{
                [DQPapertrailLogger component:@"facebook-controller" category:@"request-new-publish-permissions" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"feature": feature ?: [NSNull null],
                             @"permissions": missing ?: [NSNull null]};
                }];
                [[FBSession activeSession] requestNewPublishPermissions:missing defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error)
                        {
                            if ([weakSelf facebookErrorSignifiesCancellation:error] && cancellationBlock)
                            {
                                [DQPapertrailLogger component:@"facebook-controller" category:@"request-new-publish-permissions-cancelled" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                    return @{@"token": facebookToken ?: [NSNull null],
                                             @"feature": feature ?: [NSNull null],
                                             @"permissions": missing ?: [NSNull null],
                                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                             @"category": @([error fberrorCategory])};
                                }];
                                cancellationBlock();
                            }
                            else if (failureBlock)
                            {
                                [DQPapertrailLogger component:@"facebook-controller" category:@"request-new-publish-permissions-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                    return @{@"token": facebookToken ?: [NSNull null],
                                             @"feature": feature ?: [NSNull null],
                                             @"permissions": missing ?: [NSNull null],
                                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                             @"category": @([error fberrorCategory])};
                                }];
                                failureBlock([weakSelf niceErrorForFacebookError:error]);
                            }
                        }
                        else if ([weakSelf hasOpenFacebookSessionWithPermissions:missing])
                        {
                            sessionOpenBlock(YES);
                        }
                        else if (cancellationBlock) // if we request permissions and we get a completion block but we don't have them, the user cancelled
                        {
                            cancellationBlock();
                        }
                        else if (failureBlock)
                        {
                            failureBlock([weakSelf niceErrorForFacebookError:error]);
                        }
                    });
                }];
            });
        }
        else
        {
            sessionOpenBlock(tokenChanged);
        }
    };

    if ([self hasOpenFacebookSession]) // we know we have the email permission, at least, but perhaps more
    {
        NSString *facebookToken = [self openFacebookSessionAccessToken];
        NSArray *missing = [self openFacebookSessionPermissionsMissingFromPermissions:readPermissions];
        if ([missing count]) // need to extend the token
        {
            // dispatch_async because because the FacebookSDK may not have cleared some state yet in previous work in this iteration of the runloop
            dispatch_async(dispatch_get_main_queue(), ^{
                [DQPapertrailLogger component:@"facebook-controller" category:@"request-new-read-permissions" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"feature": feature ?: [NSNull null],
                             @"permissions": missing ?: [NSNull null]};
                }];
                [[FBSession activeSession] requestNewReadPermissions:missing completionHandler:^(FBSession *session, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error)
                        {
                            if ([weakSelf facebookErrorSignifiesCancellation:error] && cancellationBlock)
                            {
                                [DQPapertrailLogger component:@"facebook-controller" category:@"request-new-read-permissions-cancelled" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                    return @{@"token": facebookToken ?: [NSNull null],
                                             @"feature": feature ?: [NSNull null],
                                             @"permissions": missing ?: [NSNull null],
                                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                             @"category": @([error fberrorCategory])};
                                }];
                                cancellationBlock();
                            }
                            else if (failureBlock)
                            {
                                [DQPapertrailLogger component:@"facebook-controller" category:@"request-new-read-permissions-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                    return @{@"token": facebookToken ?: [NSNull null],
                                             @"feature": feature ?: [NSNull null],
                                             @"permissions": missing ?: [NSNull null],
                                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                             @"category": @([error fberrorCategory])};
                                }];
                                failureBlock([weakSelf niceErrorForFacebookError:error]);
                            }
                        }
                        else if ([weakSelf hasOpenFacebookSessionWithPermissions:missing])
                        {
                            requestPublishPermissions(YES);
                        }
                        else if (cancellationBlock) // if we request permissions and we get a completion block but we don't have them, the user cancelled
                        {
                            cancellationBlock();
                        }
                        else if (failureBlock)
                        {
                            failureBlock([weakSelf niceErrorForFacebookError:error]);
                        }
                    });
                }];
            });
        }
        else
        {
            requestPublishPermissions(NO);
        }
    }
    else
    {
        NSArray *permissions = readPermissions;
        if ( ! [permissions containsObject:@"email"])
        {
            permissions = [@[@"email"] arrayByAddingObjectsFromArray:readPermissions];
        }
        [self _requestOpenActiveSessionForFeature:feature readPermissions:permissions completionBlock:^{
            if ([weakSelf hasOpenFacebookSessionWithPermissions:permissions])
            {
                requestPublishPermissions(YES);
            }
            else if (cancellationBlock) // if we request permissions and we get a completion block but we don't have them, the user cancelled
            {
                cancellationBlock();
            }
            else if (failureBlock)
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"The operation was cancelled.", @"User cancelled Facebook authorization message")};
                NSError *error = [NSError errorWithDomain:DQFacebookErrorDomain code:DQFacebookErrorCodeCancelled userInfo:userInfo];
                failureBlock([weakSelf niceErrorForFacebookError:error]);
            }
        } failureBlock:^(NSError *error) {
            if ([weakSelf facebookErrorSignifiesCancellation:error] && cancellationBlock)
            {
                cancellationBlock();
            }
            else if (failureBlock)
            {
                failureBlock([weakSelf niceErrorForFacebookError:error]);
            }
        }];
    }
}

- (void)requestFacebookPublishAccessForFeature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestFacebookAccessForFeature:feature readPermissions:@[@"email"] publishPermissions:@[@"publish_actions"] cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)_requestOpenActiveSessionForFeature:(NSString *)feature readPermissions:(NSArray *)permissions completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __block BOOL completionHandlerCalled = NO;
    __weak typeof(self) weakSelf = self;
    [DQPapertrailLogger component:@"facebook-controller" category:@"open-active-session-with-read-permissions" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
        return @{@"feature": feature ?: [NSNull null],
                 @"permissions": permissions ?: [NSNull null]};
    }];
    [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:^(FBSession *_, FBSessionState status, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // FBSession retains the completion handler and calls it for ALL state transitions
            // so this callback can be called more than once. We can't have that, so we ensure
            // we only respond once.
            // FBSession only calls this for the open and closed states, so this wouldn't be
            // called prior to the session opening, so that's okay.
            if (completionHandlerCalled) return;
            completionHandlerCalled = YES;
            if (FB_ISSESSIONOPENWITHSTATE(status))
            {
                if (completionBlock)
                {
                    completionBlock();
                }
            }
            else if (FB_ISSESSIONSTATETERMINAL(status))
            {
                [weakSelf reset];
                [DQPapertrailLogger component:@"facebook-controller" category:@"open-active-session-with-read-permissions-terminal-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"feature": feature ?: [NSNull null],
                             @"permissions": permissions ?: [NSNull null],
                             @"status": @(status),
                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                             @"category": @([error fberrorCategory])};
                }];
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }
            else if (failureBlock)
            {
                [DQPapertrailLogger component:@"facebook-controller" category:@"open-active-session-with-read-permissions-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"feature": feature ?: [NSNull null],
                             @"permissions": permissions ?: [NSNull null],
                             @"status": @(status),
                             @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                             @"category": @([error fberrorCategory])};
                }];
                failureBlock(error);
            }
        });
    }];
}

@end
