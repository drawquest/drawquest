//
//  DQApplicationController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

// Controllers
#import "DQAccountController.h"
#import "DQAnalyticsController.h"
#import "DQActivityController.h"
#import "DQCommentUploadController.h"
#import "DQQuestUploadController.h"
#import "DQAuthServiceController.h"
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"
#import "DQDataStoreController.h"
#import "STHTTPResourceController.h"
#import "DQHTTPChannelController.h"
#import "DQFacebookController.h"
#import "DQTwitterController.h"
#import "DQAuthenticationController.h"
#import "DQCommentPublishController.h"
#import "DQQuestPublishController.h"
#import "DQPaymentObserver.h"
#import "DQShopController.h"
#import "DQCommentViewTracker.h"
#import "DQSharingController.h"
#import "DQPlaybackDataManager.h"
#import "DQFollowController.h"
#import "DQStarController.h"

// View Controllers
#import "DQNavigationController.h"
#import "CVSEditorViewController.h"
#import "DQHomeViewController.h"
#import "DQProfileViewController.h"
#import "DQAboutViewController.h"
#import "DQSettingsViewController.h"

extern NSString *DQApplicationErrorDomain;
extern NSInteger DQApplicationErrorCodeNoComments;

extern NSString *DQAppStoreAppID;

@interface DQApplicationController : NSObject <DQControllerDelegate, DQViewControllerDelegate, DQAuthServiceControllerDelegate, DQCommentPublishControllerDelegate, DQNavigationControllerDelegate>

@property (nonatomic, readonly, assign) BOOL hasLaunched;
@property (nonatomic, readonly, copy) NSString *previouslyLaunchedAppVersion;
@property (nonatomic, readonly, copy) NSString *runningAppVersion;
@property (nonatomic, readwrite, assign) BOOL hasSeen1xxTo2xxUpgradeFlow; // only needed for one launch of the app because previouslyLaunchedAppVersion won't be nil after upgrading
@property (nonatomic, readwrite, assign) BOOL hasSeenAvailableUpgradeModal; // not persisted, this is reset in takeHeavyStateSync:, server has full control over this in each launch
@property (nonatomic, readonly, copy) NSString *draftsPath;
@property (nonatomic, readonly, copy) NSString *uploadsPath;
@property (nonatomic, readonly, copy) dispatch_block_t launchCompletionBlock;
@property (nonatomic, readonly, assign) BOOL globalAlertDisplayed;
@property (nonatomic, readonly, copy) NSArray *ownedBrushes;
@property (nonatomic, readonly, copy) NSArray *globalBrushes;
@property (nonatomic, readonly, weak) NSDictionary *rewardsDictionary;
@property (nonatomic, readonly, assign) BOOL featureInviteFromFacebook;
@property (nonatomic, readonly, assign) BOOL featureInviteFromTwitter;
@property (nonatomic, readonly, assign) BOOL featureUserSearch;
@property (nonatomic, readonly, assign) BOOL featureUARegistration;
@property (nonatomic, readonly, assign) BOOL featureUARegistrationBeforeAuth;
@property (nonatomic, readwrite, copy) NSString *versionForAvailableUpgradeModal;
@property (nonatomic, readonly, copy) NSString *upgradeType;
@property (nonatomic, readonly, copy) NSString *tumblrSuccessRegexPattern;
@property (nonatomic, readwrite, copy) NSString *firstRunQuestID;
@property (nonatomic, readwrite, copy) NSString *questOfTheDayID;

@property (nonatomic, readonly, strong) DQAccountController *accountController;
@property (nonatomic, readonly, strong) DQAnalyticsController *analyticsController;
@property (nonatomic, readonly, strong) DQActivityController *activityController;
@property (nonatomic, readonly, strong) DQCommentUploadController *commentUploadController;
@property (nonatomic, readonly, strong) DQQuestUploadController *questUploadController;
@property (nonatomic, readonly, strong) DQPublicServiceController *publicServiceController;
@property (nonatomic, readonly, strong) DQPrivateServiceController *privateServiceController;
@property (nonatomic, readonly, strong) DQDataStoreController *dataStoreController;
@property (nonatomic, readonly, strong) STHTTPResourceController *imageController;
@property (nonatomic, readonly, strong) DQHTTPChannelController *channelController;
@property (nonatomic, readonly, strong) DQFacebookController *facebookController;
@property (nonatomic, readonly, strong) DQTwitterController *twitterController;
@property (nonatomic, readonly, strong) DQAuthenticationController *authenticationController;
@property (nonatomic, readonly, strong) DQCommentPublishController *publishController;
@property (nonatomic, readonly, strong) DQQuestPublishController *questPublishController;
@property (nonatomic, readonly, strong) DQPaymentObserver *paymentObserver;
@property (nonatomic, readonly, strong) DQShopController *shopController;
@property (nonatomic, readonly, strong) DQCommentViewTracker *commentViewTracker;
@property (nonatomic, readonly, strong) DQPlaybackDataManager *playbackDataManager;
@property (nonatomic, readonly, strong) DQFollowController *followController;
@property (nonatomic, readonly, strong) DQStarController *starController;

@property (nonatomic, copy) dispatch_block_t shopBarButtonRestorePurchasesCompletionBlock;
@property (nonatomic, copy) void (^shopBarButtonRestorePurchasesFailureBlock)(NSError *error);

#pragma mark -
#pragma mark UIApplicationDelegate event handling

