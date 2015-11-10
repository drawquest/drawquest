//
//  DQPhoneProfileViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneProfileViewController.h"

// Models
#import "DQQuest.h"
#import "DQUser.h"
#import "DQComment.h"

// Controllers
#import "DQPrivateServiceController.h"
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"

// View Controllers
#import "DQSegmentedCollectionViewController.h"

// Views
#import "DQPhoneProfileHeaderView.h"
#import "DQQuantifiedSegmentedControl.h"
#import "DQCommentGridCollectionViewCell.h"
#import "DQCollectionViewQuestCell.h"
#import "DQCollectionViewUserCell.h"
#import "DQPhoneErrorView.h"

// Additions
#import "UIView+STAdditions.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQViewMetricsConstants.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"

static NSString *DQPhoneProfileViewControllerThumbnailCell = @"thumbnailCell";
static NSString *DQPhoneProfileViewControllerQuestCell = @"questCell";
static NSString *DQPhoneProfileViewControllerUserCell = @"userCell";

@interface DQPhoneProfileErrorView : DQPhoneErrorView

@property (nonatomic, assign) BOOL hasUserEverLoggedIn;

@end

@interface DQPhoneProfileViewController () <DQSegmentedCollectionViewControllerDataSource, DQQuantifiedSegmentedControlDelegate>

@property (nonatomic, strong) DQUser *user;
@property (nonatomic, strong) DQSegmentedCollectionViewController *collectionViewController;
@property (nonatomic, strong) NSMutableOrderedSet *comments;
@property (nonatomic, strong) NSMutableOrderedSet *quests;
@property (nonatomic, strong) NSMutableArray *following;
@property (nonatomic, strong) NSMutableArray *followers;
@property (nonatomic, weak) DQQuantifiedSegmentedControl *segmentedControl;
@property (nonatomic, weak) DQPhoneProfileHeaderView *headerView;
@property (nonatomic, weak) DQPhoneProfileErrorView *errorView;
@property (nonatomic, weak) UIView *whiteSpaceView;

// Comments pagination
@property (nonatomic, assign) BOOL commentsNextPageFailedToLoad;
@property (nonatomic, assign) BOOL commentsPrevPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *commentsNextPageRequest;
@property (nonatomic, weak) DQHTTPRequest *commentsPrevPageRequest;
@property (nonatomic, assign) NSInteger commentsPrevPage;
@property (nonatomic, assign) NSInteger commentsNextPage;

// Quests pagination
@property (nonatomic, assign) BOOL questsNextPageFailedToLoad;
@property (nonatomic, assign) BOOL questsPrevPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *questsNextPageRequest;
@property (nonatomic, weak) DQHTTPRequest *questsPrevPageRequest;
@property (nonatomic, assign) NSInteger questsPrevPage;
@property (nonatomic, assign) NSInteger questsNextPage;

// Following pagination
@property (nonatomic, weak) DQHTTPRequest *followingRequest;
@property (nonatomic, assign) BOOL followingNextPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *followingNextPageRequest;
@property (nonatomic, copy) NSString *followingNextPage;

// Followers pagination
@property (nonatomic, weak) DQHTTPRequest *followersRequest;
@property (nonatomic, assign) BOOL followersNextPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *followersNextPageRequest;
@property (nonatomic, copy) NSString *followersNextPage;

@end

@implementation DQPhoneProfileViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
}

