//
//  DQPhoneHomeViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneHomeViewController.h"
#import "UIScrollView+SVPullToRefresh.h"

// Models
#import "DQAccount.h"

// Controllers
#import "DQCommentsCollectionViewController.h"
#import "DQPrivateServiceController.h"
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"

// Views
#import "DQSegmentedControl.h"
#import "DQPhoneErrorView.h"
#import "DQAlertView.h"
#import "DQReusableBannerView.h"
#import "DQCommentListCollectionViewCell.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"

NSString *const DQPhoneHomeViewControllerClearBadgeNotification = @"DQPhoneHomeViewControllerClearBadgeNotification";

typedef NS_ENUM(NSInteger, DQPhoneHomeErrorViewType) {
    DQPhoneHomeErrorViewTypeFollowing,
    DQPhoneHomeErrorViewTypeExplore
};

static NSString *DQPhoneHomeViewControllerBannerCell = @"bannerCell";

@interface DQPhoneHomeErrorView : DQPhoneErrorView

@property (nonatomic, assign) DQPhoneHomeErrorViewType *segmentType;
@property (nonatomic, assign) BOOL hasUserEverLoggedIn;

@end

@interface DQPhoneHomeViewController () <DQCommentsCollectionViewControllerDataSource, DQCommentsCollectionViewControllerDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *comments;
@property (nonatomic, strong) NSMutableOrderedSet *commentUploads;
@property (nonatomic, strong) NSMutableOrderedSet *exploreComments;
@property (nonatomic, strong) DQCommentsCollectionViewController *collectionViewController;
@property (nonatomic, weak) DQPhoneHomeErrorView *errorView;
@property (nonatomic, weak) UIView *whiteSpaceView;
@property (nonatomic, assign) NSInteger segmentIndex;

@property (nonatomic, weak) DQHTTPRequest *loadFollowingCommentsRequest;
@property (nonatomic, weak) DQHTTPRequest *loadExploreCommentsRequest;
// Following pagination
@property (nonatomic, assign) BOOL nextPageFailedToLoad;
@property (nonatomic, assign) BOOL prevPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *nextPageRequest;
@property (nonatomic, weak) DQHTTPRequest *prevPageRequest;
@property (nonatomic, copy) NSString *nextPage;
// Explore pagination
@property (nonatomic, assign) BOOL explorePrevPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *explorePrevPageRequest;

@end

