//
//  DQPhoneApplicationController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-11.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneApplicationController.h"
#import <FacebookSDK/FacebookSDK.h>

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "UIColor+DQAdditions.h"
#import "DQViewMetricsConstants.h"
#import "UIImage+DQAdditions.h"
#import "UIImage+ImageEffects.h"
#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"

// Models
#import "DQComment.h"
#import "DQQuest.h"
#import "DQQuestUpload.h"

// Controllers
#import "DQActivityDataStoreController.h"
#import "DQPlaybackDataManager.h"
#import "DQAuthenticationController.h"
#import "DQFirstQuestCompletionViewController.h"

// View Controllers
#import "CVSPhoneEditorViewController.h"
#import "DQPhoneHomeViewController.h"
#import "DQPhoneDrawViewController.h"
#import "DQPhoneActivityViewController.h"
#import "DQPhoneProfileViewController.h"
#import "DQAboutViewController.h"
#import "DQPhoneGalleryViewController.h"
#import "DQDrawingDetailViewController.h"
#import "DQSimilarQuestsViewController.h"
#import "DQQuestPublishViewController.h"
#import "DQPhoneCommentPublishViewController.h"
#import "DQPhoneFirstTimeViewController.h"
#import "DQPublishRewardsViewController.h"
#import "DQPhoneAddFriendsViewController.h"
#import "DQShopViewController.h"
#import "DQBioEditorViewController.h"
#import "DQUserSearchViewController.h"
#import "DQDrawingZoomViewController.h"

// Views
#import "DQButton.h"
#import "DQQuestTitleView.h"
#import "DQActionSheet.h"
#import "DQAlertView.h"
#import "DQHUDView.h"
#import "DQQuestOfTheDayView.h"

// Temp
#import "DQAlmostThereViewController.h"
#import "DQSignInViewController.h"
#import "DQSignInViewController.h"
#import "DQViewController.h"
#import "DQAddFriendsViewController.h"
#import "UIFont+DQAdditions.h"

#import "Appirater.h"

@class DQTabBarController;

@interface DQTabBarBadgeView : UIView

@property (nonatomic, strong) UIImageView *homeTabImageView;
@property (nonatomic, strong) UIImageView *drawTabImageView;
@property (nonatomic, strong) UIImageView *activityTabImageView;
@property (nonatomic, strong) UIImageView *profileTabImageView;

@property (nonatomic, strong) UIView *homeBadgeView;
@property (nonatomic, strong) UIView *drawBadgeView;
@property (nonatomic, strong) UIView *activityBadgeView;
@property (nonatomic, strong) UIView *profileBadgeView;

@end

@interface DQTabBarController : UITabBarController

@property (nonatomic, strong) DQTabBarBadgeView *badgeView;

@end

@interface DQPhoneApplicationController () <DQActivityControllerDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) DQTabBarController *tabBarController;
@property (nonatomic, strong) DQNavigationController *homeTabNavigationController;
@property (nonatomic, strong) DQPhoneHomeViewController *homeViewController;
@property (nonatomic, strong) DQNavigationController *drawTabNavigationController;
@property (nonatomic, strong) DQPhoneDrawViewController *drawViewController;
@property (nonatomic, strong) DQNavigationController *activityTabNavigationController;
@property (nonatomic, strong) DQPhoneActivityViewController *activityViewController;
@property (nonatomic, strong) DQNavigationController *profileTabNavigationController;
@property (nonatomic, strong) DQPhoneProfileViewController *profileViewController;
@property (nonatomic, strong) UIWindow *publishRewardsWindow;
@property (nonatomic, strong) UIWindow *zoomableImageWindow;
@property (nonatomic, readwrite, strong) DQCommentPublishController *publishController;
@property (nonatomic, assign) BOOL shouldAutomaticallyPopToRoot;
@end

@implementation DQPhoneApplicationController

- (void)takeHeavyStateSync:(NSDictionary *)responseDictionary
{
    [super takeHeavyStateSync:responseDictionary];
    NSDictionary *badges = [responseDictionary dictionaryForKey:@"tab_badges"];
    if ([badges count])
    {
        if ([badges boolForKey:@"home"])
        {
            [self showBadgeOnHomeTab];
        }
        if ([badges boolForKey:@"draw"])
        {
            [self showBadgeOnDrawTab];
        }
        if ([badges boolForKey:@"activity"])
        {
            [self showBadgeOnActivityTab];
        }
    }
}

- (void)displayMainTabs
{
    self.window.backgroundColor = [UIColor dq_phoneBackgroundColor];
    self.tabBarController.tabBar.hidden = NO;
    self.tabBarController.viewControllers = @[
                                              self.homeTabNavigationController,
                                              self.drawTabNavigationController,
                                              self.activityTabNavigationController,
                                              self.profileTabNavigationController
                                              ];
}

- (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation forApplication:(UIApplication *)application
{
    if ([self.tabBarController.viewControllers count] < 4)
    {
        [self displayMainTabs];
    }
    return [super openURL:url sourceApplication:sourceApplication annotation:annotation forApplication:application];
}

- (void)addStandardObservations
{
    [super addStandardObservations];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hasSeenQOTDFlagChanged:) name:DQApplicationHasSeenQOTDFlagChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(QOTDViewDidMoveToWindow:) name:DQQuestOfTheDayViewDidMoveToWindowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearBadgeOnHomeTab:) name:DQPhoneHomeViewControllerClearBadgeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearBadgeOnDrawTab:) name:DQDrawInboxViewControllerClearBadgeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearBadgeOnActivityTab:) name:DQPhoneActivityViewControllerClearBadgeNotification object:nil];
}

- (void)addPostLaunchCompletionObservations
{
    [super addPostLaunchCompletionObservations];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(channelTabBadges:) name:DQHTTPChannelControllerTabBadgesNotification object:nil];
}

#pragma mark -
#pragma mark Tab Badges

- (void)showBadgeOnHomeTab
{
    self.tabBarController.badgeView.homeBadgeView.hidden = NO;
    self.homeViewController.shouldSendClearBadgeNotification = YES;
}

- (void)hideBadgeOnHomeTab
{
    self.homeViewController.shouldSendClearBadgeNotification = NO;
    self.tabBarController.badgeView.homeBadgeView.hidden = YES;
}

- (void)showBadgeOnDrawTab
{
    self.tabBarController.badgeView.drawBadgeView.hidden = NO;
    [self.drawViewController view]; // ensure view is loaded so inboxViewController exists
    self.drawViewController.inboxViewController.shouldSendClearBadgeNotification = YES;
}

- (void)hideBadgeOnDrawTab
{
    [self.drawViewController view]; // ensure view is loaded so inboxViewController exists
    self.drawViewController.inboxViewController.shouldSendClearBadgeNotification = NO;
    self.tabBarController.badgeView.drawBadgeView.hidden = YES;
}

- (void)showBadgeOnActivityTab
{
    self.tabBarController.badgeView.activityBadgeView.hidden = NO;
}

- (void)hideBadgeOnActivityTab
{
    [self.activityController markAllActivityItemsRead];
    self.tabBarController.badgeView.activityBadgeView.hidden = YES;
}

#pragma mark -
#pragma mark Observing Notifications to support Tab Badges

- (void)channelTabBadges:(NSNotification *)notification
{
    NSString *update = [notification userInfo][DQHTTPChannelControllerTabBadgeUpdateKey];
    if (update)
    {
        if ([update rangeOfString:@"home"].location != NSNotFound)
        {
            [self showBadgeOnHomeTab];
        }
        else if ([update rangeOfString:@"draw"].location != NSNotFound)
        {
            [self showBadgeOnDrawTab];
        }
    }
}

- (void)hasSeenQOTDFlagChanged:(NSNotification *)notification
{
    if ([[notification object] boolValue])
    {
        [self showBadgeOnDrawTab];
    }
    else
    {
        [self hideBadgeOnDrawTab];
    }
}

- (void)QOTDViewDidMoveToWindow:(NSNotification *)notification
{
    self.accountController.hasNewQuestOfTheDay = NO;
    // this will cause hasSeenQOTDFlagChanged: to be called
}

- (void)clearBadgeOnHomeTab:(NSNotification *)notification
{
    [self hideBadgeOnHomeTab];
}

- (void)clearBadgeOnDrawTab:(NSNotification *)notification
{
    [self hideBadgeOnDrawTab];
}

- (void)clearBadgeOnActivityTab:(NSNotification *)notification
{
    [self hideBadgeOnActivityTab];
}

#pragma mark -
#pragma mark Public Modal Navigation Controller Factory API (template methods)

- (DQNavigationController *)newModalNavigationController
{
    return [self newNavigationController];
}

- (DQNavigationController *)newModalNavigationControllerWithRootViewController:(UIViewController *)rootViewController
{
    return [self newNavigationControllerWithRootViewController:rootViewController];
}

#pragma mark -
#pragma mark Phone-specific Navigation Controller creation