- (id)initWithUserName:(NSString *)inUserName source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithUserName:inUserName source:source delegate:delegate];
    if (self)
    {
        self.title = inUserName;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    DQPhoneProfileHeaderView *headerView = [[DQPhoneProfileHeaderView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    headerView.showShopBlock = ^(DQPhoneProfileHeaderView *view) {
        if (weakSelf.showShopBlock)
        {
            weakSelf.showShopBlock(weakSelf);
        }
    };
    self.headerView = headerView;

    DQPhoneProfileErrorView *errorView = [[DQPhoneProfileErrorView alloc] initWithFrame:CGRectZero];
    errorView.hasUserEverLoggedIn = self.hasUserEverLoggedIn;
    self.errorView = errorView;

    self.collectionViewController = [[DQSegmentedCollectionViewController alloc] initWithHeaderView:headerView errorView:errorView];
    self.collectionViewController.dataSource = self;
    [self.collectionViewController.collectionView registerClass:[DQCommentGridCollectionViewCell class] forCellWithReuseIdentifier:DQPhoneProfileViewControllerThumbnailCell];
    [self.collectionViewController.collectionView registerClass:[DQCollectionViewQuestCell class] forCellWithReuseIdentifier:DQPhoneProfileViewControllerQuestCell];
    [self.collectionViewController.collectionView registerClass:[DQCollectionViewUserCell class] forCellWithReuseIdentifier:DQPhoneProfileViewControllerUserCell];
    self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayNothing;

    [self addChildViewController:self.collectionViewController];
    [self.collectionViewController didMoveToParentViewController:self];
    [self.view addSubview:self.collectionViewController.view];
    self.collectionViewController.view.frame = self.view.bounds;

    UIView *whiteSpaceView = [[UIView alloc] initWithFrame:CGRectZero];
    whiteSpaceView.frameHeight = 1000.0f;
    whiteSpaceView.backgroundColor = [UIColor whiteColor];
    [self.collectionViewController.collectionView addSubview:whiteSpaceView];
    self.whiteSpaceView = whiteSpaceView;

    [self addPullToRefresh];
    [self setPullToRefreshOffset];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentFlagged:) name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDeleted:) name:DQCommentDeletedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.loggedIn || [self.userName length])
    {
        [self updateUserFromCache];
        if (self.user)
        {
            [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplayHeaderView | DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl];
            [self reloadData];
            [self refreshProfileInfo:nil];
            if (self.segmentedControl.selectedSegmentIndex == NSNotFound)
            {
                self.segmentedControl.selectedSegmentIndex = 0;
            }
        }
        else
        {
            if (!self.userName)
            {
                self.userName = self.loggedInAccount.username;
            }
            [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplayNothing];
            [self.collectionViewController startDisplayingSpinner];
            [self refreshProfileInfo:nil];
        }
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
        [weakSelf setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplayErrorView];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.whiteSpaceView.frameWidth = self.collectionViewController.collectionView.frameWidth;

    // Do this after all layout has happened
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf setPullToRefreshOffset];
    });
}

- (void)setPullToRefreshOffset
{
    CGFloat offset = 0.0f;
    if (self.collectionViewController.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayHeaderView)
    {
        offset -= self.collectionViewController.headerView.bounds.size.height;
    }
    if (self.collectionViewController.displayStatus & DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl)
    {
        offset -= self.collectionViewController.segmentedControl.bounds.size.height;
    }
    if (self.collectionViewController.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayErrorView)
    {
        offset -= self.collectionViewController.errorView.bounds.size.height;
    }
    self.whiteSpaceView.frameMaxY = offset;
    self.collectionViewController.collectionView.dq_pullToRefreshYOriginOffset = offset;
    [self.collectionViewController.collectionView sendSubviewToBack:self.collectionViewController.collectionView.pullToRefreshView];
    [self.collectionViewController.collectionView sendSubviewToBack:self.whiteSpaceView];
}

- (void)addPullToRefresh
{
    __weak typeof(self) weakSelf = self;
    [self setPullToRefreshOffset];
    [self.collectionViewController.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf refreshProfileInfo:^{
            [weakSelf loadForSelectedSegmentIndex:weakSelf.segmentedControl.selectedSegmentIndex completionBlock:^{
                [weakSelf.collectionViewController.collectionView.pullToRefreshView stopAnimating];
            }];
        }];
    }];
}

- (void)setDisplayStatus:(DQSegmentedCollectionViewControllerStatus)displayStatus
{
    self.collectionViewController.collectionView.contentInset = UIEdgeInsetsZero;
    self.collectionViewController.displayStatus = displayStatus;
    [self.view setNeedsLayout];
}

- (void)loadForSelectedSegmentIndex:(NSInteger)selectedIndex completionBlock:(dispatch_block_t)completionBlock
{
    if (selectedIndex == 0)
    {
        [self loadComments:completionBlock];
    }
    else if (selectedIndex == 1)
    {
        [self loadQuests:completionBlock];
    }
    else if (selectedIndex == 2)
    {
        [self loadFollowing:completionBlock];
    }
    else if (selectedIndex == 3)
    {
        [self loadFollowers:completionBlock];
    }
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [self resetView];
    }
    [super didReceiveMemoryWarning];
}