- (BOOL)finishLaunchingWithOptions:(NSDictionary *)launchOptions forApplication:(UIApplication *)application;
- (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation forApplication:(UIApplication *)application;
- (void)foreground:(UIApplication *)application;
- (void)background:(UIApplication *)application;
- (void)becomeActive:(UIApplication *)application;
- (void)resignActive:(UIApplication *)application;
- (void)terminate:(UIApplication *)application;
- (void)registerRemoteNotificationsWithDeviceToken:(NSData *)deviceToken forApplication:(UIApplication *)application;
- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error forApplication:(UIApplication *)application;
- (void)receiveRemoteNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application;
- (void)receiveLocalNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application;

#pragma mark -
#pragma mark Public API

- (void)addStandardObservations;
- (void)addPostLaunchCompletionObservations;
- (void)signOutFromViewController:(UIViewController *)presentingViewController;
- (void)showGlobalAlertWithTitle:(NSString *)inTitle description:(NSString *)inDescription;
- (void)takeHeavyStateSync:(NSDictionary *)responseDictionary;
- (void)requestQuestWithServerID:(NSString *)questID resultBlock:(void (^)(DQQuest *quest))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestCachedQuestWithServerID:(NSString *)questID resultBlock:(void (^)(DQQuest *quest))resultBlock failureBlock:(void (^)(NSError *))failureBlock;
- (void)requestCommentWithServerID:(NSString *)commentID resultBlock:(void (^)(DQQuest *quest, DQComment *comment))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestCachedQuestForComment:(DQComment *)comment resultBlock:(void (^)(DQQuest *quest, DQComment *comment))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestCachedCommentWithServerID:(NSString *)commentID resultBlock:(void (^)(DQQuest *quest, DQComment *comment))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (DQSharingController *)newSharingController;
- (DQSettingsViewController *)newSettingsViewController:(UIViewController *)presentingViewController;
- (DQShopViewController *)newShopViewControllerWithTab:(DQShopViewControllerTab)inTab source:(NSString *)source;

#pragma mark -
#pragma mark Public Publishing API

- (DQCommentPublishController *)newCommentPublishController;
- (DQQuestPublishController *)newQuestPublishController;

- (void)requestPublishFromEditorViewController:(CVSEditorViewController *)editorViewController cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)commentEditorViewControllerDone:(CVSEditorViewController *)c;

- (void)requestPublishQuestFromViewController:(UIViewController *)presentingViewController cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

#pragma mark -
#pragma mark Public Invitation API

- (DQAddFriendsViewController *)newAddFriendsViewControllerForSignupService:(DQAuthenticationSignupService)signupService;
- (void)inviteFriendsViaEmailFromPresentingViewController:(UIViewController <MFMailComposeViewControllerDelegate> *)pvc;

#pragma mark -
#pragma mark Public Push API

- (BOOL)handlePushNotificationWithDictionary:(NSDictionary *)dictionary;

#pragma mark -
#pragma mark Public App Update API

- (void)showUpgradeIsAvailableAlert;
- (void)openUpgradeURL;
- (void)showAppUpdateAlertWithMessage:(NSString *)inMessage;
- (void)recordLastSeenModalUpgradeVersion:(NSString *)currentVersion;

#pragma mark -
#pragma mark Public Authentication API

- (void)requestAuthenticationFromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestSignInFromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (DQAuthenticationController *)newAuthenticationController;

#pragma mark -
#pragma mark Public Modal Navigation Controller Factory API (template methods)

- (DQNavigationController *)newModalNavigationController;
- (DQNavigationController *)newModalNavigationControllerWithRootViewController:(UIViewController *)rootViewController;

#pragma mark -
#pragma mark Reminders

- (BOOL)shouldDisplayInviteReminder;
- (void)doneDisplayingInviteReminder;

@end

@interface DQApplicationController (TemplateMethods)

+ (void)configureUIAppearance;
- (void)configureMainWindow;
- (void)initializeViewStateWithLaunchOptions:(NSDictionary *)launchOptions;
- (BOOL)dispatchURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation forApplication:(UIApplication *)application fromActiveViewController:(UIViewController *)activeViewController checking:(BOOL)isChecking;
- (void)accountChangedWithNotification:(NSNotification *)notification;
- (UIViewController *)activeViewController;
- (BOOL)shouldOpenURL:(NSURL *)url fromViewController:(UIViewController *)vc;
- (BOOL)shouldDispatchPushNotificationFromViewController:(UIViewController *)vc;
- (void)showEditorForInterruptedQuest;
- (DQHomeViewController *)showHomeAndAutomaticModals:(BOOL)showAutomaticModals;
- (void)showExploreForCommentWithID:(NSString *)commentID;
- (DQProfileViewController *)showProfileForUserWithUserName:(NSString *)userName fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;
- (void)showCommentWithID:(NSString *)commentID questID:(NSString *)questID source:(NSString *)source publishing:(BOOL)isPublishing fromViewController:(UIViewController *)presentingViewController;
- (void)showGalleryForQuestWithID:(NSString *)questID commentID:(NSString *)commentID source:(NSString *)source publishing:(BOOL)isPublishing fromViewController:(UIViewController *)presentingViewController beforePresenting:(void (^)(DQGalleryViewController *galleryViewController))beforePresentingBlock;
- (void)showNewColorsAlert;
- (void)showQuestOfTheDay;
- (DQAboutViewController *)showAboutFromViewController:(UIViewController *)presentingViewController;

- (void)restorePurchasesComplete;
- (void)restorePurchasesFailedWithError:(NSError *)error;

- (DQActivityController *)newActivityController;
- (void)userActivityUpdated:(NSNotification *)notification;

- (void)pushViewController:(UIViewController *)vc ontoNavigationController:(UINavigationController *)navigationController;

@end
