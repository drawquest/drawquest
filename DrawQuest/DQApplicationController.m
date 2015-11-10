//
//  DQApplicationController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQApplicationController.h"
#import <objc/runtime.h>
//#import <Crashlytics/Crashlytics.h>
#import <FacebookSDK/FacebookSDK.h>
#import <StoreKit/StoreKit.h>

// 3rd party services
#import "Appirater.h"
#import "TWSignedRequest.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"

// Model
#import "DQMigrate1xxTo300.h"
#import "DQMigrate2xxTo300.h"
#import "DQCommentUpload.h"
#import "DQQuestUpload.h"
#import "DQUser.h"

// Controllers
#import "DQPapertrailLogger.h"
#import "DQRouterServiceController.h"

// View Controllers
#import "DQAboutViewController.h"
#import "DQAddFriendsViewController.h"
#import "DQPublishAuthViewController.h"
#import "DQAlmostThereViewController.h"
#import "DQSignInViewController.h"
#import "DQSignUpViewController.h"
#import "DQFirstQuestCompletionViewController.h"

// Views
#import "DQAlertView.h"
#import "DQHUDView.h"
#import "DQPlaybackImageView.h"
#import "DQActionSheet.h"

// Private Subclasses
#import "DQPadApplicationController.h"
#import "DQPhoneApplicationController.h"

NSString *DQApplicationErrorDomain = @"DQApplicationErrorDomain";
NSInteger DQApplicationErrorCodeNoComments = 2000;

NSString *DQAppUpdateURL = @"download";

// App Configuration Constants
NSString *DQApplicationImageCacheDirectoryName = @"Image Cache";

NSString *DQCurrentAppVersionKey = @"DQCurrentAppVersionKey";
NSString *DQAppStoreAppID = @"*********";

// User Defaults Constants
NSString *DQApplicationRewardsDictionaryDefaultsKey = @"RewardsDictionary";
NSString *DQApplicationTumblrSuccessRegexPatternKey = @"TumblrSuccessRegexPatternKey";
NSString *DQApplicationFeatureInviteFromFacebookKey = @"FeatureInviteFromFacebook";
NSString *DQApplicationFeatureInviteFromTwitterKey = @"FeatureInviteFromTwitter";
NSString *DQApplicationFeatureUserSearchKey = @"FeatureUserSearch";
NSString *DQApplicationFeatureUARegistrationKey = @"FeatureUARegistration";
NSString *DQApplicationFeatureUARegistrationBeforeAuthKey = @"FeatureUARegistrationBeforeAuth";
NSString *DQApplicationVersionForUpgradeModalKey = @"VersionForUpgradeModal";
NSString *DQApplicationOwnedBrushes = @"OwnedBrushes";
NSString *DQApplicationGlobalBrushes = @"GlobalBrushes";
NSString *DQApplicationUpgradeType = @"UpgradeType";
NSString *DQApplicationAppiraterReviewURL = @"AppiraterReviewURL";
NSString *DQApplicationCurrentInviteReminderKey = @"CurrentInviteReminder";
NSString *DQApplicationPreviousInviteReminderKey = @"PreviousInviteReminder";
NSString *DQApplicationFirstRunQuestDefaultsKey = @"FirstRunQuestID";
NSString *DQApplicationQuestOfTheDayDefaultsKey = @"QuestOfTheDayID";

@interface DQApplicationController () <DQTwitterControllerDelegate, DQAccountControllerDelegate, DQShopControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, readwrite, assign) BOOL hasLaunched;
@property (nonatomic, readwrite, copy) dispatch_block_t launchCompletionBlock;
@property (nonatomic, readwrite, assign) BOOL globalAlertDisplayed;
@property (nonatomic, readwrite, weak) NSDictionary *rewardsDictionary;
@property (nonatomic, readwrite, assign) BOOL featureInviteFromFacebook;
@property (nonatomic, readwrite, assign) BOOL featureInviteFromTwitter;
@property (nonatomic, readwrite, assign) BOOL featureUserSearch;
@property (nonatomic, readwrite, assign) BOOL featureUARegistration;
@property (nonatomic, readwrite, assign) BOOL featureUARegistrationBeforeAuth;
@property (nonatomic, readwrite, copy) NSString *tumblrSuccessRegexPattern;

@property (nonatomic, readwrite, strong) DQAccountController *accountController;
@property (nonatomic, readwrite, strong) DQAnalyticsController *analyticsController;
@property (nonatomic, readwrite, strong) DQActivityController *activityController;
@property (nonatomic, readwrite, strong) DQCommentUploadController *commentUploadController;
@property (nonatomic, readwrite, strong) DQQuestUploadController *questUploadController;
@property (nonatomic, readwrite, strong) DQRouterServiceController *routerServiceController;
@property (nonatomic, readwrite, strong) DQPublicServiceController *publicServiceController;
@property (nonatomic, readwrite, strong) DQPrivateServiceController *privateServiceController;
@property (nonatomic, readwrite, strong) DQDataStoreController *dataStoreController;
@property (nonatomic, readwrite, strong) STHTTPResourceController *imageController;
@property (nonatomic, readwrite, strong) DQHTTPChannelController *channelController;
@property (nonatomic, readwrite, strong) DQFacebookController *facebookController;
@property (nonatomic, readwrite, strong) DQTwitterController *twitterController;
@property (nonatomic, readwrite, strong) DQAuthenticationController *authenticationController;
@property (nonatomic, readwrite, strong) DQCommentPublishController *publishController;
@property (nonatomic, readwrite, strong) DQQuestPublishController *questPublishController;
@property (nonatomic, readwrite, strong) DQPaymentObserver *paymentObserver;
@property (nonatomic, readwrite, strong) DQShopController *shopController;
@property (nonatomic, readwrite, strong) DQCommentViewTracker *commentViewTracker;
@property (nonatomic, readwrite, strong) DQPlaybackDataManager *playbackDataManager;
@property (nonatomic, readwrite, strong) DQFollowController *followController;
@property (nonatomic, readwrite, strong) DQStarController *starController;

@end

