//
//  DQViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-21.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/SLRequest.h>
#import "DQAuthenticationConstants.h"

@class DQPublicServiceController;
@class DQPrivateServiceController;
@class DQDataStoreController;
@class DQAccount;
@class DQComment;
@class DQCommentUpload;
@class DQQuest;
@class DQUser;
@class DQButton;
@class DQPlaybackImageView;
@class DQNavigationController;

@protocol DQViewControllerDelegate;

@protocol DQViewController

@property (nonatomic, weak) id<DQViewControllerDelegate> delegate;
@property (nonatomic, readonly, strong) DQDataStoreController *dataStoreController;
@property (nonatomic, readonly, strong) DQPublicServiceController *publicServiceController;
@property (nonatomic, readonly, strong) DQPrivateServiceController *privateServiceController;
@property (nonatomic, readonly, assign, getter = isLoggedIn) BOOL loggedIn;
@property (nonatomic, readonly, assign) BOOL hasUserEverLoggedIn;
@property (nonatomic, readonly, strong) DQAccount *loggedInAccount;
@property (nonatomic, readwrite, assign) BOOL hasNewQuestOfTheDay;

- (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey;
+ (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey;

- (void)requestAuthenticationWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestFacebookPublishAccessForFeature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestTwitterAccessInView:(UIView *)view withCancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;

- (BOOL)hasOpenFacebookSession;
- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions;
- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;

- (void)hasTwitterAccess:(void (^)(BOOL result))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestDataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void)tappedPlaybackButton:(DQButton *)playbackButton forPlaybackImageView:(DQPlaybackImageView *)playbackImageView comment:(DQComment *)comment withRequestFinishedBlock:(void(^)(DQComment *newComment))requestFinishedBlock;
- (void)tappedMoreOptionsButtonForComment:(DQComment *)comment source:(NSString *)source;
- (void)tappedShareButtonForQuest:(DQQuest *)quest source:(NSString *)source;
- (void)tappedShareButtonForComment:(DQComment *)comment source:(NSString *)source;
- (void)tappedMoreOptionsButtonForQuest:(DQQuest *)quest source:(NSString *)source;
- (void)tappedCancelButton:(UIButton *)cancelButton forCommentUpload:(DQCommentUpload *)commentUpload withDeletionBlock:(dispatch_block_t)deletionBlock;
- (void)tappedRetryButton:(UIButton *)retryButton forCommentUpload:(DQCommentUpload *)commentUpload;
- (void)showDrawingDetailForCommentWithServerID:(NSString *)commentID source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)showDrawingDetailForComment:(DQComment *)comment source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)showGalleryForQuest:(DQQuest *)quest source:(NSString *)source;
- (void)showProfileForUsername:(NSString *)username source:(NSString *)source;
- (void)showZoomableImageForComment:(DQComment *)comment fromView:(UIView *)view;
- (void)showAbout;

- (DQNavigationController *)newNavigationController;
- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController;

@end

@protocol DQViewControllerDelegate

- (DQPublicServiceController *)publicServiceControllerForViewController:(UIViewController<DQViewController> *)vc;
- (DQPrivateServiceController *)privateServiceControllerForViewController:(UIViewController<DQViewController> *)vc;
- (DQDataStoreController *)dataStoreControllerForViewController:(UIViewController<DQViewController> *)vc;
- (BOOL)isLoggedInForViewController:(UIViewController<DQViewController> *)vc;
- (DQAccount *)loggedInAccountForViewController:(UIViewController<DQViewController> *)vc;
- (BOOL)hasUserEverLoggedInForViewController:(UIViewController<DQViewController> *)vc;
- (void)authenticatedFromViewController:(UIViewController<DQViewController> *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)facebookAccessGrantedForViewController:(UIViewController<DQViewController> *)vc feature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)facebookPublishAccessGrantedForViewController:(UIViewController<DQViewController> *)vc feature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)twitterAccessGrantedInView:(UIView *)view fromViewController:(UIViewController<DQViewController> *)vc cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)viewController:(UIViewController<DQViewController> *)vc logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;
- (void)hasTwitterAccessForViewController:(UIViewController<DQViewController> *)vc resultBlock:(void (^)(BOOL result))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)dataForTwitterAccountForViewController:(UIViewController<DQViewController> *)vc withURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (BOOL)hasOpenFacebookSessionForViewController:(UIViewController<DQViewController> *)vc;
- (BOOL)viewController:(UIViewController<DQViewController> *)vc hasOpenFacebookSessionWithPermissions:(NSArray *)permissions;
- (NSArray *)viewController:(UIViewController<DQViewController> *)vc openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
- (void)tappedPlaybackButton:(DQButton *)playbackButton forPlaybackImageView:(DQPlaybackImageView *)playbackImageView comment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController withRequestFinishedBlock:(void(^)(DQComment *newComment))requestFinishedBlock;
- (void)tappedMoreOptionsButtonForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source;
- (void)tappedMoreOptionsButtonForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source;
- (void)tappedShareButtonForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source;
- (void)tappedShareButtonForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source;
- (void)tappedCancelButton:(UIButton *)cancelButton forCommentUpload:(DQCommentUpload *)commentUpload withDeletionBlock:(dispatch_block_t)deletionBlock;
- (void)tappedRetryButton:(UIButton *)retryButton forCommentUpload:(DQCommentUpload *)commentUpload fromViewController:(UIViewController<DQViewController> *)viewController;
- (void)showDrawingDetailForCommentWithServerID:(NSString *)commentID fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)showDrawingDetailForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)showGalleryForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source;
- (void)showProfileForUsername:(NSString *)username fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source;
- (void)showZoomableImageForComment:(DQComment *)comment fromView:(UIView *)view viewController:(UIViewController<DQViewController> *)viewController;
- (void)showAboutForViewController:(UIViewController<DQViewController> *)viewController;
- (BOOL)hasNewQuestOfTheDayForViewController:(UIViewController<DQViewController> *)viewController;
- (void)setHasNewQuestOfTheDay:(BOOL)hasNewQuestOfTheDay forViewController:(UIViewController<DQViewController> *)viewController;

- (DQNavigationController *)newNavigationControllerForViewController:(UIViewController<DQViewController> *)vc;
- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController forViewController:(UIViewController<DQViewController> *)vc;

@end

@interface DQViewController : UIViewController <DQViewController>

// designated initializer
- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id<DQViewControllerDelegate>)delegate;

- (id)init MSDesignatedInitializer(initWithDelegate:);
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithNibName:bundle:delegate:);

- (void)didPullToRefreshWithCompletionBlock:(dispatch_block_t)completionBlock;

@end
