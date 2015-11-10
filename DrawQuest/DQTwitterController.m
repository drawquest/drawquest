//
//  DQTwitterController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-05-15.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTwitterController.h"
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import <objc/runtime.h>
#import "TWAPIManager.h"
#import "STKeychain.h"
#import "DQAccount.h"
#import "DQPrivateServiceController.h"
#import "TWSignedRequest.h"
#import "NSDictionary+STAdditions.h"
#import "DQPapertrailLogger.h"

void * const kDQTwitterControllerAccountsKey = (void *)&kDQTwitterControllerAccountsKey;
void * const kDQTwitterControllerCancellationBlockKey = (void *)&kDQTwitterControllerCancellationBlockKey;
void * const kDQTwitterControllerAccountSelectedBlockKey = (void *)&kDQTwitterControllerAccountSelectedBlockKey;
void * const kDQTwitterControllerCompletionBlockKey = (void *)&kDQTwitterControllerCompletionBlockKey;
void * const kDQTwitterControllerFailureBlockKey = (void *)&kDQTwitterControllerFailureBlockKey;

NSString *DQTwitterErrorDomain = @"DQTwitterErrorDomain";
NSInteger DQTwitterErrorCodeNoKeys = 1000;
NSInteger DQTwitterErrorCodeNoAccounts = 1001;
NSInteger DQTwitterErrorCodeNoAccess = 1002;
NSInteger DQTwitterErrorCodeUnexpectedReverseAuthResponse = 1003;
NSInteger DQTwitterAPIErrorCode = 1004;

// Defaults Keys
NSString *DQApplicationAccountTwitterUsernameDefaultsKey = @"TwitterUsername";

// Keychain Keys
NSString *DQTwitterAccessTokenKeychainServiceName = @"TwitterAccessToken";
NSString *DQTwitterAccessTokenSecretKeychainServiceName = @"TwitterAccessTokenSecret";


@interface DQTwitterController () <UIActionSheetDelegate>

@property (nonatomic, readwrite, strong) ACAccount *twitterAccount;
@property (nonatomic, readwrite, copy) NSString *twitterUsername;
@property (nonatomic, readwrite, copy) NSString *twitterAccessToken;
@property (nonatomic, readwrite, copy) NSString *twitterAccessTokenSecret;
@property (nonatomic, readwrite, assign) BOOL hasUnverifiedTwitterAuthCredentials;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;

@end

@implementation DQTwitterController

@dynamic twitterUsername; // stored in NSUserDefaults under DQApplicationAccountTwitterUsernameDefaultsKey
@dynamic twitterAccessToken; // stored in the keychain
@dynamic twitterAccessTokenSecret; // stored in the keychain
@dynamic hasUnverifiedTwitterAuthCredentials;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithDelegate:(id<DQTwitterControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _accountStore = [[ACAccountStore alloc] init];
        _apiManager = [[TWAPIManager alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forgetTwitterAccounts:) name:ACAccountStoreDidChangeNotification object:nil];
    }
    return self;
}

- (id<DQTwitterControllerDelegate>)delegate
{
    return (id<DQTwitterControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQTwitterControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

- (void)reset
{
    self.twitterAccount = nil;
    self.twitterAccessToken = nil;
    self.twitterAccessTokenSecret = nil;
    self.twitterUsername = nil; // nil this after the token and secret because this information is needed to look them up to delete them from the keychain
    self.accounts = nil;
}

- (void)forgetTwitterCredentials
{
    self.twitterAccount = nil;
    self.twitterAccessToken = nil;
    self.twitterAccessTokenSecret = nil;
    self.twitterUsername = nil;
    [self.delegate twitterControllerDidForgetCredentials:self];
}

- (void)forgetTwitterAccounts:(NSNotification *)notification
{
    [self forgetTwitterAccounts];
}

- (void)forgetTwitterAccounts
{
    if (self.accounts)
    {
        self.twitterAccount = nil;
        self.accounts = nil;
        __weak typeof(self) weakSelf = self;
        [self requestTwitterAccounts:^(NSArray *accounts) {
            weakSelf.accounts = accounts;
            if ([self hasUnverifiedTwitterAuthCredentials])
            {
                NSIndexSet *indexes = [weakSelf.accounts indexesOfObjectsPassingTest:^BOOL(ACAccount *account, NSUInteger _, BOOL *stop) {
                    if ([account.username isEqualToString:weakSelf.twitterUsername])
                    {
                        *stop = YES;
                        return YES;
                    }
                    return NO;
                }];
                if ([indexes count])
                {
                    weakSelf.twitterAccount = [weakSelf.accounts objectAtIndex:[indexes firstIndex]];
                }
                else
                {
                    [self forgetTwitterCredentials];
                }
            }
        } failureBlock:^(NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") message:[error localizedDescription] delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
            [alert show];
        }];
    }
}

- (NSString *)twitterUsername
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationAccountTwitterUsernameDefaultsKey];
}