@implementation DQApplicationController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPaymentObserverDidRestoreTransactions object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPaymentObserverFailedToRestoreTransactions object:nil];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [DQLocalization setup];
        NSFileManager *fm = [[NSFileManager alloc] init];
        _previouslyLaunchedAppVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:DQCurrentAppVersionKey] copy];
        if (!_previouslyLaunchedAppVersion)
        {
            if ([fm fileExistsAtPath:[[fm applicationSupportPath] stringByAppendingPathComponent:@"DQDataStoreController"]])
            {
                // upgrading from 1.0.1 or 1.0.2
                _previouslyLaunchedAppVersion = @"1.0";
            }
        }
        _runningAppVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] copy];

        [[NSUserDefaults standardUserDefaults] setObject:_runningAppVersion forKey:DQCurrentAppVersionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSString *appSupportPath = [fm applicationSupportPath];
        _draftsPath = [appSupportPath stringByAppendingPathComponent:@"Drafts"];
        _uploadsPath = [appSupportPath stringByAppendingPathComponent:@"Uploads"];
        [fm recursivelyCreatePath:_draftsPath];
        [fm recursivelyCreatePath:_uploadsPath];
        objc_setAssociatedObject([DQCommentUpload class], kDQCommentUploadUploadsPathKey, _uploadsPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject([DQQuestUpload class], kDQQuestUploadUploadsPathKey, _draftsPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return self;
}

- (BOOL)runMigrations
{
    if ([self.previouslyLaunchedAppVersion hasPrefix:@"1."])
    {
        // upgrade from 1.0 to 3.0
        DQMigrate1xxTo300 *migration = [[DQMigrate1xxTo300 alloc] init];
        return [migration run];
    }
    if ([self.previouslyLaunchedAppVersion hasPrefix:@"2."])
    {
        // upgrade from 2.0 to 3.0
        DQMigrate2xxTo300 *migration = [[DQMigrate2xxTo300 alloc] init];
        return [migration run];
    }
    else if (self.previouslyLaunchedAppVersion) // for the next version, we need to review the migration and perhaps change to [self.previouslyLaunchedAppVersion isEqualToString:@"2.0"])
    {
        // copy quests and comment uploads into a fresh database
//        DQMigrate300To300 *migration = [[DQMigrate300To300 alloc] init];
//        return [migration run];
    }
    return YES;
}

- (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

+ (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

#pragma mark -
#pragma mark UIApplicationDelegate events

- (BOOL)finishLaunchingWithOptions:(NSDictionary *)launchOptions forApplication:(UIApplication *)application
{
    [[self class] configureUIAppearance];

    [self runMigrations];

    NSDictionary *defaultDefaults = @{
                                      DQApplicationCrashRecoveryAttemptsKey : @(0),
                                      DQApplicationTumblrSuccessRegexPatternKey : @"<div style=\"margin-bottom:10px; font-size:40px; color:#777;\">Done!</div>",
                                      DQApplicationOwnedBrushes : @[],
                                      DQApplicationAppiraterReviewURL : @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID",
                                      };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.paymentObserver = [[DQPaymentObserver alloc] initWithDelegate:self];
    [self addStandardObservations];

    self.accountController = [[DQAccountController alloc] initWithDelegate:self];
    self.followController = [[DQFollowController alloc] initWithDelegate:self];
    self.starController = [[DQStarController alloc] initWithDelegate:self];

    [self configureMainWindow];

    // Start Crashlytics
//    [Crashlytics startWithAPIKey:@"****************************************"];

    self.paymentObserver = [[DQPaymentObserver alloc] initWithDelegate:self];
    [self addStandardObservations];
    self.imageController = [[STHTTPResourceController alloc] initWithIdentifier:DQApplicationImageCacheDirectoryName cacheDirectory:nil];
    self.facebookController = [[DQFacebookController alloc] initWithDelegate:self];
    self.twitterController = [[DQTwitterController alloc] initWithDelegate:self];
    self.dataStoreController = [[DQDataStoreController alloc] init];
    self.playbackDataManager = [[DQPlaybackDataManager alloc] initWithImageController:self.imageController delegate:self];

    self.analyticsController = [[DQAnalyticsController alloc] initWithDelegate:self];
    self.shopController = [[DQShopController alloc] initWithDelegate:self];

    __weak typeof(self) weakSelf = self;
    self.shopController.runPendingTransactionsBlock = ^{
        [weakSelf.paymentObserver runPendingTransactions];
    };

    self.activityController = [self newActivityController];

    self.commentUploadController = [[DQCommentUploadController alloc] initWithUploadsPath:self.uploadsPath accountController:self.accountController delegate:self];
    self.questUploadController = [[DQQuestUploadController alloc] initWithDraftsPath:self.draftsPath accountController:self.accountController delegate:self];
    self.commentViewTracker = [[DQCommentViewTracker alloc] initWithDelegate:self];

    // Start Appirater
    [Appirater setAppId:@"*********"];
    [Appirater setTemplateReviewURL:self.appiraterReviewURL];
    // User receives at least one star and has been using the app for at least 2 days.
    [Appirater setDaysUntilPrompt:2];
    [Appirater setUsesUntilPrompt:-1];
    [Appirater setSignificantEventsUntilPrompt:1];
    [Appirater setTimeBeforeReminding:4];
    [Appirater appLaunched:YES];

    // Start Analytics Session
    [self.analyticsController startSession];

    // Register with Urban Airshp
    //[self.accountController startUAWithLaunch];
    [self.accountController configureLocalQOTDNotification];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceErrorEncountered:) name:DQServiceErrorNotification object:nil];

    // set up a default, fail-safe launchCompletionBlock in case nothing else sets it
    self.launchCompletionBlock = ^{
        [weakSelf initializeViewStateWithLaunchOptions:launchOptions ?: @{}];
    };

    if ([self canOpenURLFromLaunchOptionsDictionary:launchOptions forApplication:application])
    {
        // launchCompletionBlock will be set by openURL:sourceApplication:annotation:forApplication:
        // so do NOTHING here
        // we have the fail-safe launchCompletionBlock so we're okay.
    }
    else if ([self hasInterruptedQuest])
    {
        // heavy state sync's completion block should show editor for interrupted quest
        self.launchCompletionBlock = ^{
            [weakSelf showEditorForInterruptedQuest];
        };
    }
    return YES;
}

- (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation forApplication:(UIApplication *)application
{
    UIViewController *activeViewController = [self activeViewController];
    BOOL shouldOpenURL = [self shouldOpenURL:url fromViewController:activeViewController];
    if (self.hasLaunched)
    {
        return (
                shouldOpenURL &&
                [self dispatchURL:url sourceApplication:sourceApplication annotation:annotation forApplication:application fromActiveViewController:activeViewController checking:NO]
                );
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        self.launchCompletionBlock = ^{
            if (shouldOpenURL)
            {
                [weakSelf dispatchURL:url sourceApplication:sourceApplication annotation:annotation forApplication:application fromActiveViewController:activeViewController checking:NO];
            }
            else
            {
                [weakSelf initializeViewStateWithLaunchOptions:nil];
            }
        };
        return shouldOpenURL;
    }
}

- (void)background:(UIApplication *)application
{
    self.channelController.monitoring = NO;
}

- (void)foreground:(UIApplication *)application
{
    [Appirater appEnteredForeground:YES];
    self.channelController.monitoring = YES;
}

- (void)resignActive:(UIApplication *)application
{
    [self.commentViewTracker stop];
}

- (void)becomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;

    __weak typeof(self) weakSelf = self;
    dispatch_block_t complete = ^{
        if (weakSelf.launchCompletionBlock)
        {
            weakSelf.launchCompletionBlock();
            weakSelf.launchCompletionBlock = nil;
            weakSelf.hasLaunched = YES;
            if (weakSelf.accountController.loggedInAccount)
            {
                [weakSelf.activityController load];
            }
            [weakSelf addPostLaunchCompletionObservations];
        }
        [self.commentViewTracker start];
    };
    NSNumber *homeTimestamp = self.accountController.loggedInAccount.homeTabBadgeTimestamp;
    NSNumber *drawTimestamp = self.accountController.loggedInAccount.drawTabBadgeTimestamp;
    NSNumber *activityTimestamp = self.accountController.loggedInAccount.activityTabBadgeTimestamp;


    dispatch_block_t stateSyncBlock = ^{
        [weakSelf.publicServiceController requestStateSyncWithHomeTimestamp:homeTimestamp drawTimestamp:drawTimestamp activityTimestamp:activityTimestamp completionBlock:^(DQHTTPRequest *inRequest) {
            [weakSelf takeHeavyStateSync:inRequest.dq_responseDictionary];
            complete();
        } failureBlock:^(DQHTTPRequest *inRequest) {
            NSError *error = inRequest.error;
            if (weakSelf.launchCompletionBlock)
            {
                DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"DrawQuest Connection Failed", @"State sync with DrawQuest failed error title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedString(@"Retry", @"Prompt for a user to attempt a failed connection again.") otherButtonTitles:DQLocalizedString(@"Continue", @"Ignore connection failure confirmation button title"), nil];
                alert.dq_cancellationBlock = ^(DQAlertView *alertView) {
                    complete();
                };
                alert.dq_completionBlock = ^(DQAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex == [alertView cancelButtonIndex])
                    {
                        [weakSelf becomeActive:application];
                    }
                    else
                    {
                        complete();
                    }
                };
                [alert show];
            }
            else
            {
                complete();
            }
        }];
    };

    if (!self.routerServiceController)
    {
        self.routerServiceController = [[DQRouterServiceController alloc] initWithDelegate:self];
        [self.routerServiceController requestConfiguration:^{
            weakSelf.channelController = [[DQHTTPChannelController alloc] initWithDelegate:weakSelf];
            weakSelf.publicServiceController = [[DQPublicServiceController alloc] initWithDelegate:weakSelf];
            weakSelf.privateServiceController = [[DQPrivateServiceController alloc] initWithDelegate:weakSelf];

            weakSelf.privateServiceController.associatedFacebookTokenBlock = ^(DQHTTPRequestStatusBlock inCompletionBlock, DQHTTPRequestStatusBlock inFailureBlock) {
                [weakSelf.accountController setShareFacebookProfileIfNotExplicitlySet:YES completionBlock:inCompletionBlock failureBlock:inFailureBlock];
            };

            weakSelf.privateServiceController.associatedTwitterTokenBlock = ^(DQHTTPRequestStatusBlock inCompletionBlock, DQHTTPRequestStatusBlock inFailureBlock) {
                [weakSelf.accountController setShareTwitterProfileIfNotExplicitlySet:YES completionBlock:inCompletionBlock failureBlock:inFailureBlock];
            };

            stateSyncBlock();
        }];
    }
    else
    {
        stateSyncBlock();
    }
    [FBAppCall handleDidBecomeActive];
}

- (void)terminate:(UIApplication *)application
{
    /* From https://developers.facebook.com/docs/technical-guides/iossdk/session/
     the close method is called in the app delegate's applicationWillTerminate:
     method. This is a good practice to trigger the clean up any dependent
     objects that rely on an open session.
     */
    [[FBSession activeSession] close]; // FIXME: refactor into DQFacebookController
}

- (void)registerRemoteNotificationsWithDeviceToken:(NSData *)deviceToken forApplication:(UIApplication *)application
{
    //[self.accountController registerUAPushWithDeviceToken:deviceToken];
}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error forApplication:(UIApplication *)application
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), error);
}

- (void)receiveRemoteNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application
{
    if (application.applicationState == UIApplicationStateInactive)
    {
        [self handlePushNotificationWithDictionary:userInfo];
    }
}

- (void)receiveLocalNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application
{
    if (application.applicationState == UIApplicationStateInactive)
    {
        [self handlePushNotificationWithDictionary:userInfo];
    }
}

#pragma mark -
#pragma mark Push
// returns YES if the push notification changed the view, NO otherwise
- (BOOL)handlePushNotificationWithDictionary:(NSDictionary *)dictionary
{
    if (dictionary)
    {
        NSString *pushType = dictionary[@"push_notification_type"];

        // Appirater significant event, the user has responded to a star push notification
        if ([pushType isEqualToString:DQPushPayloadTypeStarred])
        {
            [Appirater userDidSignificantEvent:YES];
        }

        UIViewController *activeViewController = [self activeViewController];
        UIViewController *presentingViewController = [activeViewController isKindOfClass:[CVSEditorViewController class]] ? nil : activeViewController;
        if ([self shouldDispatchPushNotificationFromViewController:activeViewController])
        {
            // Application was launched by remote notification, navigate as appropriate, if applicable
            if ([pushType isEqualToString:DQPushPayloadTypeNoop])
            {
                return NO;
            }
            else if ([pushType isEqualToString:DQPushPayloadTypeStarred])
            {
                NSInteger integerCommentID = [dictionary[@"comment_id"] integerValue];
                NSInteger integerQuestID = [dictionary[@"quest_id"] integerValue];
                NSString *commentID = [NSString stringWithFormat:@"%ld", (long)integerCommentID];
                NSString *questID = [NSString stringWithFormat:@"%ld", (long)integerQuestID];
                [self showCommentWithID:commentID questID:questID source:@"Push-Starred" publishing:NO fromViewController:presentingViewController];
                return YES;
            }
            else if ([pushType isEqualToString:DQPushPayloadTypeQuestOfTheDay])
            {
                [self showQuestOfTheDay];
                return YES;
            }
            else if ([pushType isEqualToString:DQPushPayloadTypeNewColors])
            {
                // No behavior for new colors.
                return NO;
            }
            else if ([pushType isEqualToString:DQPushPayloadTypeFacebookFriendJoined] ||
                     [pushType isEqualToString:DQPushPayloadTypeTwitterFriendJoined] ||
                     [pushType isEqualToString:DQPushPayloadTypeFollowedByUser])
            {
                NSString *username = dictionary[@"username"];
                [self showProfileForUserWithUserName:username fromViewController:presentingViewController source:[@"Push-" stringByAppendingString:pushType]];
                return YES;
            }
            else if ([pushType isEqualToString:DQPushPayloadTypeFeaturedInExplore])
            {
                NSInteger integerCommentID = [dictionary[@"comment_id"] integerValue];
                NSString *commentID = [NSString stringWithFormat:@"%ld", (long)integerCommentID];
                [self showExploreForCommentWithID:commentID];
                return YES;
            }
            else if ([pushType isEqualToString:DQPushPayloadTypeNewColors])
            {
                self.accountController.loggedInAccount.currentColorAlertVersion = dictionary.dq_colorAlertVersion;
                if (self.accountController.loggedIn)
                {
                    [self showNewColorsAlert];
                }
                return NO;
            }
            else
            {
                // If we don't recognize the push notification, it's too new for their app version.
                [self showAppUpdateAlertWithMessage:DQLocalizedString(@"That notification is not supported by this version of DrawQuest. Please update to the latest version!", @"Alert message requesting the user update their app because they received a notification not supported by the current version")];
                return NO;
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Public API

- (void)addStandardObservations
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restorePurchasesComplete:) name:DQPaymentObserverDidRestoreTransactions object:self.paymentObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restorePurchasesFailed:) name:DQPaymentObserverFailedToRestoreTransactions object:self.paymentObserver];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self.paymentObserver];
}

