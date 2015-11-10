//
//  DQNavigationController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/19/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQMainNavigationController.h"
#import "DQNavigationBar.h"
#import "DQNotifications.h"
#import "DQDataStoreController.h"
#import "UIFont+DQAdditions.h"

NSString *DQActivityCountUpdateNotification = @"DQActivityCountUpdateNotification";

@implementation DQMainNavigationController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationHasSeenQOTDFlagChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationQOTDUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQActivityCountUpdateNotification object:nil];
}

- (id)initWithRootViewController:(UIViewController *)rootViewController delegate:(id<DQMainNavigationControllerDelegate>)delegate
{
    self = [super initWithNavigationBarClass:[DQNavigationBar class] toolbarClass:nil delegate:delegate];
    if (self)
    {
        self.viewControllers = @[rootViewController];
        DQBasementButton *basementButton = [[DQBasementButton alloc] initWithStyle:DQBasementButtonStyleNavigationBar];
        basementButton.badgeCount = [self initialBadgeCount];
        [basementButton addTarget:self action:@selector(basementButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        rootViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:basementButton];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hasSeenQOTDFlagChanged:) name:DQApplicationHasSeenQOTDFlagChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(QOTDUpdated:) name:DQApplicationQOTDUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityCountUpdated:) name:DQActivityCountUpdateNotification object:nil];
    }
    return self;
}

- (id<DQMainNavigationControllerDelegate>)delegate
{
    return (id<DQMainNavigationControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQMainNavigationControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

- (void)basementButtonTapped:(DQBasementButton *)sender
{
    [self.delegate mainNavigationController:self basementButtonTapped:sender];
}

- (NSUInteger)baseBadgeCount
{
    return self.loggedIn && self.hasNewQuestOfTheDay ? 1 : 0;
}

- (NSUInteger)numberOfUnreadActivityItems
{
    return self.loggedIn ? [self.delegate numberOfUnreadActivityItemsForMainNavigationController:self] : 0;
}

- (NSUInteger)initialBadgeCount
{
    return [self baseBadgeCount] + [self numberOfUnreadActivityItems];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationBar setBackgroundImage:DQImageWithColor(DQColorGreen) forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[[UIImage alloc] init]];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeLeft;
}

- (void)activityCountUpdated:(NSNotification *)inNotification
{
    NSNumber *count = [inNotification userInfo][@"count"];
    [self updateActivityCountOnBasementButton:[count unsignedIntegerValue]];
}

- (void)hasSeenQOTDFlagChanged:(NSNotification *)inNotification
{
    [self updateActivityCountOnBasementButton:[self numberOfUnreadActivityItems]];
}

- (void)QOTDUpdated:(NSNotification *)inNotification
{
    [self updateActivityCountOnBasementButton:[self numberOfUnreadActivityItems]];
}

- (void)updateActivityCountOnBasementButton:(NSUInteger)numberOfUnreadActivityItems
{
    NSArray *vcs = self.viewControllers;
    if ([vcs count])
    {
        UIViewController *vc = [vcs objectAtIndex:0];
        UIView *view = vc.navigationItem.leftBarButtonItem.customView;
        if ([view isKindOfClass:[DQBasementButton class]])
        {
            ((DQBasementButton *)view).badgeCount = [self baseBadgeCount] + numberOfUnreadActivityItems;
        }
    }
}

@end