- (void)__configureNavigationController:(DQNavigationController *)nc
{
    [nc.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [nc.navigationBar setShadowImage:[[UIImage alloc] init]];
    nc.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [UIFont fontWithName:@"ArialRoundedMTBold" size:22.0f]};
    nc.navigationBar.translucent = NO;
    [nc.navigationBar setTitleVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
}

- (DQNavigationController *)newNavigationController
{
    DQNavigationController *nc = [[DQNavigationController alloc] initWithDelegate:self];
    [self __configureNavigationController:nc];
    return nc;
}

- (DQNavigationController *)newNavigationControllerWithTintColor:(UIColor *)tintColor
{
    DQNavigationController *nc = [[DQNavigationController alloc] initWithDelegate:self];
    [self __configureNavigationController:nc];
    nc.view.tintColor = tintColor;
    nc.navigationBar.barTintColor = nc.navigationBar.tintColor;
    return nc;
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)vc
{
    DQNavigationController *nc = [[DQNavigationController alloc] initWithRootViewController:vc delegate:self];
    [self __configureNavigationController:nc];
    return nc;
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)vc tintColor:(UIColor *)tintColor
{
    DQNavigationController *nc = [self newNavigationControllerWithRootViewController:vc];
    nc.view.tintColor = tintColor;
    nc.navigationBar.barTintColor = nc.navigationBar.tintColor;
    return nc;
}

- (void)configureTabBarItemWithImageNamed:(NSString *)imageName forViewController:(UIViewController *)vc
{
    vc.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, 20);
}

- (void)configureHomeTab
{
    DQController *c = [[DQController alloc] initWithDelegate:self];
    self.homeViewController = [[DQPhoneHomeViewController alloc] initWithDelegate:self];
    self.homeViewController.title = DQLocalizedString(@"Home", @"The user's homepage in the app");

    __weak typeof(self) weakSelf = self;
    self.homeViewController.shouldPresentAddFriendsBlock = ^(DQPhoneHomeViewController *vc) {
        return [weakSelf shouldDisplayInviteReminder];
    };
    self.homeViewController.presentAddFriendsBlock = ^(DQPhoneHomeViewController *vc) {
        [weakSelf presentAddFriendsViewControllerFromViewController:vc];
        [weakSelf doneDisplayingInviteReminder];
    };
    self.homeViewController.navigationItem.leftBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_addPeople" buttonBlock:^(DQButton *button) {
        [weakSelf presentAddFriendsViewControllerFromViewController:weakSelf.homeViewController];
    }];
    self.homeViewController.commentViewedBlock = ^(DQPhoneHomeViewController *homeViewController, NSString *commentID) {
        [weakSelf.commentViewTracker trackViewOfCommentWithServerID:commentID];
    };
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil action:nil];
    fixedSpace.width = kDQFormPhoneNavigationItemSpacing;
    self.homeViewController.navigationItem.rightBarButtonItems = @[[c newPhoneBarButtonItemWithImageNamed:@"button_topNav_shop" buttonBlock:^(DQButton *button) {
        [self showShopWithTab:DQShopViewControllerTabDefault source:@"Home" fromViewController:weakSelf.homeViewController];
    }], fixedSpace, [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_search" buttonBlock:^(DQButton *button) {
        [weakSelf presentUserSearchFromViewController:self.homeViewController];
    }]];
    UIColor *tintColor = [UIColor dq_homeTabColor];
    self.tabBarController.badgeView.homeBadgeView.backgroundColor = tintColor;
    self.homeTabNavigationController = [self newNavigationControllerWithRootViewController:self.homeViewController tintColor:tintColor];
    [self configureTabBarItemWithImageNamed:@"tab_home_large" forViewController:self.homeTabNavigationController];
}

- (void)configureDrawTab
{
    __weak typeof(self) weakSelf = self;
    void (^requestPublishQuestBlock)(UIViewController *) = ^(UIViewController *viewController) {
        [weakSelf requestPublishQuestFromViewController:viewController cancellationBlock:^{
            // <#code#>
        } completionBlock:^{
            // <#code#>
        } failureBlock:^(NSError *error) {
            [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Post Error", @"Upload error alert title") description:error.dq_displayDescription];
        }];
    };

    DQController *c = [[DQController alloc] initWithDelegate:self];
    self.drawViewController = [[DQPhoneDrawViewController alloc] initWithDelegate:self];
    self.drawViewController.showEditorForQuestBlock = ^(UIViewController *vc, DQQuest *quest, NSString *source) {
        [weakSelf showCommentEditorForQuest:quest isFirstQuest:NO source:source fromViewController:vc];
    };
    self.drawViewController.showGalleryForQuestBlock = ^(UIViewController *vc, DQQuest *quest, NSString *source) {
        [weakSelf showGalleryForQuestWithID:quest.serverID commentID:nil source:source publishing:NO fromViewController:vc beforePresenting:nil];
    };
    self.drawViewController.makeInboxViewControllerBlock = ^(DQPhoneDrawViewController *vc) {
        DQPhoneDrawInboxViewController *inboxViewController = [[DQPhoneDrawInboxViewController alloc] initWithDelegate:weakSelf];
        inboxViewController.requestPublishQuestBlock = ^(DQPhoneDrawInboxViewController *vc) {
            requestPublishQuestBlock(vc);
        };
        return inboxViewController;
    };
    self.drawViewController.makeHistoryViewControllerBlock = ^(DQPhoneDrawViewController *vc) {
        return [[DQPhoneDrawHistoryViewController alloc] initWithDelegate:weakSelf];
    };
    self.drawViewController.makeAllViewControllerBlock = ^(DQPhoneDrawViewController *vc) {
        return [[DQPhoneDrawAllViewController alloc] initWithDelegate:weakSelf];
    };
    self.drawViewController.title = DQLocalizedStringWithDefaultValue(@"DrawAreaTitle", nil, nil, @"Draw", @"Title for the area where the user can draw Quests");
    
    self.drawViewController.navigationItem.leftBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_addPeople" buttonBlock:^(DQButton *button) {
        [weakSelf presentAddFriendsViewControllerFromViewController:weakSelf.drawViewController];
    }];
    self.drawViewController.navigationItem.rightBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_add" buttonBlock:^(DQButton *button) {
        requestPublishQuestBlock(weakSelf.drawViewController);
    }];
    UIColor *tintColor = [UIColor dq_drawTabColor];
    self.tabBarController.badgeView.drawBadgeView.backgroundColor = tintColor;
    self.drawTabNavigationController = [self newNavigationControllerWithRootViewController:self.drawViewController tintColor:tintColor];
    [self configureTabBarItemWithImageNamed:@"tab_draw_large" forViewController:self.drawTabNavigationController];
}

- (void)configureActivityTab
{
    __weak typeof(self) weakSelf = self;
    DQController *c = [[DQController alloc] initWithDelegate:self];
    self.activityViewController = [[DQPhoneActivityViewController alloc] initWithDelegate:self];
    self.activityViewController.title = DQLocalizedString(@"Activity", @"Label for the area where all of the user's relevant activity is collected");
    
    self.activityViewController.navigationItem.leftBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_addPeople" buttonBlock:^(DQButton *button) {
        [weakSelf presentAddFriendsViewControllerFromViewController:weakSelf.activityViewController];
    }];
    self.activityViewController.navigationItem.rightBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_shop" buttonBlock:^(DQButton *button) {
        [self showShopWithTab:DQShopViewControllerTabDefault source:@"Activity" fromViewController:weakSelf.activityViewController];
    }];
    self.activityViewController.homeBlock = ^{
        [weakSelf showHomeAndAutomaticModals:YES];
    };
    self.activityViewController.profileBlock = ^(NSString *userName) {
        [weakSelf showProfileForUserWithUserName:userName fromViewController:weakSelf.activityViewController source:@"Activity"];
    };
    self.activityViewController.unknownActivityItemTappedBlock = ^(DQActivityItem *activityItem){
        [weakSelf showAppUpdateAlertWithMessage:DQLocalizedString(@"Your version of DrawQuest is out of date. Please update to see this activity item.", @"App needs to be updated alert title")];
    };
    self.activityViewController.refreshBlock = ^{
        [weakSelf.activityController update];
    };
    self.activityViewController.loadMoreActivitiesBlock = ^{
        [weakSelf.activityController scroll];
    };
    self.activityViewController.shopColorsBlock = ^(DQPhoneActivityViewController *c) {
        [weakSelf showShopWithTab:DQShopViewControllerTabColors source:@"Activity" fromViewController:c];
    };
    self.activityViewController.getUnreadCountBlock = ^NSInteger(DQPhoneActivityViewController *vc) {
        return [weakSelf.activityController numberOfUnreadActivityItems];
    };
    self.activityViewController.reloadActivitiesBlock = ^{
        [weakSelf.activityController load];
    };
    UIColor *tintColor = [UIColor dq_activityTabColor];
    self.tabBarController.badgeView.activityBadgeView.backgroundColor = tintColor;
    self.activityTabNavigationController = [self newNavigationControllerWithRootViewController:self.activityViewController tintColor:tintColor];
    [self configureTabBarItemWithImageNamed:@"tab_activity_large" forViewController:self.activityTabNavigationController];
}

