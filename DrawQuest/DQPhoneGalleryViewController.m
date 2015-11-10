//
//  DQPhoneGalleryViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneGalleryViewController.h"

// Controllers
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"
#import "DQCommentsCollectionViewController.h"

// Views
#import "DQPhoneGalleryHeaderView.h"
#import "DQSegmentedControl.h"
#import "DQAlertView.h"
#import "DQQuestTitleView.h"
#import "DQLoadingView.h"
#import "DQPhoneErrorView.h"
#import "DQCommentListCollectionViewCell.h"

// Models
#import "DQQuest.h"

// Additions
#import "DQAnalyticsConstants.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "DQNotifications.h"

@interface DQPhoneGalleryErrorView : DQPhoneErrorView
@end

@interface DQPhoneGalleryViewController () <DQCommentsCollectionViewControllerDataSource, DQCommentsCollectionViewControllerDelegate>

@property (nonatomic, assign) DQGalleryState state;
@property (nonatomic, readwrite, strong) DQQuest *quest;
@property (nonatomic, strong) NSMutableOrderedSet *commentUploads;
@property (nonatomic, strong) NSMutableOrderedSet *chronComments;
@property (nonatomic, strong) NSMutableOrderedSet *topComments;
@property (nonatomic, assign) BOOL nextPageFailedToLoad;
@property (nonatomic, assign) BOOL prevPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *nextPageRequest;
@property (nonatomic, weak) DQHTTPRequest *prevPageRequest;
@property (nonatomic, assign) NSInteger nextPage;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;
@property (nonatomic, assign) BOOL collectionViewHasLoaded;
@property (nonatomic, assign) BOOL isPublishing;

@property (nonatomic, strong) DQCommentsCollectionViewController *collectionViewController;
@property (nonatomic, weak) UIView *whiteSpaceView;
@property (nonatomic, weak) DQPhoneGalleryHeaderView *headerView;
@property (nonatomic, weak) DQPhoneGalleryErrorView *errorView;
@property (nonatomic, weak) DQLoadingView *loadingView;

@end

@implementation DQPhoneGalleryViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
}

- (id)initWithQuestID:(NSString *)inQuestID focusedCommentID:(NSString *)_ source:(NSString *)source publishing:(BOOL)isPublishing newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithQuestID:inQuestID focusedCommentID:nil source:source publishing:isPublishing newPlaybackDataManager:newPlaybackDataManager delegate:delegate];
    if (self)
    {
        _isPublishing = isPublishing;
        _state = DQGalleryStateStart;
        _selectedSegmentIndex = [self defaultSegmentIndexForCollectionViewController:nil];
    }
    return self;
}

#pragma mark - Finite State Machine

- (void)showErrorForTransition:(DQGalleryTransition)transition
{
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") message:DQLocalizedString(@"An unexpected error occurred", @"Unknown error alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [errorAlert show];
}

- (void)transition:(DQGalleryTransition)transition
{
    [self transition:transition userInfo:nil];
}

