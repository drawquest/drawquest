    //
//  DQAccountController.m
//  DrawQuest
//
//  Created by Buzz Andersen on 9/11/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQAccountController.h"

#import "STUtils.h"
#import <CommonCrypto/CommonDigest.h>
//#import <Crashlytics/Crashlytics.h>
//#import "Flurry.h"
#import "DQPapertrailLogger.h"
#import "DQNotifications.h"

#import "STKeychain.h"
#import "STPersistentCache.h"
#import "DQDataStoreController.h"
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"

#import "DQQuest.h"
#import "CVSEditorViewController.h"
#import "DQPushNotificationHandler.h"

#import "DQAnalyticsConstants.h"
#import "NSDictionary+DQAPIConveniences.h"

#import "DQWebProfileShareViewController.h"

// Push Constants
NSString *DQPushPayloadTypeNoop = @"noop"; // gives us the ability to send information-only pushes
NSString *DQPushPayloadTypeQuestOfTheDay = @"quest_of_the_day";
NSString *DQPushPayloadTypeStarred = @"starred";
NSString *DQPushPayloadTypeFacebookFriendJoined = @"facebook_friend_joined";
NSString *DQPushPayloadTypeTwitterFriendJoined = @"twitter_friend_joined";
NSString *DQPushPayloadTypeFeaturedInExplore = @"featured_in_explore";
NSString *DQPushPayloadTypeFollowedByUser = @"followed_by_user";
NSString *DQPushPayloadTypeNewColors = @"new_color_alert";

// Defaults Constants
NSString *DQApplicationHasEverLoggedInKey = @"UserEverLoggedIn";
NSString *DQApplicationNewQuestOfTheDayFlag = @"NewQuestOfTheDayFlag";
NSString *DQApplicationQuestOfTheDayPushEnabledKey = @"QuestOfTheDayPushEnabled";
NSString *DQApplicationStarPushEnabledKey = @"StarPushEnabled";
NSString *DQApplicationDeprecated1xxFBSharePreferenceKey = @"FBSharePreference";
NSString *DQApplicationLoggedInAccountIDDefaultsKey = @"LoggedInAccountID";

// Notification Keys
NSString *DQUserInfoKeyAccount = @"Account";

@implementation DQAccountController

@dynamic delegate;
@synthesize loggedInAccount = _loggedInAccount;

#pragma mark Initialization

- (id)initWithDelegate:(id<DQAccountControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        NSDictionary *defaultDefaults = @{
                                          DQApplicationQuestOfTheDayPushEnabledKey : @(YES),
                                          DQApplicationStarPushEnabledKey : @(YES),
                                          DQApplicationHasEverLoggedInKey : @(NO),
                                          };
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // restore the user's account
        NSString *loggedInAccountID = [self loggedInAccountID];
        if ([loggedInAccountID length])
        {
            NSError *error = nil;
            NSString *token = [DQAccount authTokenForAccountWithAccountID:loggedInAccountID forSource:@"account-controller-initialization" error:&error];
            if (token)
            {
                DQAccount *account = [self newAccountWithAccountID:loggedInAccountID];
                if (account)
                {
                    self.loggedInAccount = account;
                }
                else
                {
                    [self removeLoggedInAccount];
                    [self setLoggedInAccountID:nil];
                }
            }
            else
            {
                [self removeLoggedInAccount];
                [self setLoggedInAccountID:nil];
            }
        }
    }
    return self;
}

- (id<DQAccountControllerDelegate>)delegate
{
    return (id<DQAccountControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQAccountControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

#pragma mark -
#pragma mark Account Management

- (NSString *)loggedInAccountID
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationLoggedInAccountIDDefaultsKey];
};