- (BOOL)_activityViewControllerIsVisible
{
    BOOL result = ((self.tabBarController.selectedViewController == self.activityTabNavigationController) &&
                   ([[self.activityTabNavigationController viewControllers] count] == 1));
    return result;
}

- (void)configureProfileTab
{
    __weak typeof(self) weakSelf = self;
    DQController *c = [[DQController alloc] initWithDelegate:self];
    self.profileViewController = [[DQPhoneProfileViewController alloc] initWithUserName:self.accountController.loggedInAccount.username source:@"Tab-Bar" delegate:self];
    self.profileViewController.title = DQLocalizedString(@"Profile", @"Label for the user's own profile");

    self.profileViewController.showShopBlock = ^(DQProfileViewController *vc) {
        [weakSelf showShopWithTab:DQShopViewControllerTabDefault source:@"Profile" fromViewController:vc];
    };
    
    self.profileViewController.navigationItem.leftBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_addPeople" buttonBlock:^(DQButton *button) {
        [weakSelf presentAddFriendsViewControllerFromViewController:weakSelf.profileViewController];
    }];
    [self configureRightBarButtonItemsForProfileViewController:self.profileViewController];
    UIColor *tintColor = [UIColor dq_profileTabColor];
    self.tabBarController.badgeView.profileBadgeView.backgroundColor = tintColor;
    self.profileTabNavigationController = [self newNavigationControllerWithRootViewController:self.profileViewController tintColor:tintColor];
    [self configureTabBarItemWithImageNamed:@"tab_profile_large" forViewController:self.profileTabNavigationController];
}

- (void)configureRightBarButtonItemsForProfileViewController:(DQPhoneProfileViewController *)profileController
{
    __weak typeof(self) weakSelf = self;
    __weak typeof(profileController) weakProfileController = profileController;
    DQController *c = [[DQController alloc] initWithDelegate:self];
    if (profileController == self.profileViewController || [profileController.userName isEqualToString:self.accountController.loggedInAccount.username])
    {
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                    target:nil action:nil];
        fixedSpace.width = kDQFormPhoneNavigationItemSpacing;
        profileController.navigationItem.rightBarButtonItems = @[[c newPhoneBarButtonItemWithImageNamed:@"button_topNav_shop" buttonBlock:^(DQButton *button) {
            [weakSelf showShopWithTab:DQShopViewControllerTabDefault source:@"Profile" fromViewController:weakSelf.profileViewController];
        }], fixedSpace, [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_settings" buttonBlock:^(DQButton *button) {
            [weakSelf requestAuthenticationFromViewController:weakSelf.profileViewController cancellationBlock:nil completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
                [weakSelf showSettingsFromViewController:weakSelf.profileTabNavigationController];
            } failureBlock:^(NSError *error) {
                // FIXME: handle error
            }];
        }]];
    }
    else
    {
        profileController.navigationItem.rightBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_shop" buttonBlock:^(DQButton *button) {
            [weakSelf showShopWithTab:DQShopViewControllerTabDefault source:@"Profile" fromViewController:weakProfileController];
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
            [weakVC dismissViewControllerAnimated:YES completion:nil];
        };
        DQController *c = [[DQController alloc] initWithDelegate:self];
        bvc.navigationItem.leftBarButtonItem = [c newCancelBarButtonItemWithBlock:^(id sender) {
            [weakVC bioEditorCancelTapped:weakBVC];
            [weakVC dismissViewControllerAnimated:YES completion:nil];
        }];
        bvc.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
            [weakVC bioEditorDoneTapped:weakBVC];
            [weakVC dismissViewControllerAnimated:YES completion:nil];
        }];
        UINavigationController *nc = [self newNavigationControllerWithRootViewController:bvc tintColor:vc.view.tintColor];
        [vc presentViewController:nc animated:YES completion:nil];
    };

    UIColor *tintColor = [UIColor dq_profileTabColor];
    UINavigationController *navController = [self newNavigationControllerWithRootViewController:settingsViewController tintColor:tintColor];
    [presentingViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Presentation Helpers

- (void)showViewController:(UIViewController<DQViewController> *)vc fromViewController:(UIViewController *)presentingViewController
{
    if (presentingViewController.navigationController)
    {
        [self pushViewController:vc ontoNavigationController:presentingViewController.navigationController];
    }
    else
    {
        // FIXME: implement - display modally in a navigation controller with a Done button?
        NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
        [presentingViewController presentViewController:vc animated:YES completion:nil];
    }
}

- (void)pushViewController:(UIViewController *)vc ontoNavigationController:(UINavigationController *)navigationController
{
    [self pushViewController:vc ontoNavigationController:navigationController animated:YES];
}

- (void)pushViewController:(UIViewController *)vc ontoNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated
{
    [self pushViewController:vc ontoNavigationController:navigationController animated:animated backButtonDidPopBlock:nil];
}

- (void)pushViewController:(UIViewController *)vc ontoNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated backButtonDidPopBlock:(void (^)(UIViewController *vc))backButtonDidPopBlock
{
    __weak typeof(navigationController) weakNavigationController = navigationController;
    __weak typeof(vc) weakVC = vc;
    DQController *c = [[DQController alloc] initWithDelegate:self];
    UIBarButtonItem *backButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_back" buttonBlock:^(DQButton *button) {
        [weakNavigationController popViewControllerAnimated:YES];
        if (backButtonDidPopBlock)
        {
            backButtonDidPopBlock(weakVC);
        }
    }];
    vc.navigationItem.leftBarButtonItem = backButtonItem;

    [navigationController pushViewController:vc animated:animated];
}

#pragma mark -
#pragma mark Presenting Shop

- (void)showShopWithTab:(DQShopViewControllerTab)inTab source:(NSString *)source fromViewController:(DQViewController *)presentingViewController
{
    __weak typeof(self) weakSelf = self;
    __weak typeof(presentingViewController) weakPresentingViewController = presentingViewController;
    [self authenticatedFromViewController:presentingViewController cancellationBlock:^{
        // TODO: do anything when they cancel?
    } completionBlock:^(DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        DQShopViewController *shop = [weakSelf newShopViewControllerWithTab:inTab source:source];
        DQNavigationController *navController = [self newNavigationControllerWithRootViewController:shop tintColor:presentingViewController.navigationController.view.tintColor];

        DQController *c = [[DQController alloc] initWithDelegate:self];
        shop.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        }];

        [weakPresentingViewController presentViewController:navController animated:YES completion:nil];
    } failureBlock:^(NSError *error) {
        DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Authentication Error", @"Authentication error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
        [alert show];
    }];
}

#pragma mark -
#pragma mark Displaying onboarding

// CHECK
- (BOOL)isDisplayingOnboardingFromViewController:(UIViewController *)vc
{
    return (self.authenticationController || self.publishController ||
            (vc && ([vc isKindOfClass:[DQPhoneFirstTimeViewController class]] || vc.presentedViewController)));
}

#pragma mark -
#pragma mark Presenting an Editor

- (void)presentEditorViewController:(CVSPhoneEditorViewController *)editorViewController fromViewController:(UIViewController *)presentingViewController displayBackButton:(BOOL)shouldDisplayBackButton completionBlock:(void (^)(CVSPhoneEditorViewController *c))completionBlock
{
    __weak typeof(editorViewController) weakEditorViewController = editorViewController;
    __weak typeof(presentingViewController) weakPresentingViewController = presentingViewController;

    DQController *c = [[DQController alloc] initWithDelegate:self];
    UIBarButtonItem *doneButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
        __block DQAlertView *alertView = nil;
        dispatch_block_t readyBlock = ^{
            [alertView dismissWithClickedButtonIndex:0 animated:NO];
            alertView = nil;
            if (completionBlock)
            {
                completionBlock(weakEditorViewController);
            }
        };

        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        NSString *message = nil;
        if (orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            message = DQLocalizedString(@"↺ Please flip your device right-side-up to continue.", @"displayed in overlay to tell user what they must do before they can proceed");
        }
        else if (orientation == UIInterfaceOrientationLandscapeLeft)
        {
            message = DQLocalizedString(@"↺ Please rotate your device to Portrait to continue.", @"displayed in overlay to tell user what they must do before they can proceed");
        }
        else if (orientation == UIInterfaceOrientationLandscapeRight)
        {
            message = DQLocalizedString(@"↻ Please rotate your device to Portrait to continue.", @"displayed in overlay to tell user what they must do before they can proceed");
        }

        if (message)
        {
            weakEditorViewController.didRotateDeviceBlock = ^(CVSPhoneEditorViewController *vc) {
                if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
                {
                    weakEditorViewController.didRotateDeviceBlock = nil;
                    readyBlock();
                }
            };
            alertView = [[DQAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alertView show];
        }
        else
        {
            readyBlock();
        }
    }];

    UIBarButtonItem *shopButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_shop" buttonBlock:^(DQButton *button) {
        [self showShopWithTab:DQShopViewControllerTabDefault source:@"Editor" fromViewController:weakEditorViewController];
    }];

    UIBarButtonItem *trashButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_trash" buttonBlock:^(DQButton *button) {
        [weakEditorViewController trashButtonPressed:button];
    }];

    if (shouldDisplayBackButton)
    {
        editorViewController.navigationItem.leftBarButtonItem = [c newPhoneBarButtonItemWithImageNamed:@"button_topNav_back" buttonBlock:^(DQButton *button) {
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:^{

            }];
        }];
    }

    UIBarButtonItem *spacingItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacingItem.width = kDQFormPhoneNavigationItemSpacing;

    editorViewController.navigationItem.rightBarButtonItems = @[doneButtonItem, spacingItem, shopButtonItem, spacingItem, trashButtonItem];
    editorViewController.trashButton = (UIButton *)trashButtonItem.customView;

    UIColor *tintColor = [UIColor dq_editorTabColor];
    DQNavigationController *navController = [self newNavigationControllerWithRootViewController:editorViewController tintColor:tintColor];
    [navController enableAutorotate:YES];
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    navController.navigationBar.translucent = NO;

    [presentingViewController presentViewController:navController animated:YES completion:^{
        // Setting these here instead of in the loadView method of editorViewController causes the transition
        // to be smoother overall - go figure.
        editorViewController.automaticallyAdjustsScrollViewInsets = NO;
        editorViewController.extendedLayoutIncludesOpaqueBars = YES;
    }];
}

