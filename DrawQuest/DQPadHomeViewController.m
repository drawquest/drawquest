//
//  DQPadHomeViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadHomeViewController.h"

#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"
#import "DQAccount.h"
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"
#import "STHTTPResourceController.h"
#import "DQImageView.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

#import "DQGridViewCell.h"
#import "DQTitleView.h"
#import "DQLoadingView.h"
#import "STUtils.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STGridView.h"
#import "DQGridSectionHeader.h"
#import "DQGridSectionFooter.h"
#import "DQHomeHeaderView.h"
#import "DQQuest.h"

@interface DQPadHomeViewController () <STGridViewDelegate, STGridViewDataSource, DQHomeHeaderViewDelegate>

@property (assign, nonatomic) BOOL finishedLoading;
@property (strong, nonatomic) DQLoadingView *loadingView;
@property (strong, nonatomic) UIView *sparseView;
@property (weak, nonatomic) IBOutlet STGridView *gridView;
@property (strong, nonatomic) DQHomeHeaderView *topHeaderView;
@property (strong, nonatomic) DQGridSectionHeader *sectionHeader;
@property (strong, nonatomic) DQGridSectionFooter *sectionFooter;

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, readonly, nonatomic) DQQuest *questOfTheDay;
@property (strong, nonatomic) DQQuest *firstQuest;

@property (strong, nonatomic) NSArray *quests;

@property (nonatomic, assign) NSInteger nextPage;
@property (nonatomic, assign) BOOL loadingNextPage;
@property (nonatomic, assign) BOOL nextPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *loadNextPageRequest;
@property (nonatomic, weak) UIButton *shopButton;

@end

@implementation DQPadHomeViewController

@synthesize questOfTheDay = _questOfTheDay;

