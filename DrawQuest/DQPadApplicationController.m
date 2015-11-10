//
//  DQPadApplicationController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-11.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadApplicationController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <FacebookSDK/FacebookSDK.h>
#import "Appirater.h"

// Additions
#import "DQAnalyticsConstants.h"
#import "STUtils.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "UIFont+DQAdditions.h"
#import "DQBlockActionTarget.h"

// Model
#import "DQAccount.h"
#import "DQQuest.h"
#import "DQComment.h"

// Controllers
#import "DQController.h"
#import "DQAuthServiceController.h"
#import "DQActivityDataStoreController.h"
#import "DQPlaybackDataManager.h"

// View Controllers
#import "CVSPadEditorViewController.h"
#import "DQViewController.h"
#import "DQPadHomeViewController.h"
#import "DQPadProfileViewController.h"
#import "DQUserListViewController.h"
#import "DQExploreViewController.h"
#import "DQExploreUserSearchViewController.h"
#import "STBasementViewController.h"
#import "DQMenuViewController.h"
#import "DQPadGalleryViewController.h"
#import "DQPlaybackViewController.h"
#import "DQMainNavigationController.h"
#import "DQNavigationController.h"
#import "DQModalNavigationController.h"
#import "DQFirstTimeViewController.h"
#import "DQCommentPublishViewController.h"
#import "DQAddFriendsViewController.h"
#import "DQUpgradeModalViewController.h"
#import "DQWebProfileShareViewController.h"
#import "DQStarburstModalViewController.h"
#import "DQShopViewController.h"
#import "DQBioEditorViewController.h"

// Views
#import "DQBasementButton.h"
#import "DQActionSheet.h"
#import "DQAlertView.h"
#import "DQHUDView.h"
#import "DQButton.h"

// Additions
#import "DQViewMetricsConstants.h"
#import "UIColor+DQAdditions.h"

@interface DQPadApplicationController () <DQPadHomeViewControllerDataSource, DQActivityControllerDelegate, DQMainNavigationControllerDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) STBasementViewController *basementViewController;
@property (nonatomic, strong) DQMenuViewController *menuViewController;
@property (nonatomic, strong) UIWindow *starburstModalWindow;

@end

@implementation DQPadApplicationController

#pragma mark -
#pragma mark Public Modal Navigation Controller Factory API (template methods)

- (DQNavigationController *)newModalNavigationController
{
    DQModalNavigationController *nc = [[DQModalNavigationController alloc] initWithDelegate:self];
    return nc;
}

- (DQNavigationController *)newModalNavigationControllerWithRootViewController:(UIViewController *)rootViewController
{
    DQModalNavigationController *nc = [[DQModalNavigationController alloc] initWithRootViewController:rootViewController delegate:self];
    return nc;
}

#pragma mark - Displaying onboarding

// CHECK
- (BOOL)isDisplayingOnboardingFromViewController:(UIViewController *)vc
{
    return (self.authenticationController || self.publishController ||
            (vc && ([vc isKindOfClass:[DQFirstTimeViewController class]] || vc.presentedViewController)));
}

- (void)discloseItemPressedFromViewController:(UIViewController *)c
{
    __weak typeof(self) weakSelf = self;
    [self requestAuthenticationFromViewController:c cancellationBlock:^{
        // TODO: do anything if they cancel?
    } completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        if (weakSelf.basementViewController.basementIsVisible)
        {
            [weakSelf.basementViewController hideBottomView];
        }
        else
        {
            [weakSelf.activityController markAllActivityItemsRead];
            weakSelf.channelController.monitoring = YES;
            [weakSelf.activityController update];
            [[NSNotificationCenter defaultCenter] postNotificationName:DQActivityCountUpdateNotification object:self userInfo:@{@"count": @(0)}];
            [weakSelf.basementViewController presentBottomViewController:weakSelf.menuViewController fromEdge:STBasementViewControllerEdgeLeft];
        }
    } failureBlock:^(NSError *error) {
        NSString *description = error ? error.dq_displayDescription : DQLocalizedString(@"Please try again", @"Prompt to attempt a request again");
        [self showGlobalAlertWithTitle:DQLocalizedString(@"Sign In Failed", @"Sign in failed alert title") description:description];
    }];
}

#pragma mark -
#pragma mark Presentation Helpers

- (void)presentViewControllerWithStarburst:(UIViewController *)presentedViewController withBounds:(CGRect)bounds animated:(BOOL)animated completion:(dispatch_block_t)completionBlock
{
    DQStarburstModalViewController *starburstModal = [[DQStarburstModalViewController alloc] initWithViewController:presentedViewController withBounds:bounds];

    CGRect windowFrame = [[UIScreen mainScreen] applicationFrame];

    UIWindow *window = [[UIWindow alloc] initWithFrame:windowFrame];
    window.windowLevel = UIWindowLevelNormal + 1;
    window.rootViewController = starburstModal;
    window.hidden = NO;
    [window makeKeyAndVisible];

    if (animated)
    {
        window.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
        starburstModal.view.center = CGPointMake(window.center.x + windowFrame.size.height, window.center.y);

        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            window.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
            starburstModal.view.center = CGPointMake(window.center.x - windowFrame.size.height, window.center.y);
        } completion:^(BOOL finished) {
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
    else
    {
        window.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
        if (completionBlock)
        {
            completionBlock();
        }
    }

    self.starburstModalWindow = window;
}

- (void)dismissViewControllerWithStarburstAnimated:(BOOL)animated completion:(dispatch_block_t)completionBlock
{
    dispatch_block_t finishedBlock = ^{
        [self.starburstModalWindow resignKeyWindow];
        self.starburstModalWindow = nil;
        if (completionBlock)
        {
            completionBlock();
        }
    };

    if (animated)
    {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            UIWindow *window = weakSelf.starburstModalWindow;
            window.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
            window.rootViewController.view.center = CGPointMake(window.center.x + [[UIScreen mainScreen] applicationFrame].size.height, window.center.y);
        } completion:^(BOOL finished) {
            finishedBlock();
        }];
    }
    else
    {
        finishedBlock();
    }
}

- (void)showViewController:(UIViewController<DQViewController> *)vc fromViewController:(UIViewController *)presentingViewController withBackgroundImage:(UIImage *)backgroundImage
{
    if (presentingViewController.navigationController)
    {
        [self pushViewController:vc ontoNavigationController:presentingViewController.navigationController withBackgroundImage:backgroundImage];
    }
    else
    {
        [self replaceBasementWithViewController:vc withBackgroundImage:backgroundImage];
    }
}