- (void)showCommentEditorForQuest:(DQQuest *)quest isFirstQuest:(BOOL)isFirstQuest source:(NSString *)source fromViewController:(UIViewController *)presentingViewController;
{
    __weak typeof(self) weakSelf = self;
    CVSPhoneEditorViewController *editorViewController = [[CVSPhoneEditorViewController alloc] initCommentEditorWithQuest:quest draftsPath:self.draftsPath imageController:self.imageController source:source delegate:self];
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

    [self presentEditorViewController:editorViewController fromViewController:presentingViewController displayBackButton:YES completionBlock:^(CVSPhoneEditorViewController *c) {
        [weakSelf commentEditorViewControllerDone:c];
    }];
}

- (void)showQuestEditorWithDraftPath:(NSString *)draftPath source:(NSString *)source fromViewController:(UIViewController *)presentingViewController completionBlock:(void (^)(UIImage *templateImage))completionBlock
{
    __weak typeof(self) weakSelf = self;
    __weak typeof(presentingViewController) weakPresentingViewController = presentingViewController;

    CVSPhoneEditorViewController *editorViewController = [[CVSPhoneEditorViewController alloc] initQuestEditorWithDraftPath:draftPath source:source delegate:self];
    editorViewController.placeholderTemplateImage = [UIImage imageNamed:@"quest_with_no_template_image"];

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

    [self presentEditorViewController:editorViewController fromViewController:presentingViewController displayBackButton:NO completionBlock:^(CVSPhoneEditorViewController *c) {
        UIImage *templateImage = [c publish];
        [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        if (completionBlock)
        {
            completionBlock(templateImage);
        }
    }];
}

#pragma mark -
#pragma mark Authentication

- (DQAuthenticationController *)newAuthenticationController
{
    __weak typeof(self) weakSelf = self;
    DQAuthenticationController *result = [[DQAuthenticationController alloc] initWithDelegate:self authServiceController:[[DQAuthServiceController alloc] initWithDelegate:self]];
    result.makeModalNavigationControllerBlock = ^(DQAuthenticationController *c) {
        return [weakSelf newNavigationControllerWithTintColor:[UIColor dq_authenticationColor]];
    };
    result.titleForSignInRightBarButtonItem = ^(DQAuthenticationController *c, BOOL publishing) {
        return DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account");
    };
    result.titleForSignUpRightBarButtonItem = ^(DQAuthenticationController *c, BOOL publishing) {
        return DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
    };
    result.makeAlmostThereViewControllerBlock = ^(DQAuthenticationController *c, BOOL publishing) {
        DQAlmostThereViewController *result = [[DQAlmostThereViewController alloc] initWithDelegate:weakSelf];
        result.submitButtonTitle = DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
        return result;
    };
    result.makeSignInViewControllerBlock = ^(DQAuthenticationController *c, BOOL publishing) {
        DQSignInViewController *result = [[DQSignInViewController alloc] initWithDelegate:weakSelf];
        result.submitButtonTitle = DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account");
        return result;
    };
    result.makeSignUpViewControllerBlock = ^(DQAuthenticationController *c, BOOL publishing) {
        DQSignUpViewController *result = [[DQSignUpViewController alloc] initWithDelegate:weakSelf showSocialLoginButtons:!c.publishing];
        result.submitButtonTitle = DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
        return result;
    };
    /*
    result.makeAddFriendsViewControllerBlock = ^(DQAuthenticationController *c, DQAuthenticationSignupService signupService) {
        DQAddFriendsViewController *vc = nil;
        if ([self featureInviteFromFacebook] || [self featureInviteFromTwitter])
        {
            vc = [weakSelf newAddFriendsViewControllerForSignupService:signupService];
        }
        return vc;
    };
     */
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

#pragma mark -
#pragma mark Publishing

- (DQCommentPublishController *)newCommentPublishController
{
    DQCommentPublishController *result = [super newCommentPublishController];
    __weak typeof(self) weakSelf = self;
    result.showHomeBlock = ^(DQCommentPublishController *c, CVSEditorViewController *editorViewController) {
        [weakSelf presentRewardsWindowForQuestID:editorViewController.quest.serverID withShareFlags:c.shareFlags animationCompletionBlock:^{
            // Dismiss the tour if it's up
            [weakSelf.tabBarController dismissViewControllerAnimated:NO completion:nil];

            [editorViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            weakSelf.tabBarController.selectedViewController = weakSelf.homeTabNavigationController;
        }];
    };
    result.showGalleryBlock = ^(DQCommentPublishController *c, CVSEditorViewController *editorViewController, void (^beforePresentingBlock)(DQGalleryViewController *)) {
        [weakSelf presentRewardsWindowForQuestID:editorViewController.quest.serverID withShareFlags:c.shareFlags animationCompletionBlock:^{
            // Dismiss the tour if it's up
            [weakSelf.tabBarController dismissViewControllerAnimated:NO completion:nil];

            [editorViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            UINavigationController *selectedNavController = (UINavigationController *)weakSelf.tabBarController.selectedViewController;
            UIViewController *presentingViewController = selectedNavController.topViewController;
            if ([presentingViewController isKindOfClass:[DQPhoneGalleryViewController class]])
            {
                // If we're coming from the gallery, dismiss it so it doesn't stack up on itself
                [selectedNavController popViewControllerAnimated:NO];
                presentingViewController = selectedNavController.topViewController;
            }
            [weakSelf showGalleryForQuestWithID:editorViewController.quest.serverID commentID:nil source:@"Posting" publishing:YES fromViewController:presentingViewController beforePresenting:beforePresentingBlock];
        }];
    };
    result.makePublishViewControllerBlock = ^(DQCommentPublishController *c) {
        DQPhoneCommentPublishViewController *pvc = [[DQPhoneCommentPublishViewController alloc] initWithPublishDataSource:c publishDelegate:c delegate:weakSelf rewardsDictionary:weakSelf.rewardsDictionary facebookController:weakSelf.facebookController twitterController:weakSelf.twitterController];
        pvc.previewImage = [c.editorViewController.editorView imageRepresentation];
        pvc.questTitle = c.editorViewController.quest.title;
        return (DQCommentPublishViewController *)pvc;
    };
    result.makeModalNavigationControllerBlock = ^(DQCommentPublishController *c) {
        return [weakSelf newNavigationControllerWithTintColor:[UIColor dq_editorTabColor]];
    };
    return result;
}

- (DQQuestPublishController *)newQuestPublishController
{
    DQQuestPublishController *result = [super newQuestPublishController];
    __weak typeof(self) weakSelf = self;
    __weak typeof(result) weakResult = result;
    result.pushSimilarQuestsViewControllerBlock = ^(DQQuestPublishController *c, void (^willPresentBlock)(DQSimilarQuestsViewController *vc), void (^didPopBlock)(DQSimilarQuestsViewController *vc)) {
        DQSimilarQuestsViewController *vc = [[DQSimilarQuestsViewController alloc] initWithDelegate:weakSelf];
        vc.hidesBottomBarWhenPushed = YES;
        if (willPresentBlock)
        {
            willPresentBlock(vc);
        }
        [weakSelf pushViewController:vc ontoNavigationController:c.presentingViewController.navigationController animated:YES backButtonDidPopBlock:^(UIViewController *vc) {
            if (didPopBlock)
            {
                didPopBlock((DQSimilarQuestsViewController *)vc);
            }
        }];
    };
    result.pushShareQuestViewControllerBlock = ^(DQQuestPublishController *c, void (^willPresentBlock)(DQQuestPublishViewController *vc), void (^didPopBlock)(DQQuestPublishViewController *vc)) {
        DQQuestPublishViewController *vc = [[DQQuestPublishViewController alloc] initWithPublishDelegate:weakResult delegate:self];
        vc.hidesBottomBarWhenPushed = YES;
        vc.drawTemplateBlock = ^(DQQuestPublishViewController *vc) {
            [weakSelf showQuestEditorWithDraftPath:[weakResult.questUpload pathToDraftFiles] source:@"Quest-Publish" fromViewController:vc completionBlock:^(UIImage *templateImage) {
                [weakResult takeTemplateImage:templateImage];
            }];
        };
        if (willPresentBlock)
        {
            willPresentBlock(vc);
        }
        [weakSelf pushViewController:vc ontoNavigationController:c.presentingViewController.navigationController animated:YES backButtonDidPopBlock:^(UIViewController *vc) {
            if (didPopBlock)
            {
                didPopBlock((DQQuestPublishViewController *)vc);
            }
        }];
    };
    result.showGalleryBlock = ^(DQQuestPublishController *c, void (^beforePresentingBlock)(DQGalleryViewController *)) {
        [weakSelf.drawTabNavigationController popToRootViewControllerAnimated:NO];
        [weakSelf showGalleryForQuestWithID:c.quest.serverID commentID:nil source:@"Quest-Publish" publishing:YES fromViewController:weakSelf.drawViewController beforePresenting:beforePresentingBlock];
        weakSelf.tabBarController.selectedViewController = self.drawTabNavigationController;
    };
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
        [self.publishController presentInModalNavigationController:[self newNavigationControllerWithTintColor:[UIColor dq_editorTabColor]] forEditorViewController:editorViewController cancellationBlock:^{
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

#pragma mark -
#pragma mark Rewards Screen

- (void)presentRewardsWindowForQuestID:(NSString *)questID withShareFlags:(NSArray *)shareFlags animationCompletionBlock:(dispatch_block_t)completionBlock
{
    DQPublishRewardsViewController *rewardsViewController = [[DQPublishRewardsViewController alloc] initWithDelegate:self];
    rewardsViewController.questID = questID;
    rewardsViewController.shareFlags = shareFlags;
    rewardsViewController.rewardsDictionary = self.rewardsDictionary;
    __weak typeof(self) weakSelf = self;
    rewardsViewController.dismissBlock = ^(DQPublishRewardsViewController *vc) {
        [weakSelf dismissRewardsWindowWithCompletion:nil];
    };

    CGRect windowFrame = [[UIScreen mainScreen] bounds];

    UIWindow *window = [[UIWindow alloc] initWithFrame:windowFrame];
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.rootViewController = rewardsViewController;
    window.hidden = NO;
    [window makeKeyAndVisible];

    rewardsViewController.view.alpha = 0;
    rewardsViewController.view.backgroundColor = [UIColor colorWithPatternImage:[[UIImage screenshot] applyDarkEffect]];
    [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        rewardsViewController.view.alpha = 1;
    } completion:^(BOOL finished) {
        [rewardsViewController ready];
        if (completionBlock)
        {
            completionBlock();
        }
    }];

    self.publishRewardsWindow = window;
}

- (void)dismissRewardsWindowWithCompletion:(dispatch_block_t)completionBlock
{
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        UIWindow *window = self.publishRewardsWindow;
        window.rootViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.publishRewardsWindow resignKeyWindow];
        self.publishRewardsWindow = nil;
        [self.tabBarController setNeedsStatusBarAppearanceUpdate];
        if (completionBlock)
        {
            completionBlock();
        }
    }];
}

#pragma mark -
#pragma mark Zoomable Image View

- (void)showZoomableImageForComment:(DQComment *)comment fromView:(UIView *)view viewController:(UIViewController<DQViewController> *)viewController
{
    DQDrawingZoomViewController *zoomViewController = [[DQDrawingZoomViewController alloc] initWithDelegate:self];
    zoomViewController.comment = comment;
    zoomViewController.sourceView = view;

    __weak typeof(self) weakSelf = self;
    zoomViewController.closeWindowBlock = ^(DQDrawingZoomViewController *vc) {
        vc = nil;
        [weakSelf.zoomableImageWindow resignKeyWindow];
        weakSelf.zoomableImageWindow = nil;
    };

    CGRect windowFrame = [[UIScreen mainScreen] bounds];
    UIWindow *window = [[UIWindow alloc] initWithFrame:windowFrame];
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.rootViewController = zoomViewController;
    window.hidden = NO;
    [window makeKeyAndVisible];

    // Retain the window
    self.zoomableImageWindow = window;
}

#pragma mark -
#pragma mark Present Add Friends

- (void)presentAddFriendsViewControllerFromViewController:(UIViewController *)presentingViewController
{
    [self requestAuthenticationFromViewController:presentingViewController cancellationBlock:nil completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        [self presentAddFriendsViewControllerFromViewController:presentingViewController withQuestID:nil];
    } failureBlock:^(NSError *error) {
        // FIXME: handle error
    }];
}

- (void)presentAddFriendsViewControllerFromViewController:(UIViewController *)presentingViewController withQuestID:(NSString *)questID
{
    DQPhoneAddFriendsViewController *vc = [[DQPhoneAddFriendsViewController alloc] initWithDelegate:self facebookController:self.facebookController twitterController:self.twitterController featureInviteFromFacebook:[self featureInviteFromFacebook] featureInviteFromTwitter:[self featureInviteFromTwitter] questID:questID];

    vc.title = DQLocalizedString(@"Add Friends", @"Title for modal where the user can invite their friends to DrawQuest");
    DQController *c = [[DQController alloc] initWithDelegate:self];
    DQNavigationController *navController = [self newNavigationControllerWithRootViewController:vc tintColor:presentingViewController.navigationController.view.tintColor];
    __weak typeof(vc) weakVC = vc;
    __weak typeof(self) weakSelf = self;
    __weak typeof(presentingViewController) weakPresentingViewController = presentingViewController;
    vc.navigationItem.leftBarButtonItem = [c newCancelBarButtonItemWithBlock:^(id sender) {
        if ([weakVC numberOfInvitesSentOrPending])
        {
            // TODO: ask the user if they're sure, waiting for spec
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    vc.navigationItem.rightBarButtonItem = [c newDoneBarButtonItemWithBlock:^(id sender) {
        [weakVC submitWithCompletionBlock:^{
            [weakPresentingViewController dismissViewControllerAnimated:YES completion:nil];
        } failureBlock:^(NSError *error) {
            [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Error Inviting Friends", @"Invite error alert title") description:error.dq_displayDescription];
        }];
    }];
    vc.presentActionSheetBlock = ^(UIActionSheet *sheet) {
        [sheet showInView:weakVC.view];
    };
    [presentingViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Present User Search

- (void)presentUserSearchFromViewController:(UIViewController *)presentingViewController
{
    DQUserSearchViewController *vc = [[DQUserSearchViewController alloc] initWithDelegate:self];
    vc.title = nil;
    vc.showProfileBlock = ^(DQUserSearchViewController *vc, NSString *username) {
        [self showProfileForUserWithUserName:username fromViewController:vc source:@"User-Search"];
    };
    [self pushViewController:vc ontoNavigationController:presentingViewController.navigationController];
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
        if ([self _activityViewControllerIsVisible])
        {
            [self.activityController markAllActivityItemsRead];
        }
        else if ([self.activityController numberOfUnreadActivityItems])
        {
            [self showBadgeOnActivityTab];
        }
        [self.activityViewController replaceActivities:activities];
    });
}

- (void)activityController:(DQActivityController *)c didUpdateActivities:(NSArray *)activities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self _activityViewControllerIsVisible])
        {
            self.activityViewController.unreadCount += [self.activityController numberOfUnreadActivityItems];
            [self.activityController markAllActivityItemsRead];
        }
        else if ([self.activityController numberOfUnreadActivityItems])
        {
            [self showBadgeOnActivityTab];
        }
        [self.activityViewController prependActivities:activities];
    });
}

- (void)activityController:(DQActivityController *)c didScrollActivities:(NSArray *)activities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityViewController appendActivities:activities];
    });
}