- (void)setTwitterUsername:(NSString *)twitterUsername
{
    if ([twitterUsername length])
    {
        [[NSUserDefaults standardUserDefaults] setObject:twitterUsername forKey:DQApplicationAccountTwitterUsernameDefaultsKey];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQApplicationAccountTwitterUsernameDefaultsKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)twitterAccessToken
{
    return [STKeychain getPasswordForUsername:self.twitterUsername andServiceName:DQTwitterAccessTokenKeychainServiceName error:NULL];
}

- (void)setTwitterAccessToken:(NSString *)inAccessToken
{
    if (![self.twitterUsername length]) {
        return;
    }

    if (![inAccessToken length]) {
        [STKeychain deleteItemForUsername:self.twitterUsername andServiceName:DQTwitterAccessTokenKeychainServiceName error:nil];
        return;
    }

    NSError *error = nil;
    BOOL result = [STKeychain storeUsername:self.twitterUsername andPassword:inAccessToken forServiceName:DQTwitterAccessTokenKeychainServiceName updateExisting:YES error:&error];
    if (!result)
    {
        NSLog(@"Unable to store access token due to error: %@", error);
    }
}

- (NSString *)twitterAccessTokenSecret
{
    return [STKeychain getPasswordForUsername:self.twitterUsername andServiceName:DQTwitterAccessTokenSecretKeychainServiceName error:NULL];
}

- (void)setTwitterAccessTokenSecret:(NSString *)inAccessTokenSecret
{
    if (![self.twitterUsername length]) {
        return;
    }

    if (![inAccessTokenSecret length]) {
        [STKeychain deleteItemForUsername:self.twitterUsername andServiceName:DQTwitterAccessTokenSecretKeychainServiceName error:nil];
        return;
    }

    NSError *error = nil;
    BOOL result = [STKeychain storeUsername:self.twitterUsername andPassword:inAccessTokenSecret forServiceName:DQTwitterAccessTokenSecretKeychainServiceName updateExisting:YES error:&error];
    if (!result)
    {
        NSLog(@"Unable to store access token secret due to error: %@", error);
    }
}

- (BOOL)hasUnverifiedTwitterAuthCredentials
{
    return ([self.twitterUsername length] && [self.twitterAccessToken length] && [self.twitterAccessTokenSecret length]);
}

/**
 *  Checks for the current Twitter configuration on the device / simulator.
 *  First, we check to make sure that we've got keys to work with
 *  Then we check to see if the device has accounts available via +[TWAPIManager isLocalTwitterAccountAvailable].
 *  Next, we ask the user for permission to access his/her accounts.
 */
- (void)requestTwitterAccounts:(void (^)(NSArray *accounts))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (self.accounts)
    {
        if (resultBlock)
        {
            resultBlock(self.accounts);
        }
    }
    else if (![TWAPIManager hasAppKeys])
    {
        if (failureBlock)
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : DQLocalizedString(@"Twitter API keys are missing!", @"Twitter API keys are missing error message")};
            failureBlock([NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterErrorCodeNoKeys userInfo:userInfo]);
        }
    }
    else if (![TWAPIManager isLocalTwitterAccountAvailable])
    {
        if (failureBlock)
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : DQLocalizedString(@"There are no Twitter accounts configured. You can add or create a Twitter account in Settings on your device.", @"No Twitter accounts are configured on device error alert message")};
            failureBlock([NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterErrorCodeNoAccounts userInfo:userInfo]);
        }
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [self obtainAccessToAccounts:^(BOOL granted, NSArray *accounts) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted)
                {
                    weakSelf.accounts = accounts;
                    if (resultBlock)
                    {
                        resultBlock(weakSelf.accounts);
                    }
                }
                else
                {
                    if (failureBlock)
                    {
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : DQLocalizedString(@"DrawQuest was not granted access to your Twitter accounts.", @"Twitter access was denied by user error alert message")};
                        failureBlock([NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterErrorCodeNoAccess userInfo:userInfo]);
                    }
                }
            });
        }];
    }
}