- (void)accountChanged:(NSNotification *)notification
{
    if (self.isForLoggedInUser)
    {
        [self resetView];
        // Update User
        // This is redundant since we check later, but not bad to have
        self.userName = self.loggedInAccount.username;
    }
}

- (void)resetView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    self.segmentedControl.delegate = nil;
    self.segmentedControl = nil;
    self.headerView = nil;
    self.collectionViewController = nil;
    self.comments = nil;
    self.quests = nil;
    self.following = nil;
    self.followers = nil;
    self.commentsPrevPage = 0;
    self.commentsNextPage = 0;
    self.commentsPrevPageRequest = nil;
    self.commentsNextPageRequest = nil;
    self.commentsNextPageFailedToLoad = NO;
    self.commentsPrevPageFailedToLoad = NO;
    self.questsPrevPage = 0;
    self.questsNextPage = 0;
    self.questsPrevPageRequest = nil;
    self.questsNextPageRequest = nil;
    self.questsNextPageFailedToLoad = NO;
    self.questsPrevPageFailedToLoad = NO;
    self.followersRequest = nil;
    self.followersNextPage = nil;
    self.followersNextPageRequest = nil;
    self.followersNextPageFailedToLoad = NO;
    self.followingRequest = nil;
    self.followingNextPage = nil;
    self.followingNextPageRequest = nil;
    self.followingNextPageFailedToLoad = NO;
    self.view = nil;
}

#pragma mark -

- (void)reloadData
{
    [self.collectionViewController reloadData];
}

- (void)updateUserInfo
{
    self.headerView.avatarImageView.imageURL = self.user.avatarURL;
    self.headerView.usernameLabel.text = self.user.userName;
    self.headerView.bioLabel.text = self.user.bio;
    self.headerView.coinsLabel.text = [self.user.coinCount stringValue];

    [self.headerView setURL:self.user.facebookURL forSocialType:DQPhoneProfileHeaderViewSocialTypeFacebook showWhenInactive:NO];
    [self.headerView setURL:self.user.twitterURL forSocialType:DQPhoneProfileHeaderViewSocialTypeTwitter showWhenInactive:NO];
    [self.headerView setURL:self.user.drawQuestURL forSocialType:DQPhoneProfileHeaderViewSocialTypeDrawQuest showWhenInactive:NO];
    [self.headerView setURL:self.user.tumblrURL forSocialType:DQPhoneProfileHeaderViewSocialTypeTumblr showWhenInactive:NO];

    [self.headerView displayFollowButton:!self.isForLoggedInUser forUsername:self.user.userName];

    [self.segmentedControl setCount:self.user.commentsCount forSegmentIndex:0];
    [self.segmentedControl setCount:self.user.questsCount forSegmentIndex:1];
    [self.segmentedControl setCount:self.user.followingCount forSegmentIndex:2];
    [self.segmentedControl setCount:self.user.followerCount forSegmentIndex:3];
}

- (void)updateUserFromNetwork:(DQUser *)user
{
    self.user = user;
    [self updateUserInfo];
}

- (void)updateUserFromCache
{
    DQUser *cachedUser = [self.dataStoreController userForUserName:self.userName];
    self.user = cachedUser;
    [self updateUserInfo];
}

- (void)refreshProfileInfo:(dispatch_block_t)completionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestProfileInfoForUsername:self.userName completionBlock:^(DQHTTPRequest *request) {
        [weakSelf.collectionViewController stopDisplayingSpinner];
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *infoArray = [NSArray arrayWithObject:responseDictionary];

        [weakSelf.dataStoreController createOrUpdateUsersFromJSONList:infoArray inBackground:YES withCompletionBlock:^(NSArray *objects) {
            [weakSelf updateUserFromNetwork:[objects firstObject]];
            [weakSelf setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplayHeaderView | DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl];
            if (weakSelf.segmentedControl.selectedSegmentIndex == NSNotFound)
            {
                weakSelf.segmentedControl.selectedSegmentIndex = 0;
            }
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    } failureBlock:^(DQHTTPRequest *request) {
        [weakSelf.collectionViewController stopDisplayingSpinner];
        weakSelf.errorView.errorType = DQPhoneErrorViewTypeRequestFailed;
        weakSelf.errorView.buttonTappedBlock = ^{
            [weakSelf setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplayNothing];
            [weakSelf.collectionViewController startDisplayingSpinner];
            [weakSelf refreshProfileInfo:nil];
        };
        [weakSelf setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplayErrorView];

        NSString *errorDescription = request.error.dq_displayDescription;
        if (request.responseStatusCode == 404)
        {
            errorDescription = DQLocalizedString(@"Sorry that profile no longer exists.", @"User profile not found on server error alert message");
        }
        [weakSelf showErrorWithTitle:DQLocalizedString(@"Profile error:", @"Profile error alert title") description:errorDescription];
        if (completionBlock)
        {
            completionBlock();
        }
        if (request.responseStatusCode == 404)
        {
            if (weakSelf.dismissBlock)
            {
                weakSelf.dismissBlock();
            }
        }
    }];
}

