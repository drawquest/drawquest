//
//  DQMenuViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/13/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <objc/runtime.h>

#import "Appirater.h"

#import "DQAnalyticsConstants.h"
#import "DQMenuViewController.h"
#import "DQActivityItem.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQActivityTableViewCell.h"
#import "DQMenuTableHeaderView.h"
#import "DQLoadingView.h"

typedef enum {
    DQMenuViewSectionNavigation = 0,
    DQMenuViewSectionActivity,
    DQMenuViewSectionCount
} DQMenuViewSection;

typedef enum {
    DQMenuRowHome = 0,
    DQMenuRowProfile,
    DQMenuRowExplore,
    DQMenuRowAbout,
    DQMenuRowCount
} DQMenuRow;

@interface DQMenuViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) DQLoadingView *loadingView;
@property (nonatomic, strong) UIView *loadingMoreActivitiesView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingMoreActivitiesSpinner;
@property (strong, nonatomic) UIView *sparseView;
@property (assign, nonatomic) BOOL finishedLoading;

@property (strong, nonatomic) NSArray *activityItems;

@property (nonatomic, assign) BOOL loadingMoreActivities;
@property (nonatomic, assign) BOOL hasLoadedAllActivities;

@end


@implementation DQMenuViewController

@synthesize activityItems;

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
    self.activityItems = [(self.activityItems ?: @[]) arrayByAddingObjectsFromArray:activities];
    CGPoint offset = self.tableView.contentOffset;
    [self.tableView reloadData];
    if (offset.y != 0)
    {
        [self.tableView setContentOffset:offset animated:NO];
    }
    [self updateViewState];
}

- (void)prependActivities:(NSArray *)activities
{
    if ([activities count])
    {
        self.activityItems = [activities arrayByAddingObjectsFromArray:(self.activityItems ?: @[])];
        [self updateViewState];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:DQMenuViewSectionActivity] withRowAnimation:UITableViewRowAnimationAutomatic];
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
            self.tableView.tableFooterView = self.sparseView;
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
    [super loadView];
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 323.0f, 768.0f)];
    self.view = containerView;

    self.loadingMoreActivitiesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 251.0)];
    self.loadingMoreActivitiesSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingMoreActivitiesSpinner.center = self.loadingMoreActivitiesView.boundsCenter;
    [self.loadingMoreActivitiesView addSubview:self.loadingMoreActivitiesSpinner];

    // Loading View
    self.loadingView = [[DQLoadingView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 350.0)];
    
    // Sparse View
    UIView *sparseView = [[UIView alloc] initWithFrame:self.view.bounds];
    sparseView.backgroundColor = [UIColor whiteColor];
    self.sparseView = sparseView;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 323.0f, 768.0f) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorColor = [UIColor colorWithRed:(195/255.0) green:(195/255.0) blue:(195/255.0) alpha:1];
    [self.view addSubview:self.tableView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewState];
}

- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewBasement withParameters:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSIndexPath *homeCellIndexPath = [NSIndexPath indexPathForItem:DQMenuRowHome inSection:DQMenuViewSectionNavigation];
    UITableViewCell *homeCell = [self.tableView cellForRowAtIndexPath:homeCellIndexPath];
    [self updateStatusTextForHomeRowCell:homeCell];

    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Symbol Mappings

- (UIColor *)navigationColorForRow:(NSInteger)row {
    
    UIColor *color;
    switch (row) {
        case DQMenuRowProfile:
            color = [UIColor colorWithRed:(252/255.0) green:(134/255.0) blue:(155/255.0) alpha:1];
            break;
        case DQMenuRowExplore:
            color = [UIColor colorWithRed:(107/255.0) green:(206/255.0) blue:(217/255.0) alpha:1];
            break;
        case DQMenuRowHome:
            color = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
            break;
        case DQMenuRowAbout:
            color = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
            break;
        default:
            color = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
            break;
    }
    
    return color;
}