- (void)obtainAccessToAccounts:(void (^)(BOOL granted, NSArray *results))block
{
    ACAccountType *twitterType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
        if (granted && block)
        {
            block(granted, [_accountStore accountsWithAccountType:twitterType]);
        }
        else if (block)
        {
            block(NO, nil);
        }
    };

    [_accountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
}

- (void)hasTwitterAccess:(void (^)(BOOL))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestTwitterAccount:^(ACAccount *twitterAccount) {
        if (resultBlock)
        {
            resultBlock(twitterAccount != nil);
        }
    } failureBlock:failureBlock];
}

- (void)requestTwitterAccount:(void (^)(ACAccount *twitterAccount))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (self.twitterAccount)
    {
        if (resultBlock)
        {
            resultBlock(self.twitterAccount);
        }
    }
    else if ([self hasUnverifiedTwitterAuthCredentials])
    {
        __weak typeof(self) weakSelf = self;
        [self requestTwitterAccounts:^(NSArray *accounts) {
            NSIndexSet *indexes = [accounts indexesOfObjectsPassingTest:^BOOL(ACAccount *account, NSUInteger _, BOOL *stop) {
                if ([account.username isEqualToString:weakSelf.twitterUsername])
                {
                    *stop = YES;
                    return YES;
                }
                return NO;
            }];
            if ([indexes count])
            {
                weakSelf.twitterAccount = [weakSelf.accounts objectAtIndex:[indexes firstIndex]];
                if (resultBlock)
                {
                    resultBlock(weakSelf.twitterAccount);
                }
            }
            else
            {
                [weakSelf forgetTwitterCredentials];
                if (resultBlock)
                {
                    resultBlock(nil);
                }
            }
        } failureBlock:failureBlock];
    }
    else
    {
        if (resultBlock)
        {
            resultBlock(nil);
        }
    }
}

- (void)requestAccountInView:(UIView *)view cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    [self requestTwitterAccounts:^(NSArray *accounts) {
        if ([accounts count] == 1)
        {
            if (accountSelectedBlock)
            {
                accountSelectedBlock();
            }
            [weakSelf performReverseAuthForAccount:[accounts objectAtIndex:0] completionBlock:completionBlock failureBlock:failureBlock];
        }
        else
        {
            typeof(weakSelf) _self = weakSelf;
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:DQLocalizedString(@"Choose a Twitter Account", @"Prompt for a user to select the appropriate Twitter account from a list") delegate:_self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            for (ACAccount *acct in accounts)
            {
                [sheet addButtonWithTitle:acct.username];
            }
            sheet.cancelButtonIndex = [sheet addButtonWithTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view")];
            objc_setAssociatedObject(sheet, kDQTwitterControllerAccountsKey, accounts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(sheet, kDQTwitterControllerCancellationBlockKey, cancellationBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(sheet, kDQTwitterControllerAccountSelectedBlockKey, accountSelectedBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(sheet, kDQTwitterControllerCompletionBlockKey, completionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(sheet, kDQTwitterControllerFailureBlockKey, failureBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
            if ([view window])
            {
                [sheet showFromRect:view.bounds inView:view animated:YES];
            }
            else
            {
                [sheet showInView:[[UIApplication sharedApplication] keyWindow]];
            }
        }
    } failureBlock:failureBlock];
}

- (void)requestDataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestDataForTwitterAccountForFeature:nil URL:url parameters:parameters method:method resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)requestDataForTwitterAccountForFeature:(NSString *)feature URL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestTwitterAccount:^(ACAccount *twitterAccount) {
        id<GenericTwitterRequest> request = nil;
        request = (id<GenericTwitterRequest>)[SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:method URL:url parameters:parameters];
        [request setAccount:twitterAccount];

        [DQPapertrailLogger component:@"twitter-controller" category:[@"request-data-" stringByAppendingString:([feature length] ? feature : @"unknown")] dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            BOOL includeArgs = YES;
            id supressArgs = [categoryDict safeObjectForKey:@"suppress-args"];
            if (!supressArgs)
            {
                supressArgs = [componentDict safeObjectForKey:@"request-data-suppress-args"];
            }
            if (supressArgs)
            {
                includeArgs = ![@{@"x": supressArgs} boolForKey:@"x"];
            }
            if (includeArgs)
            {
                return @{@"feature": feature ?: [NSNull null],
                         @"username": twitterAccount.username ?: [NSNull null],
                         @"method": @(method),
                         @"url": [url absoluteString] ?: [NSNull null],
                         @"args": parameters ?: [NSNull null]};
            }
            else
            {
                return @{@"feature": feature ?: [NSNull null],
                         @"username": twitterAccount.username ?: [NSNull null],
                         @"method": @(method),
                         @"url": [url absoluteString] ?: [NSNull null]};
            }
        }];
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (error)
            {
                [DQPapertrailLogger component:@"twitter-controller" category:[@"request-data-failed-" stringByAppendingString:([feature length] ? feature : @"unknown")] error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    BOOL includeArgs = YES;
                    id supressArgs = [categoryDict safeObjectForKey:@"suppress-args"];
                    if (!supressArgs)
                    {
                        supressArgs = [componentDict safeObjectForKey:@"request-data-failed-suppress-args"];
                    }
                    if (supressArgs)
                    {
                        includeArgs = ![@{@"x": supressArgs} boolForKey:@"x"];
                    }
                    if (includeArgs)
                    {
                        return @{@"feature": feature ?: [NSNull null],
                                 @"username": twitterAccount.username ?: [NSNull null],
                                 @"method": @(method),
                                 @"url": [url absoluteString] ?: [NSNull null],
                                 @"args": parameters ?: [NSNull null]};
                    }
                    else
                    {
                        return @{@"feature": feature ?: [NSNull null],
                                 @"username": twitterAccount.username ?: [NSNull null],
                                 @"method": @(method),
                                 @"url": [url absoluteString] ?: [NSNull null]};
                    }
                }];
                if (failureBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failureBlock(error);
                    });
                }
            }
            else if (resultBlock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(responseData, urlResponse);
                });
            }
        }];
    } failureBlock:failureBlock];
}