- (void)activityController:(DQActivityController *)c loadFailedWithError:(NSError *)error
{
    [self.activityViewController loadActivitiesFailed];
}

- (void)activityController:(DQActivityController *)c updateFailedWithError:(NSError *)error
{
    // do nothing for now, the menuViewController had no idea this was happening anyway
}

- (void)activityController:(DQActivityController *)c scrollFailedWithError:(NSError *)error
{
    [self.activityViewController loadMoreActivitiesFailed];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate methods

- (BOOL)tabBarController:(DQTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    self.shouldAutomaticallyPopToRoot = ((viewController == tabBarController.selectedViewController) &&
                                         [viewController isKindOfClass:[UINavigationController class]]);
    return YES;
}

- (void)tabBarController:(DQTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if (self.shouldAutomaticallyPopToRoot)
    {
        self.shouldAutomaticallyPopToRoot = NO;
        if (viewController == tabBarController.selectedViewController)
        {
            if ([viewController isKindOfClass:[UINavigationController class]])
            {
                UINavigationController *nc = (UINavigationController *)viewController;
                [nc popToRootViewControllerAnimated:YES];
            }
        }
    }
}

#pragma mark -
#pragma mark Presenting Drawing Detail

- (void)showDrawingDetailForComment:(DQComment *)inComment inQuest:(DQQuest *)inQuest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.commentViewTracker trackViewOfCommentWithServerID:inComment.serverID];

    void (^readyBlock)(DQQuest *, DQComment *) = ^(DQQuest *quest, DQComment *comment) {
        DQPlaybackDataManager *pdm = [[DQPlaybackDataManager alloc] initWithImageController:self.imageController delegate:self];
        DQDrawingDetailViewController *drawingDetailVC = [[DQDrawingDetailViewController alloc] initWithComment:comment inQuest:quest newPlaybackDataManager:pdm source:source delegate:self];

        __weak typeof(self) weakSelf = self;
        drawingDetailVC.makeSharingControllerBlock = ^(DQDrawingDetailViewController *vc) {
            return [weakSelf newSharingController];
        };

        DQQuestTitleView *titleView = [[DQQuestTitleView alloc] initWithFrame:CGRectZero];
        titleView.titleLabel.textColor = [presentingViewController.navigationController.navigationBar.titleTextAttributes objectForKey:NSForegroundColorAttributeName];
        titleView.text = quest.title;
        drawingDetailVC.navigationItem.titleView = titleView;

        DQButton *drawQuestButton = [DQButton buttonWithImage:[UIImage imageNamed:@"button_draw_pencil"]];
        __weak typeof(drawingDetailVC) weakVC = drawingDetailVC;
        drawQuestButton.tappedBlock = ^(DQButton *button) {
            [weakSelf showCommentEditorForQuest:quest isFirstQuest:NO source:(source ? [source stringByAppendingString:@"/Drawing-Detail"] : @"Drawing-Detail") fromViewController:weakVC];
        };
        drawingDetailVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:drawQuestButton];

        drawingDetailVC.dismissBlock = ^{
            [weakVC.navigationController popViewControllerAnimated:YES];
        };
        [self pushViewController:drawingDetailVC ontoNavigationController:presentingViewController.navigationController];
    };

    if (!inQuest.content)
    {
        [self requestCommentWithServerID:inComment.serverID resultBlock:^(DQQuest *quest, DQComment *comment) {
            readyBlock(quest, comment);
        } failureBlock:failureBlock];
    }
    else
    {
        readyBlock(inQuest, inComment);
    }
}