- (void)pushViewController:(UIViewController *)vc ontoNavigationController:(UINavigationController *)navigationController withBackgroundImage:(UIImage *)backgroundImage
{
    // Isn't it possible to simply change the appearance of the standard back button?
    UIView *backOffsetView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 48.0f)];
    backOffsetView.backgroundColor = [UIColor clearColor];
    DQButton *backButton = [DQButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = backOffsetView.bounds;
    __weak typeof(self) weakSelf = self;
    __weak typeof(navigationController) weakNavigationController = navigationController;
    UIImage *navBackgroundImage = [[(DQMainNavigationController *)self.basementViewController.topViewController navigationBar] backgroundImageForBarMetrics:UIBarMetricsDefault];
    backButton.tappedBlock = ^(DQButton *button) {
        [[(DQMainNavigationController *)weakSelf.basementViewController.topViewController navigationBar] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
        [weakNavigationController popViewControllerAnimated:YES];
    };
    [backOffsetView addSubview:backButton];
    [backButton setImage:[UIImage imageNamed:@"button_topNav_back"] forState:UIControlStateNormal];
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backOffsetView];
    backButton.frameX -= 15.0f;

    if (backgroundImage)
    {
        [[(DQMainNavigationController *)weakSelf.basementViewController.topViewController navigationBar] setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    }

    [navigationController pushViewController:vc animated:YES];
}

- (void)replaceBasementWithViewController:(UIViewController<DQViewController> *)vc withBackgroundImage:(UIImage *)backgroundImage
{
    DQMainNavigationController *navigationController = [[DQMainNavigationController alloc] initWithRootViewController:vc delegate:self];
    // FIXME: HACK: ios7 sdk layout issue with big black/white bar on the right side of views.
    navigationController.view.frame = [[[[[UIApplication sharedApplication] keyWindow] rootViewController] view] bounds];//vc.view.frame;
    self.basementViewController.topViewController = navigationController;

    if (backgroundImage)
    {
        [[(DQMainNavigationController *)self.basementViewController.topViewController navigationBar] setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    }

    [self.basementViewController hideBottomView];
}

#pragma mark -
#pragma mark Basement Menu

- (DQMenuViewController *)newMenuViewController
{
    __weak typeof(self) weakSelf = self;
    DQMenuViewController *result = [[DQMenuViewController alloc] initWithDelegate:self];
    result.homeBlock = ^{
        [weakSelf showHomeAndAutomaticModals:YES];
    };
    result.aboutBlock = ^(DQMenuViewController *vc) {
        [vc showAbout];
    };
    result.exploreWithCommentIDBlock = ^(NSString *commentID) {
        [weakSelf showExploreForCommentWithID:commentID];
    };
    result.galleryBlock = ^(NSString *questID, NSString *commentID) {
        [weakSelf showGalleryForQuestWithID:questID commentID:commentID source:@"Activity" publishing:NO fromViewController:nil beforePresenting:nil];
    };
    result.profileBlock = ^(NSString *userName) {
    [weakSelf showProfileForUserWithUserName:userName fromViewController:nil source:(userName ? @"Activity" : @"Menu")];
    };
    result.unknownActivityItemTappedBlock = ^(DQActivityItem *activityItem){
        [weakSelf showAppUpdateAlertWithMessage:DQLocalizedString(@"Your version of DrawQuest is out of date. Please update to see this activity item.", @"App needs to be updated alert title")];
    };
    result.loadMoreActivitiesBlock = ^{
        [weakSelf.activityController scroll];
    };
    result.shopColorsBlock = ^(DQMenuViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabColors source:@"Activity" fromViewController:c];
    };
    return result;
}

- (void)showShareWebProfileModalThenUpgradeIsAvailableModalFromViewController:(UIViewController *)presentingViewController
{
    DQNavigationController *mnc = [self newModalNavigationController];

    __weak UIViewController *weakPresentingViewController = presentingViewController;
    DQUpgradeModalViewController *upgradeViewController = [self newUpgradeModalViewControllerWithCompletionBarButtonItemTitle:DQLocalizedString(@"Upgrade", @"Upgrade alert confirmation button title") cancellationBlock:^{
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    } completionBlock:^{
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];

    __weak typeof(mnc) weakMNC = mnc;
    DQWebProfileShareViewController *shareVC = [self newWebProfileShareViewControllerWithCompletionBarButtonItemTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") completionBlock:^{
        [weakMNC pushViewController:upgradeViewController animated:YES];
    }];
    [mnc setViewControllers:@[shareVC]];
    [presentingViewController presentViewController:mnc animated:YES completion:nil];
}

// DQ-269: show share web profile, then add friends
- (void)showUpgradeFlowFor1xxTo2xxFromHomeViewController:(DQHomeViewController *)homeViewController
{
    // skip add friends if we've disabled facebook and twitter
    if ([self featureInviteFromFacebook] || [self featureInviteFromTwitter])
    {
        __weak typeof(self) weakSelf = self;
        DQController *c = [[DQController alloc] initWithDelegate:self];
        DQNavigationController *mnc = [self newModalNavigationController];

        // set up the add friends view controller, it is pushed when completing the share web profile view controller
        __weak typeof(homeViewController) weakPVC = homeViewController;
        DQAddFriendsViewController *addFriendsVC = [self newAddFriendsViewControllerForSignupService:DQAuthenticationSignupServiceNone];
        addFriendsVC.title = DQLocalizedString(@"Add Friends", @"Title for modal where the user can invite their friends to DrawQuest");
        //        addFriendsVC.navigationItem.leftBarButtonItem = [c newCancelBarButtonItemWithBlock:^(id sender) {
        //            [weakPVC dismissViewControllerAnimated:YES completion:nil];
        //        }];
        addFriendsVC.navigationItem.hidesBackButton = YES;
        __weak typeof(addFriendsVC) weakAddFriendsVC = addFriendsVC;
        addFriendsVC.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
            [weakAddFriendsVC submitWithCancellationBlock:^{
                // do nothing on cancel
            } completionBlock:^{
                [weakPVC dismissViewControllerAnimated:YES completion:nil];
            } failureBlock:^(NSError *error) {
                [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Error sending invites.", @"Invite error alert title") description:error.dq_displayDescription];
            }];
        }];

        __weak typeof(mnc) weakMNC = mnc;
        DQWebProfileShareViewController *shareVC = [self newWebProfileShareViewControllerWithCompletionBarButtonItemTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") completionBlock:^{
            [weakMNC pushViewController:addFriendsVC animated:YES];
        }];
        [mnc setViewControllers:@[shareVC]];
        [homeViewController presentViewController:mnc animated:YES completion:nil];
    }
    else
    {
        [self showWebProfileModalFromViewController:homeViewController];
    }
}

#pragma mark -
#pragma mark Presenting the Version Upgrade modal and alert

- (DQUpgradeModalViewController *)newUpgradeModalViewControllerWithCompletionBarButtonItemTitle:(NSString *)completionBarButtonItemTitle cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock
{
    DQUpgradeModalViewController *vc = [[DQUpgradeModalViewController alloc] initWithDelegate:self];
    DQController *c = [[DQController alloc] initWithDelegate:self];
    __weak typeof(self) weakSelf = self;
    if (cancellationBlock)
    {
        vc.navigationItem.leftBarButtonItem = [c newCancelBarButtonItemWithBlock:^(id sender) {
            weakSelf.hasSeenAvailableUpgradeModal = YES;
            [weakSelf recordLastSeenModalUpgradeVersion:weakSelf.versionForAvailableUpgradeModal];
            cancellationBlock();
        }];
    }
    else
    {
        vc.navigationItem.hidesBackButton = YES;
    }
    vc.navigationItem.rightBarButtonItem = [c newBarButtonItemWithTitle:completionBarButtonItemTitle isPrimaryAction:YES block:^(id sender) {
        weakSelf.hasSeenAvailableUpgradeModal = YES;
        [weakSelf recordLastSeenModalUpgradeVersion:weakSelf.versionForAvailableUpgradeModal];
        [weakSelf openUpgradeURL];
        if (completionBlock)
        {
            completionBlock();
        }
    }];
    return vc;
}