@implementation DQPhoneHomeViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    DQPhoneHomeErrorView *errorView = [[DQPhoneHomeErrorView alloc] initWithFrame:CGRectZero];
    errorView.hasUserEverLoggedIn = self.hasUserEverLoggedIn;
    self.errorView = errorView;
    
    // Set up Collection View Controller
    self.collectionViewController = [[DQCommentsCollectionViewController alloc] initWithHeaderView:nil errorView:errorView];
    self.collectionViewController.delegate = self;
    self.collectionViewController.dataSource = self;
    __weak typeof(self) weakSelf = self;
    self.collectionViewController.showDrawingDetailBlock = ^(DQComment *comment) {
        [weakSelf showDrawingDetailForComment:comment source:(weakSelf.segmentIndex == 0 ? @"Home/Following" : @"Home/Explore") completionBlock:nil failureBlock:^(NSError *error) {
            // FIXME: implement
        }];
    };
    self.collectionViewController.imageTappedBlock = ^(DQComment *comment, UIView *imageView) {
        [weakSelf showZoomableImageForComment:comment fromView:imageView];
    };
    self.collectionViewController.playbackBlock = ^(DQButton *playbackButton, DQPlaybackImageView *playbackImageView, DQComment *comment) {
        [weakSelf tappedPlaybackButton:playbackButton forPlaybackImageView:playbackImageView comment:comment withRequestFinishedBlock:^(DQComment *newComment) {
            // Refresh with the updated comment to show the new note count
            if (newComment)
            {
                NSUInteger index = NSNotFound;
                if (weakSelf.segmentIndex == 0)
                {
                    index = [weakSelf.comments indexOfObject:comment];
                    if (index != NSNotFound)
                    {
                        weakSelf.comments[index] = newComment;
                        [weakSelf.collectionViewController updateNoteCountForCommentAtIndex:index];
                    }
                }
                else if (weakSelf.segmentIndex == 1)
                {
                    index = [weakSelf.exploreComments indexOfObject:comment];
                    if (index != NSNotFound)
                    {
                        weakSelf.exploreComments[index] = newComment;
                        [weakSelf.collectionViewController updateNoteCountForCommentAtIndex:index];
                    }
                }
            }
        }];
    };
    self.collectionViewController.cancelCommentUploadBlock = ^(DQCommentUpload *commentUpload, UIButton *sender) {
        [weakSelf tappedCancelButton:sender forCommentUpload:commentUpload withDeletionBlock:^{
            [weakSelf.commentUploads removeObject:commentUpload];
            [weakSelf reloadData];
        }];
    };
    self.collectionViewController.retryCommentUploadBlock = ^(DQCommentUpload *commentUpload, UIButton *sender) {
        [weakSelf tappedRetryButton:sender forCommentUpload:commentUpload];
    };
    self.collectionViewController.showMoreOptionsBlock = ^(DQComment *comment) {
        // Notifications will take care of removing flagged or deleted drawings
        [weakSelf tappedMoreOptionsButtonForComment:comment source:(weakSelf.segmentIndex == 0 ? @"Home/Following" : @"Home/Explore")];
    };
    self.collectionViewController.showUserProfileBlock = ^(DQComment *comment) {
        [weakSelf showProfileForUsername:comment.authorName source:(weakSelf.segmentIndex == 0 ? @"Home/Following" : @"Home/Explore")];
    };
    self.collectionViewController.shareCommentBlock = ^(DQComment *comment) {
        [weakSelf tappedShareButtonForComment:comment source:@"Home"];
    };
    self.collectionViewController.commentViewedBlock = ^(DQCommentsCollectionViewController *cvc, NSString *commentID) {
        if (weakSelf.commentViewedBlock)
        {
            weakSelf.commentViewedBlock(weakSelf, commentID);
        }
    };
    [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl];

    // Banner
    [self.collectionViewController.collectionView registerClass:[DQReusableBannerView class] forCellWithReuseIdentifier:DQPhoneHomeViewControllerBannerCell];

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];
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

- (void)sendClearBadgeNotification
{
    self.shouldSendClearBadgeNotification = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPhoneHomeViewControllerClearBadgeNotification object:nil userInfo:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewHome withParameters:nil];
    [self addPullToRefresh];

    if (self.shouldSendClearBadgeNotification && (self.segmentIndex == 0) && self.collectionViewController.collectionView.contentOffset.y <= 30.0)
    {
        [self sendClearBadgeNotification];
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
    [self resetView];
}

- (void)resetView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    self.commentUploads = nil;
    self.comments = nil;
    self.exploreComments = nil;
    self.collectionViewController = nil;
    self.nextPage = nil;
    self.prevPageRequest = nil;
    self.nextPageRequest = nil;
    self.nextPageFailedToLoad = NO;
    self.prevPageFailedToLoad = NO;
    self.explorePrevPageRequest = nil;
    self.explorePrevPageFailedToLoad = NO;
    self.view = nil;
}

- (void)addPullToRefresh
{
    __weak typeof(self) weakSelf = self;
    [self setPullToRefreshOffset];
    [self.collectionViewController.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf loadNewerPaginatedContent:^{
            [weakSelf.collectionViewController.collectionView.pullToRefreshView stopAnimating];
        }];
    }];
}

- (void)setDisplayStatus:(DQSegmentedCollectionViewControllerStatus)displayStatus
{
    self.collectionViewController.collectionView.contentInset = UIEdgeInsetsZero;
    self.collectionViewController.displayStatus = displayStatus;
    [self.view setNeedsLayout];
}

#pragma mark -