- (UIImage *)navigationIconForRow:(NSInteger)row
{
    NSString *imageName;
    switch(row) {
        case DQMenuRowProfile:
            imageName = @"icon_activity_places_profile";
            break;
        case DQMenuRowExplore:
            imageName = @"icon_activity_places_explore";
            break;
        case DQMenuRowHome:
            imageName = @"icon_activity_places_draw";
            break;
        case DQMenuRowAbout:
            imageName = @"icon_activity_places_about";
            break;
        default:
            imageName = @"";
            break;
    }
    
    return [UIImage imageNamed:imageName];
}

- (NSString *)menuTitleForRow:(NSInteger)row
{
    NSString *title = nil;
    switch(row) {
        case DQMenuRowProfile:
            title = DQLocalizedString(@"Profile", @"Label for the user's own profile");
            break;
        case DQMenuRowExplore:
            title = DQLocalizedString(@"Explore", @"Title for section where users can explore for new content");
            break;
        case DQMenuRowHome:
            title = DQLocalizedStringWithDefaultValue(@"DrawAreaTitle", nil, nil, @"Draw", @"Title for the area where the user can draw Quests");
            break;
        case DQMenuRowAbout:
            title = DQLocalizedString(@"About DrawQuest", @"Navigation title for about us modal");
            break;
        default:
            break;
    }
    
    return title;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MenuCellID = @"MenuCell";
    static NSString *ActivityCellID = @"ActivityCell";
    
    NSString *reuseIdentifier;
    if(indexPath.section == DQMenuViewSectionNavigation) {
        reuseIdentifier = MenuCellID;
    } else {
        reuseIdentifier = ActivityCellID;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        Class cellClass;
        if ([reuseIdentifier isEqualToString:ActivityCellID]) {
            cellClass = [DQActivityTableViewCell class];
        } else {
            cellClass = [UITableViewCell class];
        }
        
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    }

    if(indexPath.section == DQMenuViewSectionNavigation) {
        UIImageView *accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_pad"]];
        cell.accessoryView = accessoryView;
        cell.textLabel.font = [UIFont dq_basementNavigationFont];
        cell.textLabel.textColor = [self navigationColorForRow:indexPath.row];
        cell.textLabel.text = [self menuTitleForRow:indexPath.row];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.5f;
        cell.detailTextLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15.0];
        cell.detailTextLabel.textColor = [UIColor dq_greenColor];
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.minimumScaleFactor = 0.5f;
        cell.imageView.image = [self navigationIconForRow:indexPath.row];
    }
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ((scrollView == self.tableView) && !(self.loadingMoreActivities || self.hasLoadedAllActivities))
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
    if (indexPath.section == DQMenuViewSectionActivity) {
        DQActivityItem *item = [self.activityItems objectAtIndex:indexPath.row];
        DQActivityTableViewCell *activityCell = (DQActivityTableViewCell *)cell;
        [activityCell initializeWithActivityItem:item];
        __weak typeof(self) weakSelf = self;
        activityCell.avatarOrUserNameTappedBlock = ^{
            [weakSelf navigateToProfileForUsername:item.creatorUserName];
        };
    } else if (indexPath.section == DQMenuViewSectionNavigation && indexPath.row == DQMenuRowHome) {
        [self updateStatusTextForHomeRowCell:cell];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return DQMenuViewSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 0;
    if (section == DQMenuViewSectionNavigation) {
        rowCount = DQMenuRowCount;
    } else if (section == DQMenuViewSectionActivity) {
        rowCount = self.activityItems.count;
    }
    
    return rowCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if (section == DQMenuViewSectionNavigation) {
        title = DQLocalizedString(@"Places", @"Label for all the areas of the app the user can visit");
    } else if (section == DQMenuViewSectionActivity) {
        title = DQLocalizedString(@"Activity", @"Label for the area where all of the user's relevant activity is collected");
    }

return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    DQMenuTableHeaderView *headerView = [[DQMenuTableHeaderView alloc] initWithFrame:CGRectZero];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTop:)];
    [headerView addGestureRecognizer:tap];
    headerView.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(section == 0)?@"icon_places":@"icon_activity"]];
    iconImageView.frame = CGRectMake(0, 0, 64, 46);
    iconImageView.contentMode = UIViewContentModeBottom;
    [headerView addSubview:iconImageView];
    
    if (section == 0) { //On account of status bar
        iconImageView.center = CGPointMake(iconImageView.center.x, iconImageView.center.y + 5);
        headerView.titleY = 7;
    }
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    int height = 59;
    
    if (section == 0)
        height = 64; //The first section needs more height to account for status bar
    
    return height;
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
    if (indexPath.section == DQMenuViewSectionNavigation) {
        switch (indexPath.row) {
            case DQMenuRowProfile: {
                [self navigateToProfileForLoggedInUser];
                break;
            }
            case DQMenuRowExplore: {
                [self navigateToExplore];
                break;
            }
            case DQMenuRowHome: {
                [self navigateToHome];
                break;
            }
            case DQMenuRowAbout: {
                [self navigateToAbout];
                break;
            }
            default:
                break;
        }
    } else if (indexPath.section) {
        DQActivityItem *activityItem = [self.activityItems objectAtIndex:indexPath.row];
        switch (activityItem.activityType) {
            case DQActivityItemTypeFollow:
            case DQActivityItemTypeFacebookFriendJoined:
            case DQActivityItemTypeTwitterFriendJoined:
                // Go to profile
                [self navigateToProfileForUsername:activityItem.creatorUserName];
                break;
            case DQActivityItemTypeWelcome:
                [self navigateToHome];
                break;
            case DQActivityItemTypeFeaturedInExplore:
                [self navigateToExploreWithCommentID:activityItem.commentID];
                break;
            case DQActivityItemTypeStar:
                // Appirater significant event: user has tapped a star notification
                dispatch_async(dispatch_get_main_queue(), ^{
                    [Appirater userDidSignificantEvent:YES];
                });
            case DQActivityItemTypeRemix:
            case DQActivityItemTypePlayback:
            case DQActivityItemTypePost:
            case DQActivityItemTypeUGQ:
                [self navigateToGalleryWithQuestID:activityItem.questID commentID:activityItem.commentID];
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
}

#pragma mark -
#pragma mark Pagination

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

- (void)scrollToTop:(UIGestureRecognizer *)sender
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)navigateToHome
{
    if (self.homeBlock)
    {
        self.homeBlock();
    }
}