- (void)showUpgradeIsAvailableModalFromViewController:(UIViewController *)presentingViewController
{
    __weak UIViewController *weakPresentingViewController = presentingViewController;
    DQUpgradeModalViewController *upgradeViewController = [self newUpgradeModalViewControllerWithCompletionBarButtonItemTitle:DQLocalizedString(@"Upgrade", @"Upgrade alert confirmation button title") cancellationBlock:^{
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    } completionBlock:^{
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];

    DQNavigationController *navigationController = [self newModalNavigationControllerWithRootViewController:upgradeViewController];
    [presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Presenting the Share Web Profile modal

- (DQWebProfileShareViewController *)newWebProfileShareViewControllerWithCompletionBarButtonItemTitle:(NSString *)completionBarButtonItemTitle completionBlock:(dispatch_block_t)completionBlock
{
    BOOL privacy = self.accountController.loggedInAccount.webProfileEnabled;
    __weak typeof(self) weakSelf = self;
    DQWebProfileShareViewController *vc = [[DQWebProfileShareViewController alloc] initWithPrivacy:privacy twitterController:self.twitterController facebookController:self.facebookController delegate:self];
    DQController *c = [[DQController alloc] initWithDelegate:self];
    __weak typeof(vc) weakVC = vc;
    vc.navigationItem.hidesBackButton = YES;
    vc.navigationItem.rightBarButtonItem = [c newBarButtonItemWithTitle:completionBarButtonItemTitle isPrimaryAction:YES block:^(id sender) {
        [weakSelf.privateServiceController requestSendMessage:weakVC.shareMessage
                                                facebookToken:(weakVC.shareOnFacebook ? weakSelf.facebookController.openFacebookSessionAccessToken : nil)
                                                 twitterToken:(weakVC.shareOnTwitter ? weakSelf.twitterController.twitterAccessToken : nil)
                                                twitterSecret:(weakVC.shareOnTwitter ? weakSelf.twitterController.twitterAccessTokenSecret : nil)];
        if (completionBlock)
        {
            completionBlock();
        }
    }];
    return vc;
}

- (void)showWebProfileModalFromViewController:(UIViewController *)presentingViewController
{
    if (![self isDisplayingOnboardingFromViewController:self.basementViewController])
    {
        __weak typeof(presentingViewController) weakPVC = presentingViewController;
        DQWebProfileShareViewController *vc = [self newWebProfileShareViewControllerWithCompletionBarButtonItemTitle:DQLocalizedString(@"Done", @"User is done with this action button title") completionBlock:^{
            [weakPVC dismissViewControllerAnimated:YES completion:nil];
        }];
        DQNavigationController *navigationController = [self newModalNavigationControllerWithRootViewController:vc];
        [presentingViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Presenting a User List modally

- (void)showUserListOfType:(DQUserListType)type forUserName:(NSString *)userName fromViewController:(UIViewController *)presentingViewController
{
    __weak typeof(self) weakSelf = self;
    __weak UIViewController *weakPresentingViewController = presentingViewController;

    DQUserListViewController *userListViewController = [[DQUserListViewController alloc] initWithUserName:userName userListType:type delegate:self];
    userListViewController.title = type == DQUserListTypeFollowers ? DQLocalizedString(@"Followers", @"Label for a collection of users a particular user is following") : DQLocalizedStringWithDefaultValue(@"FollowingUserListLabel", nil, nil, @"Following", @"Label for a collection of users following a particular user");
    
    userListViewController.displayProfileBlock = ^(DQUserListViewController *c, NSString *userName)
    {
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        [weakSelf showProfileForUserWithUserName:userName fromViewController:weakPresentingViewController source:[@"UserList-" stringByAppendingString:(type == DQUserListTypeFollowers ? @"Followers" : @"Following")]];
    };
    DQController *c = [[DQController alloc] initWithDelegate:self];
    userListViewController.navigationItem.hidesBackButton = YES;
    userListViewController.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    DQNavigationController *navController = [self newModalNavigationControllerWithRootViewController:userListViewController];
    [presentingViewController presentViewController:navController animated:YES completion:nil];
    [navController.navigationBar setBackgroundImage:DQImageWithColor(DQColorRed) forBarMetrics:UIBarMetricsDefault];
    
}

#pragma mark -
#pragma mark Presenting Shop

- (void)showShopWithTab:(DQShopViewControllerTab)inTab source:(NSString *)source fromViewController:(DQViewController *)presentingViewController
{
    // Show new color alert instead if there are new colors and we are opening to colors or default
    if (self.accountController.loggedIn && (inTab == DQShopViewControllerTabColors || inTab == DQShopViewControllerTabDefault) && self.accountController.loggedInAccount.lastViewedColorAlertVersion < self.accountController.loggedInAccount.currentColorAlertVersion)
    {
        [self showNewColorsAlert];
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        __weak UIViewController *weakPresentingViewController = presentingViewController;
        [self authenticatedFromViewController:presentingViewController cancellationBlock:^{
            // TODO: do anything when they cancel?
        } completionBlock:^(DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
            DQController *c = [[DQController alloc] initWithDelegate:weakSelf];
            DQShopViewController *shop = [weakSelf newShopViewControllerWithTab:inTab source:source];
            shop.title = DQLocalizedString(@"Shop", @"Title for the shop area of the app where users can purchase new items");
            shop.navigationItem.hidesBackButton = YES;
            shop.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
                weakSelf.shopBarButtonRestorePurchasesCompletionBlock = nil;
                weakSelf.shopBarButtonRestorePurchasesFailureBlock = nil;
                [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
            }];
            DQNavigationController *navController = [weakSelf newModalNavigationControllerWithRootViewController:shop];
            // FIXME: We should be doing this for all modal navigation bars now that we're on iOS 7
            navController.navigationBar.translucent = NO;
            [presentingViewController presentViewController:navController animated:YES completion:nil];
        } failureBlock:^(NSError *error) {
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Authentication Error", @"Authentication error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
        }];
    }
}

#pragma mark -
#pragma mark Presenting Settings

- (void)showSettingsFromViewController:(UIViewController *)presentingViewController
{
    DQSettingsViewController *settingsViewController = [self newSettingsViewController:presentingViewController];

    settingsViewController.presentBioEditorViewControllerBlock = ^(DQSettingsViewController *vc) {
        DQBioEditorViewController *bvc = [[DQBioEditorViewController alloc] initWithNibName:nil bundle:nil];
        bvc.title = @"Settings";
        bvc.text = vc.bio;
        __weak typeof(vc) weakVC = vc;
        __weak typeof(bvc) weakBVC = bvc;
        bvc.keyboardDoneTappedBlock = ^{
            [weakVC bioEditorDoneTapped:weakBVC];
            [weakVC.navigationController popViewControllerAnimated:YES];
        };
        DQController *c = [[DQController alloc] initWithDelegate:self];
        bvc.navigationItem.leftBarButtonItem = [c newCancelBarButtonItemWithBlock:^(id sender) {
            [weakVC bioEditorCancelTapped:weakBVC];
            [weakVC.navigationController popViewControllerAnimated:YES];
        }];
        bvc.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
            [weakVC bioEditorDoneTapped:weakBVC];
            [weakVC.navigationController popViewControllerAnimated:YES];
        }];
        [vc.navigationController pushViewController:bvc animated:YES];
    };

    DQNavigationController *navController = [self newModalNavigationControllerWithRootViewController:settingsViewController];
    navController.view.tintColor = [UIColor dq_profileTabColor];
    [presentingViewController presentViewController:navController animated:YES completion:nil];
    [navController.navigationBar setBackgroundImage:DQImageWithColor(DQColorRed) forBarMetrics:UIBarMetricsDefault];
}

- (void)saveCommentToCameraRoll:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)presentingViewController fromView:(UIView *)view
{
    NSString *imageURLString = [comment imageURLForKey:DQImageKeyCameraRoll];
    [self.imageController requestImageForURL:imageURLString forceReload:NO completionBlock:^(UIImage *image, STHTTPResourceControllerLoadStatus status, NSError *error) {
        //            [hud hideAnimated:YES];
        if (status == STHTTPResourceControllerLoadStatusLoadFailed)
        {
            DQAlertView *errorAlert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Saving Failed", @"File save failure alert title")
                                                                 message:error.dq_displayDescription
                                                                delegate:nil
                                                       cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view")
                                                       otherButtonTitles:nil];
            [errorAlert show];
        }
        else
        {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(saveCommentToCameraRollImage:didFinishSavingWithError:contextInfo:), NULL);
        }
    }];
}

