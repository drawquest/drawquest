//
//  DQPhoneActivityViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneActivityViewController.h"
#import <objc/runtime.h>

#import "DQAnalyticsConstants.h"
#import "Appirater.h"
#import "DQActivityItem.h"
#import "DQNotifications.h"
#import "DQDataStoreController.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQPhoneActivityTableViewCell.h"
#import "DQLoadingView.h"
#import "DQPrivateServiceController.h"
#import "DQButton.h"
#import "DQPhoneErrorView.h"
#import "UIScrollView+SVPullToRefresh.h"

NSString *const DQPhoneActivityViewControllerClearBadgeNotification = @"DQPhoneActivityViewControllerClearBadgeNotification";

@interface DQPhoneActivityErrorView : DQPhoneErrorView

@property (nonatomic, assign) BOOL hasUserEverLoggedIn;

@end

@interface DQPhoneActivityViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) DQLoadingView *loadingView;
@property (nonatomic, strong) UIView *loadingMoreActivitiesView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingMoreActivitiesSpinner;
@property (nonatomic, strong) DQPhoneActivityErrorView *errorView;
@property (assign, nonatomic) BOOL finishedLoading;

@property (strong, nonatomic) NSArray *activityItems;

@property (nonatomic, assign) BOOL loadingMoreActivities;
@property (nonatomic, assign) BOOL hasLoadedAllActivities;
@property (nonatomic, assign) BOOL loadFailed;

@end

@implementation DQPhoneActivityViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
}

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil delegate:delegate];
    if (self)
    {
    }
    return self;
}

- (void)replaceActivities:(NSArray *)activities
{
    self.loadingMoreActivities = NO;
    self.finishedLoading = YES;
    self.activityItems = activities;
    [self updateViewState];
    [self.tableView reloadData];
}

- (void)appendActivities:(NSArray *)activities
{
    self.loadingMoreActivities = NO;
    self.hasLoadedAllActivities = [activities count] == 0;
    if (self.activityItems)
    {
        NSUInteger index = [self.activityItems count];
        self.activityItems = [self.activityItems arrayByAddingObjectsFromArray:activities];
        [self.tableView beginUpdates];
        NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[activities count]];
        for (id _ in activities)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:index++ inSection:0]];
        }
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        self.activityItems = [NSArray arrayWithArray:activities];
        [self.tableView reloadData];
    }
    [self updateViewState];
}