- (void)addPostLaunchCompletionObservations
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(questOfTheDayUpdated:) name:DQHTTPChannelControllerQuestOfTheDayUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userActivityUpdated:) name:DQHTTPChannelControllerUserActivityUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coinBalanceUpdated:) name:DQHTTPChannelControllerCoinBalanceUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];
}

- (void)signOutFromViewController:(UIViewController *)presentingViewController
{
    __weak typeof(self) weakSelf = self;
    DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Confirmation", @"Confirmation alert title") message:DQLocalizedString(@"Are you sure you want to sign out?", @"User requested sign out confirmation message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Sign Out", @"Sign the currently signed in user out of DrawQuest"), nil];
    alert.dq_completionBlock = ^(DQAlertView *av, NSInteger buttonIndex) {
        if (buttonIndex != [av cancelButtonIndex])
        {
            __block BOOL hasFinishedRequest = NO;
            __block BOOL hasFinishedAnimation = NO;

            DQHUDView *hud = [[DQHUDView alloc] initWithFrame:presentingViewController.view.bounds];
            [hud showInView:presentingViewController.view animated:YES];
            hud.text = DQLocalizedString(@"Signing out", @"Message letting the user know they must wait as the sign out is completed");

            // Don't post notifications until the vc is dismissed and request has finished
            dispatch_block_t readyToLogoutBlock = ^{
                if (hasFinishedAnimation && hasFinishedRequest)
                {
                    [hud hideAnimated:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationDidChangeAccountNotification object:weakSelf userInfo:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationDidLogoutNotification object:weakSelf userInfo:nil];
                }
            };

            [presentingViewController dismissViewControllerAnimated:YES completion:^{
                hasFinishedAnimation = YES;
                readyToLogoutBlock();
            }];

            [weakSelf.accountController requestLogout:^(DQHTTPRequest *request) {
                hasFinishedRequest = YES;
                [weakSelf takeHeavyStateSync:request.dq_responseDictionary.dq_authHeavyStateSync];
                readyToLogoutBlock();
            } failureBlock:^(DQHTTPRequest *request) {
                [hud hideAnimated:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationDidChangeAccountNotification object:weakSelf userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationDidLogoutNotification object:weakSelf userInfo:nil];
                if (request.error)
                {
                    [weakSelf showGlobalAlertWithTitle:nil description:request.error.dq_displayDescription];
                }
            }];
        }
    };
    [alert show];
}

- (void)showGlobalAlertWithTitle:(NSString *)inTitle description:(NSString *)inDescription
{
    if (self.globalAlertDisplayed)
    {
        // TODO: what should be done if an alert is already displayed? Right now it looks like the
        // request to show an alert is just ignored. Perhaps the alerts should be queued instead?
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        self.globalAlertDisplayed = YES;
        DQAlertView *globalAlertView = [[DQAlertView alloc] initWithTitle:inTitle message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
        globalAlertView.dq_cancellationBlock = ^(DQAlertView *alert) {
            weakSelf.globalAlertDisplayed = NO;
        };
        globalAlertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
            weakSelf.globalAlertDisplayed = NO;
        };
        [globalAlertView show];
    }
}

- (void)takeHeavyStateSync:(NSDictionary *)responseDictionary
{
    // Twitter consumer key / secret
    [TWSignedRequest storeTwitterSyncString:responseDictionary.dq_twitterSync];

    // DrawQuest Upgrade is Available modal
    self.hasSeenAvailableUpgradeModal = NO;
    // hasSeenAvailableUpgradeModal is reset because after we see the modal, we tell the server we saw it
    // the server will not ask us to show the modal again if we've already seen it, unless the server has
    // decided we want them to see it again anyway.
    // so if the flag is present again, we'll show it again
    [self setVersionForAvailableUpgradeModal:responseDictionary.dq_versionOfAvailableUpgrade upgradeType:responseDictionary.dq_typeOfAvailableUpgrade];

    // Onboarding quest
    NSString *tumblrSucccessRegexPattern = responseDictionary.dq_realtimeTumblrSuccessRegexPattern;
    if (tumblrSucccessRegexPattern) {
        self.tumblrSuccessRegexPattern = tumblrSucccessRegexPattern;
    }

    NSArray *supportedLanguages = responseDictionary.dq_supportedLanguages;
    [DQLocalization setSupportedLanguages:supportedLanguages];

    NSString *localizationZipFileURLString = responseDictionary.dq_localizationZipFileURL;
    [DQLocalization setZipFileURLString:[localizationZipFileURLString copy]];

    // Feature Flags
    self.featureInviteFromFacebook = responseDictionary.dq_featureInviteFromFacebook;
    self.featureInviteFromTwitter = responseDictionary.dq_featureInviteFromTwitter;
    self.featureUserSearch = responseDictionary.dq_featureUserSearch;
    self.featureUARegistration = responseDictionary.dq_featureEnableUARegistration;
    self.featureUARegistrationBeforeAuth = responseDictionary.dq_featureEnableUARegistrationBeforeAuth;
    [DQPapertrailLogger logger].configuration = responseDictionary.dq_loggingConfiguration;

    self.rewardsDictionary = responseDictionary.dq_rewardsInfo;

    // Update user brushes
    for (NSDictionary *brush in responseDictionary.dq_userBrushes)
    {
        [self addOwnedBrush:brush];
    }

    // Update global brushes
    [self setGlobalBrushes:responseDictionary.dq_globalBrushes];

    self.commentViewTracker.uploadInterval = responseDictionary.dq_commentViewTrackerUploadInterval;

    // Update the Appirater review URL
    NSString *reviewURL = responseDictionary.dq_appiraterReviewURL;
    self.appiraterReviewURL = reviewURL;
    [Appirater setTemplateReviewURL:reviewURL];

    // Reminders
    NSDictionary *reminders = responseDictionary.dq_reminders;
    NSInteger inviteReminder = reminders.dq_inviteReminder;
    if (inviteReminder)
    {
        self.currentInviteReminder = inviteReminder;
    }

    [self.accountController takeHeavyStateSync:responseDictionary];

    // Update QotD
    DQDataStoreController *dataStoreController = self.dataStoreController;
    NSDictionary *currentQuestInfo = responseDictionary.dq_currentQuest;
    if (currentQuestInfo)
    {
        [dataStoreController createOrUpdateQuestsFromJSONList:[NSArray arrayWithObject:currentQuestInfo] inBackground:NO resultsBlock:nil];
        self.questOfTheDayID = currentQuestInfo.dq_serverID;
    }

    // Onboarding quest
    NSString *onboardingQuestID = responseDictionary.dq_realtimeOnboardingQuestID;
    if (onboardingQuestID)
    {
        self.firstRunQuestID = onboardingQuestID;
    }

    // Update completed quests
    NSArray *completedQuests = [[NSSet setWithArray:responseDictionary.dq_realtimeCompletedQuestIDs] allObjects];
    if (completedQuests.count)
    {
        self.accountController.loggedInAccount.completedQuestIDs = completedQuests;
        [dataStoreController markQuestsIDsFromJSONListCompleted:completedQuests inBackground:YES];
    }

    [self.channelController updateChannelInfoFromSyncJSONInfo:responseDictionary.dq_realtimeSyncInfo];
    self.channelController.monitoring = YES;
}

- (void)requestQuestWithServerID:(NSString *)questID resultBlock:(void (^)(DQQuest *quest))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestQuestWithServerID:questID completionBlock:^(DQHTTPRequest *request) {
        NSDictionary *dict = request.dq_responseDictionary;
        NSDictionary *questDict = dict.dq_quest;
        DQQuest *quest = [weakSelf.dataStoreController createOrUpdateQuestWithJSONInfo:questDict];
        if (resultBlock)
        {
            resultBlock(quest);
        }
    } failureBlock:^(DQHTTPRequest *request) {
        if (failureBlock)
        {
            failureBlock(request.error);
        }
    }];
}

- (void)requestCachedQuestWithServerID:(NSString *)questID resultBlock:(void (^)(DQQuest *quest))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    if (resultBlock)
    {
        DQQuest *quest = [self.dataStoreController questForServerID:questID];
        if (quest.content) // quests can be created with just a title, those are useless
        {
            resultBlock(quest);
        }
        else
        {
            [self requestQuestWithServerID:questID resultBlock:resultBlock failureBlock:failureBlock];
        }
    }
    else
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"requestCachedQuestWithServerID: resultBlock not provided." userInfo:nil];
    }
}

- (void)requestCommentWithServerID:(NSString *)commentID resultBlock:(void (^)(DQQuest *quest, DQComment *comment))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestCommentWithServerID:commentID completionBlock:^(DQHTTPRequest *request) {
        NSDictionary *dict = request.dq_responseDictionary;
        NSArray *comments = dict.dq_comments;
        NSDictionary *questDict = dict.dq_quest;
        NSString *questID = questDict.dq_serverID;
        [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:questID fromJSONList:comments questJSONDictionary:questDict inBackground:NO resultsBlock:^(NSArray *objects) {
            if ([objects count])
            {
                if (resultBlock)
                {
                    DQQuest *quest = [weakSelf.dataStoreController questForServerID:questID];
                    DQComment *comment = [weakSelf.dataStoreController commentForServerID:commentID];
                    resultBlock(quest, comment);
                }
            }
            else if (failureBlock)
            {
                failureBlock([NSError errorWithDomain:DQApplicationErrorDomain code:DQApplicationErrorCodeNoComments userInfo:nil]);
            }
        }];
    } failureBlock:^(DQHTTPRequest *request) {
        if (failureBlock)
        {
            failureBlock(request.error);
        }
    }];
}