- (void)loadComments:(dispatch_block_t)completionBlock
{
    if (self.comments && !completionBlock)
    {
        return;
        // FIXME: I hate early returns but this is just to have a clean diff
        // after 3.0 ships, refactor this to be if (!self.comments || completionBlock) { do stuff }
    }

    if ( ! self.comments)
    {
        [self.collectionViewController startDisplayingSpinner];
    }
        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestCommentsForUsername:self.userName page:nil completionBlock:^(DQHTTPRequest *request) {
            if (weakSelf)
            {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:responseDictionary.dq_comments inBackground:YES resultsBlock:^(NSArray *objects) {
                    [weakSelf handleCommentsLoadResponseForRequest:request JSONDict:responseDictionary objects:objects];
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }];
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (weakSelf)
            {
                // TODO: error
                if (completionBlock)
                {
                    completionBlock();
                }
            }
        }];
}

- (void)handleCommentsLoadResponseForRequest:(DQHTTPRequest *)request JSONDict:(NSDictionary *)JSONDict objects:(NSArray *)objects
{
    [self.collectionViewController stopDisplayingSpinner];
    self.commentsPrevPage = [JSONDict.dq_paginationPage.dq_paginationPreviousPage integerValue];
    self.commentsNextPage = [JSONDict.dq_paginationPage.dq_paginationNextPage integerValue];
    self.comments = [[NSMutableOrderedSet alloc] init];
    [self.comments addObjectsFromArray:objects ?: @[]];
    [self reloadData];
}

- (void)loadQuests:(dispatch_block_t)completionBlock
{
    if (self.quests && !completionBlock)
    {
        return;
        // FIXME: I hate early returns but this is just to have a clean diff
        // after 3.0 ships, refactor this to be if (!self.quests || completionBlock) { do stuff }
    }

    if ( ! self.quests)
    {
        [self.collectionViewController startDisplayingSpinner];
    }
        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestQuestsForUsername:self.userName page:nil completionBlock:^(DQHTTPRequest *request) {
            if (weakSelf)
            {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:responseDictionary.dq_quests inBackground:YES resultsBlock:^(NSArray *objects) {
                    [weakSelf handleQuestsLoadResponseForRequest:request JSONDict:responseDictionary objects:objects];
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }];
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (weakSelf)
            {
                // TODO: Error
                if (completionBlock)
                {
                    completionBlock();
                }
            }
        }];
}

- (void)handleQuestsLoadResponseForRequest:(DQHTTPRequest *)request JSONDict:(NSDictionary *)JSONDict objects:(NSArray *)objects
{
    [self.collectionViewController stopDisplayingSpinner];
    self.questsPrevPage = [JSONDict.dq_paginationPage.dq_paginationPreviousPage integerValue];
    self.questsNextPage = [JSONDict.dq_paginationPage.dq_paginationNextPage integerValue];
    self.quests = [[NSMutableOrderedSet alloc] init];
    [self.quests addObjectsFromArray:objects ?: @[]];
    [self reloadData];
}