- (void)saveCommentToCameraRollImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error)
    {
        DQAlertView *errorAlert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Saving Failed", @"File save failure alert title")
                                                             message:error.code == ALAssetsLibraryDataUnavailableError ? DQLocalizedString(@"DrawQuest was denied access to your photo library. You can allow access using the iOS Settings app.", @"File save access denied error message") : error.dq_displayDescription
                                                            delegate:nil
                                                   cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view")
                                                   otherButtonTitles:nil];
        [errorAlert show];
    }
}

#pragma mark -
#pragma mark Presenting Playback

- (void)showPlaybackForComment:(DQComment *)comment inQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController
{
    __weak typeof(self) weakSelf = self;
    __weak UIViewController *weakPresentingViewController = presentingViewController;
    DQPlaybackDataManager *pdm = [[DQPlaybackDataManager alloc] initWithImageController:self.imageController delegate:self];
    DQPlaybackViewController *vc = [[DQPlaybackViewController alloc] initWithComment:comment inQuest:quest newPlaybackDataManager:pdm delegate:self];
    vc.dismissBlock = ^(DQPlaybackViewController *vc) {
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:^{
            //navbar height fix hack
            UIViewController *top = self.basementViewController.topViewController;
            if ([top isKindOfClass:[DQMainNavigationController class]])
            {
                DQMainNavigationController *nav = (DQMainNavigationController *)top;
                [(DQNavigationBar *)nav.navigationBar correctSize]; // FIXME: call a method on nav that in turn messages its navbar to avoid this cast
            }
        }];
    };

    [vc requestPreparePlaybackFromViewController:presentingViewController completionBlock:^{
        [weakPresentingViewController presentViewController:vc animated:YES completion:nil];
    } failureBlock:^(NSError *error) {
        [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Playback Error", @"Drawing playback error title") description:error.dq_displayDescription];
    }];
}

#pragma mark -
#pragma mark Presenting an Editor

- (void)showCommentEditorForQuest:(DQQuest *)quest isFirstQuest:(BOOL)isFirstQuest source:(NSString *)source fromViewController:(UIViewController *)presentingViewController
{
    __weak typeof(self) weakSelf = self;
    CVSPadEditorViewController *editorViewController = [[CVSPadEditorViewController alloc] initCommentEditorWithQuest:quest draftsPath:self.draftsPath imageController:self.imageController source:source delegate:self];
    editorViewController.title = quest.title;
    editorViewController.ownedBrushesBlock = ^(CVSEditorViewController *c) {
        return [weakSelf ownedBrushes];
    };
    editorViewController.globalBrushesBlock = ^(CVSEditorViewController *c) {
        return [weakSelf globalBrushes];
    };
    editorViewController.addBrushesBlock = ^(CVSEditorViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabBrushes source:@"Editor-Brushes" fromViewController:c];
    };
    editorViewController.addColorsBlock = ^(CVSEditorViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabColors source:@"Editor-Colors" fromViewController:c];
    };

    if (isFirstQuest && [quest.serverID isEqualToString:self.dataStoreController.preloadedQuestID])
    {
        editorViewController.placeholderTemplateImage = [UIImage imageNamed:@"preloaded_quest_template"];
    }

    [self presentEditorViewController:editorViewController fromViewController:presentingViewController displayBackButton:YES completionBlock:^(CVSPadEditorViewController *c) {
        [weakSelf commentEditorViewControllerDone:c];
    }];
    /*
    __weak typeof(self) weakSelf = self;
    BOOL noLoggedInUser = (self.accountController.loggedInAccount == nil);

    CVSPadEditorViewController *editorViewController = [[CVSPadEditorViewController alloc] initCommentEditorWithQuest:quest draftsPath:self.draftsPath imageController:self.imageController source:source delegate:self];
    editorViewController.moreColorsDisabled = isFirstQuest || noLoggedInUser;
    editorViewController.addColorsBlock = ^(CVSEditorViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabColors source:@"Editor-Colors" fromViewController:c];
    };
    editorViewController.addBrushesBlock = ^(CVSEditorViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabBrushes source:@"Editor-Brushes" fromViewController:c];
    };
    editorViewController.shopBlock = ^(CVSEditorViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabDefault source:@"Editor" fromViewController:c];
    };
    editorViewController.ownedBrushesBlock = ^(CVSEditorViewController *c) {
        return [self ownedBrushes];
     };
     editorViewController.globalBrushesBlock = ^(CVSEditorViewController *c) {
     return [weakSelf globalBrushes];
     };
    editorViewController.doneButtonTappedBlock = ^(CVSEditorViewController *c) {
        [weakSelf commentEditorViewControllerDone:c];
    };
    if (isFirstQuest)
    {
        if ([quest.serverID isEqualToString:self.dataStoreController.preloadedQuestID])
        {
            editorViewController.placeholderTemplateImage = [UIImage imageNamed:@"preloaded_quest_template"];
        }
    }

    UIButton *navButton = [UIButton buttonWithType:UIButtonTypeCustom];
    navButton.frame = CGRectMake(16.0f, 6.0f, 48.0f, 48.0f);

    if (noLoggedInUser)
    {
        if ( ! presentingViewController)
        {
            presentingViewController = [self showHomeAndAutomaticModals:NO];
        }
        [navButton addTarget:presentingViewController.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
        [navButton setImage:[UIImage imageNamed:@"button_topNav_back"] forState:UIControlStateNormal];
        [self showViewController:editorViewController fromViewController:presentingViewController];
    }
    else
    {
        DQMainNavigationController *navigationController = [[DQMainNavigationController alloc] initWithRootViewController:editorViewController delegate:self];

        [navButton addTarget:self action:@selector(editorBasementButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [navButton setImage:[UIImage imageNamed:@"button_topNav_menu"] forState:UIControlStateNormal];

        // FIXME: HACK: ios7 sdk layout issue with big black/white bar on the right side of views.
        //        navigationController.view.frame = editorViewController.view.frame;
        navigationController.view.frame = [[[[[UIApplication sharedApplication] keyWindow] rootViewController] view] bounds];
        self.basementViewController.topViewController = navigationController;
        [self.basementViewController hideBottomView];

        // Display new colors alert if appropriate
        if (self.accountController.loggedInAccount.lastViewedColorAlertVersion < self.accountController.loggedInAccount.currentColorAlertVersion)
        {
            // Delay to prevent animation glitch
            double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self showNewColorsAlert];
            });
        }
    }
     */
}

#pragma mark -
#pragma mark Presenting an Editor