- (void)transition:(DQGalleryTransition)transition userInfo:(NSDictionary *)userInfo
{
    if (self.state == DQGalleryStateStart)
    {
        if (transition == DQGalleryTransitionLoadView)
        {
            self.state = DQGalleryStateViewLoaded;
            [self setupViews];
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStatePublishingStart)
    {
        if (transition == DQGalleryTransitionLoadView)
        {
            self.state = DQGalleryStatePublishingViewLoaded;
            [self setupViews];
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStateViewLoaded)
    {
        if (transition == DQGalleryTransitionLoadCommentUploads)
        {
            [self fetchQuestAndCommentUploads];
            self.state = DQGalleryStateCommentUploadsLoaded;
            [self transition:DQGalleryTransitionLoadGallery];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStatePublishingViewLoaded)
    {
        if (transition == DQGalleryTransitionLoadCommentUploads)
        {
            [self fetchQuestAndCommentUploads];
            self.state = DQGalleryStatePublishingCommentUploadsLoaded;
            self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayHeaderView | DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl;
            [self transition:DQGalleryTransitionLoadGallery];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStatePublishingStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStateCommentUploadsLoaded)
    {
        if (transition == DQGalleryTransitionLoadGallery)
        {
            self.state = DQGalleryStateDisplayingLoadingView;
            DQLoadingView *loadingView = [[DQLoadingView alloc] initWithFrame:self.view.bounds];
            [self.view addSubview:loadingView];
            self.loadingView = loadingView;
            [self loadGallery];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStatePublishingCommentUploadsLoaded)
    {
        if (transition == DQGalleryTransitionLoadGallery)
        {
            self.state = DQGalleryStatePublishingDisplayingCommentUploadsLoadingGallery;
            [self reloadData];
            [self loadGallery];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStatePublishingStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStateDisplayingLoadingView)
    {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;

        if (transition == DQGalleryTransitionLoadGallerySucceeded)
        {
            if ([self.commentUploads count] + [[self currentCommentSet] count])
            {
                self.state = DQGalleryStateDisplayingGalleryWithCommentUploads;
                self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayHeaderView | DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl;
                [self displayCollectionView];
                [self reloadData];
            }
            else
            {
                self.state = DQGalleryStateDisplayingSparseView;
                self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayHeaderView | DQSegmentedCollectionViewControllerStatusDisplayErrorView;
                self.errorView.errorType = DQPhoneErrorViewTypeEmpty;
                __weak typeof(self) weakSelf = self;
                self.errorView.buttonTappedBlock = ^{
                    if (weakSelf.showEditorBlock)
                    {
                        weakSelf.showEditorBlock(weakSelf, weakSelf.quest);
                    }
                };
                [self displayCollectionView];
            }
        }
        else if (transition == DQGalleryTransitionLoadGalleryNotFound)
        {
            self.state = DQGalleryStateDisplayingNotFoundErrorView;
            self.errorView.errorType = DQPhoneErrorViewTypeRequestFailed;
            self.errorView.buttonTappedBlock = nil;
            self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayErrorView;
            [self displayCollectionView];
        }
        else if (transition == DQGalleryTransitionLoadGalleryFailed)
        {
            self.state = DQGalleryStateDisplayingRetryView;
            self.errorView.errorType = DQPhoneErrorViewTypeRequestFailed;
            __weak typeof(self) weakSelf = self;
            self.errorView.buttonTappedBlock = ^{
                weakSelf.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayNothing;
                [weakSelf transition:DQGalleryTransitionLoadGallery];
            };
            self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplayErrorView;
            [self displayCollectionView];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStateDisplayingRetryView)
    {
        if (transition == DQGalleryTransitionLoadGallery)
        {
            self.state = DQGalleryStateViewLoaded;
            [self transition:DQGalleryTransitionLoadCommentUploads];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStateDisplayingGalleryWithCommentUploads)
    {
        if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else if (transition == DQGalleryTransitionLoadGallerySucceeded)
        {
            // TEMP Hack: We load in TWO sets of comments now
            [self reloadData];
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStatePublishingDisplayingCommentUploadsLoadingGallery)
    {
        if (transition == DQGalleryTransitionLoadGallerySucceeded)
        {
            self.state = DQGalleryStateDisplayingGalleryWithCommentUploads;
            [self reloadData];
        }
        else if (transition == DQGalleryTransitionLoadGalleryNotFound)
        {
            self.state = DQGalleryStatePublishingDisplayingCommentUploads;
            [self showErrorWithTitle:userInfo[@"errorTitle"]
                      andDescription:((NSError *)userInfo[@"error"]).dq_displayDescription];
        }
        else if (transition == DQGalleryTransitionLoadGalleryFailed)
        {
            self.state = DQGalleryStatePublishingDisplayingCommentUploads;
            [self showErrorWithTitle:DQLocalizedString(@"Unable to Refresh Gallery",  @"Quest gallery refresh failure alert title")
                      andDescription:((NSError *)userInfo[@"error"]).dq_displayDescription];
        }
        else if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if ((self.state == DQGalleryStateDisplayingSparseView) ||
             (self.state == DQGalleryStateDisplayingNotFoundErrorView))
    {
        if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStateStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }


    else if (self.state == DQGalleryStatePublishingDisplayingCommentUploads)
    {
        if (transition == DQGalleryTransitionUnloadView)
        {
            self.state = DQGalleryStatePublishingStart;
        }
        else
        {
            [self showErrorForTransition:transition];
        }
    }

    
    else
    {
        [self showErrorForTransition:transition];
    }
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self transition:DQGalleryTransitionLoadView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    __weak typeof(self) weakSelf = self;
    [self.collectionViewController.collectionView addPullToRefreshWithActionHandler:^{
        [weakSelf loadNewerPaginatedContent:^{
            [weakSelf.collectionViewController.collectionView.pullToRefreshView stopAnimating];
        }];
    }];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
    self.quest = nil;
    self.commentUploads = nil;
    self.topComments = nil;
    self.chronComments = nil;
    self.nextPage = 0;
    self.prevPageRequest = nil;
    self.nextPageRequest = nil;
    self.nextPageFailedToLoad = NO;
    self.prevPageFailedToLoad = NO;
    [self transition:DQGalleryTransitionUnloadView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Do this after all layout has happened
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf setPullToRefreshOffset];
    });
}

#pragma mark -

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

- (NSMutableOrderedSet *)currentCommentSet
{
    NSMutableOrderedSet *set = nil;
    if (self.selectedSegmentIndex == 0)
    {
        set = self.topComments;
    }
    else if (self.selectedSegmentIndex == 1)
    {
        set = self.chronComments;
    }
    return set;
}

- (void)displayCollectionView
{
    [self addChildViewController:self.collectionViewController];
    [self.collectionViewController didMoveToParentViewController:self];
    [self.view addSubview:self.collectionViewController.view];
    self.collectionViewController.view.frame = self.view.bounds;

    UIView *whiteSpaceView = [[UIView alloc] initWithFrame:CGRectZero];
    whiteSpaceView.backgroundColor = [UIColor whiteColor];
    whiteSpaceView.frameWidth = self.collectionViewController.view.frameWidth;
    whiteSpaceView.frameHeight = 1000.0f;
    [self.collectionViewController.collectionView addSubview:whiteSpaceView];
    [self.collectionViewController.collectionView sendSubviewToBack:whiteSpaceView];
    self.whiteSpaceView = whiteSpaceView;
}

- (void)hideCollectionView
{
    [self.collectionViewController.view removeFromSuperview];
    [self.collectionViewController removeFromParentViewController];
    [self.collectionViewController didMoveToParentViewController:nil];
}

- (void)fetchQuestAndCommentUploads
{
    self.quest = [self.dataStoreController questForServerID:self.questID];
    if (self.quest)
    {
        self.title = self.quest.title;
        ((DQQuestTitleView *)self.navigationItem.titleView).text = self.title;
    }
    NSArray *sortedCommentUploads = [self.dataStoreController sortedCommentUploadsForQuest:self.quest];
    NSMutableOrderedSet *newGallery = [[NSMutableOrderedSet alloc] initWithArray:sortedCommentUploads ?: @[]];
    self.commentUploads = newGallery;
    if (self.quest.attributionUsername.length > 0)
    {
        self.headerView.avatarImageView.imageURL = self.quest.attributionAvatarUrl;
        self.headerView.usernameLabel.text = self.quest.attributionUsername;
        self.headerView.descriptionLabel.text = self.quest.attributionCopy;
        self.headerView.hasAttributedAuthor = YES;
    }
    else
    {
        self.headerView.avatarImageView.imageURL = self.quest.authorAvatarUrl;
        self.headerView.usernameLabel.text = self.quest.authorUsername;
        self.headerView.descriptionLabel.text = DQLocalizedString(@"Created this Quest", @"Label explaining that the above user is responsible for creating the current Quest");
    }
    self.headerView.timestampLabel.timestamp = self.quest.timestamp;
    [self.headerView setTemplateImageURL:[self.quest imageURLForKey:DQImageKeyGallery]];
}

- (void)setupViews
{
    __weak typeof(self) weakSelf = self;

    DQPhoneGalleryHeaderView *headerView = [[DQPhoneGalleryHeaderView alloc] initWithFrame:CGRectZero];
    headerView.inviteToQuestBlock = ^{
        if (weakSelf.inviteToQuestBlock)
        {
            weakSelf.inviteToQuestBlock(weakSelf, weakSelf.quest);
        }
    };
    headerView.showEditorBlock = ^{
        if (weakSelf.showEditorBlock)
        {
            weakSelf.showEditorBlock(weakSelf, weakSelf.quest);
        }
    };
    headerView.moreOptionsBlock = ^{
        [weakSelf tappedMoreOptionsButtonForQuest:weakSelf.quest source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
    };
    headerView.showProfileBlock = ^{
        NSString *username = (weakSelf.quest.attributionUsername.length > 0) ? weakSelf.quest.attributionUsername : weakSelf.quest.authorUsername;
        [weakSelf showProfileForUsername:username source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
    };
    headerView.shareButtonTappedBlock = ^{
        [weakSelf tappedShareButtonForQuest:weakSelf.quest source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
    };
    self.headerView = headerView;

    DQPhoneGalleryErrorView *errorView = [[DQPhoneGalleryErrorView alloc] initWithFrame:CGRectZero];
    self.errorView = errorView;

    // Set up Collection View Controller

    self.collectionViewController = [[DQCommentsCollectionViewController alloc] initWithHeaderView:headerView errorView:errorView];
    self.collectionViewController.delegate = self;
    self.collectionViewController.dataSource = self;
    self.collectionViewController.imageTappedBlock = ^(DQComment *comment, UIView *imageView) {
        [weakSelf showZoomableImageForComment:comment fromView:imageView];
    };
    self.collectionViewController.showDrawingDetailBlock = ^(DQComment *comment) {
        [weakSelf showDrawingDetailForComment:comment source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery") completionBlock:nil failureBlock:^(NSError *error) {
            // FIXME: implement
        }];
    };
    self.collectionViewController.showUserProfileBlock = ^(DQComment *comment) {
        [weakSelf showProfileForUsername:comment.authorName source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
    };
    self.collectionViewController.playbackBlock = ^(DQButton *playbackButton, DQPlaybackImageView *playbackImageView, DQComment *comment) {
        [weakSelf tappedPlaybackButton:playbackButton forPlaybackImageView:playbackImageView comment:comment withRequestFinishedBlock:^(DQComment *newComment) {
            if (newComment)
            {
                // Refresh with the updated comment to show the new note count
                NSUInteger index = [[weakSelf currentCommentSet] indexOfObject:comment];
                if (index != NSNotFound)
                {
                    [weakSelf currentCommentSet][index] = newComment;
                    [weakSelf.collectionViewController updateNoteCountForCommentAtIndex:index];
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
        [weakSelf tappedMoreOptionsButtonForComment:comment source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
    };
    self.collectionViewController.shareCommentBlock = ^(DQComment *comment) {
        [weakSelf tappedShareButtonForComment:comment source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
    };
    self.collectionViewController.commentViewedBlock = ^(DQCommentsCollectionViewController *cvc, NSString *commentID) {
        if (weakSelf.commentViewedBlock)
        {
            weakSelf.commentViewedBlock(weakSelf, commentID);
        }
    };

    [self transition:DQGalleryTransitionLoadCommentUploads];
}

#pragma mark -

- (void)commentFlagged:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.topComments containsObject:comment])
    {
        [self.topComments removeObject:comment];
    }
    if ([self.chronComments containsObject:comment])
    {
        [self.chronComments removeObject:comment];
    }
    [self reloadData];
}

- (void)questFlagged:(NSNotification *)notification
{
    DQQuest *quest = [[notification userInfo] objectForKey:DQQuestObjectNotificationKey];
    if ([self.questID isEqualToString:quest.serverID])
    {
        if (self.dismissBlock)
        {
            self.dismissBlock();
        }
    }
}

- (void)commentDeleted:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.topComments containsObject:comment])
    {
        [self.topComments removeObject:comment];
    }
    if ([self.chronComments containsObject:comment])
    {
        [self.chronComments removeObject:comment];
    }
    [self reloadData];
}

- (void)commentPlayed:(NSNotification *)notification
{
    // FIXME: implement
}

- (void)commentUploadCompleted:(NSNotification *)notification
{
    DQCommentUpload *commentUpload = [[notification userInfo] objectForKey:DQCommentUploadObjectNotificationKey];
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];

    NSUInteger index = [self.commentUploads indexOfObject:commentUpload];
    if (index != NSNotFound)
    {
        [self.commentUploads removeObjectAtIndex:index];
        [self.chronComments insertObject:comment atIndex:0];
        [self reloadData];
    }
}

- (void)reloadData
{
    [self.collectionViewController reloadData];
}

- (void)loadGallery
{
    [self collectionViewController:self.collectionViewController didSelectSegmentIndex:[self defaultSegmentIndexForCollectionViewController:self.collectionViewController]];
}

- (void)loadTopComments
{
    if ( ! self.topComments)
    {
        [self.collectionViewController startDisplayingSpinner];

        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestTopCommentsForQuestWithServerID:self.questID completionBlock:^(DQHTTPRequest *request) {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;
            NSDictionary *questDict = responseDictionary.dq_quest;

            [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:weakSelf.questID fromJSONList:commentList questJSONDictionary:questDict inBackground:YES resultsBlock:^(NSArray *objects) {
                [weakSelf handleTopGalleryLoadResponseForRequest:request JSONDict:responseDictionary objects:objects];
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            [weakSelf handleTopGalleryLoadResponseForRequest:request JSONDict:nil objects:nil];
        }];
    }
}

- (void)handleTopGalleryLoadResponseForRequest:(DQHTTPRequest *)request JSONDict:(NSDictionary *)JSONDict objects:(NSArray *)objects
{
    [self.collectionViewController stopDisplayingSpinner];

    if (request.error)
    {
        if (request.responseStatusCode == 404)
        {
            [self transition:DQGalleryTransitionLoadGalleryNotFound
                    userInfo:
             @{
               @"error":request.error,
               @"errorTitle":DQLocalizedString(@"Unable to Refresh Gallery",  @"Quest gallery refresh failure alert title")
               }];
        }
        else
        {
            [self transition:DQGalleryTransitionLoadGalleryFailed
                    userInfo:
             @{
               @"error":request.error,
               @"errorTitle":DQLocalizedString(@"Unable to Refresh Gallery",  @"Quest gallery refresh failure alert title")
               }];
        }
    }
    else
    {
        if (!self.quest)
        {
            NSDictionary *questJSONInfo = JSONDict.dq_quest;
            if (questJSONInfo)
            {
                self.quest = [self.dataStoreController createOrUpdateQuestWithJSONInfo:questJSONInfo];
            }
        }
        if (self.quest)
        {
            self.title = self.quest.title;
            ((DQQuestTitleView *)self.navigationItem.titleView).text = self.title;
            if (self.topComments)
            {
                [self.topComments addObjectsFromArray:objects];
            }
            else
            {
                self.topComments = [[NSMutableOrderedSet alloc] initWithArray:objects];
            }
            [self transition:DQGalleryTransitionLoadGallerySucceeded];
            [self reloadData];
        }
        else
        {
            [self transition:DQGalleryTransitionLoadGalleryFailed
                    userInfo:
             @{
               @"errorTitle":DQLocalizedString(@"Unable to Find Quest", @"Quest could not be found on server error alert title")
               }];
        }
    }
}

- (void)loadChronComments
{
    if ( ! self.chronComments)
    {
        [self.collectionViewController startDisplayingSpinner];

        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestCommentsForQuestWithServerID:self.questID forcedCommentID:nil completionBlock:^(DQHTTPRequest *request) {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;
            NSDictionary *questDict = responseDictionary.dq_quest;

            [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:weakSelf.questID fromJSONList:commentList questJSONDictionary:questDict inBackground:YES resultsBlock:^(NSArray *objects) {
                [weakSelf handleChronGalleryLoadResponseForRequest:request JSONDict:responseDictionary objects:objects];
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            [weakSelf handleChronGalleryLoadResponseForRequest:request JSONDict:nil objects:nil];
        }];
    }
}

- (void)handleChronGalleryLoadResponseForRequest:(DQHTTPRequest *)request JSONDict:(NSDictionary *)JSONDict objects:(NSArray *)objects
{
    [self.collectionViewController stopDisplayingSpinner];

    if (request.error)
    {
        if (request.responseStatusCode == 404)
        {
            [self transition:DQGalleryTransitionLoadGalleryNotFound
                    userInfo:
             @{
               @"error":request.error,
               @"errorTitle":DQLocalizedString(@"Unable to Refresh Gallery",  @"Quest gallery refresh failure alert title")
               }];
        }
        else
        {
            [self transition:DQGalleryTransitionLoadGalleryFailed
                    userInfo:
             @{
               @"error":request.error,
               @"errorTitle":DQLocalizedString(@"Unable to Refresh Gallery",  @"Quest gallery refresh failure alert title")
               }];
        }
    }
    else
    {
        if (!self.quest)
        {
            NSDictionary *questJSONInfo = JSONDict.dq_quest;
            if (questJSONInfo)
            {
                self.quest = [self.dataStoreController createOrUpdateQuestWithJSONInfo:questJSONInfo];
            }
        }
        if (self.quest)
        {
            self.title = self.quest.title;
            ((DQQuestTitleView *)self.navigationItem.titleView).text = self.title;
            self.nextPage = [JSONDict.dq_paginationPage.dq_paginationNextPage integerValue];
            if (self.chronComments)
            {
                [self.chronComments addObjectsFromArray:objects];
            }
            else
            {
                self.chronComments = [[NSMutableOrderedSet alloc] initWithArray:objects];
            }
            [self transition:DQGalleryTransitionLoadGallerySucceeded];
            [self reloadData];
        }
        else
        {
            [self transition:DQGalleryTransitionLoadGalleryFailed
                    userInfo:
             @{
               @"errorTitle":DQLocalizedString(@"Unable to Find Quest", @"Quest could not be found on server error alert title")
               }];
        }
    }
}

#pragma mark - DQCommentsCollectionViewControllerDelegate Methods

- (void)collectionViewController:(DQCommentsCollectionViewController *)viewController didSelectSegmentIndex:(NSUInteger)index
{
    self.selectedSegmentIndex = index;
    if (index == 0)
    {
        [self logEvent:DQAnalyticsEventViewGalleryPhoneTop withParameters:[self viewEventLoggingParameters]];
        [self loadTopComments];
    }
    else if (index == 1)
    {
        [self logEvent:DQAnalyticsEventViewGalleryPhoneNew withParameters:[self viewEventLoggingParameters]];
        [self loadChronComments];
    }
    [self reloadData];
}

- (void)collectionViewController:(DQCommentsCollectionViewController *)viewController scrollViewDidScroll:(UIScrollView *)scrollView;
{
    // nothing, but it's a required method
}

#pragma mark - DQSegmentedCollectionViewControllerDataSource methods

- (NSInteger)collectionViewController:(DQCommentsCollectionViewController *)viewController numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == 0)
    {
        count = [self.commentUploads count];
    }
    else if (section == 1)
    {
        count = [[self currentCommentSet] count];
    }
    return count;
}

- (BOOL)contentIsPaginatedInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    return self.selectedSegmentIndex != 0;
}

- (BOOL)hasMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    return self.nextPage > 0;
}

- (void)loadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    // FIXME: remove this, we don't have failure handling yet
    if (self.nextPageFailedToLoad)
    {
        self.nextPageFailedToLoad = NO;
    }

    if ( ! (self.nextPage == 0 || self.nextPageRequest || self.nextPageFailedToLoad))
    {
        NSLog(@"requesting next page");
        NSInteger page = self.nextPage;

        __weak typeof(self) weakSelf = self;
        self.nextPageRequest = [self.publicServiceController requestCommentsForQuestWithServerID:self.quest.serverID forcedCommentID:nil offset:@(page) direction:DQOffsetDirectionNext completionBlock:^(DQHTTPRequest *request) {
            weakSelf.nextPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;
            NSDictionary *questDict = responseDictionary.dq_quest;

            [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:weakSelf.questID fromJSONList:commentList questJSONDictionary:questDict inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    [weakSelf.chronComments addObjectsFromArray:objects];
                }

                NSInteger nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];
                weakSelf.nextPage = (weakSelf.nextPage || nextPage) ? nextPage : 0;

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
        self.prevPageRequest = [self.publicServiceController requestCommentsForQuestWithServerID:self.questID forcedCommentID:nil completionBlock:^(DQHTTPRequest *request) {
            weakSelf.prevPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;

            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:commentList inBackground:YES resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    DQComment *oldFirst = [weakSelf.chronComments firstObject];
                    DQComment *newFirst = [objects firstObject];
                    if (! [newFirst.serverID isEqualToString:oldFirst.serverID])
                    {
                        weakSelf.chronComments = [[NSMutableOrderedSet alloc] initWithArray:objects ?: @[]];
                        weakSelf.nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];
                        [weakSelf reloadData];
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

#pragma mark - DQCommentsCollectionViewControllerDataSource Methods

- (NSString *)loggedInUsernameForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return self.loggedInAccount.username;
}

- (DQCommentUpload *)collectionViewController:(DQCommentsCollectionViewController *)viewController commentUploadForIndexPath:(NSIndexPath *)indexPath
{
    return [self.commentUploads objectAtIndex:indexPath.item];
}

- (DQComment *)collectionViewController:(DQCommentsCollectionViewController *)viewController commentForIndexPath:(NSIndexPath *)indexPath
{
    return [[self currentCommentSet] objectAtIndex:indexPath.item];
}

- (BOOL)collectionViewController:(DQCommentsCollectionViewController *)viewController replaceCommentAtIndexPath:(NSIndexPath *)indexPath withComment:(DQComment *)newComment
{
    BOOL result = NO;
    NSMutableOrderedSet *set = [self currentCommentSet];
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

- (NSArray *)segmentItemsForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return @[DQLocalizedStringWithDefaultValue(@"TopTabTitle", nil, nil, @"Top", @"Tab title which shows the best items in order of ranking"), DQLocalizedStringWithDefaultValue(@"NewTabTitle", nil, nil, @"New", @"Tab title which shows the newest items in reverse chron order")];
}

- (DQSegmentedControlViewOption)defaultViewOptionForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return DQSegmentedControlViewOptionList;
}

- (NSUInteger)defaultSegmentIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController
{
    return self.isPublishing ? 1 : 0;
}

- (BOOL)collectionViewController:(DQCommentsCollectionViewController *)viewController shouldDisplayFollowButtonForComment:(DQComment *)comment
{
    return ![comment.authorName isEqualToString:self.loggedInAccount.username];
}

@end

@implementation DQPhoneGalleryErrorView

- (NSString *)message
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
            return DQLocalizedString(@"No one's drawn this Quest yet. Be the first!", @"No drawings exist for this Quest message");
            break;
        case DQPhoneErrorViewTypeRequestFailed:
        default:
            return DQLocalizedString(@"We couldn't load the gallery. Please try again.", @"Unknown error while loading Quest gallery, retry prompt");
            break;
    }
}

- (NSString *)buttonTitle
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
            return DQLocalizedStringWithDefaultValue(@"DrawPrompt", nil, nil, @"Draw", @"Prompt for a user to draw the Quest");
            break;
        case DQPhoneErrorViewTypeRequestFailed:
        default:
            return DQLocalizedString(@"Retry", @"Prompt for a user to attempt a failed connection again.");
            break;
    }
}

@end