- (void)requestCachedQuestForComment:(DQComment *)comment resultBlock:(void (^)(DQQuest *quest, DQComment *comment))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (resultBlock)
    {
        DQQuest *quest = [self.dataStoreController questForServerID:comment.questID];
        if (quest.content) // quests can be created with just a title, those are useless
        {
            resultBlock(quest, comment);
        }
        else
        {
            [self requestCommentWithServerID:comment.serverID resultBlock:resultBlock failureBlock:failureBlock];
        }
    }
    else
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"requestCachedQuestForComment: resultBlock not provided." userInfo:nil];
    }
}

- (void)requestCachedCommentWithServerID:(NSString *)commentID resultBlock:(void (^)(DQQuest *quest, DQComment *comment))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (resultBlock)
    {
        DQComment *comment = [self.dataStoreController commentForServerID:commentID];
        if (comment)
        {
            [self requestCachedQuestForComment:comment resultBlock:resultBlock failureBlock:failureBlock];
        }
        else
        {
            [self requestCommentWithServerID:commentID resultBlock:resultBlock failureBlock:failureBlock];
        }
    }
    else
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"requestCachedCommentWithServerID: resultBlock not provided." userInfo:nil];
    }
}

#pragma mark -
#pragma mark Public Modal Navigation Controller Factory API (template methods)

- (DQNavigationController *)newModalNavigationController
{
    return nil; // subclasses must override
}

- (DQNavigationController *)newModalNavigationControllerWithRootViewController:(UIViewController *)rootViewController
{
    return nil; // subclasses must override
}

#pragma mark -
#pragma mark Application Defaults

- (void)addOwnedBrush:(NSDictionary *)brush
{
    NSArray *ownedBrushes = self.ownedBrushes;
    if ( ! [ownedBrushes containsObject:brush])
    {
        ownedBrushes = [ownedBrushes arrayByAddingObject:brush];
        [[NSUserDefaults standardUserDefaults] setObject:ownedBrushes forKey:DQApplicationOwnedBrushes];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:CVSBrushesUpdatedNotication object:nil];
    }
}

- (NSArray *)ownedBrushes
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:DQApplicationOwnedBrushes];
}

- (void)setGlobalBrushes:(NSArray *)globalBrushes
{
    [[NSUserDefaults standardUserDefaults] setObject:globalBrushes forKey:DQApplicationGlobalBrushes];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)globalBrushes
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:DQApplicationGlobalBrushes];
}

- (void)setVersionForAvailableUpgradeModal:(NSString *)versionForAvailableUpgradeModal upgradeType:(NSString *)upgradeType
{
    [[NSUserDefaults standardUserDefaults] setObject:versionForAvailableUpgradeModal forKey:DQApplicationVersionForUpgradeModalKey];
    [[NSUserDefaults standardUserDefaults] setObject:upgradeType forKey:DQApplicationUpgradeType];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)versionForAvailableUpgradeModal
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationVersionForUpgradeModalKey];
}

- (NSString *)upgradeType
{
    return [[[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationUpgradeType] copy];
}

- (void)setTumblrSuccessRegexPattern:(NSString *)regexPattern
{
    [[NSUserDefaults standardUserDefaults] setObject:regexPattern forKey:DQApplicationTumblrSuccessRegexPatternKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)tumblrSuccessRegexPattern
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationTumblrSuccessRegexPatternKey];
}

- (void)setFeatureInviteFromFacebook:(BOOL)inviteFromFacebook
{
    [[NSUserDefaults standardUserDefaults] setBool:inviteFromFacebook forKey:DQApplicationFeatureInviteFromFacebookKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)featureInviteFromFacebook
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationFeatureInviteFromFacebookKey];
}

- (void)setFeatureInviteFromTwitter:(BOOL)inviteFromTwitter
{
    [[NSUserDefaults standardUserDefaults] setBool:inviteFromTwitter forKey:DQApplicationFeatureInviteFromTwitterKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)featureInviteFromTwitter
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationFeatureInviteFromTwitterKey];
}

- (void)setFeatureUserSearch:(BOOL)enableUserSearch
{
    [[NSUserDefaults standardUserDefaults] setBool:enableUserSearch forKey:DQApplicationFeatureUserSearchKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)featureUserSearch
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationFeatureUserSearchKey];
}

- (void)setFeatureUARegistration:(BOOL)enableUARegistration
{
    [[NSUserDefaults standardUserDefaults] setBool:enableUARegistration forKey:DQApplicationFeatureUARegistrationKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)featureUARegistration
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationFeatureUARegistrationKey];
}

- (void)setFeatureUARegistrationBeforeAuth:(BOOL)enableUARegistrationBeforeAuth
{
    [[NSUserDefaults standardUserDefaults] setBool:enableUARegistrationBeforeAuth forKey:DQApplicationFeatureUARegistrationBeforeAuthKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)featureUARegistrationBeforeAuth
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DQApplicationFeatureUARegistrationBeforeAuthKey];
}

- (void)setRewardsDictionary:(NSDictionary *)rewardsDictionary
{
    if (rewardsDictionary)
    {
        [[NSUserDefaults standardUserDefaults] setObject:rewardsDictionary forKey:DQApplicationRewardsDictionaryDefaultsKey];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQApplicationRewardsDictionaryDefaultsKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)rewardsDictionary
{
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:DQApplicationRewardsDictionaryDefaultsKey];
}

- (void)setAppiraterReviewURL:(NSString *)reviewURL
{
    [[NSUserDefaults standardUserDefaults] setObject:reviewURL forKey:DQApplicationAppiraterReviewURL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)appiraterReviewURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAppiraterReviewURL];
}

- (void)setCurrentInviteReminder:(NSInteger)value
{
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:DQApplicationCurrentInviteReminderKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)currentInviteReminder
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:DQApplicationCurrentInviteReminderKey];
}

- (void)setPreviousInviteReminder:(NSInteger)value
{
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:DQApplicationPreviousInviteReminderKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)previousInviteReminder
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:DQApplicationPreviousInviteReminderKey];
}

- (void)setFirstRunQuestID:(NSString *)inFirstRunQuestID
{
    NSString *currentFirstQuestID = [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationFirstRunQuestDefaultsKey];
    if ([inFirstRunQuestID isEqualToString:currentFirstQuestID]) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:inFirstRunQuestID forKey:DQApplicationFirstRunQuestDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationFirstRunQuestUpdatedNotification object:nil userInfo:nil];
}

- (NSString *)firstRunQuestID
{
    NSString *firstRunID = [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationFirstRunQuestDefaultsKey];
    if (!firstRunID.length) {
        return nil;
    }

    return firstRunID;
}

- (void)setQuestOfTheDayID:(NSString *)inQuestOfTheDayID
{
    NSString *currentQOTDID = [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationQuestOfTheDayDefaultsKey];
    if ([inQuestOfTheDayID isEqualToString:currentQOTDID]) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:inQuestOfTheDayID forKey:DQApplicationQuestOfTheDayDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // FIXME: move this flag to DQApplicationController too
    self.accountController.hasNewQuestOfTheDay = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationQOTDUpdatedNotification object:nil userInfo:nil];
}

- (NSString *)questOfTheDayID
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationQuestOfTheDayDefaultsKey];
}

#pragma mark -
#pragma mark Reminders

- (BOOL)shouldDisplayInviteReminder
{
    return self.currentInviteReminder > self.previousInviteReminder;
}

- (void)doneDisplayingInviteReminder
{
    self.previousInviteReminder = self.currentInviteReminder;
}

#pragma mark -
#pragma mark Account Change Notifications

- (void)accountChanged:(NSNotification *)notification
{
    //[self.accountController updateUAPushSettings];

    // Configure Local Notifications
    [self.accountController configureLocalQOTDNotification];

    if (self.accountController.loggedIn)
    {
        [self.activityController load];
    }
    else
    {
        [self.activityController reset];
        [self.followController reset];
        [self.starController reset];
        // TODO: Note from Jim: does this even make sense?
        // Don't change the view if the user is in the editor.
        [self initializeViewStateWithLaunchOptions:nil];
    }

    [self accountChangedWithNotification:notification];
}

#pragma mark -
#pragma mark Realtime Channel Notifications

- (void)questOfTheDayUpdated:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestCurrentQuestWithCompletionBlock:^(DQHTTPRequest *request) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *quests = responseDictionary.dq_quests;

        [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:NO resultsBlock:^(NSArray *objects) {
            weakSelf.questOfTheDayID = [(NSDictionary *)[quests firstObject] dq_serverID];
        }];

    } failureBlock:^(DQHTTPRequest *request) {
        // TODO: error handling?
    }];
    [self.publicServiceController requestQuestArchiveWithPage:nil completionBlock:^(DQHTTPRequest *request) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *quests = responseDictionary.dq_quests;

        [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:YES resultsBlock:nil];
    } failureBlock:^(DQHTTPRequest *request) {
        // TODO: error handling?
    }];
}

// channel controller was notified of new activities
- (void)userActivityUpdated:(NSNotification *)notification
{
    [self.activityController update];
}

- (void)coinBalanceUpdated:(NSNotification *)notification
{
    NSNumber *balance = [notification userInfo][DQHTTPChannelControllerCoinBalanceNotificationKey];
    [self.accountController updateCoinBalanceForLoggedInUser:balance];
}

#pragma mark -
#pragma mark Private API

- (void)serviceErrorEncountered:(NSNotification *)notification
{
    NSError *serviceError = [notification.userInfo objectForKey:DQServiceNotificationKeyError];
    NSString *reasonString = serviceError.dq_displayDescription;

    [self showGlobalAlertWithTitle:DQLocalizedString(@"Service Error", @"API Service error alert title") description:reasonString];
}

- (BOOL)canOpenURLFromLaunchOptionsDictionary:(NSDictionary *)launchOptions forApplication:(UIApplication *)application
{
    return launchOptions[UIApplicationLaunchOptionsURLKey] && [self dispatchURL:launchOptions[UIApplicationLaunchOptionsURLKey]
                                                              sourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]
                                                                     annotation:launchOptions[UIApplicationLaunchOptionsAnnotationKey]
                                                                 forApplication:application
                                                       fromActiveViewController:nil
                                                                       checking:YES];
}

- (void)restorePurchasesComplete:(NSNotification *)notification
{
    [self restorePurchasesComplete];
}

- (void)restorePurchasesFailed:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey:NSUnderlyingErrorKey];
    [self restorePurchasesFailedWithError:error];
}