- (void)requestTwitterAccessInView:(UIView *)view cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    void (^sessionOpenBlock)(void) = ^{
        if (self.loggedIn)
        {
            [weakSelf.privateServiceController requestAssociateTwitterToken:weakSelf.twitterAccessToken twitterSecret:weakSelf.twitterAccessTokenSecret completionBlock:^(DQHTTPRequest *request, id JSONObject) {
                if (completionBlock)
                {
                    completionBlock();
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
            completionBlock();
        }
    };
    [self requestTwitterAccount:^(ACAccount *twitterAccount) {
        if (twitterAccount)
        {
            sessionOpenBlock();
        }
        else
        {
            [weakSelf requestAccountInView:view cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:^{
                sessionOpenBlock();
            } failureBlock:failureBlock];
        }
    } failureBlock:failureBlock];
}

- (void)requestTwitterUsersForIDs:(NSArray *)userIDs resultBlock:(void (^)(NSArray *resultList))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    int maxIDsPerRequest = 100;
    __weak typeof(self) weakSelf = self;
    __block NSArray *resultList = [NSArray array];

    void (^requestBlock)(id, int) = ^(id thisBlock, int offset) {
        if (offset > [userIDs count])
        {
            if (resultBlock)
            {
                resultBlock(resultList);
            }
        }
        else
        {
            NSUInteger sliceLength = (maxIDsPerRequest + offset <= [userIDs count]) ? 100 : [userIDs count] - offset;
            NSRange sliceRange = NSMakeRange(offset, sliceLength);
            NSArray *userIDsSlice = [userIDs subarrayWithRange:sliceRange];

            NSDictionary *params = @{@"user_id": [userIDsSlice componentsJoinedByString:@","]};

            [weakSelf requestDataForTwitterAccountForFeature:@"users-for-ids" URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json"] parameters:params method:SLRequestMethodPOST resultBlock:^(NSData *responseData, NSHTTPURLResponse *urlResponse) {
                if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300)
                {
                    NSError *jsonError = nil;
                    NSArray *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];

                    if (timelineData)
                    {
                        // Success
                        resultList = [resultList arrayByAddingObjectsFromArray:timelineData];
                        void(^block)(id, int) = thisBlock;
                        block(thisBlock, offset + maxIDsPerRequest);
                    }
                    else
                    {
                        // Our JSON deserialization went awry
                        if (failureBlock)
                        {
                            failureBlock(jsonError);
                        }
                    }
                }
                else
                {
                    // The server did not respond successfully... were we rate-limited?
                    if (failureBlock)
                    {
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Request to Twitter failed: %@",
                                                                               [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]]};
                        NSError *error = [NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterAPIErrorCode userInfo:userInfo];
                        failureBlock(error);
                    }
                }
            } failureBlock:failureBlock];
        }
    };
    requestBlock(requestBlock, 0);
}