- (void)presentEditorViewController:(CVSPadEditorViewController *)editorVC fromViewController:(UIViewController *)presentingViewController displayBackButton:(BOOL)shouldDisplayBackButton completionBlock:(void (^)(CVSPadEditorViewController *c))completionBlock
{
    __weak typeof(editorVC) weakEditorVC = editorVC;
    __weak typeof(presentingViewController) weakPresentingViewController = presentingViewController;

    DQController *c = [[DQController alloc] initWithDelegate:self];
    UIBarButtonItem *doneButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
        if (completionBlock)
        {
            completionBlock(weakEditorVC);
        }
    }];

    UIBarButtonItem *shopButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_shop" buttonBlock:^(DQButton *button) {
        [self showShopWithTab:DQShopViewControllerTabDefault source:@"Home" fromViewController:weakEditorVC];
    }];

    if (shouldDisplayBackButton)
    {
        
        editorVC.navigationItem.leftBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_back" buttonBlock:^(DQButton *button) {
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        }];
    }

    UIBarButtonItem *spacingItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    // FIXME: Use Correct padding here
    spacingItem.width = kDQFormPhoneNavigationItemSpacing;

    editorVC.navigationItem.rightBarButtonItems = @[doneButtonItem, spacingItem, shopButtonItem];

    DQNavigationController *navController = [self newNavigationControllerWithRootViewController:editorVC forViewController:nil];
    navController.view.tintColor = [UIColor dq_editorTabColor];
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    navController.navigationBar.translucent = NO;

    if ([self.accountController loggedInAccount])
    {
        if ( ! presentingViewController)
        {
            presentingViewController = [self showHomeAndAutomaticModals:NO];
        }
        [self showViewController:editorVC fromViewController:presentingViewController withBackgroundImage:nil];
    }
    else
    {
        DQMainNavigationController *navigationController = [[DQMainNavigationController alloc] initWithRootViewController:editorVC delegate:self];

        // FIXME: HACK: ios7 sdk layout issue with big black/white bar on the right side of views.
        //        navigationController.view.frame = editorViewController.view.frame;
        navigationController.view.frame = [[[[[UIApplication sharedApplication] keyWindow] rootViewController] view] bounds];
        self.basementViewController.topViewController = navigationController;
        [self.basementViewController hideBottomView];

        // Display new colors alert if appropriate
        if (self.accountController.loggedInAccount.lastViewedColorAlertVersion < self.accountController.loggedInAccount.currentColorAlertVersion)
        {
            // Delay to prevent animation glitch
            double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self showNewColorsAlert];
            });
        }
    }
}


- (void)editorBasementButtonTapped:(id)sender
{
    UIViewController *presentingViewController = self.basementViewController.topViewController;
    if ([presentingViewController isKindOfClass:[UINavigationController class]])
    {
        presentingViewController = ((UINavigationController *)presentingViewController).topViewController;
    }
    [self discloseItemPressedFromViewController:presentingViewController];
}

#pragma mark - Presenting the Add Friends Modal

- (void)showAddFriendsModalFromPresentingViewController:(UIViewController<MFMailComposeViewControllerDelegate> *)presentingViewController
{
    if ([self featureInviteFromFacebook] || [self featureInviteFromTwitter])
    {
        DQAddFriendsViewController *addFriendsViewController = [self newAddFriendsViewControllerForSignupService:DQAuthenticationSignupServiceNone];
        DQNavigationController *modalNavController = [self newModalNavigationControllerWithRootViewController:addFriendsViewController];

        addFriendsViewController.title = DQLocalizedString(@"Add Friends", @"Title for modal where the user can invite their friends to DrawQuest");

        DQController *controller = [[DQController alloc] initWithDelegate:self];

        __weak typeof(self) weakSelf = self;
        __weak typeof(addFriendsViewController) weakAddFriendsViewController = addFriendsViewController;
        __weak typeof(presentingViewController) weakPVC = presentingViewController;

        addFriendsViewController.navigationItem.leftBarButtonItem = [controller newCancelBarButtonItemWithBlock:^(id sender) {
            [weakPVC dismissViewControllerAnimated:YES completion:nil];
        }];

        addFriendsViewController.navigationItem.rightBarButtonItem = [controller newDoneBarButtonItemWithBlock:^(id sender) {
            [weakAddFriendsViewController submitWithCancellationBlock:^{
                // Do nothing on cancel
            } completionBlock:^{
                [weakPVC dismissViewControllerAnimated:YES completion:nil];
            } failureBlock:^(NSError *error) {
                [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Error sending invites.", @"Invite error alert title") description:error.dq_displayDescription];
            }];
        }];

        [presentingViewController presentViewController:modalNavController animated:YES completion:nil];
    }
    else
    {
        // Just go directly to email if it's the only option
        [self inviteFriendsViaEmailFromPresentingViewController:presentingViewController];
    }
}

#pragma mark -
#pragma mark Publishing

- (DQCommentPublishController *)newCommentPublishController
{
    DQCommentPublishController *result = [super newCommentPublishController];
    __weak typeof(self) weakSelf = self;
    result.showGalleryBlock = ^(DQCommentPublishController *c, CVSEditorViewController *editorViewController, void (^beforePresentingBlock)(DQGalleryViewController *)) {
        [weakSelf showGalleryForQuestWithID:editorViewController.quest.serverID commentID:nil source:@"Posting" publishing:YES fromViewController:nil beforePresenting:beforePresentingBlock];
    };
    result.makePublishViewControllerBlock = ^(DQCommentPublishController *c) {
        return [[DQCommentPublishViewController alloc] initWithPublishDataSource:c publishDelegate:c delegate:weakSelf rewardsDictionary:weakSelf.rewardsDictionary facebookController:weakSelf.facebookController twitterController:weakSelf.twitterController];
    };
    return result;
}

#pragma mark -
#pragma mark DQViewControllerDelegate methods

- (DQNavigationController *)newNavigationControllerForViewController:(UIViewController<DQViewController> *)vc
{
    return [self newModalNavigationController];
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController forViewController:(UIViewController<DQViewController> *)vc
{
    return [self newModalNavigationControllerWithRootViewController:rootViewController];
}

#pragma mark -
#pragma mark DQMainNavigationControllerDelegate methods

- (void)mainNavigationController:(DQMainNavigationController *)nc basementButtonTapped:(DQBasementButton *)basementButton
{
    [self discloseItemPressedFromViewController:nc.topViewController];
}

- (NSUInteger)numberOfUnreadActivityItemsForMainNavigationController:(DQMainNavigationController *)nc
{
    return [self.activityController numberOfUnreadActivityItems];
}

#pragma mark -
#pragma mark DQActivityControllerDelegate methods

- (DQActivityDataStoreController *)newActivityDataStoreControllerForActivityController:(DQActivityController *)c
{
    return [[DQActivityDataStoreController alloc] initWithDelegate:self];
}

- (void)activityController:(DQActivityController *)c didLoadActivities:(NSArray *)activities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger count = 0;
        if (self.basementViewController.basementIsVisible)
        {
            [self.activityController markAllActivityItemsRead];
        }
        else
        {
            count = [self.activityController numberOfUnreadActivityItems];
        }
        [self.menuViewController replaceActivities:activities];
        [[NSNotificationCenter defaultCenter] postNotificationName:DQActivityCountUpdateNotification object:self userInfo:@{@"count": @(count)}];
    });
}

- (void)activityController:(DQActivityController *)c didUpdateActivities:(NSArray *)activities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger count = 0;
        BOOL visible = self.basementViewController.basementIsVisible;
        if (visible)
        {
            [self.activityController markAllActivityItemsRead];
        }
        else
        {
            count = [self.activityController numberOfUnreadActivityItems];
        }
        [self.menuViewController prependActivities:activities];
        [[NSNotificationCenter defaultCenter] postNotificationName:DQActivityCountUpdateNotification object:self userInfo:@{@"count": @(count)}];
    });
}

- (void)activityController:(DQActivityController *)c didScrollActivities:(NSArray *)activities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.menuViewController appendActivities:activities];
    });
}

- (void)activityController:(DQActivityController *)c loadFailedWithError:(NSError *)error
{
    // not sure what to do here, the old implementation didn't do anything in this situation
    // and i'm not sure what the right thing to do is
}

- (void)activityController:(DQActivityController *)c updateFailedWithError:(NSError *)error
{
    // do nothing for now, the menuViewController had no idea this was happening anyway
}

- (void)activityController:(DQActivityController *)c scrollFailedWithError:(NSError *)error
{
    [self.menuViewController loadMoreActivitiesFailed];
}

#pragma mark -
#pragma mark DQPadHomeViewControllerDataSource methods