#pragma mark -
#pragma mark Restoring Purchases

// CHECK
- (void)restorePurchasesComplete
{
    if (self.shopBarButtonRestorePurchasesCompletionBlock)
    {
        self.shopBarButtonRestorePurchasesCompletionBlock();
        self.shopBarButtonRestorePurchasesCompletionBlock = nil;
        self.shopBarButtonRestorePurchasesFailureBlock = nil;
    }
}

// CHECK
- (void)restorePurchasesFailedWithError:(NSError *)error
{
    if (self.shopBarButtonRestorePurchasesFailureBlock)
    {
        self.shopBarButtonRestorePurchasesFailureBlock(error);
        self.shopBarButtonRestorePurchasesCompletionBlock = nil;
        self.shopBarButtonRestorePurchasesFailureBlock = nil;
    }
}

#pragma mark -
#pragma mark App Update

- (void)openUpgradeURL
{
    NSURL *upgradeURL = [NSURL URLWithString:[@"http://itunes.apple.com/app/drawquest/id" stringByAppendingString:DQAppStoreAppID]];
    if ([[UIApplication sharedApplication] canOpenURL:upgradeURL])
    {
        [[UIApplication sharedApplication] openURL:upgradeURL];
    }
}

- (void)recordLastSeenModalUpgradeVersion:(NSString *)currentVersion
{
    [self.privateServiceController requestSetLastSeenModalUpgradeVersion:currentVersion failureBlock:nil];
}

- (void)showUpgradeIsAvailableAlert
{

    DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"New Version Available!", @"App update available alert title") message:DQLocalizedString(@"There's a new version of DrawQuest available. Upgrade now?", @"App update available alert message") delegate:nil cancelButtonTitle:DQLocalizedString(@"Later", @"App update available alert dismiss button title") otherButtonTitles:DQLocalizedString(@"Upgrade!", @"App update available alert confirmation button title"), nil];
    __weak typeof(self) weakSelf = self;
    alert.dq_completionBlock = ^(DQAlertView *alertView, NSInteger buttonIndex) {
        weakSelf.hasSeenAvailableUpgradeModal = YES;
        [weakSelf recordLastSeenModalUpgradeVersion:weakSelf.versionForAvailableUpgradeModal];
        if (buttonIndex != [alertView cancelButtonIndex])
        {
            [weakSelf openUpgradeURL];
        }
    };
    [alert show];
}

- (void)showAppUpdateAlertWithMessage:(NSString *)inMessage
{
    DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Update DrawQuest", @"Update app alert title")
                                                    message:inMessage
                                                   delegate:nil
                                          cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view")
                                          otherButtonTitles:DQLocalizedString(@"Update", @"Update app alert confirmation button title"), nil];
    alert.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex != [alert cancelButtonIndex])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey] stringByAppendingString:DQAppUpdateURL]]];
        }
    };
    [alert show];
}

#pragma mark -
#pragma mark Presenting the About Screen

- (DQAboutViewController *)showAboutFromViewController:(UIViewController *)presentingViewController
{
    DQAboutViewController *aboutViewController = nil;
    if (presentingViewController)
    {
        aboutViewController = [[DQAboutViewController alloc] initWithDelegate:self];
        DQNavigationController *modalNavController = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [self newModalNavigationControllerWithRootViewController:aboutViewController] : nil;
        DQController *controller = [[DQController alloc] initWithDelegate:self];
        __weak typeof(presentingViewController) weakPVC = presentingViewController;
        aboutViewController.navigationItem.hidesBackButton = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            aboutViewController.navigationItem.rightBarButtonItem = [controller newDoneBarButtonItemWithBlock:^(id sender) {
                [weakPVC dismissViewControllerAnimated:YES completion:nil];
            }];
            [presentingViewController presentViewController:modalNavController animated:YES completion:nil];
        }
        else
        {
            [self pushViewController:aboutViewController ontoNavigationController:presentingViewController.navigationController];
        }
    }
    return aboutViewController;
}

#pragma mark -
#pragma mark Presenting an Editor

- (BOOL)hasInterruptedQuest
{
    BOOL result = NO;
    NSString *serverID = [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationDrawingCrashProtectionQuestServerIDKey];
    if (serverID)
    {
        DQQuest *interruptedQuest = [self.dataStoreController questForServerID:serverID];
        if (interruptedQuest)
        {
            result = YES;
        }
    }
    return result;
}

#pragma mark Facebook Access

- (BOOL)hasOpenFacebookSession
{
    return [self.facebookController hasOpenFacebookSession];
}

- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions
{
    return [self.facebookController hasOpenFacebookSessionWithPermissions:permissions];
}

- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
{
    return [self.facebookController openFacebookSessionPermissionsMissingFromPermissions:permissions];
}

- (NSString *)openFacebookSessionAccessToken
{
    return [self.facebookController openFacebookSessionAccessToken];
}

- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.facebookController requestFacebookAccessForFeature:feature readPermissions:readPermissions publishPermissions:publishPermissions cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookPublishAccessForFeature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.facebookController requestFacebookAccessForFeature:feature readPermissions:@[@"email"] publishPermissions:@[@"publish_actions"] cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

#pragma mark -
#pragma mark Publishing

- (DQFirstQuestCompletionViewController *)newFirstQuestCompletionViewControllerForPublishing:(BOOL)isPublishing
{
    DQFirstQuestCompletionViewController *completionViewController = [[DQFirstQuestCompletionViewController alloc] initWithDelegate:self];
    completionViewController.title = isPublishing ? DQLocalizedString(@"Nice Questing!", @"Message complementing users on a job well done as they post a drawing") : DQLocalizedString(@"Happy Questing!", @"Sign up completed modal title");
    return completionViewController;
}

- (DQCommentPublishController *)newCommentPublishController
{
    __weak typeof(self) weakSelf = self;
    DQCommentPublishController *result = [[DQCommentPublishController alloc] initWithDelegate:self accountController:self.accountController commentUploadController:self.commentUploadController];
    result.makeModalNavigationControllerBlock = ^(DQCommentPublishController *c) {
        return [weakSelf newModalNavigationController];
    };
    result.makePublishAuthViewControllerBlock = ^(DQCommentPublishController *c) {
        return [[DQPublishAuthViewController alloc] initWithDelegate:weakSelf];
    };
    result.makeAddFriendsViewControllerBlock = ^(DQCommentPublishController *c) {
        DQAddFriendsViewController *vc = nil;
        if ([self featureInviteFromFacebook] || [self featureInviteFromTwitter])
        {
            vc = [weakSelf newAddFriendsViewControllerForSignupService:c.signupService];
        }
        return vc;
    };
    result.makeNiceJobViewControllerBlock = ^(DQCommentPublishController *c) {
        return [weakSelf newFirstQuestCompletionViewControllerForPublishing:YES];
    };
    return result;
}

- (DQQuestPublishController *)newQuestPublishController
{
    DQQuestUpload *upload = [[self.dataStoreController questUploads] firstObject];
    if (!upload)
    {
        upload = [self.dataStoreController createQuestUpload];
    }
    DQQuestPublishController *result = [[DQQuestPublishController alloc] initWithDelegate:self accountController:self.accountController questUpload:upload questUploadController:self.questUploadController];
    return result;
}

- (void)requestPublishFromEditorViewController:(CVSEditorViewController *)editorViewController cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (self.publishController)
    {
        NSLog(@"already publishing, ignoring");
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        self.publishController = [self newCommentPublishController];
        [self.publishController presentInModalNavigationController:[self newModalNavigationController] forEditorViewController:editorViewController cancellationBlock:^{
            if (cancellationBlock)
            {
                cancellationBlock();
            }
            weakSelf.publishController = nil;
        } completionBlock:^{
            if (completionBlock)
            {
                completionBlock();
            }
            weakSelf.publishController = nil;
        } failureBlock:^(NSError *error) {
            if (failureBlock)
            {
                failureBlock(error);
            }
            weakSelf.publishController = nil;
        }];
    }
}

- (void)requestPublishQuestFromViewController:(UIViewController *)presentingViewController cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    self.questPublishController = [self newQuestPublishController];
    [self.questPublishController presentFromViewController:presentingViewController cancellationBlock:^{
        if (cancellationBlock)
        {
            cancellationBlock();
        }
        weakSelf.questPublishController = nil;
    } completionBlock:^{
        if (completionBlock)
        {
            completionBlock();
        }
        weakSelf.questPublishController = nil;
    } failureBlock:^(NSError *error) {
        if (failureBlock)
        {
            failureBlock(error);
        }
        weakSelf.questPublishController = nil;
    }];
}

#pragma mark -
#pragma mark New Sharing Controller

- (DQSharingController *)newSharingController
{
    __weak typeof(self) weakSelf = self;

    DQSharingController *c = [[DQSharingController alloc] initWithDelegate:self];
    c.imageController = self.imageController;
    c.tumblrSuccessRegexPattern = self.tumblrSuccessRegexPattern;
    c.makeNavigationControllerBlock = ^(DQSharingController *c, UIViewController *rootViewController) {
        return [weakSelf newModalNavigationControllerWithRootViewController:rootViewController];
    };
    c.makeControllerBlock = ^(DQSharingController *c) {
        return [[DQController alloc] initWithDelegate:self];
    };
    return c;
}

#pragma mark -
#pragma mark New Settings View Controller