- (void)setLoggedInAccountID:(NSString *)inLoggedInAccountID
{
    if (inLoggedInAccountID)
    {
        [[NSUserDefaults standardUserDefaults] setObject:inLoggedInAccountID forKey:DQApplicationLoggedInAccountIDDefaultsKey];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQApplicationLoggedInAccountIDDefaultsKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeLoggedInAccount
{
    DQAccount *loggedInAccount = [self newAccountForLoggedInID];
    if (loggedInAccount)
    {
        [loggedInAccount setAuthToken:nil forSource:@"remove-logged-in-account"];
        [[NSUserDefaults standardUserDefaults] removeAccountWithName:loggedInAccount.accountID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (DQAccount *)newAccountForLoggedInID
{
    return [[DQAccount alloc] initWithAccountID:[self loggedInAccountID]];
}

- (DQAccount *)newAccountWithAccountID:(NSString *)inAccountID
{
    if ([inAccountID length])
    {
        return [[DQAccount alloc] initWithAccountID:inAccountID];
    }
    return nil;
}

#pragma mark -
#pragma mark Life Cycle

- (void)requestLogout:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    if (self.loggedInAccount)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationWillLogoutNotification object:self userInfo:nil];

        // Log them out even if the request fails
        void (^done)(typeof(self), DQServiceStatusBlock, DQHTTPRequest *) = ^(typeof(self) _self, DQServiceStatusBlock callback, DQHTTPRequest *request) {

            //[_self unregisterUAPush];

            NSLog(@"Resetting account controller.");

            // Clear logged in account defaults data
            [self removeLoggedInAccount];
            _self.loggedInAccount = nil;
            [_self.delegate accountControllerDidReset:_self];

            // call completion block here
            if (callback)
            {
                callback(request);
            }
        };

        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestLogout:^(DQHTTPRequest *request) {
            id _self = weakSelf;
            if (_self)
            {
                done(_self, inCompletionBlock, request);
            }
        } failureBlock:^(DQHTTPRequest *request) {
            id _self = weakSelf;
            if (_self)
            {
                done(_self, inFailureBlock, request);
            }
        }];
    }
    else if (inFailureBlock)
    {
        inFailureBlock(nil);
    }

}

#pragma mark Accessors

- (DQAccount *)loggedInAccount
{
    return _loggedInAccount;
}

- (void)setLoggedInAccount:(DQAccount *)inLoggedInAccount
{
    _loggedInAccount = inLoggedInAccount;

    if (_loggedInAccount)
    {
        NSData *stringBytes = [inLoggedInAccount.username dataUsingEncoding: NSUTF8StringEncoding];
        NSString *hash = [stringBytes sha1DigestString];
        if ([hash length])
        {
//            [Crashlytics setUserIdentifier:hash];
            [DQPapertrailLogger logger].username = hash;
        }
        else
        {
//            [Crashlytics setUserIdentifier:nil];
            [DQPapertrailLogger logger].username = nil;
        }
    }
    else
    {
//        [Crashlytics setUserIdentifier:nil];
        [DQPapertrailLogger logger].username = nil;
    }

    [self setLoggedInAccountID:_loggedInAccount.accountID];
//    [Flurry setUserID:inLoggedInAccount.username];

    [self.delegate accountControllerDidChangeLoggedInAccount:self];
}

- (void)takeHeavyStateSync:(NSDictionary *)responseDictionary
{
    // Update email
    self.loggedInAccount.email = responseDictionary.dq_realtimeUserEmail;

    // Update coin count
    [self updateCoinBalanceForLoggedInUser:responseDictionary.dq_coinBalance];
    
    // Update user colors
    [self updateColorsForLoggedInUser:responseDictionary.dq_userColors];

    // Update web profile privacy
    self.loggedInAccount.webProfileEnabled = ( ! responseDictionary.dq_webProfilePrivacy);
    
    // Update social profile privacy only if they exist (could be null, YES or NO)
    if (responseDictionary.dq_facebookPrivacyExplicitlySet)
    {
        self.loggedInAccount.facebookProfileEnabled = ( ! responseDictionary.dq_facebookPrivacy);
    }
    if (responseDictionary.dq_twitterPrivacyExplicitlySet)
    {
        self.loggedInAccount.twitterProfileEnabled = ( ! responseDictionary.dq_twitterPrivacy);
    }

    // Show web profile
    self.loggedInAccount.shouldShowShareWebProfile = responseDictionary.dq_showWebProfileModal;
    
    // Update current color alert version
    self.loggedInAccount.currentColorAlertVersion = responseDictionary.dq_colorAlertVersion;

    // Update Facebook Sharing settings
    if (responseDictionary.dq_hasPublishToFacebook)
    {
        [self.loggedInAccount takeShareToFacebookOn:responseDictionary.dq_publishToFacebook];
    }
    else if (self.loggedInAccount.hasShareToFacebookOn)
    {
        [self setShareToFacebookOn:self.loggedInAccount.shareToFacebookOn completionBlock:nil failureBlock:nil];
    }
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationDeprecated1xxFBSharePreferenceKey] != nil)
    {
        // migrate the setting from 1.x, which was stored in NSUserDefaults but not in the account area, into DQAccount and the server
        [self setShareToFacebookOn:[[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationDeprecated1xxFBSharePreferenceKey] completionBlock:nil failureBlock:nil];
    }

    // Update Twitter Sharing settings
    if (responseDictionary.dq_hasPublishToTwitter)
    {
        [self.loggedInAccount takeShareToTwitterOn:responseDictionary.dq_publishToTwitter];
    }
    else if (self.loggedInAccount.hasShareToTwitterOn)
    {
        [self setShareToTwitterOn:self.loggedInAccount.shareToTwitterOn completionBlock:nil failureBlock:nil];
    }
}

