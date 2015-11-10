//
//  DQNavigationController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-05-31.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQNavigationController.h"
#import "DQAccount.h"

@interface DQNavigationController ()

@property (nonatomic, assign) BOOL allowAutoRotation;

@end

@implementation DQNavigationController

@dynamic delegate;

- (void)dealloc
{
    self.delegate = nil; // delegate is assign in UINavigationController, not weak
}

- (id)initWithDelegate:(id<DQNavigationControllerDelegate>)delegate
{
    self = [super initWithNavigationBarClass:nil toolbarClass:nil];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (id)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass delegate:(id<DQNavigationControllerDelegate>)delegate
{
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController delegate:(id<DQNavigationControllerDelegate>)delegate
{
    self = [super initWithRootViewController:rootViewController];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (BOOL)shouldAutorotate
{
    return self.allowAutoRotation;
}

- (void)enableAutorotate:(BOOL)enable
{
    self.allowAutoRotation = enable;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return UIInterfaceOrientationMaskLandscape;
    }
    else
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
    return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return YES;
}

- (id<DQNavigationControllerDelegate>)delegate
{
    return (id<DQNavigationControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQNavigationControllerDelegate>)delegate
{
    [super setDelegate:delegate];
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

- (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

+ (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

- (void)requestAuthenticationWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate authenticatedFromViewController:self cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.delegate facebookAccessGrantedForViewController:self feature:feature readPermissions:readPermissions publishPermissions:publishPermissions cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookPublishAccessForFeature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
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

- (DQNavigationController *)newNavigationController
{
    return [self.delegate newNavigationControllerForViewController:self];
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController
{
    return [self.delegate newNavigationControllerWithRootViewController:rootViewController forViewController:self];
}

- (void)tappedShareButtonForComment:(DQComment *)comment source:(NSString *)source
{
    return [self.delegate tappedShareButtonForComment:comment fromViewController:self source:source];
}

- (void)tappedShareButtonForQuest:(DQQuest *)quest source:(NSString *)source
{
    return [self.delegate tappedShareButtonForQuest:quest fromViewController:self source:source];
}

- (void)showZoomableImageForComment:(DQComment *)comment fromView:(UIView *)view
{
    return [self.delegate showZoomableImageForComment:comment fromView:view viewController:self];
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

@end