- (void)dealloc
{
    [self.dataStoreController removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate dataSource:(id<DQPadHomeViewControllerDataSource>)dataSource
{
    self = [super initWithNibName:@"DQHomeView" bundle:nil delegate:delegate];
    if (self)
    {
        _dataSource = dataSource;
    }
    return self;
}

#pragma mark - Accessors

- (DQQuest *)questOfTheDay
{
    if (!_questOfTheDay)
    {
        NSString *questOfTheDayID = [self.dataSource questOfTheDayIDForPadHomeViewController:self];
        DQQuest *latestQuest = [self.quests firstObject];

        _questOfTheDay = latestQuest;
        if (questOfTheDayID)
        {
            DQQuest *questOfTheDay = [self.dataStoreController questForServerID:questOfTheDayID];

            _questOfTheDay = questOfTheDay ?: latestQuest;
        }
        return _questOfTheDay;
    }
    return _questOfTheDay;
}

#pragma mark - HomeHeaderViewDelegate

- (void)homeHeaderViewDrawButtonTapped:(DQHomeHeaderView *)view
{
    [self showEditorForQuestOfTheDay];
}

- (void)homeHeaderViewResponsesButtonTapped:(DQHomeHeaderView *)view
{
    if (self.showGalleryForQuestOfTheDayBlock)
    {
        self.showGalleryForQuestOfTheDayBlock(self, self.questOfTheDay);
    }
}

- (void)homeHeaderViewImageViewTapped:(DQHomeHeaderView *)view
{
    [self showEditorForQuestOfTheDay];
}

- (void)homeHeaderViewSponsorTapped:(DQHomeHeaderView *)view
{
    if (self.showProfileForUserBlock)
    {
        NSString *username = self.questOfTheDay.attributionUsername ?: self.questOfTheDay.authorUsername;
        self.showProfileForUserBlock(self, username);
    }
}

- (BOOL)homeHeaderViewHasUserEverLoggedIn
{
    return self.hasUserEverLoggedIn;
}

#pragma mark - Actions

- (void)showEditorForQuestOfTheDay
{
    if (self.showEditorForQuestOfTheDayBlock)
    {
        BOOL isFirstQuest = self.firstQuest != nil;
        DQQuest *quest = isFirstQuest ? self.firstQuest : self.questOfTheDay;
        self.showEditorForQuestOfTheDayBlock(self, quest, isFirstQuest);
        [self logEvent:DQAnalyticsEventViewQuestOfTheDayEdtior withParameters:nil];
    }
}

- (void)shopButtonTapped:(id)sender
{
    if (self.showShopBlock)
    {
        self.showShopBlock(self);
    }
}

#pragma mark - View State

- (void)updateViewState
{
    if (self.firstQuest && !self.hasUserEverLoggedIn)
    {
        [self.loadingView removeFromSuperview];
        [self.sparseView removeFromSuperview];
        self.gridView.hidden = NO;
    }
    else if (!self.questOfTheDay)
    {
        self.gridView.hidden = YES;

        if (self.finishedLoading)
        {
            [self.loadingView removeFromSuperview];
            [self.view addSubview:self.sparseView];
        } else
        {
            [self.sparseView removeFromSuperview];
            [self.view addSubview:self.loadingView];
        }
    }
    else
    {
        [self.loadingView removeFromSuperview];
        [self.sparseView removeFromSuperview];
        self.gridView.hidden = NO;
        [self updateTopHeaderForCurrentQOTD];
    }
}

#pragma mark Errors

- (void)handleLoadError:(NSError *)loadError
{
    if (loadError && self.hasUserEverLoggedIn)
    {
        NSString *localizedDescription = loadError.localizedDescription;
        NSString *reasonString = localizedDescription ? [NSString stringWithFormat:DQLocalizedString(@"Unable to refresh quests due to error: %@", @"Quest refresh error alert message prefix"), localizedDescription] : DQLocalizedString(@"Unable to refresh quests due to unknown error.", @"Quest refresh unknown error alert message");
        UIAlertView *questsLoadAlert = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Unable to Refresh Quests", @"Quest refresh error alert title") message:reasonString delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
        [questsLoadAlert show];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Sparse View
    self.sparseView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.sparseView.backgroundColor = [UIColor whiteColor];

    // Loading View
    self.loadingView = [[DQLoadingView alloc] initWithFrame:self.view.bounds];

    // Background View
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    self.backgroundView = view;

    // Title Bar
    DQTitleView *titleView = [[DQTitleView alloc] initWithStyle:DQTitleViewStyleNavigationBar];
    titleView.text = DQLocalizedStringWithDefaultValue(@"DrawAreaTitle", nil, nil, @"Draw", @"Title for the area where the user can draw Quests");
    self.navigationItem.titleView = titleView;
    
    // Shop Button
    UIImage *shopImage = [UIImage imageNamed:@"button_topNav_shop"];
    UIView *shopButtonView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, shopImage.size.width, shopImage.size.height)];
    UIButton *shopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shopButton.frame = shopButtonView.bounds;
    
    [shopButton setBackgroundImage:shopImage forState:UIControlStateNormal];
    [shopButton addTarget:self action:@selector(shopButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [shopButtonView addSubview:shopButton];
    UIBarButtonItem *shopButtonItem = [[UIBarButtonItem alloc] initWithCustomView:shopButtonView];
    self.navigationItem.rightBarButtonItem = shopButtonItem;
    shopButton.hidden = ! self.loggedInAccount;
    self.shopButton = shopButton;

    // Header View
    DQHomeHeaderView *headerView = [[DQHomeHeaderView alloc] initWithFrame:CGRectMake(0.0f, 10.0f, CGRectGetWidth(self.gridView.bounds), 354)];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if (DQSystemVersionAtLeast(@"7.0"))
    {
        CGRect frame = self.gridView.frame;
        frame.origin.y += 36;
        self.gridView.frame = frame;

        UIEdgeInsets insets = self.gridView.contentInset;
        insets.top -= 81;
        self.gridView.contentInset = insets;
    }
#endif
    [headerView setDelegate:self];
    self.topHeaderView = headerView;

    self.view.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
    self.gridView.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
    
    self.gridView.dataSource = self;
    self.gridView.delegate = self;
    self.gridView.gridHeaderView = self.topHeaderView;
    self.sectionHeader = [[DQGridSectionHeader alloc] initWithFrame:CGRectZero];
    self.sectionFooter = [[DQGridSectionFooter alloc] initWithFrame:CGRectZero];

    [self.sectionFooter addTarget:self action:@selector(loadMorePressed:) forControlEvents:UIControlEventTouchUpInside];

    [self updateViewState];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    if (self.hasUserEverLoggedIn && self.loggedIn)
    {
        [self markNewQuestOfTheDaySeen];
    }

    [self updateQuestsFromCache];

    [self.dataStoreController addObserver:self action:@selector(questsUpdated:) forEntityName:@"Quest"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(questsUpdated:) name:DQApplicationQOTDUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];

    __weak typeof(self) weakSelf = self;
    __weak UIView *weakView = self.view;
    [self.publicServiceController requestQuestArchiveWithPage:nil completionBlock:^(DQHTTPRequest *request) {
        if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
        {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *quests = responseDictionary.dq_quests;

            [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:YES resultsBlock:^(NSArray *objects) {
                weakSelf.nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];

                weakSelf.quests = [(objects ?: @[]) sortedArrayUsingComparator:^NSComparisonResult(DQQuest* quest1, DQQuest* quest2) {
                    return [quest2.timestamp compare:quest1.timestamp];
                }];

                [weakSelf updateViewState];
                [weakSelf.gridView reloadData];

                [weakSelf updateTopHeaderForCurrentQOTD];
                if (weakSelf.hasUserEverLoggedIn)
                {
                    [weakSelf.publicServiceController requestCurrentQuestWithCompletionBlock:^(DQHTTPRequest *request) {
                        if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
                        {
                            NSDictionary *responseDictionary = request.dq_responseDictionary;
                            NSArray *quests = responseDictionary.dq_quests;

                            [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:NO resultsBlock:^(NSArray *objects) {
                                // padHomeViewController:takeQuestOfTheDayID: is a good indication that
                                // this class shouldn't be responsible for this functionality
                                [weakSelf.dataSource padHomeViewController:weakSelf takeQuestOfTheDayID:[(NSDictionary *)[quests firstObject] dq_serverID]];
                                weakSelf.finishedLoading = YES;
                                [weakSelf updateViewState];
                            }];
                        }
                    } failureBlock:^(DQHTTPRequest *request) {
                        // TODO: error handling?
                        if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
                        {
                            weakSelf.finishedLoading = YES;
                            [weakSelf updateViewState];
                        }
                    }];
                }
                else
                {
                    weakSelf.finishedLoading = YES;
                    [weakSelf updateForCurrentFirstRunQuest];
                }

                [weakSelf logEvent:DQAnalyticsEventViewQuestOfTheDayHomepage withParameters:nil];
            }];
        }
    } failureBlock:^(DQHTTPRequest *request) {
        if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
        {
            weakSelf.finishedLoading = YES;
            [weakSelf updateViewState];
            [weakSelf handleLoadError:request.error];
        }
    }];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationQOTDUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
    [self.dataStoreController removeObserver:self];
    [self.loadNextPageRequest cancel];
    self.loadNextPageRequest = nil;
    self.loadingNextPage = NO;
    self.nextPageFailedToLoad = NO;
    [super viewWillDisappear:animated];
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

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.quests = nil;
        self.finishedLoading = NO;
        self.loadingView = nil;
        self.sparseView = nil;
        self.topHeaderView = nil;
        self.sectionHeader = nil;
        self.sectionFooter = nil;
        self.backgroundView = nil;
        self.firstQuest = nil;
        self.nextPage = 0;
        [self.loadNextPageRequest cancel];
        self.loadNextPageRequest = nil;
        self.loadingNextPage = NO;
        self.nextPageFailedToLoad = NO;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark STGridViewDataSource

- (STGridViewCell *)STGridView:(STGridView *)inGridView cellForIndexPath:(NSIndexPath *)inIndexPath
{
    static NSString *CellID = @"GridCell";

    DQGridViewCell *cell = (DQGridViewCell *)[inGridView dequeueReusableCellWithIdentifier:CellID];
    if (!cell)
    {
        cell = [[DQGridViewCell alloc] initWithReuseIdentifier:CellID];
    }

    DQQuest *quest = [self.quests objectAtIndex:inIndexPath.row];
    cell.titleLabel.text = quest.title;
    cell.timestampLabel.timestamp = quest.timestamp;

    cell.imageView.imageURL = [quest imageURLForKey:DQImageKeyArchive];

    if (quest.completedByUser)
    {
        UIImageView *checkmarkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark"]];
        cell.imageView.accessoryView = checkmarkView;
        cell.imageView.accessoryViewCenterBlock = ^(CGRect bounds) {
            return CGPointMake(CGRectGetMaxX(bounds) - 4, CGRectGetMinY(bounds) + 4);
        };
    }
    return cell;
}

- (void)STGridView:(STGridView *)tableView willDisplayCell:(STGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == (self.quests.count - 1))
    {
        [self loadNextPage];
    }
}

- (STGridViewCellPriority)STGridView:(STGridView *)inGridView priorityForCellAtIndexPath:(NSIndexPath *)inIndexPath
{
    return 0.0f;
}

- (NSInteger)numberOfSectionsInSTGridView:(STGridView *)inGridView
{
    return 1;
}

- (NSInteger)STGridView:(STGridView *)inGridView numberOfCellsInSection:(NSInteger)inSection
{
    return self.quests ? self.quests.count : 0;
}

- (NSInteger)numberOfColumnsForSection:(NSInteger)inSection inSTGridView:(STGridView *)inGridView
{
    return 5;
}

- (NSInteger)minimumCellColumnSpanForSection:(NSInteger)inSection inSTGridView:(STGridView *)inGridView
{
    return 1;
}

#pragma mark -
#pragma mark Reloading Data

// reloadData defers and coalesces the load requests, calling _reloadData when it's appropriate
- (void)reloadData
{
    [self.gridView reloadData];
}


#pragma mark -
#pragma mark STGridViewDelegate

- (void)STGridView:(STGridView *)inGridView didSelectCellAtIndexPath:(NSIndexPath *)inIndexPath
{
    if (self.showGalleryForQuestBlock)
    {
        DQQuest *currentQuest = [self.quests objectAtIndex:inIndexPath.row];
        self.showGalleryForQuestBlock(self, currentQuest);
    }
}

- (CGFloat)STGridView:(STGridView *)inGridView minimumRowHeightForSection:(NSInteger)inSection
{
    return 180.0f;
}

- (CGFloat)STGridView:(STGridView *)inGridView preferredRowHeightForCellAtIndexPath:(NSIndexPath *)inIndexPath
{
    return 190.0f;
}

- (UIView *)STGridView:(STGridView *)gridView viewForHeaderInSection:(NSInteger)inSection
{
    return self.sectionHeader;
}

- (CGFloat)STGridView:(STGridView *)gridView heightForHeaderInSection:(NSInteger)inSection
{
    return 40.0f;
}

- (UIView *)STGridView:(STGridView *)gridView viewForFooterInSection:(NSInteger)inSection
{
    return self.sectionFooter;
}

- (CGFloat)STGridView:(STGridView *)gridView heightForFooterInSection:(NSInteger)inSection
{
    return 58.0f;
}

- (UIView *)STGridView:(STGridView *)gridView backgroundViewForSection:(NSInteger)section
{
    return self.backgroundView;
}

- (UIEdgeInsets)STGridView:(STGridView *)gridView insetsForSection:(NSInteger)inSection;
{
    return UIEdgeInsetsMake(0, 0, 75.0f, 0);
}

#pragma mark - Pagination Methods

- (void)loadNextPage
{
    if (self.nextPage && !self.loadingNextPage && !self.nextPageFailedToLoad)
    {
        self.loadingNextPage = YES;

        [self.sectionFooter setSectionState:DQGridSectionFooterStateLoading];

        __weak typeof(self) weakSelf = self;
        __weak UIView *weakView = self.view;
        [self.loadNextPageRequest cancel]; // it should be nil here, but if it isn't, cancel it.
        self.loadNextPageRequest = [self.publicServiceController requestQuestArchiveWithPage:@(self.nextPage) completionBlock:^(DQHTTPRequest *request) {
            if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
            {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSArray *quests = responseDictionary.dq_quests;

                [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:YES resultsBlock:^(NSArray *objects) {
                    NSArray *completedQuestIDs = self.loggedInAccount.completedQuestIDs;
                    if (completedQuestIDs.count > 0)
                    {
                        [weakSelf.dataStoreController markQuestsIDsFromJSONListCompleted:completedQuestIDs inBackground:NO];
                    }

                    NSInteger nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];

                    weakSelf.quests = [[(weakSelf.quests ?: @[]) arrayByAddingObjectsFromArray:objects] sortedArrayUsingComparator:^NSComparisonResult(DQQuest* quest1, DQQuest* quest2) {
                        return [quest2.timestamp compare:quest1.timestamp];
                    }];

                    if (!nextPage || !weakSelf.nextPage)
                    {
                        weakSelf.nextPage = nil;
                    }
                    else if (weakSelf.nextPage > nextPage)
                    {
                        weakSelf.nextPage = nextPage;
                    }

                    [weakSelf.gridView reloadData];
                    weakSelf.loadingNextPage = NO;

                    [weakSelf.sectionFooter setSectionState:DQGridSectionFooterStateLoaded];
                }];
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
            {
                [weakSelf.sectionFooter setSectionState:DQGridSectionFooterStateLoadFailed];
                [weakSelf.gridView reloadData];
                weakSelf.loadingNextPage = NO;
                weakSelf.nextPageFailedToLoad = YES;
            }
        }];
    }
}

- (void)loadMorePressed:(id)sender
{
    if (self.nextPageFailedToLoad)
    {
        self.nextPageFailedToLoad = NO;
        [self loadNextPage];
    }
}

#pragma mark -
#pragma mark Data Store Controller

- (void)updateForCurrentFirstRunQuest
{
    DQQuest *quest = nil;

    NSString *firstRunQuestID = [self.dataSource firstRunQuestIDForPadHomeViewController:self];
    if (firstRunQuestID)
    {
        quest = [self.dataStoreController questForServerID:firstRunQuestID];
    }

    if (quest)
    {
        self.firstQuest = quest;
        [self updateTopHeaderForFirstQuest];
    }
    else
    {
        NSString *preloadedQuestID = self.dataStoreController.preloadedQuestID;
        if (preloadedQuestID)
        {
            DQQuest *preloadedQuest = [self.dataStoreController questForServerID:preloadedQuestID];
            if (preloadedQuest)
            {
                self.firstQuest = preloadedQuest;
                [self updateTopHeaderForPreLoadedFirstQuest];
            }
        }
    }

}

- (void)questsUpdated:(NSDictionary *)inUserInfo
{
    _questOfTheDay = nil;
    [self updateQuestsFromCache];

    if (!self.hasUserEverLoggedIn)
    {
        [self updateForCurrentFirstRunQuest];
    }
}

- (void)accountChanged:(NSNotification *)note
{
    self.shopButton.hidden = ! self.loggedInAccount;
}

- (void)updateQuestsFromCache
{
    // FIXME: this asks for ALL quests, but the home screen is paginated, it shouldn't ask for ALL quests
    NSArray *cachedQuests = [self.dataStoreController quests];
    [self updateViewState];
    if (cachedQuests.count)
    {
        [self reloadData];
    }
}

- (void)markNewQuestOfTheDaySeen
{
    self.hasNewQuestOfTheDay = NO;
}

- (void)updateTopHeaderForCurrentQOTD
{
    if (self.hasUserEverLoggedIn)
    {
        // tell the topheaderview to refresh in case it has the first quest hub rather than the qotd hub
        [self.topHeaderView setNeedsDisplay];

        DQHomeHeaderView *headerView = self.topHeaderView;
        headerView.imageView.imageURL = [self.questOfTheDay imageURLForKey:DQImageKeyHomePageFeatured];
        headerView.questLabel.text = self.questOfTheDay.title;

        [headerView configureWithQuest:self.questOfTheDay];

        // The current QotD top header should always be updated with the most current QotD
        [self markNewQuestOfTheDaySeen];
    }
}

- (void)updateTopHeaderForPreLoadedFirstQuest
{
    DQHomeHeaderView *headerView = self.topHeaderView;
    headerView.imageView.image = [UIImage imageNamed:@"preloaded_quest_template_preview.jpg"];
    headerView.questLabel.text = DQLocalizedString(@"Give him a smile!", @"Quest title instructing users to draw the smiley face a smile");
    
    [self updateViewState];
}

- (void)updateTopHeaderForFirstQuest
{
    DQHomeHeaderView *headerView = self.topHeaderView;
    headerView.imageView.imageURL = [self.firstQuest imageURLForKey:DQImageKeyHomePageFeatured];
    headerView.questLabel.text = DQLocalizedString(@"Give him a smile!", @"Quest title instructing users to draw the smiley face a smile");
    
    [self updateViewState];
}

@end