- (void)handleSuccessfulAuthForRequest:(DQHTTPRequest *)inRequest withResponseDictionary:(NSDictionary *)inDictionary
{
    NSString *sessionID = inDictionary.dq_userSessionID;

    NSDictionary *userInfo = inDictionary.dq_userInfo;

    NSString *userID = userInfo.dq_serverID;

    DQAccount *loggedInAccount = [self newAccountWithAccountID:userID];
    [loggedInAccount setAuthToken:sessionID forSource:@"handle-successful-auth"];

    loggedInAccount.username = userInfo.dq_userName;
    loggedInAccount.email = userInfo.dq_userEmail;

    // TODO: hard coded this key, but it should really be a constant
    loggedInAccount.bio = [inDictionary stringForKey:@"user_bio"];

    BOOL allowStarPush = [inDictionary boolForKey:@"user_subscribed_to_starred"];
    [self setStarAlertsPushEnabled:allowStarPush];

    loggedInAccount.avatarURL = inDictionary.dq_profileUserAvatarURL;

    // if the user is signing up or has logged in but has never published, we want to show the
    // first quest completion view controller upon entering the gallery after they publish
    // for the first time
    NSInteger commentCount = inDictionary.dq_commentCount;
    loggedInAccount.hasPublishedAComment = commentCount > 0;

    NSInteger questCount = inDictionary.dq_questCount;
    loggedInAccount.hasPublishedAQuest = questCount > 0;
    self.loggedInAccount = loggedInAccount;

    if ( ! self.hasUserEverLoggedIn)
    {
        [self logEvent:DQAnalyticsEventViewFTESignupSuccess withParameters:nil];
    }
    self.hasUserEverLoggedIn = YES;
}

- (void)setQuestOfTheDayPushEnabled:(BOOL)inQOTDPushEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:inQOTDPushEnabled forKey:DQApplicationQuestOfTheDayPushEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self configureLocalQOTDNotification];
}

- (BOOL)questOfTheDayPushEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationQuestOfTheDayPushEnabledKey];
}

- (void)setStarAlertsPushEnabled:(BOOL)starAlertsPushEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:starAlertsPushEnabled forKey:DQApplicationStarPushEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)starAlertsPushEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationStarPushEnabledKey];
}

- (void)setHasUserEverLoggedIn:(BOOL)hasEverLoggedIn
{
    [[NSUserDefaults standardUserDefaults] setBool:hasEverLoggedIn forKey:DQApplicationHasEverLoggedInKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasUserEverLoggedIn
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationHasEverLoggedInKey];
}

- (void)setHasNewQuestOfTheDay:(BOOL)hasNewQuestOfTheDay
{
    [[NSUserDefaults standardUserDefaults] setBool:hasNewQuestOfTheDay forKey:DQApplicationNewQuestOfTheDayFlag];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationHasSeenQOTDFlagChangedNotification object:@(hasNewQuestOfTheDay)];
}