- (void)requestEntiretyOfCursoredUserIDsListForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)inParameters method:(SLRequestMethod)method resultBlock:(void (^)(NSArray *resultList))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    __block NSNumber *nextCursor = @(-1);
    __block NSArray *resultList = [NSArray array];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:inParameters];

    void (^cursorRequestBlock)(id) = ^(id thisBlock) {
        if ([nextCursor intValue] == 0)
        {
            if (resultBlock)
            {
                resultBlock(resultList);
            }
        }
        else
        {
            if ([nextCursor intValue] > -1)
            {
                [params setObject:nextCursor forKey:@"cursor"];
            }

            [weakSelf requestDataForTwitterAccountForFeature:@"cursored-user-ids" URL:url parameters:params method:method resultBlock:^(NSData *responseData, NSHTTPURLResponse *urlResponse) {
                if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300)
                {
                    NSError *jsonError = nil;
                    NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];

                    if (timelineData)
                    {
                        // Success
                        nextCursor = [timelineData numberForKey:@"next_cursor"];
                        resultList = [resultList arrayByAddingObjectsFromArray:[timelineData objectForKey:@"ids"]];
                        void(^block)(id) = thisBlock;
                        block(thisBlock);
                    }
                    else
                    {
                        // Our JSON deserialization went awry
                        if (failureBlock)
                        {
                            failureBlock(jsonError);
                        }
                    }
                }
                else
                {
                    // The server did not respond successfully... were we rate-limited?
                    if (failureBlock)
                    {
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Request to Twitter failed: %@",
                                                                               [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]]};
                        NSError *error = [NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterAPIErrorCode userInfo:userInfo];
                        failureBlock(error);
                    }
                }
            } failureBlock:failureBlock];
        }
    };
    cursorRequestBlock(cursorRequestBlock);
}

- (void)requestFriendsListForTwitterAccount:(void (^)(NSArray *))resultBlock cancellationBlock:(dispatch_block_t)cancellationBlock failureBlock:(void (^)(NSError *))failureBlock
{
    __weak typeof(self) weakSelf = self;
    __block BOOL followingRequestFinished = NO;
    __block BOOL followersRequestFinished = NO;
    __block BOOL failureBlockCalled = NO;
    __block NSArray *followingList = nil;
    __block NSArray *followersList = nil;

    dispatch_block_t checkIfFinishedBlock = ^{
        if (followingRequestFinished && followersRequestFinished)
        {
            // Now compare lists
            NSMutableArray *friendList = [NSMutableArray array];
            for (NSNumber *user_id in followingList)
            {
                if ([followersList containsObject:user_id])
                {
                    [friendList addObject:user_id];
                }
            }
            if ([friendList count])
            {
                [weakSelf requestTwitterUsersForIDs:friendList resultBlock:^(NSArray *resultList) {
                    if (resultBlock)
                    {
                        resultBlock(resultList);
                    }
                } failureBlock:failureBlock];
            }
            else
            {
                if (resultBlock)
                {
                    resultBlock(friendList);
                }
            }
        }
    };

    [self requestEntiretyOfCursoredUserIDsListForTwitterAccountWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json"] parameters:@{} method:SLRequestMethodGET resultBlock:^(NSArray *resultList) {
        followingRequestFinished = YES;
        followingList = resultList;
        checkIfFinishedBlock();
    } failureBlock:^(NSError *error) {
        if (failureBlock && ! failureBlockCalled)
        {
            failureBlockCalled = YES;
            failureBlock(error);
        }
    }];

    [self requestEntiretyOfCursoredUserIDsListForTwitterAccountWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/followers/ids.json"] parameters:@{} method:SLRequestMethodGET resultBlock:^(NSArray *resultList) {
        followersRequestFinished = YES;
        followersList = resultList;
        checkIfFinishedBlock();
    } failureBlock:^(NSError *error) {
        if (failureBlock && ! failureBlockCalled)
        {
            failureBlockCalled = YES;
            failureBlock(error);
        }
    }];
}