- (NSString *)firstRunQuestIDForPadHomeViewController:(DQPadHomeViewController *)vc
{
    return self.firstRunQuestID;
}

- (NSString *)questOfTheDayIDForPadHomeViewController:(DQPadHomeViewController *)vc
{
    return self.questOfTheDayID;
}

- (void)padHomeViewController:(DQPadHomeViewController *)vc takeQuestOfTheDayID:(NSString *)questOfTheDayID
{
    self.questOfTheDayID = questOfTheDayID;
}

@end

@implementation DQPadApplicationController (TemplateMethods)

// CHECK
+ (void)configureUIAppearance
{
    
    [[UINavigationBar appearanceWhenContainedIn:[DQModalNavigationController class], nil] setBackgroundImage:DQImageWithColor(DQColorGreen) forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedIn:[DQModalNavigationController class], nil] setShadowImage:[[UIImage alloc] init]];
    
    
    NSDictionary *atts = @{
                           NSForegroundColorAttributeName: [UIColor whiteColor],
                           NSFontAttributeName: [UIFont dq_modalNavigationBarTitleFont]
                           };
    [[UINavigationBar appearanceWhenContainedIn:[DQModalNavigationController class], nil] setTitleTextAttributes:atts];
    atts = @{
             NSForegroundColorAttributeName: [UIColor whiteColor],
             NSFontAttributeName: [UIFont fontWithName:@"ArialRoundedMTBold" size:24.0f]
             };
    [[UINavigationBar appearanceWhenContainedIn:[DQNavigationController class], nil] setTitleTextAttributes:atts];
}

// CHECK
- (void)configureMainWindow
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    self.basementViewController = [[STBasementViewController alloc] initWithNibName:nil bundle:nil];
    self.followController.basementViewController = self.basementViewController;
    self.starController.basementViewController = self.basementViewController;
    self.menuViewController = [self newMenuViewController];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.basementViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

// CHECK
- (void)initializeViewStateWithLaunchOptions:(NSDictionary *)launchOptions
{
    if (self.accountController.hasUserEverLoggedIn)
    {
        // Fake Push Notifications
        // FB Friend joined
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"facebook_friend_joined", @"push_notification_type", @"dmauro", @"username", nil];
        // Starred
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"starred", @"push_notification_type", @"3930", @"comment_id", @"926", @"quest_id", nil];
        // Quest of the Day
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"quest_of_the_day", @"push_notification_type", nil];
        // New Colors
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"new_palettes", @"push_notification_type", nil];
        // Featured in Explore
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"featured_in_explore", @"push_notification_type", @"3930", @"comment_id", nil];
        // Unknown Push notification
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"unknown_future_push_notification", @"push_notification_type", @"999", @"comment_id", @"999", @"unknown_id", nil];
        // New Colors Alert
        // NSDictionary *remoteNotification = [[NSDictionary alloc] initWithObjectsAndKeys:@"new_color_alert", @"push_notification_type", @(1), @"color_alert_version", nil];

        // if the user has never logged in, don't process push notifications
        // Check the payload, set up the view hierarchy to respond;
        NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        BOOL showHome = YES;
        if (remoteNotification)
        {
            showHome = ! [self handlePushNotificationWithDictionary:remoteNotification];
        }
        else if (localNotification)
        {
            showHome = ! [self handlePushNotificationWithDictionary:localNotification.userInfo];
        }
        if (showHome)
        {
            [self showHomeAndAutomaticModals:self.accountController.loggedIn];
        }
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        DQFirstTimeViewController *firstTimeViewController = [[DQFirstTimeViewController alloc] initWithDelegate:self];
        firstTimeViewController.showAuthBlock = ^(DQFirstTimeViewController *c) {
            [weakSelf requestSignInFromViewController:c cancellationBlock:^{
                // TODO: do anything if they cancel?
            } completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
                [weakSelf showHomeAndAutomaticModals:(signupService == DQAuthenticationSignupServiceNone)]; // only if the user just logged in, not for signups.
            } failureBlock:^(NSError *error) {
                [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") description:error.dq_displayDescription];
            }];
        };
        firstTimeViewController.showFirstQuestBlock = ^{
            [weakSelf showHomeAndAutomaticModals:NO]; // we want the user to see the onboarding quest
        };
        self.basementViewController.topViewController = firstTimeViewController;

        //This is a kinda ugly fix for the iOS 5 initial orientation bug (which displayed the first run image as 768x1024, rather than 1024x768
        // Note: It's also ugly because it probably doesn't belong here, rather, in the first time view controller itself
        //       (a violation of the law of demeter)
        UIImageView *iv = [[firstTimeViewController.view subviews] objectAtIndex:0];
        iv.frame = CGRectMake(0, 0, 1024, 768);
    }
}

- (void)accountChangedWithNotification:(NSNotification *)notification
{
    // Do we need to do anything here?
}