- (DQSettingsViewController *)newSettingsViewController:(UIViewController *)presentingViewController
{
    DQSettingsViewController *settingsViewController = [[DQSettingsViewController alloc] initWithDelegate:self accountController:self.accountController];

    __weak typeof(self) weakSelf = self;
    __weak UIViewController *weakPresentingViewController = presentingViewController;
    __weak typeof(settingsViewController) weakSettingsViewController = settingsViewController;
    DQController *c = [[DQController alloc] initWithDelegate:self];

    settingsViewController.navigationItem.leftBarButtonItem = [c newCancelBarButtonItemWithBlock:^(id sender) {
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];

    settingsViewController.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
        if (weakSettingsViewController.finishedLoading)
        {
            [weakSettingsViewController save:sender completionBlock:^{
                [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
            } failureBlock:^{
                // error messages are presented by the settings view controller, so there's nothing to do here
            }];
        }
        else
        {
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];

    settingsViewController.signOutBlock = ^(DQSettingsViewController *vc) {
        [weakSelf signOutFromViewController:weakPresentingViewController];
    };

    return settingsViewController;
}

#pragma mark -
#pragma mark New Shop View Controller

- (DQShopViewController *)newShopViewControllerWithTab:(DQShopViewControllerTab)inTab source:(NSString *)source
{
    // Run pending transactions when shop is opened
    [self.paymentObserver runPendingTransactions];

    DQShopViewController *shop = [[DQShopViewController alloc] initWithTab:inTab source:source delegate:self.shopController dataSource:self.shopController];
    shop.title = DQLocalizedString(@"Shop", @"Title for the shop area of the app where users can purchase new items");
    shop.navigationItem.hidesBackButton = YES;
    __weak typeof(self) weakSelf = self;
    shop.restorePurchasesBlock = ^(DQShopViewController *vc, DQButton *restoreButton) {
        [restoreButton disableWithActivityIndicator];
        weakSelf.shopBarButtonRestorePurchasesCompletionBlock = ^{
            [restoreButton enableAndRemoveActivityIndicator];
            // We need to dismiss the shop so they can reload it
            [vc.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        };
        weakSelf.shopBarButtonRestorePurchasesFailureBlock = ^(NSError *error) {
            [restoreButton enableAndRemoveActivityIndicator];
            if ([error code] != SKErrorPaymentCancelled)
            {
                [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Restore Error", @"Error restoring purchases the user has made in the shop alert title") description:error.dq_displayDescription];
            }
        };
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    };
    return shop;
}

#pragma mark -
#pragma mark Twitter Access

- (void)hasTwitterAccess:(void (^)(BOOL))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.twitterController hasTwitterAccess:resultBlock failureBlock:failureBlock];
}

- (void)dataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *, NSHTTPURLResponse *))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.twitterController requestDataForTwitterAccountWithURL:url parameters:parameters method:method resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)requestTwitterAccessInView:(UIView *)view fromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.twitterController requestTwitterAccessInView:view cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:completionBlock failureBlock:failureBlock];
}

#pragma mark -
#pragma mark Authentication

- (DQAuthenticationController *)newAuthenticationController
{
    __weak typeof(self) weakSelf = self;
    DQAuthenticationController *result = [[DQAuthenticationController alloc] initWithDelegate:self authServiceController:[[DQAuthServiceController alloc] initWithDelegate:self]];
    result.makeModalNavigationControllerBlock = ^(DQAuthenticationController *c) {
        return [weakSelf newModalNavigationController];
    };
    result.titleForSignInRightBarButtonItem = ^(DQAuthenticationController *c, BOOL publishing) {
        return publishing ? DQLocalizedString(@"Sign In & Post", @"Prompt for the user to sign into their DrawQuest account so they can upload an item") : DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account");
    };
    result.titleForSignUpRightBarButtonItem = ^(DQAuthenticationController *c, BOOL publishing) {
        return publishing ? DQLocalizedString(@"Sign Up & Post", @"Prompt for the user to sign up for DrawQuest so they can upload an item") : DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
    };
    result.makeAlmostThereViewControllerBlock = ^(DQAuthenticationController *c, BOOL publishing) {
        DQAlmostThereViewController *result = [[DQAlmostThereViewController alloc] initWithDelegate:weakSelf];
        result.submitButtonTitle = publishing ? DQLocalizedString(@"Sign Up & Post", @"Prompt for the user to sign up for DrawQuest so they can upload an item") : DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
        return result;
    };
    result.makeSignInViewControllerBlock = ^(DQAuthenticationController *c, BOOL publishing) {
        DQSignInViewController *result = [[DQSignInViewController alloc] initWithDelegate:weakSelf];
        result.submitButtonTitle = publishing ? DQLocalizedString(@"Sign In & Post", @"Prompt for the user to sign into their DrawQuest account so they can upload an item") : DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account");
        return result;
    };
    result.makeSignUpViewControllerBlock = ^(DQAuthenticationController *c, BOOL publishing) {
        DQSignUpViewController *result = [[DQSignUpViewController alloc] initWithDelegate:weakSelf showSocialLoginButtons:!c.publishing];
        result.submitButtonTitle = publishing ? DQLocalizedString(@"Sign Up & Post", @"Prompt for the user to sign up for DrawQuest so they can upload an item") : DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
        return result;
    };
    result.makeAddFriendsViewControllerBlock = ^(DQAuthenticationController *c, DQAuthenticationSignupService signupService) {
        DQAddFriendsViewController *vc = nil;
        if ([self featureInviteFromFacebook] || [self featureInviteFromTwitter])
        {
            vc = [weakSelf newAddFriendsViewControllerForSignupService:signupService];
        }
        return vc;
    };
    result.signedUpBlock = ^(DQAuthenticationSignupService signupService) {
        if (signupService == DQAuthenticationSignupServiceFacebook)
        {
            [weakSelf.accountController setShareFacebookProfileIfNotExplicitlySet:YES completionBlock:nil failureBlock:nil];
        }
        else if (signupService == DQAuthenticationSignupServiceTwitter)
        {
            [weakSelf.accountController setShareTwitterProfileIfNotExplicitlySet:YES completionBlock:nil failureBlock:nil];
        }
    };
    return result;
}

- (void)startNewAuthenticationSessionWithOption:(DQAuthenticationOption)option fromView:(UIView *)sender fromViewController:(UIViewController *)vc modalNavigationController:(DQNavigationController *)modalNavigationController publishing:(BOOL)isPublishing twitterSheetDismissedBlock:(DQAuthenticationControllerBlock)twitterSheetDismissedBlock cancellationBlock:(DQAuthenticationControllerBlock)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(DQAuthenticationControllerFailureBlock)failureBlock
{
    if (option == DQAuthenticationOptionDefault)
    {
        if (self.accountController.hasUserEverLoggedIn)
        {
            [self.authenticationController startSignInFromView:sender fromViewController:vc modalNavigationController:modalNavigationController publishing:isPublishing twitterSheetDismissedBlock:twitterSheetDismissedBlock cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
        }
        else
        {
            [self.authenticationController startSignUpFromView:sender fromViewController:vc modalNavigationController:modalNavigationController withOption:option publishing:isPublishing twitterSheetDismissedBlock:twitterSheetDismissedBlock cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
        }
    }
    else if (option == DQAuthenticationOptionSignIn)
    {
        [self.authenticationController startSignInFromView:sender fromViewController:vc modalNavigationController:modalNavigationController publishing:isPublishing twitterSheetDismissedBlock:twitterSheetDismissedBlock cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
    }
    else
    {
        [self.authenticationController startSignUpFromView:sender fromViewController:vc modalNavigationController:modalNavigationController withOption:option publishing:isPublishing twitterSheetDismissedBlock:twitterSheetDismissedBlock cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
    }
}

// called by initializeViewStateWithLaunchOptions:
- (void)requestSignInFromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestAuthenticationWithOption:DQAuthenticationOptionSignIn fromView:nil fromViewController:vc modalNavigationController:nil publishing:NO twitterSheetDismissedBlock:nil cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

// called by commentPublishController:authenticateFromEditor:modalNavigationController:withOption:fromView:cancellationBlock:completionBlock:failureBlock:
- (void)requestAuthenticationFromViewController:(UIViewController *)vc modalNavigationController:(DQNavigationController *)modalNavigationController withOption:(DQAuthenticationOption)option fromView:(UIView *)sender publishing:(BOOL)isPublishing twitterSheetDismissedBlock:(dispatch_block_t)twitterSheetDismissedBlock cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestAuthenticationWithOption:option fromView:sender fromViewController:vc modalNavigationController:modalNavigationController publishing:isPublishing twitterSheetDismissedBlock:twitterSheetDismissedBlock cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

// called by discloseItemPressedFromViewController: and the DQ[View]Controller delegate methods
- (void)requestAuthenticationFromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestAuthenticationWithOption:DQAuthenticationOptionDefault fromView:nil fromViewController:vc modalNavigationController:nil publishing:NO twitterSheetDismissedBlock:nil cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

// called by the other requestAuthentication methods and requestSignInFromViewController:cancellationBlock:completionBlock:failureBlock:
- (void)requestAuthenticationWithOption:(DQAuthenticationOption)option fromView:(UIView *)sender fromViewController:(UIViewController *)vc modalNavigationController:(DQNavigationController *)inModalNavigationController publishing:(BOOL)isPublishing twitterSheetDismissedBlock:(dispatch_block_t)twitterSheetDismissedBlock cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (self.authenticationController)
    {
        NSLog(@"already authenticating, ignoring");
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        self.authenticationController = [self newAuthenticationController];
        [self startNewAuthenticationSessionWithOption:option fromView:sender fromViewController:vc modalNavigationController:inModalNavigationController publishing:isPublishing twitterSheetDismissedBlock:^(DQAuthenticationController *c, DQNavigationController *modalNavigationController) {
            weakSelf.authenticationController = nil;
            if (twitterSheetDismissedBlock)
            {
                twitterSheetDismissedBlock();
            }
            [c self]; // ensure it exists until we can clear the state
            // TODO: implement
        } cancellationBlock:^(DQAuthenticationController *c, DQNavigationController *modalNavigationController) {
            weakSelf.authenticationController = nil;
            // dismiss the modal navigation controller if it wasn't provided to us
            if (!inModalNavigationController && modalNavigationController.presentingViewController)
            {
                [modalNavigationController.presentingViewController dismissViewControllerAnimated:YES completion:cancellationBlock];
            }
            else if (cancellationBlock)
            {
                cancellationBlock();
            }
            [c self]; // ensure it exists until we can clear the state
        } completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
            weakSelf.authenticationController = nil;
            // dismiss the modal navigation controller if it wasn't provided to us
            if (!inModalNavigationController && modalNavigationController.presentingViewController)
            {
                [modalNavigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    if (completionBlock)
                    {
                        completionBlock(c, signupService, modalNavigationController);
                    }
                }];
            }
            else if (completionBlock)
            {
                completionBlock(c, signupService, modalNavigationController);
            }
            [c self]; // ensure it exists until we can clear the state
        } failureBlock:^(DQAuthenticationController *c, NSError *error, DQNavigationController *modalNavigationController) {
            weakSelf.authenticationController = nil;
            // dismiss the modal navigation controller if it wasn't provided to us
            if (!inModalNavigationController && modalNavigationController.presentingViewController)
            {
                [modalNavigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    if (failureBlock)
                    {
                        failureBlock(error);
                    }
                }];
            }
            else if (failureBlock)
            {
                failureBlock(error);
            }
            [c self]; // ensure it exists until we can clear the state
        }];
    }
}