#pragma mark -
#pragma mark - DQViewControllerDelegate Methods

- (void)showDrawingDetailForCommentWithServerID:(NSString *)commentID fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestCachedCommentWithServerID:commentID resultBlock:^(DQQuest *quest, DQComment *comment) {
        [self showDrawingDetailForComment:comment inQuest:quest fromViewController:viewController source:source completionBlock:completionBlock failureBlock:failureBlock];
    } failureBlock:failureBlock];
}

- (void)showDrawingDetailForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self requestCachedQuestForComment:comment resultBlock:^(DQQuest *quest, DQComment *comment) {
        [self showDrawingDetailForComment:comment inQuest:quest fromViewController:viewController source:source completionBlock:completionBlock failureBlock:failureBlock];
    } failureBlock:failureBlock];
}

- (void)tappedShareButtonForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    DQSharingController *sharingController = [self newSharingController];
    [sharingController showSharingSheetForComment:comment fromViewController:viewController source:source];
}

- (void)tappedShareButtonForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    DQSharingController *sharingController = [self newSharingController];
    [sharingController showSharingSheetForQuest:quest fromViewController:viewController source:source];
}

- (void)tappedMoreOptionsButtonForComment:(DQComment *)comment fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"comment_id": comment.serverID ?: @"unknown"};

    BOOL userIsAuthor = [[self.accountController loggedInAccount].username isEqualToString:comment.authorName];
    NSString *destructiveButtonTitle = userIsAuthor ? DQLocalizedString(@"Delete this Drawing", @"Label for option to delete a drawing from DrawQuest") : DQLocalizedString(@"Report this Drawing", @"Label for option to flag an innappropriate drawing for staff review");

    DQActionSheet *sheet = [[DQActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", DQLocalizedString(@"Quest", @"The name for our daily Quests the users can draw"), comment.questTitle] delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:DQLocalizedString(@"View this Quest", @"Label for option to view the Quest this drawing was drawn for"), nil];
    sheet.dq_completionBlock = ^(DQActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == sheet.destructiveButtonIndex)
        {
            if (userIsAuthor)
            {
                // Delete
                DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Delete Drawing", @"Delete a drawing alert title") message:DQLocalizedString(@"Are you sure you want to permanently delete your drawing?", @"Delete a drawing alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Delete", @"Destroy item alert confirmation button title"), nil];
                alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
                    if (buttonIndex != [alert cancelButtonIndex])
                    {
                        [weakSelf.analyticsController logEvent:DQAnalyticsEventDelete withParameters:eventLoggingParameters];
                        [weakSelf.dataStoreController deleteCommentWithServerID:comment.serverID];
                        [weakSelf.privateServiceController requestDeleteCommentWithServerID:comment.serverID];
                    }
                };
                [alertView show];
            }
            else
            {
                // Flagging
                DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Flag Drawing", @"Flag an inappropriate drawing for staff review title") message:DQLocalizedString(@"Are you sure you want to flag this drawing as inappropriate?", @"Flag an inappropriate drawing for staff review message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Flag", @"Flag an inappropriate drawing or Quest for staff review alert confirmation button title"), nil];
                alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
                    if (buttonIndex != [alert cancelButtonIndex])
                    {
                        [weakSelf.analyticsController logEvent:DQAnalyticsEventFlag withParameters:eventLoggingParameters];
                        [weakSelf.dataStoreController flagCommentWithServerID:comment.serverID];
                        [weakSelf.privateServiceController requestFlagForCommentWithServerID:comment.serverID];
                    }
                };
                [alertView show];
            }
        }
        else
        {
            NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
            if ([title isEqualToString:DQLocalizedString(@"View this Quest", @"Label for option to view the Quest this drawing was drawn for")])
            {
                [self requestCachedQuestForComment:comment resultBlock:^(DQQuest *quest, DQComment *comment) {
                    [weakSelf showGalleryForQuest:quest fromViewController:viewController source:source];
                } failureBlock:^(NSError *error) {
                    [self showGlobalAlertWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") description:error.dq_displayDescription];
                }];
            }
        }
    };
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)tappedMoreOptionsButtonForQuest:(DQQuest *)quest fromViewController:(UIViewController<DQViewController> *)viewController source:(NSString *)source
{
    __weak typeof(self) weakSelf = self;
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"quest_id": quest.serverID ?: @"unknown"};


    NSString *destructiveButtonTitle = ([quest.authorUsername isEqualToString:@"Questbot"]) ? nil : DQLocalizedString(@"Report this Quest", @"Label for option to flag an inappropriate Quest for staff review");
    DQActionSheet *sheet = [[DQActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", DQLocalizedString(@"Quest", @"The name for our daily Quests the users can draw"), quest.title] delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:DQLocalizedString(@"Draw this Quest", @"Label for option to draw a particular Quest"), nil];
    sheet.dq_completionBlock = ^(DQActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == sheet.destructiveButtonIndex)
        {
            // Flagging
            DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Flag Quest", @"Flag an inappropriate Quest for staff review alert title") message:DQLocalizedString(@"Are you sure you want to flag this Quest as inappropriate?", @"Flag an inappropriate Quest for staff review alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Flag", @"Flag an inappropriate drawing or Quest for staff review alert confirmation button title"), nil];
            alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
                if (buttonIndex != [alert cancelButtonIndex])
                {
                    [weakSelf.analyticsController logEvent:DQAnalyticsEventFlag withParameters:eventLoggingParameters];
                    [weakSelf.dataStoreController flagQuestWithServerID:quest.serverID];
                    [weakSelf.privateServiceController requestFlagForQuestWithServerID:quest.serverID];
                }
            };
            [alertView show];
        }
        else
        {
            NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
            if ([title isEqualToString:DQLocalizedString(@"Draw this Quest", @"Label for option to draw a particular Quest")])
            {
                [weakSelf showCommentEditorForQuest:quest isFirstQuest:NO source:source fromViewController:viewController];
            }
        }
    };
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (DQNavigationController *)newNavigationControllerForViewController:(UIViewController<DQViewController> *)vc
{
    return [self newNavigationController];
}

- (DQNavigationController *)newNavigationControllerWithRootViewController:(UIViewController *)rootViewController forViewController:(UIViewController<DQViewController> *)vc
{
    return [self newNavigationControllerWithRootViewController:rootViewController];
}