- (void)commentFlagged:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.comments containsObject:comment])
    {
        [self.comments removeObject:comment];
    }
    if ([self.exploreComments containsObject:comment])
    {
        [self.exploreComments removeObject:comment];
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
    if ([self.exploreComments containsObject:comment])
    {
        [self.exploreComments removeObject:comment];
    }
    [self reloadData];
}

- (void)reloadData
{
    [self.collectionViewController reloadData];
}

- (void)loadFollowingComments
{
    if (!self.loggedIn)
    {
        return; // FIXME: no early returns, it's like this so that the diff is easy.
    }
    if (!self.loadFollowingCommentsRequest)
    {
        if ( ! self.comments)
        {
            [self.collectionViewController startDisplayingSpinner];
        }
        __weak typeof(self) weakSelf = self;
        double timestamp = [[NSDate date] timeIntervalSince1970];
        self.loadFollowingCommentsRequest = [self.privateServiceController requestCommentsForFolloweeFeedWithCompletionBlock:^(DQHTTPRequest *request) {
            weakSelf.loggedInAccount.homeTabBadgeTimestamp = @(timestamp);
            [weakSelf handleFeedLoadResponseForRequest:request completionBlock:^{
                weakSelf.loadFollowingCommentsRequest = nil;
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            [weakSelf handleFeedLoadResponseForRequest:request completionBlock:^{
                weakSelf.loadFollowingCommentsRequest = nil;
            }];
        }];
    }
}

- (void)loadExploreComments
{
    if (!self.loadExploreCommentsRequest)
    {
        if ( ! self.exploreComments)
        {
            [self.collectionViewController startDisplayingSpinner];
        }
        __weak typeof(self) weakSelf = self;
        self.loadExploreCommentsRequest = [self.publicServiceController requestExploreCommentsWithCompletionBlock:^(DQHTTPRequest *request) {
            [weakSelf.collectionViewController stopDisplayingSpinner];
            [weakSelf handleExploreLoadResponseForRequest:request completionBlock:^{
                weakSelf.loadExploreCommentsRequest = nil;
            }];
        }];
    }
}

- (void)displayPhoneErrorViewTypeLoginRequired
{
    __weak typeof(self) weakSelf = self;
    self.errorView.errorType = DQPhoneErrorViewTypeLoginRequired;
    self.errorView.segmentType = DQPhoneHomeErrorViewTypeFollowing;
    self.errorView.buttonTappedBlock = ^{
        [weakSelf requestAuthenticationWithCancellationBlock:nil completionBlock:^(DQAuthenticationSignupService service, DQNavigationController *modalNavigationController) {
            [weakSelf loadFollowingComments];
        } failureBlock:^(NSError *error) {
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Authentication Error", @"Authentication error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
        }];
    };
    [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl | DQSegmentedCollectionViewControllerStatusDisplayErrorView];
}

- (void)handleFeedLoadResponseForRequest:(DQHTTPRequest *)request completionBlock:(dispatch_block_t)completionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.collectionViewController stopDisplayingSpinner];
    if (request.error && self.segmentIndex == 0)
    {
        if (self.loggedIn)
        {
            self.errorView.errorType = DQPhoneErrorViewTypeRequestFailed;
            self.errorView.segmentType = DQPhoneHomeErrorViewTypeFollowing;
            self.errorView.buttonTappedBlock = ^{
                [weakSelf loadFollowingComments];
            };
            [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl | DQSegmentedCollectionViewControllerStatusDisplayErrorView];
        }
        else
        {
            [self displayPhoneErrorViewTypeLoginRequired];
        }
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *commentList = responseDictionary.dq_comments;
        [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
            if ([objects count])
            {
                weakSelf.nextPage = responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                if (weakSelf.comments)
                {
                    [weakSelf.comments addObjectsFromArray:objects ?: @[]];
                }
                else
                {
                    weakSelf.comments = [[NSMutableOrderedSet alloc] initWithArray:objects ?: @[]];
                }
                if (self.segmentIndex == 0)
                {
                    [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl];
                    [weakSelf reloadData];
                }
            }
            else
            {
                if (self.segmentIndex == 0)
                {
                    // Make sure we wipe out following in this case (we might have unfollowed everyone)
                    weakSelf.comments = [[NSMutableOrderedSet alloc] init];
                    // Get rid of "Loading..." below error view if we dropped content
                    weakSelf.nextPage = nil;

                    // Sparse view
                    weakSelf.errorView.errorType = DQPhoneErrorViewTypeEmpty;
                    weakSelf.errorView.segmentType = DQPhoneHomeErrorViewTypeFollowing;
                    weakSelf.errorView.buttonTappedBlock = ^{
                        if (weakSelf.presentAddFriendsBlock)
                        {
                            weakSelf.presentAddFriendsBlock(weakSelf);
                        }
                    };
                    [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl | DQSegmentedCollectionViewControllerStatusDisplayErrorView];
                }
            }
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
}

- (void)handleExploreLoadResponseForRequest:(DQHTTPRequest *)request completionBlock:(dispatch_block_t)completionBlock
{
    __weak typeof(self) weakSelf = self;
    if (request.error && self.segmentIndex == 1)
    {
        self.errorView.errorType = DQPhoneErrorViewTypeRequestFailed;
        self.errorView.segmentType = DQPhoneHomeErrorViewTypeExplore;
        self.errorView.buttonTappedBlock = ^{
            [weakSelf loadExploreComments];
        };
        [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl | DQSegmentedCollectionViewControllerStatusDisplayErrorView];
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *commentList = responseDictionary.dq_comments;
        [self.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
            if ([objects count])
            {
                weakSelf.exploreComments = [[NSMutableOrderedSet alloc] initWithArray:objects ?: @[]];
                if (weakSelf.segmentIndex == 1)
                {
                    [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl];
                    [weakSelf reloadData];
                }
            }
            else
            {
                if (weakSelf.segmentIndex == 1)
                {
                    weakSelf.errorView.errorType = DQPhoneErrorViewTypeEmpty;
                    weakSelf.errorView.segmentType = DQPhoneHomeErrorViewTypeExplore;
                    weakSelf.errorView.buttonTappedBlock = nil;
                    [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl | DQSegmentedCollectionViewControllerStatusDisplayErrorView];
                }
            }
            if (completionBlock)
            {
                completionBlock();
            }
        }];
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
    return self.segmentIndex == 0;
}

- (BOOL)hasMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    return self.nextPage != nil;
}

- (void)loadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    // FIXME: remove this, we don't have failure handling in pagination yet
    if (self.nextPageFailedToLoad)
    {
        self.nextPageFailedToLoad = NO;
    }

    if (self.nextPage == nil || self.nextPageRequest || self.nextPageFailedToLoad || self.prevPageRequest || self.loadFollowingCommentsRequest)
    {
        [viewController loadingMorePaginatedContentCompleted];
    }
    else
    {
        NSLog(@"requesting next page");
        NSString *page = self.nextPage;

        __weak typeof(self) weakSelf = self;
        self.nextPageRequest = [self.privateServiceController requestCommentsForFolloweeFeedWithOffset:page direction:DQOffsetDirectionNext completionBlock:^(DQHTTPRequest *request) {
            weakSelf.nextPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;

            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    [weakSelf.comments addObjectsFromArray:objects];
                    NSString *nextPage = responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                    weakSelf.nextPage = (weakSelf.nextPage || nextPage) ? nextPage : nil;
                }

                weakSelf.nextPageRequest = nil;
                [viewController loadingMorePaginatedContentCompleted];
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.nextPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.nextPageRequest = nil;
            [viewController loadingMorePaginatedContentFailed];
        }];
    }
}