- (void)loadFollowing:(dispatch_block_t)completionBlock
{
    if (self.following && !completionBlock) // this is when we're just switching segments
    {
        return;
        // FIXME: I hate early returns but this is just to have a clean diff
        // after 3.0 ships, refactor this to be if (!self.following || completionBlock) { do stuff }
    }

    if (self.followingRequest) // don't load while already loading
    {
        if (completionBlock)
        {
            completionBlock();
        }
        return;
    }

    if ( ! self.following)
    {
        [self.collectionViewController startDisplayingSpinner];
    }
        __weak typeof(self) weakSelf = self;
        self.followingRequest = [self.publicServiceController requestFollowingForUserName:self.userName withCompletionBlock:^(DQHTTPRequest *request, NSArray *objects) {
            if (weakSelf)
            {
                weakSelf.followingRequest = nil;
                [weakSelf.collectionViewController stopDisplayingSpinner];
                weakSelf.following = [objects mutableCopy];
                self.followingNextPage = request.dq_responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                [weakSelf reloadData];
                if (completionBlock)
                {
                    completionBlock();
                }
            }
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.followingRequest = nil;
            [weakSelf.collectionViewController stopDisplayingSpinner];
            if (completionBlock)
            {
                completionBlock();
            }
        }];
}

- (void)loadFollowers:(dispatch_block_t)completionBlock
{
    if (self.followers && !completionBlock) // this is when we're just switching segments
    {
        return;
        // FIXME: I hate early returns but this is just to have a clean diff
        // after 3.0 ships, refactor this to be if (!self.followers || completionBlock) { do stuff }
    }

    if (self.followersRequest) // don't load while already loading
    {
        if (completionBlock)
        {
            completionBlock();
        }
        return;
    }

    if ( ! self.followers)
    {
        [self.collectionViewController startDisplayingSpinner];
    }
        __weak typeof(self) weakSelf = self;
        self.followersRequest = [self.publicServiceController requestFollowersForUserName:self.userName withCompletionBlock:^(DQHTTPRequest *request, NSArray *objects) {
            if (weakSelf)
            {
                weakSelf.followersRequest = nil;
                [weakSelf.collectionViewController stopDisplayingSpinner];
                self.followers = [objects mutableCopy];
                self.followersNextPage = request.dq_responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                [weakSelf reloadData];
                if (completionBlock)
                {
                    completionBlock();
                }
            }
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.followersRequest = nil;
            [weakSelf.collectionViewController stopDisplayingSpinner];
            if (completionBlock)
            {
                completionBlock();
            }
        }];
}

#pragma mark - Notifications

- (void)usersUpdated:(NSNotification *)inNotification
{
    [self updateUserFromCache];
}

- (void)profileUpdated:(NSNotification *)inNotification
{
    [self refreshProfileInfo:nil];
}

- (void)coinBalanceUpdated:(NSNotification *)inNotification
{
    self.headerView.coinsLabel.text = [self.user.coinCount stringValue];
}

- (void)commentFlagged:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.comments containsObject:comment])
    {
        [self.comments removeObject:comment];
    }
    [self reloadData];
}

- (void)commentDeleted:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.comments containsObject:comment])
    {
        [self.comments removeObject:comment];
    }
    [self reloadData];
}

- (void)commentUploadCompleted:(NSNotification *)notification
{
    if ([self.userName isEqualToString:self.loggedInAccount.username])
    {
        DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];

        [self.comments addObject:comment];
        if (self.segmentedControl.selectedSegmentIndex == 0)
        {
            [self reloadData];
        }
    }
}

- (void)questUploadCompleted:(NSNotification *)notification
{
    if ([self.userName isEqualToString:self.loggedInAccount.username])
    {
        DQQuest *quest = [[notification userInfo] objectForKey:DQQuestObjectNotificationKey];

        [self.quests addObject:quest];
        if (self.segmentedControl.selectedSegmentIndex == 1)
        {
            [self reloadData];
        }
    }
}

#pragma mark - Error Handling

- (void)showError:(NSError *)inError
{
    [self showErrorWithTitle:nil andDescription:inError.dq_displayDescription];
}

- (void)showErrorWithTitle:(NSString *)inTitle andDescription:(NSString *)inDescription
{
    if (!inTitle) {
        inTitle = DQLocalizedString(@"Error", @"Generic error alert title");
    }

    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:inTitle message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [errorAlert show];
}

#pragma mark - DQSegmentedCollectionViewControllerDataSource Methods

- (BOOL)contentIsPaginatedInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    return YES;
}

- (BOOL)hasMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    NSInteger selectedIndex = self.segmentedControl.selectedSegmentIndex;
    if (selectedIndex == 0)
    {
        return self.commentsNextPage > 0;
    }
    else if (selectedIndex == 1)
    {
        return self.questsNextPage > 0;
    }
    else if (selectedIndex == 2)
    {
        return self.followingNextPage != nil;
    }
    else if (selectedIndex == 3)
    {
        return self.followersNextPage != nil;
    }
    return NO;
}