// CHECK
- (BOOL)dispatchURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation forApplication:(UIApplication *)application fromActiveViewController:(UIViewController *)activeViewController checking:(BOOL)isChecking
{
    UIViewController *presentingViewController = [activeViewController isKindOfClass:[CVSEditorViewController class]] ? nil : activeViewController;
    if ([[url scheme] isEqualToString:@"drawquest"])
    {
        NSArray *pathComponents = [url pathComponents];
        NSString *host = [url host];

        // drawquest:// or drawquest:/// (etc)
        if (!host)
        {
            if ( ! isChecking)
            {
                [self showHomeAndAutomaticModals:YES];
                [self.basementViewController hideBottomView];
            }
            return YES;
        }
        // drawquest://about or drawquest://about/
        else if ([host isEqualToString:@"about"] && [pathComponents count] < 2)
        {
            if ( ! isChecking)
            {
                [self showAboutFromViewController:activeViewController]; // use activeViewController because we CAN show about on top of the editor
                [self.basementViewController hideBottomView];
            }
            return YES;
        }
        // drawquest://settings or drawquest://settings/
        else if ([host isEqualToString:@"settings"] && [pathComponents count] < 2)
        {
            if (self.accountController.loggedIn)
            {
                if ( ! isChecking)
                {
                    // FIXME: Why isn't this using the presentation method?
                    NSString *username = self.accountController.loggedInAccount.username;
                    DQProfileViewController *profileViewController = [self showProfileForUserWithUserName:username fromViewController:presentingViewController source:@"URL-Settings"];
                    [self.basementViewController hideBottomView];
                    [self showSettingsFromViewController:profileViewController];
                }
            }
            else
            {
                return NO;
            }
            return YES;
        }
        // drawquest://explore or drawquest://explore/
        else if ([host isEqualToString:@"explore"] && [pathComponents count] < 2)
        {
            if ( ! isChecking)
            {
                [self showExploreForCommentWithID:nil];
                [self.basementViewController hideBottomView];
            }
            return YES;
        }
        // drawquest://profile/username or drawquest://profile/username/
        else if ([host isEqualToString:@"profile"] && ([pathComponents count] == 2))
        {
            if ( ! isChecking)
            {
                NSString *username = pathComponents[1];
                [self showProfileForUserWithUserName:username fromViewController:presentingViewController source:@"URL-Profile"];
                [self.basementViewController hideBottomView];
            }
            return YES;
        }
        // drawquest://draw/questID
        else if ([host isEqualToString:@"draw"] && ([pathComponents count] == 2))
        {
            NSString *questID = pathComponents[1];
            DQQuest *quest = [self.dataStoreController questForServerID:questID];
            if (quest)
            {
                if ( ! isChecking)
                {
                    [self showCommentEditorForQuest:quest isFirstQuest:NO source:@"URL-Draw" fromViewController:presentingViewController];
                    [self.basementViewController hideBottomView];
                }
            }
            else
            {
                // FIXME: this is no good, we need to be able to show an editor for a quest *id*
                // because it might not be fetched yet, and we need to fetch it to be able to display
                // an editor, but we can't do that synchronously
                return NO;
            }
            return YES;
        }
        // drawquest://quest/questID/drawing/commentID
        else if ([host isEqualToString:@"quest"] && ([pathComponents count] == 4) && [pathComponents[2] isEqualToString:@"drawing"])
        {
            if ( ! isChecking)
            {
                NSString *questID = pathComponents[1];
                NSString *commentID = pathComponents[3];
                [self showGalleryForQuestWithID:questID commentID:commentID source:@"URL-Drawing" publishing:NO fromViewController:presentingViewController beforePresenting:nil];
                [self.basementViewController hideBottomView];
            }
            return YES;
        }
        // drawquest://quest/questID
        else if ([host isEqualToString:@"quest"] && ([pathComponents count] == 2))
        {
            if ( ! isChecking)
            {
                NSString *questID = pathComponents[1];
                [self showGalleryForQuestWithID:questID commentID:nil source:@"URL-Quest" publishing:NO fromViewController:presentingViewController beforePresenting:nil];
                [self.basementViewController hideBottomView];
            }
            return YES;
        }
        // drawquest://<unknown>
        else
        {
            return NO;
        }
    }
    else
    {
        // when we get valid facebook openURL requests, we've already launched, and we won't be checking
        // so if we get a facebook openURL request and we're checking, we've just launched, and in that
        // case an appcall isn't going to work, so just return NO
        return !isChecking && [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    }
}

#pragma mark -
#pragma mark Push

// CHECK
- (UIViewController *)activeViewController
{
    UIViewController *result = self.basementViewController.topViewController;
    if ([result isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)result;
        result = navigationController.topViewController;
    }
    return result;
}

// CHECK
- (BOOL)shouldOpenURL:(NSURL *)url fromViewController:(UIViewController *)vc
{
    return
    [[url scheme] hasPrefix:@"fb"] || // allow all facebook URLs to pass through
    // but drawquest:// URLs can be opened only when we aren't authenticating
    (! (self.authenticationController || self.publishController ||
        // and (if there is a vc already) it isn't the first time screen
        (vc && ([vc isKindOfClass:[DQFirstTimeViewController class]] ||
                // and there isn't a modal being presented
                vc.presentedViewController))
        ));
}

// CHECK
- (BOOL)shouldDispatchPushNotificationFromViewController:(UIViewController *)vc
{
    return ![self isDisplayingOnboardingFromViewController:vc];
}

// CHECK
- (void)showEditorForInterruptedQuest
{
    NSString *serverID = [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationDrawingCrashProtectionQuestServerIDKey];
    DQQuest *interruptedQuest = [self.dataStoreController questForServerID:serverID];
    DQHomeViewController *home = [self showHomeAndAutomaticModals:NO];
    [self showCommentEditorForQuest:interruptedQuest isFirstQuest:NO source:@"Interrupted-Quest" fromViewController:home];
}

#pragma mark -
#pragma mark Presenting the Home Page

- (DQHomeViewController *)showHomeAndAutomaticModals:(BOOL)showAutomaticModals
{
    __weak typeof(self) weakSelf = self;
    DQPadHomeViewController *homeViewController = [[DQPadHomeViewController alloc] initWithDelegate:self dataSource:self];
    homeViewController.showEditorForQuestOfTheDayBlock = ^(DQHomeViewController *presentingViewController, DQQuest *quest, BOOL isFirstQuest) {
        [weakSelf showCommentEditorForQuest:quest isFirstQuest:isFirstQuest source:@"Quest-Of-The-Day" fromViewController:presentingViewController];
    };
    homeViewController.showGalleryForQuestBlock = ^(DQHomeViewController *presentingViewController, DQQuest *quest) {
        [weakSelf showGalleryForQuestWithID:quest.serverID commentID:nil source:@"Quest-Archive" publishing:NO fromViewController:presentingViewController beforePresenting:nil];
    };
    homeViewController.showGalleryForQuestOfTheDayBlock = ^(DQHomeViewController *presentingViewController, DQQuest *quest) {
        [weakSelf showGalleryForQuestWithID:quest.serverID commentID:nil source:@"Quest-Of-The-Day" publishing:NO fromViewController:presentingViewController beforePresenting:nil];
    };
    homeViewController.showProfileForUserBlock = ^(DQHomeViewController *presentingViewController, NSString *username) {
        [weakSelf showProfileForUserWithUserName:username fromViewController:presentingViewController source:@"Quest-Of-The-Day-Attribution"];
    };
    homeViewController.showShopBlock = ^(DQHomeViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabColors source:@"Quest-Archive" fromViewController:c];
    };
    [self replaceBasementWithViewController:homeViewController withBackgroundImage:nil];

    BOOL upgradingFrom1xx = [self.previouslyLaunchedAppVersion hasPrefix:@"1."];
    if (showAutomaticModals)
    {
        NSString *upgradeType = self.upgradeType;
        BOOL upgradeIsAvailable = !self.hasSeenAvailableUpgradeModal && [self.versionForAvailableUpgradeModal length] && ([self.runningAppVersion compare:self.versionForAvailableUpgradeModal options:NSNumericSearch] == NSOrderedAscending);
        BOOL shouldShowUpgradeIsAvailableModal = upgradeIsAvailable && [upgradeType isEqualToString:DQAPIValueUpgradeTypeModal];
        BOOL shouldShowUpgradeIsAvailableAlert = upgradeIsAvailable && [upgradeType isEqualToString:DQAPIValueUpgradeTypeAlert];
        if (self.accountController.loggedIn)
        {
            if (upgradingFrom1xx && !self.hasSeen1xxTo2xxUpgradeFlow)
            {
                dispatch_async(dispatch_get_main_queue(), ^{ // async because we need any modal that is currently dismissing to be dismissed before we present
                    [self showUpgradeFlowFor1xxTo2xxFromHomeViewController:homeViewController];
                    self.hasSeen1xxTo2xxUpgradeFlow = YES;
                });
            }
            else
            {
                if (self.accountController.loggedInAccount.shouldShowShareWebProfile && shouldShowUpgradeIsAvailableModal)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{ // async because we need any modal that is currently dismissing to be dismissed before we present
                        [self showShareWebProfileModalThenUpgradeIsAvailableModalFromViewController:homeViewController];
                    });
                }
                else if (self.accountController.loggedInAccount.shouldShowShareWebProfile)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{ // async because we need any modal that is currently dismissing to be dismissed before we present
                        [self showWebProfileModalFromViewController:homeViewController];
                    });
                }
                else if (shouldShowUpgradeIsAvailableModal)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{ // async because we need any modal that is currently dismissing to be dismissed before we present
                        [self showUpgradeIsAvailableModalFromViewController:homeViewController];
                    });
                }
            }
        }
        else
        {
            if (shouldShowUpgradeIsAvailableModal)
            {
                dispatch_async(dispatch_get_main_queue(), ^{ // async because we need any modal that is currently dismissing to be dismissed before we present
                    [self showUpgradeIsAvailableModalFromViewController:homeViewController];
                });
            }
        }

        if (shouldShowUpgradeIsAvailableAlert) // mutually exclusive with showing the modal
        {
            dispatch_async(dispatch_get_main_queue(), ^{ // async because we need any modal that is currently dismissing to be dismissed before we present
                [self showUpgradeIsAvailableAlert];
            });
        }
    }

    // Ask for push permissions the first time we see the home page
    /*
    if (self.featureUARegistration)
    {
        if (self.accountController.loggedIn || self.featureUARegistrationBeforeAuth)
        {
            [[UAPush shared] setPushEnabled:YES];
        }
    }
     */

    return homeViewController;
}