#pragma mark -
#pragma mark DQAuthServiceControllerDelegate methods

- (void)authServiceController:(DQAuthServiceController *)authServiceController handleSuccessfulAuthForRequest:(DQHTTPRequest *)inRequest withResponseDictionary:(NSDictionary *)inDictionary completionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    [super authServiceController:authServiceController handleSuccessfulAuthForRequest:inRequest withResponseDictionary:inDictionary completionBlock:inCompletionBlock];
    // FIXME: We're gonna make the profile tab deal with auth itself
    //[self configureProfileTab];
    NSArray *vcs = self.profileTabNavigationController.viewControllers;
    NSMutableArray *newVcs = [[NSMutableArray alloc] initWithArray:vcs];
    newVcs[0] = self.profileViewController;
    [self.profileTabNavigationController setViewControllers:newVcs animated:YES];
}

@end



#pragma mark -
#pragma mark Template Method Implementations

@implementation DQPhoneApplicationController (TemplateMethods)

// CHECK
+ (void)configureUIAppearance
{
}

// CHECK
- (void)configureMainWindow
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    self.tabBarController = [[DQTabBarController alloc] initWithNibName:nil bundle:nil];
    self.tabBarController.tabBar.backgroundImage = [[UIImage alloc] init];
    self.tabBarController.tabBar.shadowImage = [[UIImage alloc] init];
    self.tabBarController.tabBar.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.tabBarController.tabBar.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.tabBarController.tabBar.layer.shadowOpacity = 0.1f;
    self.tabBarController.tabBar.layer.shadowRadius = 0.0f;
    self.tabBarController.tabBar.translucent = NO;
    self.tabBarController.delegate = self;
    self.tabBarController.tabBar.barTintColor = [UIColor whiteColor];
    self.tabBarController.tabBar.hidden = YES;
    self.followController.tabBarController = self.tabBarController;
    self.starController.tabBarController = self.tabBarController;

    [self configureHomeTab];
    [self configureDrawTab];
    [self configureActivityTab];
    [self configureProfileTab];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.tabBarController;
    NSString *imageName = nil;
    if ([[UIScreen mainScreen] bounds].size.height > 480.0)
    {
        imageName = @"Default-568h";
    }
    else
    {
        imageName = @"loading_iphone4";
    }
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *scaledImage = [UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp];
    self.window.backgroundColor = [UIColor colorWithPatternImage:scaledImage];
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

        [self displayMainTabs];

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
        DQPhoneFirstTimeViewController *firstTimeViewController = [[DQPhoneFirstTimeViewController alloc] initWithNibName:nil bundle:nil];
        __weak typeof(self) weakSelf = self;
        firstTimeViewController.showAuthBlock = ^(DQPhoneFirstTimeViewController *c) {
            [weakSelf requestSignInFromViewController:c cancellationBlock:^{
                // TODO: do anything if they cancel?
            } completionBlock:^(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
                [weakSelf displayMainTabs];
                if (signupService != DQAuthenticationSignupServiceNone)
                {
                    // Go to the Explore tab after publish because they just signed up and have no followers yet
                    weakSelf.homeViewController.oneUseDefaultSegmentIndex = 1;
                }
                [weakSelf showHomeAndAutomaticModals:(signupService == DQAuthenticationSignupServiceNone)]; // only if the user just logged in, not for signups.
                [weakSelf.tabBarController dismissViewControllerAnimated:YES completion:nil];
            } failureBlock:^(NSError *error) {
                [weakSelf showGlobalAlertWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") description:error.dq_displayDescription];
            }];
        };
        firstTimeViewController.showFirstQuestBlock = ^(DQPhoneFirstTimeViewController *vc) {
            NSString *preloadedQuestID = weakSelf.dataStoreController.preloadedQuestID;
            if (preloadedQuestID)
            {
                DQQuest *preloadedQuest = [weakSelf.dataStoreController questForServerID:preloadedQuestID];
                if (preloadedQuest)
                {
                    [weakSelf displayMainTabs];
                    // Go to the Explore tab after publish because they have no followers yet
                    weakSelf.homeViewController.oneUseDefaultSegmentIndex = 1;
                    [weakSelf showCommentEditorForQuest:preloadedQuest isFirstQuest:YES source:@"Onboarding" fromViewController:vc];
                }
            }
        };
        firstTimeViewController.showHomeBlock = ^(DQPhoneFirstTimeViewController *vc) {
            [weakSelf displayMainTabs];
            [weakSelf showHomeAndAutomaticModals:NO]; // we want the user to see the onboarding quest
            [weakSelf.tabBarController dismissViewControllerAnimated:YES completion:nil];
        };
        firstTimeViewController.enablePushBlock = ^(DQPhoneFirstTimeViewController *vc) {
            if (self.featureUARegistration && self.featureUARegistrationBeforeAuth)
            {
                //[[UAPush shared] setPushEnabled:YES];
            }
        };
        [self.tabBarController presentViewController:firstTimeViewController animated:NO completion:nil];
    }
}