- (void)loadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    NSInteger selectedIndex = self.segmentedControl.selectedSegmentIndex;
    if (selectedIndex == 0)
    {
        [self commentsLoadMorePaginatedContentInCollectionViewController:viewController];
    }
    else if (selectedIndex == 1)
    {
        [self questsLoadMorePaginatedContentInCollectionViewController:viewController];
    }
    else if (selectedIndex == 2)
    {
        [self followingLoadMorePaginatedContentInCollectionViewController:viewController];
    }
    else if (selectedIndex == 3)
    {
        [self followersLoadMorePaginatedContentInCollectionViewController:viewController];
    }
}

- (void)commentsLoadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    // FIXME: remove this, we don't have failure handling in pagination yet
    if (self.commentsNextPageFailedToLoad)
    {
        self.commentsNextPageFailedToLoad = NO;
    }

    if ( ! (self.commentsNextPage == 0 || self.commentsNextPageRequest || self.commentsNextPageFailedToLoad))
    {
        NSLog(@"requesting next page");
        NSInteger page = self.commentsNextPage;

        __weak typeof(self) weakSelf = self;
        self.commentsNextPageRequest = [self.publicServiceController requestCommentsForUsername:self.userName page:@(page) completionBlock:^(DQHTTPRequest *request) {
            weakSelf.commentsNextPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;

            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    [weakSelf.comments addObjectsFromArray:objects];
                }

                NSInteger nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];
                weakSelf.commentsNextPage = (weakSelf.commentsNextPage || nextPage) ? nextPage : 0;

                weakSelf.commentsNextPageRequest = nil;
                [viewController loadingMorePaginatedContentCompleted];
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.commentsNextPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.commentsNextPageRequest = nil;
            [viewController loadingMorePaginatedContentFailed];
        }];
    }
}

- (void)questsLoadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    // FIXME: remove this, we don't have failure handling in pagination yet
    if (self.questsNextPageFailedToLoad)
    {
        self.questsNextPageFailedToLoad = NO;
    }

    if ( ! (self.questsNextPage == 0 || self.questsNextPageRequest || self.questsNextPageFailedToLoad))
    {
        NSLog(@"requesting next page");
        NSInteger page = self.questsNextPage;

        __weak typeof(self) weakSelf = self;
        self.questsNextPageRequest = [self.publicServiceController requestQuestsForUsername:self.userName page:@(page) completionBlock:^(DQHTTPRequest *request) {
            weakSelf.questsNextPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *questList = responseDictionary.dq_quests;

            [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:questList inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    [weakSelf.quests addObjectsFromArray:objects];
                }

                NSInteger nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];
                weakSelf.questsNextPage = (weakSelf.questsNextPage || nextPage) ? nextPage : 0;

                weakSelf.questsNextPageRequest = nil;
                [viewController loadingMorePaginatedContentCompleted];
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.questsNextPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.questsNextPageRequest = nil;
            [viewController loadingMorePaginatedContentFailed];
        }];
    }
}

- (void)followingLoadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    // FIXME: remove this, we don't have failure handling in pagination yet
    if (self.followingNextPageFailedToLoad)
    {
        self.followingNextPageFailedToLoad = NO;
    }

    if ( ! (self.followingNextPage == nil || self.followingNextPageRequest || self.followingNextPageFailedToLoad))
    {
        NSLog(@"requesting next page");
        NSString *page = self.followingNextPage;

        __weak typeof(self) weakSelf = self;
        self.followingNextPageRequest = [self.publicServiceController requestFollowingForUserName:self.userName offset:page withCompletionBlock:^(DQHTTPRequest *request, NSArray *objects) {
            weakSelf.followingNextPageFailedToLoad = NO;
            if ([objects count])
            {
                [weakSelf.following addObjectsFromArray:objects];
                NSString *nextPage = request.dq_responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                weakSelf.followingNextPage = (weakSelf.followingNextPage || nextPage) ? nextPage : nil;
            }
            weakSelf.followingNextPageRequest = nil;
            [viewController loadingMorePaginatedContentCompleted];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.followingNextPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.followingNextPageRequest = nil;
            [viewController loadingMorePaginatedContentFailed];
        }];
    }
}