#pragma mark -
#pragma mark Presenting the Explore Page

- (void)showExploreForCommentWithID:(NSString *)commentID
{
    if (self.accountController.loggedInAccount)
    {
        __weak typeof(self) weakSelf = self;
        [self.basementViewController hideBottomView];
        DQExploreViewController *exploreController = [[DQExploreViewController alloc] initWithSearchEnabled:self.featureUserSearch delegate:self];
        // FIXME: HACK: ios7 sdk layout issue with big black/white bar on the right side of views.
        exploreController.view.frame = [[[[[UIApplication sharedApplication] keyWindow] rootViewController] view] bounds];//self.basementViewController.topViewController.view.frame;
        if (commentID)
        {
            exploreController.forcedCommentID = commentID;
        }
        exploreController.tappedCommentBlock = ^(DQExploreViewController *c, NSString *questID, NSString *commentID) {
            [weakSelf showGalleryForQuestWithID:questID commentID:commentID source:@"Explore" publishing:NO fromViewController:c beforePresenting:nil];
        };
        exploreController.displaySearchBlock = ^(DQExploreViewController *c) {
            DQExploreUserSearchViewController *controller = [[DQExploreUserSearchViewController alloc] initWithDelegate:self];
            controller.displayProfileBlock = ^(DQExploreUserSearchViewController *c, NSString *userName) {
                [weakSelf showProfileForUserWithUserName:userName fromViewController:c source:@"Search-Users"];
            };
            [c.navigationController pushViewController:controller animated:YES];
        };
       
        [self replaceBasementWithViewController:exploreController withBackgroundImage:DQImageWithColor(DQColorBlue)];
    }
}

#pragma mark -
#pragma mark Presenting a Profile

- (DQProfileViewController *)showProfileForUserWithUserName:(NSString *)userName fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    userName = userName ?: self.accountController.loggedInAccount.username;
    DQPadProfileViewController *profileController = [[DQPadProfileViewController alloc] initWithUserName:userName source:source delegate:self];

    __weak typeof(self) weakSelf = self;
    profileController.showShopBlock = ^(DQProfileViewController *vc) {
        [weakSelf showShopWithTab:DQShopViewControllerTabDefault source:@"Profile" fromViewController:vc];
    };
    profileController.displayFollowingBlock = ^(DQProfileViewController *c) {
        [weakSelf showUserListOfType:DQUserListTypeFollowing forUserName:c.userName fromViewController:c];
    };
    profileController.displayFollowersBlock = ^(DQProfileViewController *c) {
        [weakSelf showUserListOfType:DQUserListTypeFollowers forUserName:c.userName fromViewController:c];
    };
    profileController.displayGalleryForCommentBlock = ^(DQProfileViewController *c, DQComment *comment) {
        [weakSelf showGalleryForQuestWithID:comment.questID commentID:comment.serverID source:@"Profile" publishing:NO fromViewController:c beforePresenting:nil];
    };
    profileController.displaySettingsBlock = ^(DQProfileViewController *c) {
        [weakSelf showSettingsFromViewController:c];
    };
    profileController.inviteFriendsBlock = ^(UIViewController<MFMailComposeViewControllerDelegate> *pvc) {
        [weakSelf showAddFriendsModalFromPresentingViewController:pvc];
    };
    profileController.shopBlock = ^(DQProfileViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabColors source:@"Profile" fromViewController:c];
    };
    [self showViewController:profileController fromViewController:presentingViewController withBackgroundImage:DQImageWithColor(DQColorRed)];
    
    return profileController;
}

#pragma mark -
#pragma mark Presenting a Gallery

- (void)showCommentWithID:(NSString *)commentID questID:(NSString *)questID source:(NSString *)source publishing:(BOOL)isPublishing fromViewController:(UIViewController *)presentingViewController
{
    [self showGalleryForQuestWithID:questID commentID:commentID source:source publishing:isPublishing fromViewController:presentingViewController beforePresenting:nil];
}

- (void)showGalleryForQuestWithID:(NSString *)questID commentID:(NSString *)commentID source:(NSString *)source publishing:(BOOL)isPublishing fromViewController:(UIViewController *)presentingViewController beforePresenting:(void (^)(DQGalleryViewController *galleryViewController))beforePresentingBlock
{
    __weak typeof(self) weakSelf = self;
    DQPadGalleryViewController *galleryViewController = [[DQPadGalleryViewController alloc] initWithQuestID:questID focusedCommentID:commentID source:source publishing:isPublishing newPlaybackDataManager:nil delegate:self];
    galleryViewController.drawThisQuestBlock = ^(DQPadGalleryViewController *c) {
        [weakSelf showCommentEditorForQuest:c.quest isFirstQuest:NO source:@"Gallery" fromViewController:c];
    };
    galleryViewController.displayProfileForUserNameBlock = ^(DQGalleryViewController *c, NSString *userName) {
        [weakSelf showProfileForUserWithUserName:userName fromViewController:c source:@"Gallery"];
    };
    galleryViewController.saveToCameraRollBlock = ^(DQGalleryViewController *c, DQComment *comment, UIView *view) {
        [weakSelf saveCommentToCameraRoll:comment fromViewController:c fromView:view];
    };
    galleryViewController.displayPlaybackBlock = ^(DQGalleryViewController *c, DQQuest *quest, DQComment *comment) {
        [weakSelf showPlaybackForComment:comment inQuest:quest fromViewController:c];
    };
    galleryViewController.commentViewedBlock = ^(DQGalleryViewController *c, NSString *commentID) {
        [weakSelf.commentViewTracker trackViewOfCommentWithServerID:commentID];
    };
    galleryViewController.makeSharingControllerBlock = ^(DQGalleryViewController *c) {
        return [weakSelf newSharingController];
    };

    if (beforePresentingBlock)
    {
        beforePresentingBlock(galleryViewController);
    }
    [self showViewController:galleryViewController fromViewController:presentingViewController withBackgroundImage:DQImageWithColor(DQColorGreen)];
}

#pragma mark -
#pragma mark Presenting Shop

- (void)showNewColorsAlert
{
    if (self.accountController.loggedIn)
    {
        // Update last viewed color alert version
        self.accountController.loggedInAccount.lastViewedColorAlertVersion = self.accountController.loggedInAccount.currentColorAlertVersion;

        __weak typeof(self) weakSelf = self;
        DQController *c = [[DQController alloc] initWithDelegate:self];
        DQShopViewController *shop = [self newShopViewControllerWithTab:DQShopViewControllerTabColors source:@"NewColorsAlert"];
        shop.title = DQLocalizedString(@"New Colors!", @"New colors available in shop message");
        shop.navigationItem.hidesBackButton = YES;
        shop.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
            weakSelf.shopBarButtonRestorePurchasesCompletionBlock = nil;
            weakSelf.shopBarButtonRestorePurchasesFailureBlock = nil;
            [weakSelf dismissViewControllerWithStarburstAnimated:YES completion:nil];
        }];
        DQNavigationController *navController = [self newModalNavigationControllerWithRootViewController:shop];
        [self presentViewControllerWithStarburst:navController withBounds:CGRectMake(0.0f, 0.0f, 540.0f, 620.0f) animated:YES completion:nil];
    }
}

#pragma mark - Show QotD

- (void)showQuestOfTheDay
{
    [self showHomeAndAutomaticModals:NO]; // user wants to see the new quest of the day here
}

// CHECK
- (DQActivityController *)newActivityController
{
    return [[DQActivityController alloc] initWithDelegate:self];
}

@end