- (void)prependActivities:(NSArray *)activities
{
    [[self.tableView pullToRefreshView] stopAnimating];
    if ([activities count])
    {
        self.activityItems = [activities arrayByAddingObjectsFromArray:(self.activityItems ?: @[])];
        [self updateViewState];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - View State

- (void)updateViewState
{
    if (self.activityItems.count == 0)
    {
        [self.loadingMoreActivitiesSpinner stopAnimating];
        if (self.finishedLoading)
        {
            self.errorView.errorType = DQPhoneErrorViewTypeEmpty;
            self.errorView.buttonTappedBlock = nil;
            self.tableView.tableFooterView = self.errorView;
        }
        else if (self.loadFailed)
        {
            __weak typeof(self) weakSelf = self;
            self.errorView.errorType = DQPhoneErrorViewTypeRequestFailed;
            self.errorView.buttonTappedBlock = ^{
                if (weakSelf.reloadActivitiesBlock)
                {
                    weakSelf.loadFailed = NO;
                    weakSelf.tableView.tableFooterView = nil;
                    weakSelf.errorView.buttonTappedBlock = nil;
                    [weakSelf.loadingMoreActivitiesSpinner startAnimating];
                    weakSelf.reloadActivitiesBlock();
                }
            };
            self.tableView.tableFooterView = self.errorView;
        }
        else
        {
            self.tableView.tableFooterView = self.loadingView;
        }
    }
    else if (self.loadingMoreActivities)
    {
        [self.loadingMoreActivitiesSpinner startAnimating];
        self.tableView.tableFooterView = self.loadingMoreActivitiesView;
    }
    else
    {
        [self.loadingMoreActivitiesSpinner stopAnimating];
        self.tableView.tableFooterView = self.loadingMoreActivitiesView;
    }
}

#pragma mark - UIViewController

- (void)loadView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.view = self.tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    self.loadingMoreActivitiesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 151.0)];
    self.loadingMoreActivitiesView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.loadingMoreActivitiesSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingMoreActivitiesSpinner.center = self.loadingMoreActivitiesView.boundsCenter;
    self.loadingMoreActivitiesSpinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.loadingMoreActivitiesView addSubview:self.loadingMoreActivitiesSpinner];

    // Loading View
    self.loadingView = [[DQLoadingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 350.0)];
    self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.errorView = [[DQPhoneActivityErrorView alloc] initWithFrame:CGRectZero];
    self.errorView.hasUserEverLoggedIn = self.hasUserEverLoggedIn;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.getUnreadCountBlock)
    {
        self.unreadCount = self.getUnreadCountBlock(self);
    }

    if (self.loggedInAccount)
    {
        [self updateViewState];
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        self.errorView.errorType = DQPhoneErrorViewTypeLoginRequired;
        self.errorView.buttonTappedBlock = ^{
            [weakSelf requestAuthenticationWithCancellationBlock:^{
                // TODO: anything when they cancel?
            } completionBlock:^(DQAuthenticationSignupService service, DQNavigationController *modalNavigationController) {
                // leave this for viewWillAppear:
            } failureBlock:^(NSError *error) {
                [weakSelf showError:error];
            }];
        };
        self.tableView.tableFooterView = self.errorView;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.errorView.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self logEvent:DQAnalyticsEventViewActivities withParameters:nil];
    [super viewDidAppear:animated];
    // if we appear near the top of the screen clear the badge
    if (self.tableView.contentOffset.y <= 30.0)
    {
        [self clearBadge];
    }
    if (self.loggedIn)
    {
        __weak typeof(self) weakSelf = self;
        [self.tableView addPullToRefreshWithActionHandler:^{
            if (weakSelf.refreshBlock)
            {
                weakSelf.refreshBlock();
            }
            if (weakSelf.getUnreadCountBlock)
            {
                weakSelf.unreadCount = weakSelf.getUnreadCountBlock(weakSelf);
            }
            [weakSelf.tableView reloadData];
        }];
    }
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [self resetView];
    }
    [super didReceiveMemoryWarning];
}

- (void)clearBadge
{
    self.unreadCount = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPhoneActivityViewControllerClearBadgeNotification object:nil userInfo:nil];
}

- (void)accountChanged:(NSNotification *)notification
{
    [self resetView];
}