- (BOOL)hasNewQuestOfTheDay
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationNewQuestOfTheDayFlag];
}

- (void)setShareToFacebookOn:(BOOL)inShareToFacebookOn completionBlock:(dispatch_block_t)inCompletionBlock failureBlock:(void (^)(NSError *error))inFailureBlock
{
    BOOL old = self.loggedInAccount.shareToFacebookOn;
    if (inShareToFacebookOn == old)
    {
        if (inCompletionBlock)
        {
            inCompletionBlock();
        }
    }
    else
    {
        [self.loggedInAccount takeShareToFacebookOn:inShareToFacebookOn];
        [self.privateServiceController requestSetPublishToFacebookUserKV:inShareToFacebookOn completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            if (inCompletionBlock)
            {
                inCompletionBlock();
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (inFailureBlock)
            {
                inFailureBlock(request.error);
            }
        }];
    }
}

- (void)setShareToTwitterOn:(BOOL)inShareToTwitterOn completionBlock:(dispatch_block_t)inCompletionBlock failureBlock:(void (^)(NSError *error))inFailureBlock
{
    BOOL old = self.loggedInAccount.shareToTwitterOn;
    if (inShareToTwitterOn == old)
    {
        if (inCompletionBlock)
        {
            inCompletionBlock();
        }
    }
    else
    {
        [self.loggedInAccount takeShareToTwitterOn:inShareToTwitterOn];
        [self.privateServiceController requestSetPublishToTwitterUserKV:inShareToTwitterOn completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            if (inCompletionBlock)
            {
                inCompletionBlock();
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (inFailureBlock)
            {
                inFailureBlock(request.error);
            }
        }];
    }
}

- (void)setShareFacebookProfileOn:(BOOL)inShareFacebookProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    BOOL old = self.loggedInAccount.facebookProfileEnabled;
    if (inShareFacebookProfile == old)
    {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil);
        }
    }
    else
    {
        [self.loggedInAccount setFacebookProfileEnabled:inShareFacebookProfile];
        [self.privateServiceController requestFacebookProfilePrivacyChange:( ! inShareFacebookProfile) completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            weakSelf.loggedInAccount.facebookProfileEnabled = inShareFacebookProfile;
            if (inCompletionBlock)
            {
                inCompletionBlock(request);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationFacebookPrivacyUpdatedNotification object:nil];
        } failureBlock:^(DQHTTPRequest *request) {
            if (inFailureBlock)
            {
                inFailureBlock(request);
            }
        }];
    }
}

- (void)setShareFacebookProfileIfNotExplicitlySet:(BOOL)inShareFacebookProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock
{
    if (self.loggedInAccount && ! self.loggedInAccount.facebookProfileExplicitlySet)
    {
        [self setShareFacebookProfileOn:YES completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    }
    else
    {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil);
        }
    }
}

- (void)setShareTwitterProfileOn:(BOOL)inShareTwitterProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    BOOL old = self.loggedInAccount.twitterProfileEnabled;
    if (inShareTwitterProfile == old)
    {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil);
        }
    }
    else
    {
        [self.loggedInAccount setTwitterProfileEnabled:inShareTwitterProfile];
        [self.privateServiceController requestTwitterProfilePrivacyChange:( ! inShareTwitterProfile) completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            weakSelf.loggedInAccount.twitterProfileEnabled = inShareTwitterProfile;
            if (inCompletionBlock)
            {
                inCompletionBlock(request);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationTwitterPrivacyUpdatedNotification object:nil];
        } failureBlock:^(DQHTTPRequest *request) {
            if (inFailureBlock)
            {
                inFailureBlock(request);
            }
        }];
    }
}

- (void)setShareTwitterProfileIfNotExplicitlySet:(BOOL)inShareTwitterProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock
{
    if (self.loggedInAccount && ! self.loggedInAccount.twitterProfileExplicitlySet)
    {
        [self setShareTwitterProfileOn:YES completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    }
    else
    {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil);
        }
    }
}

#pragma mark Shop Related