- (void)sendDirectMessageForTwitterAccount:(NSString *)messageBody toUserID:(NSString *)userID cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id", messageBody, @"text", nil];
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages/new.json"];

    [self requestDataForTwitterAccountForFeature:@"send-dm" URL:url parameters:params method:SLRequestMethodPOST resultBlock:^(NSData *responseData, NSHTTPURLResponse *urlResponse) {
        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300)
        {
            NSError *jsonError = nil;
            NSArray *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];

            if (timelineData)
            {
                // Success
                if (completionBlock)
                {
                    completionBlock();
                }
            }
            else
            {
                // Our JSON deserialization went awry
                if (failureBlock)
                {
                    failureBlock(jsonError);
                }
            }
        }
        else
        {
            // The server did not respond successfully... were we rate-limited?
            if (failureBlock)
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Request to Twitter failed: %@",
                                                                       [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]]};
                NSError *error = [NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterAPIErrorCode userInfo:userInfo];
                failureBlock(error);
            }
        }
    } failureBlock:failureBlock];
}

- (void)performReverseAuthForAccount:(ACAccount *)account completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    
    [self.apiManager performReverseAuthForAccount:account withHandler:^(NSData *responseData, NSError *error) {
        if (responseData)
        {
            NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

            TWDLog(@"Reverse Auth process returned: %@", responseStr);

            NSArray *parts = [responseStr componentsSeparatedByString:@"&"];

            NSString *token = nil;
            NSString *secret = nil;
            for (NSString *part in parts)
            {
                NSArray *components = [part componentsSeparatedByString:@"="];
                if ([components count] == 2)
                {
                    NSString *key = components[0];
                    NSString *value = components[1];
                    if ([@"oauth_token" isEqualToString:key])
                    {
                        token = value;
                    }
                    else if ([@"oauth_token_secret" isEqualToString:key])
                    {
                        secret = value;
                    }
                    if (token && secret)
                    {
                        break;
                    }
                }
            }
            if (token && secret)
            {
                if (completionBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.twitterAccount = account;
                        weakSelf.twitterUsername = account.username;
                        weakSelf.twitterAccessToken = token;
                        weakSelf.twitterAccessTokenSecret = secret;
                        completionBlock();
                    });
                }
            }
            else
            {
                if (failureBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [DQPapertrailLogger component:@"twitter-controller" category:@"reverse-auth-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                            if ([categoryDict boolForKey:@"include-response"])
                            {
                                return @{@"account": account.username ?: [NSNull null],
                                         @"token": token ?: [NSNull null],
                                         @"secret": secret ?: [NSNull null],
                                         @"response": responseStr ?: [NSNull null]};
                            }
                            else
                            {
                                return @{@"account": account.username ?: [NSNull null],
                                         @"token": token ?: [NSNull null],
                                         @"secret": secret ?: [NSNull null]};
                            }
                        }];
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : DQLocalizedString(@"There was an unexpected error communicating with Twitter. Please try again.", @"Unknown Twitter error alert message")};
                        failureBlock([NSError errorWithDomain:DQTwitterErrorDomain code:DQTwitterErrorCodeUnexpectedReverseAuthResponse userInfo:userInfo]);
                    });
                }
            }
        }
        else if (failureBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }
    }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // pull the context out of the actionSheet
    NSArray *accounts = (NSArray *)objc_getAssociatedObject(actionSheet, kDQTwitterControllerAccountsKey);
    dispatch_block_t cancellationBlock = (dispatch_block_t)objc_getAssociatedObject(actionSheet, kDQTwitterControllerCancellationBlockKey);
    dispatch_block_t accountSelectedBlock = (dispatch_block_t)objc_getAssociatedObject(actionSheet, kDQTwitterControllerAccountSelectedBlockKey);
    dispatch_block_t completionBlock = (dispatch_block_t)objc_getAssociatedObject(actionSheet, kDQTwitterControllerCompletionBlockKey);
    void (^failureBlock)(NSError *) = (void (^)(NSError *))objc_getAssociatedObject(actionSheet, kDQTwitterControllerFailureBlockKey);

    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        if (cancellationBlock)
        {
            cancellationBlock();
        }
    }
    else
    {
        if (accountSelectedBlock)
        {
            accountSelectedBlock();
        }
        
        ACAccount *account = accounts[buttonIndex];
        [self performReverseAuthForAccount:account completionBlock:completionBlock failureBlock:failureBlock];
    }
}

@end