- (void)followersLoadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    // FIXME: remove this, we don't have failure handling in pagination yet
    if (self.followersNextPageFailedToLoad)
    {
        self.followersNextPageFailedToLoad = NO;
    }

    if ( ! (self.followersNextPage == nil || self.followersNextPageRequest || self.followersNextPageFailedToLoad))
    {
        NSLog(@"requesting next page");
        NSString *page = self.followersNextPage;

        __weak typeof(self) weakSelf = self;
        self.followersNextPageRequest = [self.publicServiceController requestFollowersForUserName:self.userName offset:page withCompletionBlock:^(DQHTTPRequest *request, NSArray *objects) {
            weakSelf.followersNextPageFailedToLoad = NO;
            if ([objects count])
            {
                [weakSelf.followers addObjectsFromArray:objects];
                NSString *nextPage = request.dq_responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                weakSelf.followersNextPage = (weakSelf.followersNextPage || nextPage) ? nextPage : nil;
            }
            weakSelf.followersNextPageRequest = nil;
            [viewController loadingMorePaginatedContentCompleted];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.followersNextPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.followersNextPageRequest = nil;
            [viewController loadingMorePaginatedContentFailed];
        }];
    }
}

#pragma mark - DQSegmentedCollectionViewControllerDataSource Methods

- (UIView *)segmentedControlForCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    DQQuantifiedSegmentedControl *segmentedControl = [[DQQuantifiedSegmentedControl alloc] initWithItems:@[DQLocalizedString(@"Drawings", @"Label for a colleciton of drawings"), DQLocalizedString(@"Quests", @"Label for a colleciton of Quests"), DQLocalizedStringWithDefaultValue(@"FollowingUserListLabel", nil, nil, @"Following", @"Label for a collection of users following a particular user"), DQLocalizedString(@"Followers", @"Label for a collection of users a particular user is following")]];
    segmentedControl.delegate = self;
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.frameHeight = kDQQuantifiedSegmentedControlDesiredHeight;
    self.segmentedControl = segmentedControl;
    return segmentedControl;
}

- (NSInteger)collectionViewController:(DQSegmentedCollectionViewController *)viewController numberOfItemsInSection:(NSInteger)section
{
    NSInteger selectedIndex = self.segmentedControl.selectedSegmentIndex;
    NSInteger count = 0;
    if (selectedIndex == 0)
    {
        count = [self.comments count];
    }
    else if (selectedIndex == 1)
    {
        count = [self.quests count];
    }
    else if (selectedIndex == 2)
    {
        count = [self.following count];
    }
    else if (selectedIndex == 3)
    {
        count = [self.followers count];
    }
    return count;
}