- (void)loadNewerPaginatedContent:(dispatch_block_t)completionBlock
{
    if (self.segmentIndex == 0)
    {
        [self followingLoadNewerPaginatedContent:completionBlock];
    }
    else
    {
        [self exploreLoadNewerPaginatedContent:completionBlock];
    }
}

- (void)followingLoadNewerPaginatedContent:(dispatch_block_t)completionBlock
{
    // FIXME: remove this, we don't have failure handling yet
    if (self.prevPageFailedToLoad)
    {
        self.prevPageFailedToLoad = NO;
    }

    if (self.prevPageRequest || self.prevPageFailedToLoad || self.nextPageRequest)
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        NSLog(@"requesting previous page");

        __weak typeof(self) weakSelf = self;
        double timestamp = [[NSDate date] timeIntervalSince1970];
        self.prevPageRequest = [self.privateServiceController requestCommentsForFolloweeFeedWithCompletionBlock:^(DQHTTPRequest *request) {
            weakSelf.loggedInAccount.homeTabBadgeTimestamp = @(timestamp);
            weakSelf.prevPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;

            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    DQComment *oldFirst = [weakSelf.comments firstObject];
                    DQComment *newFirst = [objects firstObject];
                    if (! [newFirst.serverID isEqualToString:oldFirst.serverID])
                    {
                        weakSelf.comments = [[NSMutableOrderedSet alloc] initWithArray:objects ?: @[]];
                        weakSelf.nextPage = responseDictionary.dq_paginationPage.dq_paginationNextPageString;
                        if (weakSelf.segmentIndex == 0)
                        {
                            [weakSelf reloadData];
                        }
                    }
                }

                weakSelf.prevPageRequest = nil;
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.prevPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.prevPageRequest = nil;
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
}

- (void)exploreLoadNewerPaginatedContent:(dispatch_block_t)completionBlock
{
    // FIXME: remove this, we don't have failure handling yet
    if (self.explorePrevPageFailedToLoad)
    {
        self.explorePrevPageFailedToLoad = NO;
    }

    if (self.explorePrevPageRequest || self.explorePrevPageFailedToLoad)
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        NSLog(@"re-requesting explore page");

        __weak typeof(self) weakSelf = self;
        self.explorePrevPageRequest = [self.publicServiceController requestExploreCommentsWithCompletionBlock:^(DQHTTPRequest *request) {
            weakSelf.explorePrevPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;

            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    weakSelf.exploreComments = [[NSMutableOrderedSet alloc] initWithArray:objects ?: @[]];
                    if (weakSelf.segmentIndex == 1)
                    {
                        [weakSelf reloadData];
                    }
                }

                weakSelf.explorePrevPageRequest = nil;
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.explorePrevPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            weakSelf.explorePrevPageRequest = nil;
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
}

#pragma mark - DQCommentsCollectionViewControllerDelegate Methods

- (void)collectionViewController:(DQCommentsCollectionViewController *)viewController didSelectSegmentIndex:(NSUInteger)index
{
    [self.collectionViewController stopDisplayingSpinner];
    self.segmentIndex = index;
    if (index == 0)
    {
        [self logEvent:DQAnalyticsEventViewHomeFollowing withParameters:nil];
        [self loadFollowingComments];
    }
    else if (index == 1)
    {
        [self logEvent:DQAnalyticsEventViewHomeExplore withParameters:nil];
        [self loadExploreComments];
    }
    if (self.loggedIn || (index == 1))
    {
        self.collectionViewController.collectionView.showsPullToRefresh = YES;
        [self setDisplayStatus:DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl];
    }
    else
    {
        self.collectionViewController.collectionView.showsPullToRefresh = NO;
        [self displayPhoneErrorViewTypeLoginRequired];
    }
}

- (void)collectionViewController:(DQCommentsCollectionViewController *)viewController scrollViewDidScroll:(UIScrollView *)scrollView;
{
    // once you're near the top, send the notification
    if (self.shouldSendClearBadgeNotification && (scrollView == self.collectionViewController.collectionView) && scrollView.contentOffset.y <= 30.0)
    {
        [self sendClearBadgeNotification];
    }
}

#pragma mark - DQCommentsCollectionViewControllerDataSource Methods

- (NSInteger)numberOfContentSectionsInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    return 3;
}

- (NSUInteger)defaultSegmentIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    if (self.oneUseDefaultSegmentIndex)
    {
        self.oneUseDefaultSegmentIndex = nil;
        return self.oneUseDefaultSegmentIndex;
    }
    else
    {
        return self.loggedInAccount ? 0 : 1;
    }
}

