//
//  DQViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-21.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQDataStoreController.h"

@implementation DQViewController

@synthesize delegate = _delegate;

@dynamic dataStoreController;
@dynamic loggedIn;
@dynamic hasUserEverLoggedIn;
@dynamic hasNewQuestOfTheDay;

- (void)dealloc
{
    _delegate = nil;
}

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [self initWithNibName:nil bundle:nil delegate:delegate];
    if (self)
    {
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        _delegate = delegate;
    }
    return self;
}

- (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

+ (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
- (void)didPullToRefreshWithCompletionBlock:(dispatch_block_t)completionBlock
{
    // subclasses may override this

}

- (DQDataStoreController *)dataStoreController
{
    return [self.delegate dataStoreControllerForViewController:self];
}

- (DQPublicServiceController *)publicServiceController
{
    return [self.delegate publicServiceControllerForViewController:self];
}

- (DQPrivateServiceController *)privateServiceController
{
    return [self.delegate privateServiceControllerForViewController:self];
}

- (BOOL)isLoggedIn
{
    return [self.delegate isLoggedInForViewController:self];
}

- (BOOL)hasUserEverLoggedIn
{
    return [self.delegate hasUserEverLoggedInForViewController:self];
}

- (DQAccount *)loggedInAccount
{
    return [self.delegate loggedInAccountForViewController:self];
}

- (void)requestAuthenticationWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate authenticatedFromViewController:self cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.delegate facebookAccessGrantedForViewController:self feature:feature readPermissions:readPermissions publishPermissions:publishPermissions cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookPublishAccessForFeature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.delegate facebookPublishAccessGrantedForViewController:self feature:feature cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestTwitterAccessInView:(UIView *)view withCancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate twitterAccessGrantedInView:view fromViewController:self cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters
{
    [self.delegate viewController:self logEvent:event withParameters:parameters];
}

- (BOOL)hasOpenFacebookSession
{
    return [self.delegate hasOpenFacebookSessionForViewController:self];
}

- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions
{
    return [self.delegate viewController:self hasOpenFacebookSessionWithPermissions:permissions];
}

- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
{
    return [self.delegate viewController:self openFacebookSessionPermissionsMissingFromPermissions:permissions];
}

- (void)hasTwitterAccess:(void (^)(BOOL result))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate hasTwitterAccessForViewController:self resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)requestDataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate dataForTwitterAccountForViewController:self withURL:url parameters:parameters method:method resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)tappedPlaybackButton:(DQButton *)playbackButton forPlaybackImageView:(DQPlaybackImageView *)playbackImageView comment:(DQComment *)comment withRequestFinishedBlock:(void(^)(DQComment *newComment))requestFinishedBlock
{
    [self.delegate tappedPlaybackButton:playbackButton forPlaybackImageView:playbackImageView comment:comment fromViewController:self withRequestFinishedBlock:requestFinishedBlock];
}

- (void)tappedMoreOptionsButtonForComment:(DQComment *)comment source:(NSString *)source
{
    [self.delegate tappedMoreOptionsButtonForComment:comment fromViewController:self source:source];
}

- (void)tappedMoreOptionsButtonForQuest:(DQQuest *)quest source:(NSString *)source
{
    [self.delegate tappedMoreOptionsButtonForQuest:quest fromViewController:self source:source];
}

- (void)tappedShareButtonForComment:(DQComment *)comment source:(NSString *)source
{
    [self.delegate tappedShareButtonForComment:comment fromViewController:self source:source];
}

- (void)tappedShareButtonForQuest:(DQQuest *)quest source:(NSString *)source
{
    [self.delegate tappedShareButtonForQuest:quest fromViewController:self source:source];
}

- (void)tappedCancelButton:(UIButton *)cancelButton forCommentUpload:(DQCommentUpload *)commentUpload withDeletionBlock:(dispatch_block_t)deletionBlock
{
    [self.delegate tappedCancelButton:cancelButton forCommentUpload:commentUpload withDeletionBlock:deletionBlock];
}

- (void)tappedRetryButton:(UIButton *)retryButton forCommentUpload:(DQCommentUpload *)commentUpload
{
    [self.delegate tappedRetryButton:retryButton forCommentUpload:commentUpload fromViewController:self];
}

- (void)showDrawingDetailForCommentWithServerID:(NSString *)commentID source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate showDrawingDetailForCommentWithServerID:commentID fromViewController:self source:source completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)showDrawingDetailForComment:(DQComment *)comment source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate showDrawingDetailForComment:comment fromViewController:self source:source completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)showGalleryForQuest:(DQQuest *)quest source:(NSString *)source
{
    [self.delegate showGalleryForQuest:quest fromViewController:self source:source];
}

- (void)showProfileForUsername:(NSString *)username source:(NSString *)source
{
    [self.delegate showProfileForUsername:username fromViewController:self source:source];
}

- (void)showZoomableImageForComment:(DQComment *)comment fromView:(UIView *)view
{
    [self.delegate showZoomableImageForComment:comment fromView:view viewController:self];
}

- (void)showAbout
{
    return [self.delegate showAboutForViewController:self];
}

- (BOOL)hasNewQuestOfTheDay
{
    return [self.delegate hasNewQuestOfTheDayForViewController:self];
}

- (void)setHasNewQuestOfTheDay:(BOOL)hasNewQuestOfTheDay
{
    [self.delegate setHasNewQuestOfTheDay:hasNewQuestOfTheDay forViewController:self];
}

- (DQNavigationController *)newNavigationController
{
    return [self.delegate newNavigationControllerForViewController:self];
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController
{
    return [self.delegate newNavigationControllerWithRootViewController:rootViewController forViewController:self];
}

@end