- (void)updateCoinBalanceForLoggedInUser:(NSNumber *)inCoinBalance
{
    if (inCoinBalance)
    {
        self.loggedInAccount.coinCount = inCoinBalance;
        [self.dataStoreController updateCoinBalanceForUserWithUserName:self.loggedInAccount.username withCount:inCoinBalance];

        [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationCoinBalanceUpdatedNotication object:nil];
    }
}

- (void)updateColorsForLoggedInUser:(NSArray *)colors
{
    if (colors)
    {
        self.loggedInAccount.colors = colors;
        [[NSNotificationCenter defaultCenter] postNotificationName:CVSColorsUpdatedNotification object:nil];
    }
}

#pragma mark -
#pragma mark Push
/*
- (void)startUAWithLaunch
{
    NSString *appKey = @(AIRSHIP_APP_KEY);
    NSString *appSecret = @(AIRSHIP_APP_SECRET);
    UAConfig *config = [UAConfig defaultConfig];
    //config.developmentLogLevel = UALogLevelTrace; // if you're debugging pushes, uncomment this
    config.developmentAppKey = appKey;
    config.developmentAppSecret = appSecret;
    config.detectProvisioningMode = NO;
    config.inProduction = NO;
    [UAirship takeOff:config];
    // Don't ask for permissions yet
    [UAPush setDefaultPushEnabledValue:NO];
    [[UAPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    // We're not doing anything with the pushes for now
    DQPushNotificationHandler *pushHandler = [DQPushNotificationHandler new];
    [UAPush shared].pushNotificationDelegate = pushHandler;
    [self updateUAPushSettings];
}

- (void)registerUAPushWithDeviceToken:(NSData *)inDeviceToken
{
    if (inDeviceToken)
    {
        [[UAPush shared] registerDeviceToken:inDeviceToken];
        [UAPush shared].pushEnabled = YES;

        [self updateUAPushSettings];
    }
    else
    {
        NSLog(@"Unable to register with Urban Airship for push: no device token specified.");
    }
}

- (void)unregisterUAPush
{
    [[UAPush shared] setAlias:nil];
    [UAPush shared].pushEnabled = NO;
}

- (void)updateUAPushSettings
{
    if (self.loggedInAccount)
    {
        [UAPush shared].pushEnabled = YES;

        BOOL QOTDPushEnabled = self.questOfTheDayPushEnabled;

        NSMutableArray *tags = [[NSMutableArray alloc] init];

        if (QOTDPushEnabled)
        {
            [tags addObject:[NSString stringWithFormat:@"%@-%@", DQPushPayloadTypeQuestOfTheDay, [[NSLocale preferredLanguages] firstObject] ?: @"en"]];
        }
        
        // Opt everyone in so we can use tags instead of broadcast
        BOOL NewColorsAlertEnabled = NO;
        if (NewColorsAlertEnabled)
        {
            [tags addObject:DQPushPayloadTypeNewColors];
        }

        [[UAPush shared] setTags:tags];

        NSString *alias = self.loggedInAccount.username;
        if (alias.length)
        {
            [[UAPush shared] setAlias:alias];
        }

        [[UAPush shared] updateRegistration];
    }
}
 */

#pragma mark -
#pragma mark Local Notifications

- (void)configureLocalQOTDNotification
{
    if (self.questOfTheDayPushEnabled)
    {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        NSDateComponents *dateComponents = [calendar components:kCFCalendarUnitEra | kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay fromDate:now];
        [dateComponents setHour:17]; // 5pm GMT
        [dateComponents setMinute:5]; // Give a few minutes leeway
        NSDate *notificationDate = [calendar dateFromComponents:dateComponents];
        UILocalNotification *qotdNotification = [[UILocalNotification alloc] init];
        qotdNotification.fireDate = notificationDate;
        qotdNotification.alertBody = DQLocalizedString(@"Today's Quest is now available. Come draw it!", @"A reminder that a new Quest of the Day is now available");
        qotdNotification.userInfo = @{@"push_notification_type" : DQPushPayloadTypeQuestOfTheDay};
        qotdNotification.applicationIconBadgeNumber = 1;
        qotdNotification.repeatInterval = NSDayCalendarUnit;
        [[UIApplication sharedApplication] scheduleLocalNotification:qotdNotification];
    }
    else
    {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

@end