- (void)accountChangedWithNotification:(NSNotification *)notification
{
    if ( ! self.accountController.loggedInAccount)
    {
        [self configureHomeTab];
        [self configureDrawTab];
        [self configureActivityTab];
        [self configureProfileTab];

        [self displayMainTabs];

        // Keep them on the profile tab
        self.tabBarController.selectedViewController = self.profileTabNavigationController;
        [self hideBadgeOnHomeTab];
        [self hideBadgeOnDrawTab];
        [self hideBadgeOnActivityTab];
    }
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
            }
            return YES;
        }
        // drawquest://about or drawquest://about/
        else if ([host isEqualToString:@"about"] && [pathComponents count] < 2)
        {
            if ( ! isChecking)
            {
                [self showAboutFromViewController:activeViewController]; // use activeViewController because we CAN show about on top of the editor
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
                    [self showSettingsFromViewController:presentingViewController];
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
                NSString *commentID = pathComponents[3];
                [self requestCachedCommentWithServerID:commentID resultBlock:^(DQQuest *quest, DQComment *comment) {
                    [self showDrawingDetailForComment:comment inQuest:quest fromViewController:presentingViewController source:@"URL-Drawing" completionBlock:nil failureBlock:^(NSError *error) {
                        // FIXME: handle failure
                    }];
                } failureBlock:^(NSError *error) {
                    // FIXME: handle failure
                }];
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
    UIViewController *result = nil;
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
        else
        {
            NSLog(@"WARNING: tabBarController.selectedViewController is not a navigation controller");
        }
    }
    else
    {
        NSLog(@"ERROR: activeViewController has no tabBarController");
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
        (vc && ([vc isKindOfClass:[DQPhoneFirstTimeViewController class]] ||
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
    [self displayMainTabs];
    NSString *serverID = [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationDrawingCrashProtectionQuestServerIDKey];
    DQQuest *interruptedQuest = [self.dataStoreController questForServerID:serverID];
    DQHomeViewController *home = [self showHomeAndAutomaticModals:NO];
    [self showCommentEditorForQuest:interruptedQuest isFirstQuest:NO source:@"Interrupted-Quest" fromViewController:home];
}

#pragma mark -
#pragma mark Presenting the Home Page

- (DQHomeViewController *)showHomeAndAutomaticModals: (BOOL)showAutomaticModals
{
    self.tabBarController.selectedViewController = self.homeTabNavigationController;
    return self.homeViewController;
}

#pragma mark -
#pragma mark Presenting the Explore Page

- (void)showExploreForCommentWithID:(NSString *)commentID
{
    // FIXME: implement
    NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
}

#pragma mark -
#pragma mark Presenting a Profile

- (DQProfileViewController *)showProfileForUserWithUserName:(NSString *)userName fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    userName = userName ?: self.accountController.loggedInAccount.username;
    DQPhoneProfileViewController *profileController = [[DQPhoneProfileViewController alloc] initWithUserName:userName source:source delegate:self];

    [self configureRightBarButtonItemsForProfileViewController:profileController];

    if (presentingViewController.navigationController)
    {
        __weak typeof(profileController) weakProfileController = profileController;
        profileController.dismissBlock = ^{
            [weakProfileController.navigationController popViewControllerAnimated:YES];
        };
    } // FIXME: if we're ever going to present it from not-a-navigation-controller add a dismiss block that just dismisses
    [self showViewController:profileController fromViewController:presentingViewController];
    return profileController;
}

#pragma mark -
#pragma mark Presenting a Gallery

- (void)showCommentWithID:(NSString *)commentID questID:(NSString *)questID source:(NSString *)source publishing:(BOOL)isPublishing fromViewController:(UIViewController *)presentingViewController
{
    [self requestCachedCommentWithServerID:commentID resultBlock:^(DQQuest *quest, DQComment *comment) {
        [self showDrawingDetailForComment:comment inQuest:quest fromViewController:presentingViewController source:source completionBlock:nil failureBlock:^(NSError *error) {
            // FIXME: handle error
        }];
    } failureBlock:^(NSError *error) {
        // FIXME: display error
    }];
}

- (void)showGalleryForQuestWithID:(NSString *)questID commentID:(NSString *)commentID source:(NSString *)source publishing:(BOOL)isPublishing fromViewController:(UIViewController *)presentingViewController beforePresenting:(void (^)(DQGalleryViewController *galleryViewController))beforePresentingBlock
{
    __weak typeof(self) weakSelf = self;
    DQPlaybackDataManager *pdm = [[DQPlaybackDataManager alloc] initWithImageController:self.imageController delegate:self];
    DQPhoneGalleryViewController *galleryViewController = [[DQPhoneGalleryViewController alloc] initWithQuestID:questID focusedCommentID:commentID source:source publishing:isPublishing newPlaybackDataManager:pdm delegate:self];

    DQQuestTitleView *titleView = [[DQQuestTitleView alloc] initWithFrame:CGRectZero];
    titleView.titleLabel.textColor = [presentingViewController.navigationController.navigationBar.titleTextAttributes objectForKey:NSForegroundColorAttributeName];
    galleryViewController.navigationItem.titleView = titleView;

    DQButton *drawQuestButton = [DQButton buttonWithImage:[UIImage imageNamed:@"button_draw_pencil"]];
    __weak typeof(galleryViewController) weakGalleryViewController = galleryViewController;
    drawQuestButton.tappedBlock = ^(DQButton *button) {
        [self requestCachedQuestWithServerID:questID resultBlock:^(DQQuest *quest) {
            [weakSelf showCommentEditorForQuest:quest isFirstQuest:NO source:(source ? [source stringByAppendingString:@"/Gallery"] : @"Gallery") fromViewController:weakGalleryViewController];
        } failureBlock:^(NSError *error) {
            [self showGlobalAlertWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") description:error.dq_displayDescription];
        }];
    };
    galleryViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:drawQuestButton];

    galleryViewController.showEditorBlock = ^(DQGalleryViewController *galleryViewController, DQQuest *quest) {
        [weakSelf showCommentEditorForQuest:quest isFirstQuest:NO source:(source ? [source stringByAppendingString:@"/Gallery"] : @"Gallery") fromViewController:galleryViewController];
    };
    galleryViewController.inviteToQuestBlock = ^(DQGalleryViewController *galleryViewController, DQQuest *quest) {
        [weakSelf presentAddFriendsViewControllerFromViewController:galleryViewController withQuestID:quest.serverID];
    };
    galleryViewController.dismissBlock = ^{
        [weakGalleryViewController.navigationController popViewControllerAnimated:YES];
    };
    galleryViewController.commentViewedBlock = ^(DQGalleryViewController *c, NSString *commentID) {
        [weakSelf.commentViewTracker trackViewOfCommentWithServerID:commentID];
    };
    if (beforePresentingBlock)
    {
        beforePresentingBlock(galleryViewController);
    }
    [self pushViewController:galleryViewController ontoNavigationController:presentingViewController.navigationController animated:!isPublishing];
}

#pragma mark -
#pragma mark Presenting Shop

- (void)showNewColorsAlert
{
    if (self.accountController.loggedIn)
    {
        // FIXME: implement
        NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
    }
}

// CHECK
- (DQActivityController *)newActivityController
{
    return [[DQActivityController alloc] initWithDelegate:self];
}

#pragma mark - Show QotD

- (void)showQuestOfTheDay
{
    [self.tabBarController setSelectedViewController:self.drawTabNavigationController];
    [self.drawViewController showQuestOfTheDay];
}

@end

@implementation DQTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _badgeView = [[DQTabBarBadgeView alloc] initWithFrame:CGRectZero];
        _badgeView.userInteractionEnabled = NO;
    }
    return self;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.tabBar && ((!self.badgeView.superview) || (self.badgeView.superview != self.tabBar)))
    {
        [self.badgeView removeFromSuperview];
        [self.tabBar addSubview:self.badgeView];
        [self.tabBar bringSubviewToFront:self.badgeView];
    }
    CGRect bounds = self.tabBar.bounds;
    self.badgeView.frame = bounds;
}

- (void)updateColors
{
    if ([self.viewControllers count] == 4)
    {
        UIViewController *selectedViewController = self.selectedViewController;
        UIViewController *vc0 = self.viewControllers[0];
        UIViewController *vc1 = self.viewControllers[1];
        UIViewController *vc2 = self.viewControllers[2];
        UIViewController *vc3 = self.viewControllers[3];
        self.badgeView.homeTabImageView.tintColor = selectedViewController == vc0 ? vc0.view.tintColor : [UIColor dq_defaultTabColor];
        self.badgeView.drawTabImageView.tintColor = selectedViewController == vc1 ? vc1.view.tintColor : [UIColor dq_defaultTabColor];
        self.badgeView.activityTabImageView.tintColor = selectedViewController == vc2 ? vc2.view.tintColor : [UIColor dq_defaultTabColor];
        self.badgeView.profileTabImageView.tintColor = selectedViewController == vc3 ? vc3.view.tintColor : [UIColor dq_defaultTabColor];
//        NSLog(@"%@", self.badgeView.homeTabImageView.tintColor);
//        NSLog(@"%@", self.badgeView.drawTabImageView.tintColor);
//        NSLog(@"%@", self.badgeView.activityTabImageView.tintColor);
//        NSLog(@"%@", self.badgeView.profileTabImageView.tintColor);
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];
    [self updateColors];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    [super setSelectedViewController:selectedViewController];
    [self updateColors];
}

@end

@interface DQTabBarBadgeView ()

@property (nonatomic, strong) UIView *border1;
@property (nonatomic, strong) UIView *border2;
@property (nonatomic, strong) UIView *border3;

@end
@implementation DQTabBarBadgeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        _homeTabImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tab_home_large"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _drawTabImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tab_draw_large"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _activityTabImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tab_activity_large"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _profileTabImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tab_profile_large"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _homeTabImageView.contentMode = UIViewContentModeCenter;
        _drawTabImageView.contentMode = UIViewContentModeCenter;
        _activityTabImageView.contentMode = UIViewContentModeCenter;
        _profileTabImageView.contentMode = UIViewContentModeCenter;
        _homeBadgeView = [[UIView alloc] initWithFrame:CGRectZero];
        _drawBadgeView = [[UIView alloc] initWithFrame:CGRectZero];
        _activityBadgeView = [[UIView alloc] initWithFrame:CGRectZero];
        _profileBadgeView = [[UIView alloc] initWithFrame:CGRectZero];

        _homeTabImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        _drawTabImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        _activityTabImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
        _profileTabImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;

        _homeBadgeView.hidden = YES;
        _drawBadgeView.hidden = YES;
        _activityBadgeView.hidden = YES;
        _profileBadgeView.hidden = YES;

        _border1 = [[UIView alloc] initWithFrame:CGRectZero];
        _border1.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
        _border2 = [[UIView alloc] initWithFrame:CGRectZero];
        _border2.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
        _border3 = [[UIView alloc] initWithFrame:CGRectZero];
        _border3.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
        [self addSubview:_border1];
        [self addSubview:_border2];
        [self addSubview:_border3];
        [self addSubview:_homeTabImageView];
        [self addSubview:_drawTabImageView];
        [self addSubview:_activityTabImageView];
        [self addSubview:_profileTabImageView];
        [self addSubview:_homeBadgeView];
        [self addSubview:_drawBadgeView];
        [self addSubview:_activityBadgeView];
        [self addSubview:_profileBadgeView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    CGFloat tabWidth = bounds.size.width / 4;
    CGFloat height = bounds.size.height;
    CGRect imageFrame = CGRectMake(0, 3.5, tabWidth, height - 6.5);
    CGRect badgeFrame = CGRectMake(0, height - 4, tabWidth, 4);
    _homeTabImageView.frame = imageFrame;
    imageFrame.origin.x += tabWidth;
    _drawTabImageView.frame = imageFrame;
    imageFrame.origin.x += tabWidth;
    _activityTabImageView.frame = imageFrame;
    imageFrame.origin.x += tabWidth;
    _profileTabImageView.frame = imageFrame;

    _homeBadgeView.frame = badgeFrame;
    badgeFrame.origin.x += tabWidth;
    _drawBadgeView.frame = badgeFrame;
    badgeFrame.origin.x += tabWidth;
    _activityBadgeView.frame = badgeFrame;
    badgeFrame.origin.x += tabWidth;
    _profileBadgeView.frame = badgeFrame;

    CGRect borderFrame = CGRectMake(tabWidth, 0, 1.0, height);
    _border1.frame = borderFrame;
    borderFrame.origin.x += tabWidth;
    _border2.frame = borderFrame;
    borderFrame.origin.x += tabWidth;
    _border3.frame = borderFrame;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    // do not allow user interaction to be enabled, it makes this view hide touches from the tab bar
    if (!userInteractionEnabled)
    {
        [super setUserInteractionEnabled:userInteractionEnabled];
    }
}

@end