- (DQSegmentedControlViewOption)defaultViewOptionForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
{
    return DQSegmentedControlViewOptionList;
}

- (NSString *)loggedInUsernameForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return self.loggedInAccount.username;
}

- (NSInteger)collectionViewController:(DQCommentsCollectionViewController *)viewController numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == 0)
    {
        if (self.segmentIndex == 1 && self.shouldPresentAddFriendsBlock && self.loggedIn)
        {
            count = self.shouldPresentAddFriendsBlock(self) ? 1 : 0;
        }
    }
    else if (section == 1)
    {
        count = [self.commentUploads count];
    }
    else if (section == 2)
    {
        if (self.segmentIndex == 0)
        {
            count = [self.comments count];
        }
        else if (self.segmentIndex == 1)
        {
            count = [self.exploreComments count];
        }
    }
    return count;
}

- (DQComment *)collectionViewController:(DQCommentsCollectionViewController *)viewController commentForIndexPath:(NSIndexPath *)indexPath
{
    DQComment *comment = nil;
    if (self.segmentIndex == 0)
    {
        comment = [self.comments objectAtIndex:indexPath.row];
    }
    else if (self.segmentIndex == 1)
    {
        comment = [self.exploreComments objectAtIndex:indexPath.row];
    }
    return comment;
}