- (UICollectionViewCell *)collectionViewController:(DQSegmentedCollectionViewController *)viewController cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectedIndex = self.segmentedControl.selectedSegmentIndex;
    if (selectedIndex == 0)
    {
        // Comments
        DQCommentGridCollectionViewCell *cell = [viewController.collectionView dequeueReusableCellWithReuseIdentifier:DQPhoneProfileViewControllerThumbnailCell forIndexPath:indexPath];
        if ([self.comments count] > indexPath.item)
        {
            DQComment *comment = [self.comments objectAtIndex:indexPath.item];
            cell.imageView.imageURL = [comment imageURLForKey:DQImageKeyArchive];
            __weak typeof(self) weakSelf = self;
            cell.cellTappedBlock = ^{
                [weakSelf showDrawingDetailForComment:comment source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Profile"] : @"Profile") completionBlock:nil failureBlock:^(NSError *error) {
                    // FIXME: implement
                }];
            };
        }
        return cell;
    }
    else if (selectedIndex == 1)
    {
        // Quests
        DQCollectionViewQuestCell *cell = [viewController.collectionView dequeueReusableCellWithReuseIdentifier:DQPhoneProfileViewControllerQuestCell forIndexPath:indexPath];
        if ([self.quests count] > indexPath.item)
        {
            DQQuest *quest = [self.quests objectAtIndex:indexPath.item];
            cell.questTemplateImageView.imageURL = [quest imageURLForKey:DQImageKeyArchive];
            cell.questTitleLabel.text = quest.title;
            cell.hasDivider = YES;
            __weak typeof(self) weakSelf = self;
            cell.cellTappedBlock = ^(DQCollectionViewCell *cell) {
                [weakSelf showGalleryForQuest:quest source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Profile"] : @"Profile")];
            };
        }
        return cell;
    }
    else if (selectedIndex == 2 || selectedIndex == 3)
    {
        // Following and Followers
        NSArray *users = (selectedIndex == 2) ? self.following : self.followers;
        DQCollectionViewUserCell *cell = [viewController.collectionView dequeueReusableCellWithReuseIdentifier:DQPhoneProfileViewControllerUserCell forIndexPath:indexPath];
        if ([users count] > indexPath.item)
        {
            NSDictionary *userInfo = [users objectAtIndex:indexPath.item];
            NSString *username = userInfo.dq_userName;
            cell.avatarImageView.imageURL = userInfo.dq_galleryUserAvatarURL;
            cell.usernameLabel.text = username;
            __weak typeof(self) weakSelf = self;
            cell.cellTappedBlock = ^{
                [weakSelf showProfileForUsername:username source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Profile"] : @"Profile")];
            };
            BOOL userIsMe = [username isEqualToString:self.loggedInAccount.username];
            if (!userIsMe && ((selectedIndex == 3) || !self.isForLoggedInUser))
            {
                [cell displayFollowButtonForUsername:username];
            }
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

#pragma mark - DQQuantifiedSegmentedControlDelegate Methods

- (void)segmentedControl:(DQQuantifiedSegmentedControl *)segmentedControl didSelectSegmentAtIndex:(NSInteger)index
{
    [self.collectionViewController stopDisplayingSpinner];
    if (index == 0)
    {
        [self logEvent:(self.isForLoggedInUser ? DQAnalyticsEventViewMyProfileDrawings : DQAnalyticsEventViewOtherProfileDrawings) withParameters:@{@"source": (self.source ? [self.source stringByAppendingString:@"/Profile"] : @"Profile"), @"username": self.userName ?: @"unknown"}];
        // Grid Layout
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewController.collectionViewLayout;
        layout.itemSize = CGSizeMake(kDQFormPhoneThumbnailWidth, kDQFormPhoneThumbnailHeight);
        layout.sectionInset = UIEdgeInsetsMake(10.0f, 6.0f, 10.0f, 6.0f);
        layout.minimumLineSpacing = 10.0f;
        layout.minimumInteritemSpacing = 10.0f;
    }
    else if (index == 1)
    {
        [self logEvent:(self.isForLoggedInUser ? DQAnalyticsEventViewMyProfileQuests : DQAnalyticsEventViewOtherProfileQuests) withParameters:@{@"source": (self.source ? [self.source stringByAppendingString:@"/Profile"] : @"Profile"), @"username": self.userName ?: @"unknown"}];
        // Quest List Layout
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewController.collectionViewLayout;
        layout.itemSize = CGSizeMake(kDQCollectionViewQuestCellWidth, kDQCollectionViewQuestCellHeight);
        layout.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        layout.minimumLineSpacing = 0.0f;
        layout.minimumInteritemSpacing = 0.0f;
    }
    else if (index == 2 || index == 3)
    {
        [self logEvent:(self.isForLoggedInUser ? DQAnalyticsEventViewMyProfileUserList : DQAnalyticsEventViewOtherProfileUserList) withParameters:@{@"source": (self.source ? [self.source stringByAppendingString:@"/Profile"] : @"Profile"), @"type": ((index == 3) ? @"followers" : @"following"), @"username": self.userName ?: @"unknown"}];
        // User List Layout
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewController.collectionViewLayout;
        layout.itemSize = CGSizeMake(kDQCollectionViewUserCellWidth, kDQCollectionViewUserCellHeight);
        layout.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        layout.minimumLineSpacing = 0.0f;
        layout.minimumInteritemSpacing = 0.0f;
    }
    [self loadForSelectedSegmentIndex:index completionBlock:nil];
    [self reloadData];
}

@end

@implementation DQPhoneProfileErrorView : DQPhoneErrorView

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
        case DQPhoneErrorViewTypeRequestFailed:
        default:
            return DQLocalizedString(@"We couldn't load the profile. Please try again.", @"Prompt to retry a failed attempt to load the current profile from the server");
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