#pragma mark -
#pragma mark Add Friends

- (DQAddFriendsViewController *)newAddFriendsViewControllerForSignupService:(DQAuthenticationSignupService)signupService
{
    __weak typeof(self) weakSelf = self;
    DQAddFriendsViewController *vc = [[DQAddFriendsViewController alloc] initWithDelegate:self facebookController:self.facebookController twitterController:self.twitterController signupService:signupService featureInviteFromFacebook:[self featureInviteFromFacebook] featureInviteFromTwitter:[self featureInviteFromTwitter]];
    vc.inviteEmailBlock = ^(UIViewController <MFMailComposeViewControllerDelegate> *pvc) {
        [weakSelf inviteFriendsViaEmailFromPresentingViewController:pvc];
    };
    return vc;
}

#pragma mark -
#pragma mark Sending Email

- (void)inviteFriendsViaEmailFromPresentingViewController:(UIViewController <MFMailComposeViewControllerDelegate> *)pvc
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (![MFMailComposeViewController canSendMail]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"No Email Accounts", @"Invite friends failed because no accounts are set up alert title") message:DQLocalizedString(@"Sorry, but to invite friends you'll need to setup an email account on your device first.", @"Invite friends failed because no accounts are set up alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
        [alertView show];
        return;
    }

    [self.analyticsController logEvent:DQAnalyticsEventTapInvite withParameters:nil];

    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:pvc.view.bounds];
    hud.text = DQLocalizedString(@"Loading", @"The user must wait as a request is currently being made.");
    [hud showInView:pvc.view animated:YES];

    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestCreateEmailInviteURLWithCompletionBlock:^(DQHTTPRequest *request, id JSONObject) {
        [hud hideAnimated:YES];

        if (request.error)
        {
            [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") description:request.error.dq_displayDescription];
        }

        NSString *shareURL = ((NSDictionary *)JSONObject).dq_sharingInviteURL;

        NSString *messageBody = [NSString stringWithFormat:DQLocalizedString(@"I'm using DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad. DrawQuest sends you daily drawing challenges and allows you to create your own to share with friends. You can follow me in the app as \"%@\". \n\nDownload DrawQuest for free here: %@", @"Invite a friend via email message body"), self.accountController.loggedInAccount.username, shareURL];

        MFMailComposeViewController *mailComposeController = [[MFMailComposeViewController alloc] init];
        mailComposeController.mailComposeDelegate = pvc;
        [mailComposeController setSubject:DQLocalizedString(@"Come draw with me on DrawQuest!", @"Invite a friend via email message subject")];
        [mailComposeController setMessageBody:messageBody isHTML:NO];
        [pvc presentViewController:mailComposeController animated:YES completion:nil];
    }];
}

#pragma mark -
#pragma mark DQAccountControllerDelegate methods

- (void)accountControllerDidReset:(DQAccountController *)c
{
    // Reset service controller but don't clear
    // it totally (still want to be able to do
    // auth requests)
    [self.publicServiceController reset];
    [self.privateServiceController reset];

    // Reset the real time apparatus
    [self.channelController reset];

    // Reset the Facebook Controller
    [self.facebookController reset];

    // Reset the Twitter Controller
    [self.twitterController reset];

    // Clear the data store controller
    [self.dataStoreController deletePersistentStore];

    // Clear the image cache
    [self.imageController clearResourceCache];
}

- (void)accountControllerDidChangeLoggedInAccount:(DQAccountController *)c
{
    DQAccount *account = self.accountController.loggedInAccount;
    if (account)
    {
        [self.channelController reset];
    }
}

#pragma mark -
#pragma mark DQTwiterControllerDelegate methods

- (void)twitterControllerDidForgetCredentials:(DQTwitterController *)c
{
    [self.accountController setShareToTwitterOn:NO completionBlock:nil failureBlock:nil];
}

#pragma mark -
#pragma mark DQAuthServiceControllerDelegate methods

- (void)authServiceController:(DQAuthServiceController *)authServiceController handleSuccessfulAuthForRequest:(DQHTTPRequest *)inRequest withResponseDictionary:(NSDictionary *)inDictionary completionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.accountController handleSuccessfulAuthForRequest:inRequest withResponseDictionary:inDictionary];
    [weakSelf takeHeavyStateSync:inDictionary.dq_authHeavyStateSync];

    NSDictionary *userInfo = @{DQUserInfoKeyAccount :self.accountController.loggedInAccount};
    [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationDidChangeAccountNotification object:self userInfo:userInfo];

    if ( ! inRequest.dq_responseDictionary.dq_wasLoginRequest)
    {
        // Make the 'new quest' badge show up for newly signed in users
        // because the daily quest is new to them.
        self.accountController.hasNewQuestOfTheDay = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:DQApplicationQOTDUpdatedNotification object:nil userInfo:nil];
    }

    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.featureUARegistration)
        {
            [[UAPush shared] setPushEnabled:YES];
        }
    });
     */

    if (inCompletionBlock)
    {
        inCompletionBlock(inRequest);
    }
}

#pragma mark -
#pragma mark DQControllerDelegate methods

- (DQDataStoreController *)dataStoreControllerForController:(DQController *)vc
{
    return self.dataStoreController;
}

- (DQPublicServiceController *)publicServiceControllerForController:(DQController *)c
{
    return self.publicServiceController;
}

- (DQPrivateServiceController *)privateServiceControllerForController:(DQController *)c
{
    return self.privateServiceController;
}

- (DQFacebookController *)facebookControllerForController:(DQController *)c
{
    return self.facebookController;
}

- (DQTwitterController *)twitterControllerForController:(DQController *)c
{
    return self.twitterController;
}

- (BOOL)isLoggedInForController:(DQController *)vc
{
    return self.accountController.loggedInAccount != nil;
}

- (BOOL)hasUserEverLoggedInForController:(DQController *)vc
{
    return self.accountController.hasUserEverLoggedIn;
}

- (DQAccount *)loggedInAccountForController:(DQController *)c
{
    return self.accountController.loggedInAccount;
}

- (void)authenticatedForController:(DQController *)c fromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestAuthenticationFromViewController:vc cancellationBlock:cancellationBlock completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        if (completionBlock)
        {
            completionBlock(signupService, modalNavigationController);
        }
    } failureBlock:failureBlock];
}

- (void)facebookAccessGrantedForController:(DQController *)c feature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestFacebookAccessForFeature:feature readPermissions:readPermissions publishPermissions:publishPermissions cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)facebookPublishAccessGrantedForController:(DQController *)c feature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestFacebookPublishAccessForFeature:feature cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)twitterAccessGrantedForController:(DQController *)c inView:(UIView *)view fromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestTwitterAccessInView:view fromViewController:vc cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)controller:(DQController *)c logEvent:(NSString *)event withParameters:(NSDictionary *)parameters
{
    [self.analyticsController logEvent:event withParameters:parameters];
}

- (BOOL)hasOpenFacebookSessionForController:(DQController *)c
{
    return [self hasOpenFacebookSession];
}

- (BOOL)controller:(DQController *)c hasOpenFacebookSessionWithPermissions:(NSArray *)permissions
{
    return [self hasOpenFacebookSessionWithPermissions:permissions];
}

- (NSArray *)controller:(DQController *)c openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions
{
    return [self openFacebookSessionPermissionsMissingFromPermissions:permissions];
}

- (NSString *)openFacebookSessionAccessTokenForController:(DQController *)c
{
    return [self openFacebookSessionAccessToken];
}

- (void)hasTwitterAccessForController:(DQController *)c resultBlock:(void (^)(BOOL))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self hasTwitterAccess:resultBlock failureBlock:failureBlock];
}

- (void)dataForTwitterAccountForController:(DQController *)c withURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *, NSHTTPURLResponse *))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self dataForTwitterAccountWithURL:url parameters:parameters method:method resultBlock:resultBlock failureBlock:failureBlock];
}

#pragma mark -
#pragma mark DQViewControllerDelegate methods

- (void)authenticatedFromViewController:(UIViewController<DQViewController> *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestAuthenticationFromViewController:vc cancellationBlock:cancellationBlock completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        if (completionBlock)
        {
            completionBlock(signupService, modalNavigationController);
        }
    } failureBlock:failureBlock];
}

- (void)facebookAccessGrantedForViewController:(UIViewController<DQViewController> *)vc feature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestFacebookAccessForFeature:feature readPermissions:readPermissions publishPermissions:publishPermissions cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)facebookPublishAccessGrantedForViewController:(UIViewController<DQViewController> *)vc feature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestFacebookPublishAccessForFeature:feature cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)twitterAccessGrantedInView:(UIView *)view fromViewController:(UIViewController<DQViewController> *)vc cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestTwitterAccessInView:view fromViewController:vc cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)viewController:(UIViewController<DQViewController> *)vc logEvent:(NSString *)event withParameters:(NSDictionary *)parameters
{
    [self.analyticsController logEvent:event withParameters:parameters];
}

- (DQDataStoreController *)dataStoreControllerForViewController:(UIViewController<DQViewController> *)vc
{
    return self.dataStoreController;
}

- (DQPublicServiceController *)publicServiceControllerForViewController:(UIViewController<DQViewController> *)vc
{
    return self.publicServiceController;
}

- (DQPrivateServiceController *)privateServiceControllerForViewController:(UIViewController<DQViewController> *)vc
{
    return self.privateServiceController;
}

- (BOOL)isLoggedInForViewController:(UIViewController<DQViewController> *)vc
{
    return self.accountController.loggedInAccount != nil;
}

- (DQAccount *)loggedInAccountForViewController:(UIViewController<DQViewController> *)vc
{
    return self.accountController.loggedInAccount;
}

- (BOOL)hasUserEverLoggedInForViewController:(UIViewController<DQViewController> *)vc
{
    return self.accountController.hasUserEverLoggedIn;
}

- (BOOL)hasOpenFacebookSessionForViewController:(UIViewController<DQViewController> *)vc
{
    return [self hasOpenFacebookSession];
}