- (BOOL)collectionViewController:(DQCommentsCollectionViewController *)viewController replaceCommentAtIndexPath:(NSIndexPath *)indexPath withComment:(DQComment *)newComment
{
    BOOL result = NO;
    NSMutableOrderedSet *set = (self.segmentIndex == 0) ? self.comments : self.exploreComments;
    NSUInteger index = indexPath.item;
    if (index < [set count])
    {
        DQComment *old = set[index];
        if ([old.serverID isEqualToString:newComment.serverID])
        {
            set[index] = newComment;
            result = YES;
        }
    }
    return result;
}

- (DQCommentUpload *)collectionViewController:(DQCommentsCollectionViewController *)viewController commentUploadForIndexPath:(NSIndexPath *)indexPath
{
    return [self.commentUploads objectAtIndex:indexPath.row];
}

- (NSArray *)segmentItemsForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return @[DQLocalizedStringWithDefaultValue(@"FollowingHomeAreaLabel", nil, nil, @"Following", @"Label for the area where the content from followed users will appear"), DQLocalizedString(@"Explore", @"Title for section where users can explore for new content")];
}

#pragma mark - Banner View

- (NSUInteger)commentUploadsSectionIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return 1;
}

- (NSUInteger)commentsSectionIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return 2;
}

- (UICollectionViewCell *)collectionViewController:(DQCommentsCollectionViewController *)viewController cellForUnknownItemAtIndexPath:(NSIndexPath *)indexPath
{
    DQReusableBannerView *cell = nil;
    if (indexPath.section == 0 && self.segmentIndex == 1)
    {
        cell = [viewController.collectionView dequeueReusableCellWithReuseIdentifier:DQPhoneHomeViewControllerBannerCell forIndexPath:indexPath];
        cell.imageView.image = [UIImage imageNamed:@"characters_spot_findFriends"];
        cell.messageLabel.text = DQLocalizedString(@"Find Your Friends on DrawQuest", @"Find your friends from other services that are registered on DrawQuest button title");
        __weak typeof(self) weakSelf = self;
        cell.cellTappedBlock = ^(DQReusableBannerView *cell) {
            if (weakSelf.presentAddFriendsBlock)
            {
                weakSelf.presentAddFriendsBlock(weakSelf);
            }
        };
    }
    return cell;
}