- (void)navigateToAbout
{
    if (self.aboutBlock)
    {
        self.aboutBlock(self);
    }
}

- (void)navigateToExplore
{
    [self navigateToExploreWithCommentID:nil];
}

- (void)navigateToExploreWithCommentID:(NSString *)commentID
{
    if (self.exploreWithCommentIDBlock)
    {
        self.exploreWithCommentIDBlock(commentID);
    }
}

- (void)navigateToProfileForLoggedInUser
{
    if (self.profileBlock)
    {
        self.profileBlock(nil);
    }
}

- (void)navigateToProfileForUsername:(NSString *)username
{
    if (self.profileBlock)
    {
        self.profileBlock(username);
    }
}

- (void)navigateToGalleryWithQuestID:(NSString *)questID commentID:(NSString *)commentID
{
    if (self.galleryBlock)
    {
        self.galleryBlock(questID, commentID);
    }
}

- (void)navigateToShopColors
{
    if (self.shopColorsBlock)
    {
        self.shopColorsBlock(self);
    }
}

#pragma mark - Helpers

- (void)updateStatusTextForHomeRowCell:(UITableViewCell *)homeCell
{
    if (self.hasNewQuestOfTheDay)
    {
        homeCell.detailTextLabel.text = DQLocalizedString(@"New Quest!", @"A new Quest is available alert label");
    }
    else
    {
        homeCell.detailTextLabel.text = nil;
    }
}

@end