- (BOOL)viewController:(UIViewController<DQViewController> *)vc hasOpenFacebookSessionWithPermissions:(NSArray *)permissions
{
    return [self hasOpenFacebookSessionWithPermissions:permissions];
}

- (NSArray *)viewController:(UIViewController<DQViewController> *)vc openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions
{
    return [self openFacebookSessionPermissionsMissingFromPermissions:permissions];
}

- (void)hasTwitterAccessForViewController:(UIViewController<DQViewController> *)vc resultBlock:(void (^)(BOOL))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self hasTwitterAccess:resultBlock failureBlock:failureBlock];
}

- (void)dataForTwitterAccountForViewController:(UIViewController<DQViewController> *)vc withURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *, NSHTTPURLResponse *))resultBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self dataForTwitterAccountWithURL:url parameters:parameters method:method resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)showDrawingDetailForCommentWithServerID:(NSString *)commentID fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    // Subclass for phone only for now
}

- (void)showDrawingDetailForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    // Subclass for phone only for now
}

- (void)showZoomableImageForComment:(DQComment *)comment fromView:(UIView *)view viewController:(UIViewController<DQViewController> *)viewController
{
    // Subclass for phone only for now
}

- (void)showAboutForViewController:(UIViewController<DQViewController> *)viewController
{
    [self showAboutFromViewController:viewController];
}

- (BOOL)hasNewQuestOfTheDayForViewController:(UIViewController<DQViewController> *)viewController
{
    return self.accountController.hasNewQuestOfTheDay;
}

- (void)setHasNewQuestOfTheDay:(BOOL)hasNewQuestOfTheDay forViewController:(UIViewController<DQViewController> *)viewController
{
    self.accountController.hasNewQuestOfTheDay = hasNewQuestOfTheDay;
}

- (void)showGalleryForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    [self showGalleryForQuestWithID:quest.serverID commentID:nil source:source publishing:NO fromViewController:viewController beforePresenting:nil];
}

- (void)showProfileForUsername:(NSString *)username fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    [self showProfileForUserWithUserName:username fromViewController:viewController source:source];
}

- (DQNavigationController *)newNavigationControllerForViewController:(UIViewController<DQViewController> *)vc
{
    return nil; // subclasses must override
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController forViewController:(UIViewController<DQViewController> *)vc
{
    return nil; // subclasses must override
}

#pragma mark - DQViewControllerDelegate Phone-specific methods

- (void)tappedPlaybackButton:(DQButton *)playbackButton forPlaybackImageView:(DQPlaybackImageView *)playbackImageView comment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController withRequestFinishedBlock:(void (^)(DQComment *))requestFinishedBlock
{
    if (playbackButton.selected)
    {
        [playbackImageView showPauseIcon];
        [playbackImageView pausePlayback];
        playbackButton.selected = NO;
        [playbackImageView stopDisplayingSpinner];
    }
    else if ([playbackImageView isPlayingOrPaused])
    {
        [playbackImageView showPlayIcon];
        playbackButton.selected = YES;
        [playbackImageView startPlayback];
    }
    else
    {
        [playbackImageView showPlayIcon];
        playbackButton.selected = YES;
        [playbackImageView startDisplayingSpinner];
        playbackButton.selected = YES;
        playbackButton.enabled = NO;
        __weak typeof(self) weakSelf = self;
        [self requestCachedQuestForComment:comment resultBlock:^(DQQuest *quest, DQComment *comment) {
            [self.playbackDataManager requestDrawingAndTemplateImageForComment:comment inQuest:quest fromViewController:viewController resultBlock:^(CVSDrawing *drawing, UIImage *templateImage) {
                playbackButton.enabled = YES;
                if (playbackButton.selected && playbackImageView.window)
                {
                    [playbackImageView stopDisplayingSpinner];
                    [playbackImageView playbackDrawing:drawing withTemplateImage:templateImage completionBlock:^{
                        playbackButton.selected = NO;
                    }];
                    [weakSelf.playbackDataManager requestLogPlaybackForComment:comment withCompletionBlock:^(DQComment *newComment) {
                        if (playbackImageView.window && requestFinishedBlock && newComment)
                        {
                            requestFinishedBlock(newComment);
                        }
                    }];
                }
                else if (requestFinishedBlock)
                {
                    requestFinishedBlock(nil);
                }
            } failureBlock:^(NSError *error) {
                [playbackImageView stopDisplayingSpinner];
                playbackButton.enabled = YES;
                playbackButton.selected = NO;
                // FIXME: display error
            }];
        } failureBlock:^(NSError *error) {
            [playbackImageView stopDisplayingSpinner];
            playbackButton.enabled = YES;
            playbackButton.selected = NO;
            // FIXME: display error
        }];
    }
}

- (void)tappedMoreOptionsButtonForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    // Subclass
}

- (void)tappedMoreOptionsButtonForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    // Subclass
}

- (void)tappedShareButtonForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    // Subclass
}

- (void)tappedShareButtonForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    // Subclass
}

- (void)tappedCancelButton:(UIButton *)cancelButton forCommentUpload:(DQCommentUpload *)commentUpload withDeletionBlock:(dispatch_block_t)deletionBlock;
{
    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Delete Upload", @"Delete upload alert title") message:DQLocalizedString(@"Are you sure you want to delete this drawing?", @"Delete upload alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Delete", @"Destroy item alert confirmation button title"), nil];
    __weak typeof(self) weakSelf = self;
    alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex != [alert cancelButtonIndex])
        {
            cancelButton.enabled = NO;
            [weakSelf.dataStoreController deleteCommentUpload:commentUpload];
            if (deletionBlock)
            {
                deletionBlock();
            }
        }
    };
    [alertView show];
}

- (void)tappedRetryButton:(UIButton *)retryButton forCommentUpload:(DQCommentUpload *)commentUpload fromViewController:(UIViewController<DQViewController> *)viewController
{
    if (commentUpload.status == DQCommentUploadStatusFailedWithInvalidFacebookToken)
    {
        retryButton.enabled = NO;
        [self.facebookController reset];
        __weak typeof(self) weakSelf = self;
        [self.facebookController requestFacebookPublishAccessForFeature:@"comment-upload-retry-button" cancellationBlock:^{
            retryButton.enabled = YES;
        } completionBlock:^(NSString *facebookToken) {
            retryButton.enabled = YES;
            [weakSelf.dataStoreController saveFacebookToken:facebookToken forCommentUpload:commentUpload];
            [weakSelf.commentUploadController retryCommentUpload:commentUpload];
        } failureBlock:^(NSError *error) {
            retryButton.enabled = YES;
            NSString *message = error.localizedDescription;
            [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") description:message];
        }];
    }
    if (commentUpload.status == DQCommentUploadStatusFailedWithInvalidTwitterToken)
    {
        retryButton.enabled = NO;
        [self.twitterController reset];
        __weak typeof(self) weakSelf = self;
        [self.twitterController requestTwitterAccessInView:retryButton fromViewController:viewController withCancellationBlock:^{
            retryButton.enabled = YES;
        } accountSelectedBlock:^{
            // <#code#>
        } completionBlock:^{
            retryButton.enabled = YES;
            [weakSelf.dataStoreController saveTwitterToken:weakSelf.twitterController.twitterAccessToken twitterTokenSecret:weakSelf.twitterController.twitterAccessTokenSecret forCommentUpload:commentUpload];
            [weakSelf.commentUploadController retryCommentUpload:commentUpload];
        } failureBlock:^(NSError *error) {
            retryButton.enabled = YES;
            NSString *message = error.localizedDescription;
            [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Twitter Error", @"Twitter error alert title") description:message];
        }];
    }
    else
    {
        [self.commentUploadController retryCommentUpload:commentUpload];
    }
}

#pragma mark -
#pragma mark DQNavigationControllerDelegate methods

// there none at this time

#pragma mark -
#pragma mark CVSEditorViewControllerDelegate methods

- (void)commentEditorViewControllerDone:(CVSEditorViewController *)c
{
    if ([c isDirty])
    {
        __weak typeof(self) weakSelf = self;
        [self requestPublishFromEditorViewController:c cancellationBlock:^{
            // TODO: do anything if they cancel? I don't think anything is necessary here
        } completionBlock:^{
            // this code moved into DQPublishController
        } failureBlock:^(NSError *error) {
            [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Post Error", @"Upload error alert title") description:error.dq_displayDescription];
        }];
    }
    else
    {
        [self showGlobalAlertWithTitle:DQLocalizedString(@"Empty Drawing", @"Empty drawing alert title") description:DQLocalizedString(@"Please draw something before posting it!", @"Empty drawing alert message")];
    }
}

#pragma mark -
#pragma mark DQCommentPublishControllerDelegate methods

- (void)commentPublishController:(DQCommentPublishController *)publishController
          authenticateFromEditor:(CVSEditorViewController *)editorViewController
       modalNavigationController:(DQNavigationController *)modalNavigationController
                      withOption:(DQAuthenticationOption)option
                        fromView:(UIView *)sender
    twitterSheetDismissedBlock:(dispatch_block_t)twitterSheetDismissedBlock
               cancellationBlock:(dispatch_block_t)cancellationBlock
                 completionBlock:(DQAuthenticationCompletionBlock)completionBlock
                    failureBlock:(void (^)(NSError *error))failureBlock
{
    [self requestAuthenticationFromViewController:editorViewController modalNavigationController:modalNavigationController withOption:option fromView:sender publishing:YES twitterSheetDismissedBlock:twitterSheetDismissedBlock cancellationBlock:cancellationBlock completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        if (completionBlock)
        {
            completionBlock(signupService, modalNavigationController);
        }
    } failureBlock:failureBlock];
}

#pragma mark -
#pragma mark DQShopControllerDelegate methods

- (void)shopController:(DQShopController *)shopController updateCoinBalanceForLoggedInUser:(NSNumber *)inCoinBalance
{
    [self.accountController updateCoinBalanceForLoggedInUser:inCoinBalance];
}

- (void)shopController:(DQShopController *)shopController updateColorsForLoggedInUser:(NSArray *)colors;
{
    [self.accountController updateColorsForLoggedInUser:colors];
}

- (void)shopController:(DQShopController *)shopController addOwnedBrush:(NSDictionary *)brush
{
    [self addOwnedBrush:brush];
}

- (NSArray *)ownedBrushesForShopController:(DQShopController *)shopController
{
    return [self ownedBrushes];
}

@end