- (CGSize)collectionViewController:(DQSegmentedCollectionViewController *)viewController sizeForUnknownItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;
    if (indexPath.section == 0 && self.segmentIndex == 1)
    {
        size = CGSizeMake(306.0f, 85.0f);
    }
    return size;
}

- (UIEdgeInsets)collectionViewController:(DQSegmentedCollectionViewController *)viewController insetForUnknownSection:(NSInteger)section
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (section == 0 && self.segmentIndex == 1 && [self collectionViewController:viewController numberOfItemsInSection:0])
    {
        insets = UIEdgeInsetsMake(12.0f, 7.0f, 7.0f, 7.0f);
    }
    return insets;
}

- (BOOL)collectionViewController:(DQCommentsCollectionViewController *)viewController shouldDisplayFollowButtonForComment:(DQComment *)comment
{
    return (self.segmentIndex == 1) && (![comment.authorName isEqualToString:self.loggedInAccount.username]);
}

@end

#pragma mark -
#pragma mark Error View

@implementation DQPhoneHomeErrorView

- (void)setSegmentType:(DQPhoneHomeErrorViewType *)segmentType
{
    _segmentType = segmentType;
    [self reloadView];
}

- (UIImage *)image
{
    if (self.segmentType == DQPhoneHomeErrorViewTypeFollowing)
    {
        switch (self.errorType)
        {
            case DQPhoneErrorViewTypeLoginRequired:
                return [UIImage imageNamed:@"tour_avatar_stars_grouped"];
                break;
            default:
                return nil;
                break;
        }
    }
    else
    {
        return nil;
    }
}

- (NSString *)message
{
    if (self.segmentType == DQPhoneHomeErrorViewTypeFollowing)
    {
        switch (self.errorType)
        {
            case DQPhoneErrorViewTypeLoginRequired:
                return self.hasUserEverLoggedIn ? DQLocalizedString(@"Sign In and see what your fellow Questers are drawing!", @"Prompt to sign into an existing DrawQuest account to see what others are drawing") : DQLocalizedString(@"Sign Up and start following other Questers!", @"Prompt to sign up for DrawQuest so they can start following other users");
                break;
            case DQPhoneErrorViewTypeEmpty:
                return DQLocalizedString(@"Follow more Questers and their drawings will appear here!", @"Prompt to follow users so that they can see their drawings on this page");
                break;
            case DQPhoneErrorViewTypeRequestFailed:
            default:
                return DQLocalizedString(@"The request failed. Try again?", @"Prompt to try a failed request once again");
                break;
        }
    }
    else
    {
        switch (self.errorType)
        {
            case DQPhoneErrorViewTypeEmpty:
                return DQLocalizedString(@"This shouldn't be empty. Please try back later!", @"A message explaining that the user is seeing something unexpected and they should try again at a later time");
                break;
            case DQPhoneErrorViewTypeRequestFailed:
            default:
                return DQLocalizedString(@"The request failed. Try again?", @"Prompt to try a failed request once again");
                break;
        }
    }
}

- (NSString *)buttonTitle
{
    if (self.segmentType == DQPhoneHomeErrorViewTypeFollowing)
    {
        switch (self.errorType)
        {
            case DQPhoneErrorViewTypeLoginRequired:
                return self.hasUserEverLoggedIn ? DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account") : DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
                break;
            case DQPhoneErrorViewTypeEmpty:
                return DQLocalizedString(@"Add Friends", @"Title for modal where the user can invite their friends to DrawQuest");
                break;
            case DQPhoneErrorViewTypeRequestFailed:
            default:
                return DQLocalizedString(@"Retry", @"Prompt for a user to attempt a failed connection again.");
                break;
        }
    }
    else
    {
        switch (self.errorType)
        {
            case DQPhoneErrorViewTypeRequestFailed:
            default:
                return DQLocalizedString(@"Retry", @"Prompt for a user to attempt a failed connection again.");
                break;
        }
    }
}

@end