- (void)resetView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
    self.loadingView = nil;
    self.tableView = nil;
    self.loadingMoreActivitiesView = nil;
    self.loadingMoreActivitiesSpinner = nil;
    self.errorView = nil;
    self.loadingMoreActivities = NO;
    self.hasLoadedAllActivities = NO;
    self.loadFailed = NO;
    self.view = nil;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ActivityCellID = @"ActivityCell";

    DQPhoneActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ActivityCellID];
    if (!cell)
    {
        cell = [[DQPhoneActivityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActivityCellID];
    }
    cell.isUnread = indexPath.row < self.unreadCount;
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // once you see half of the top one we mark them all read
    if (self.unreadCount && (scrollView == self.tableView) && scrollView.contentOffset.y <= 30.0)
    {
        [self clearBadge];
        [[NSNotificationCenter defaultCenter] postNotificationName:DQPhoneActivityTableViewCellMarkAsReadNotification object:nil userInfo:nil];
    }

    // if we're near the bottom, load more
    if ((scrollView == self.tableView) && !(self.loadingMoreActivities || self.hasLoadedAllActivities) && (self.tableView.tableFooterView == self.loadingMoreActivitiesView))
    {
        CGFloat scrollViewHeight = scrollView.frame.size.height;
        CGFloat scrollContentSizeHeight = scrollView.contentSize.height;
        CGFloat scrollOffset = scrollView.contentOffset.y;

        if (scrollOffset + scrollViewHeight >= scrollContentSizeHeight - 50.0)
        {
            [self loadMoreActivities];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DQActivityItem *item = [self.activityItems objectAtIndex:indexPath.row];
    DQPhoneActivityTableViewCell *activityCell = (DQPhoneActivityTableViewCell *)cell;
    [activityCell initializeWithActivityItem:item];
    __weak typeof(self) weakSelf = self;
    activityCell.avatarOrUserNameTappedBlock = ^{
        [weakSelf navigateToProfileForUsername:item.creatorUserName];
    };
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = self.activityItems.count;
    return rowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self navigateFromRow:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)navigateFromRow:(NSIndexPath *)indexPath
{
    DQActivityItem *activityItem = [self.activityItems objectAtIndex:indexPath.row];
    switch (activityItem.activityType)
    {
        case DQActivityItemTypeFollow:
        case DQActivityItemTypeFacebookFriendJoined:
        case DQActivityItemTypeTwitterFriendJoined:
            // Go to profile
            [self navigateToProfileForUsername:activityItem.creatorUserName];
            break;
        case DQActivityItemTypeWelcome:
            // Per https://canvas.atlassian.net/wiki/display/DRAW/Activity:
            // Destination: Nowhere; first-time experience.
            // [self navigateToHome];
            break;
        case DQActivityItemTypeStar:
            // Appirater significant event: user has tapped a star notification
            dispatch_async(dispatch_get_main_queue(), ^{
                [Appirater userDidSignificantEvent:YES];
            });
        case DQActivityItemTypeRemix:
        case DQActivityItemTypePlayback:
        case DQActivityItemTypePost:
        case DQActivityItemTypeFeaturedInExplore:
            [self navigateToCommentID:activityItem.commentID inQuestWithID:activityItem.questID];
            break;
        case DQActivityItemTypeNewColors:
            [self navigateToShopColors];
            break;
        case DQActivityItemTypeOther:
        case DQActivityItemTypeUnknown:
        default:
            if (self.unknownActivityItemTappedBlock)
            {
                self.unknownActivityItemTappedBlock(activityItem);
            }

            break;
    }
}

#pragma mark -
#pragma mark Pagination

- (void)loadActivitiesFailed
{
    self.loadFailed = YES;
    [self updateViewState];
}

- (void)loadMoreActivitiesFailed
{
    self.loadingMoreActivities = NO;
    [self updateViewState];
}

- (void)loadMoreActivities
{
    if (self.loadMoreActivitiesBlock)
    {
        NSLog(@"loading next page of activities");
        self.loadingMoreActivities = YES;
        [self updateViewState];
        self.loadMoreActivitiesBlock();
    }
}

#pragma mark -
#pragma mark Navigation

- (void)navigateToHome
{
    if (self.homeBlock)
    {
        self.homeBlock();
    }
}

- (void)navigateToProfileForUsername:(NSString *)username
{
    if (self.profileBlock)
    {
        self.profileBlock(username);
    }
}

- (void)navigateToCommentID:(NSString *)commentID inQuestWithID:(NSString *)questID
{
    [self showDrawingDetailForCommentWithServerID:commentID source:@"Activity" completionBlock:nil failureBlock:^(NSError *error) {
        // FIXME: implement
    }];
}

- (void)navigateToShopColors
{
    if (self.shopColorsBlock)
    {
        self.shopColorsBlock(self);
    }
}

#pragma mark - Error Handling

- (void)showError:(NSError *)inError
{
    [self showErrorWithTitle:nil description:inError.dq_displayDescription];
}

- (void)showErrorWithTitle:(NSString *)title description:(NSString *)description
{
    if (!title) {
        title = DQLocalizedString(@"Error", @"Generic error alert title");
    }

    if (!description) {
        description = DQLocalizedString(@"Unknown error.", @"Unknown error alert message");
    }

    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
    [errorAlert show];
}

@end

@implementation DQPhoneActivityErrorView

- (UIImage *)image
{
    return [UIImage imageNamed:@"tour_avatar_stars_grouped"];
}

- (NSString *)message
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeLoginRequired:
            return self.hasUserEverLoggedIn ? DQLocalizedString(@"Sign In and Start Drawing", @"Prompt to sign in and immediately begin drawing") : DQLocalizedString(@"Sign Up and Start Drawing", @"Prompt to sign up and immediately begin drawing");
            break;
        case DQPhoneErrorViewTypeEmpty:
            return DQLocalizedString(@"You don't have any activity yet.", @"Message for user that do not yet have any activity items");
            break;
        case DQPhoneErrorViewTypeRequestFailed:
        default:
            return DQLocalizedString(@"We couldn't load your activity. Please try again.", @"Error loading activity from server message");
            break;
    }
}

- (NSString *)buttonTitle
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeLoginRequired:
            return self.hasUserEverLoggedIn ? DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account") : DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
            break;
        case DQPhoneErrorViewTypeRequestFailed:
        default:
            return DQLocalizedString(@"Retry", @"Prompt for a user to attempt a failed connection again.");
            break;
    }
}

@end
