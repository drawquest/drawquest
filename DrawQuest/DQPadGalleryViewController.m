//
//  DQPadGalleryViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadGalleryViewController.h"

#import <objc/runtime.h>

#import "DQGalleryCellTableHeader.h"
#import "DQGalleryActivityTableViewCell.h"
#import "DQImageView.h"
#import "DQTitleView.h"
#import "DQAlertView.h"
#import "DQGalleryErrorView.h"
#import "DQLoadingView.h"
#import "DQNavigationBar.h"

#import "DQDataStoreController.h"
#import "DQSharingController.h"

#import "DQComment.h"
#import "DQCommentUpload.h"
#import "DQQuest.h"

#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"

#import "DQGalleryCell.h"
#import "DQFlowLayout.h"
#import "DQGalleryLoadingMoreView.h"
#import "DQGalleryCellTableHeader.h"
#import "DQPublicServiceController.h"
#import "DQStarButton.h"

void * const kDQGalleryCellTableViewCommentKey = (void *)&kDQGalleryCellTableViewCommentKey;

NSString *DQGalleryCommentCellReuseIdentifier = @"DQGalleryCommentCellReuseIdentifier";
NSString *DQGalleryCellReuseIdentifier = @"DQGalleryCellReuseIdentifier";
NSString *DQGalleryFooterReuseIdentifer = @"DQGalleryFooterReuseIdentifer";
NSString *DQGalleryViewControllerReloadDataNotification = @"DQGalleryViewControllerReloadDataNotification";
NSInteger DQGalleryViewControllerLoadMoreTriggerOffset = 3;

static CGSize kItemSize = { 640.0f, 755.0f };
static const CGFloat kItemSpacing = 22.0f;

@interface DQPadGalleryViewController () <DQGalleryCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) DQGalleryState state;
@property (nonatomic, readwrite, strong) DQQuest *quest;
@property (nonatomic, strong) NSMutableOrderedSet *galleryObjects;
@property (nonatomic, strong) DQSharingController *sharingController;
@property (nonatomic, assign) BOOL nextPageFailedToLoad;
@property (nonatomic, assign) BOOL prevPageFailedToLoad;
@property (nonatomic, weak) DQHTTPRequest *nextPageRequest;
@property (nonatomic, weak) DQHTTPRequest *prevPageRequest;
@property (nonatomic, assign) NSInteger prevPage;
@property (nonatomic, assign) NSInteger nextPage;

@property (nonatomic, strong) UICollectionView *slidingView;

@property (nonatomic, strong) UIBarButtonItem *drawButtonItem;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) CGPoint lastOffset;

@property (nonatomic, strong) UIScrollView* dummyView;

@end

@implementation DQPadGalleryViewController

#pragma mark Initialization

- (id)initWithQuestID:(NSString *)inQuestID focusedCommentID:(NSString *)inScrolledCommentID source:(NSString *)source publishing:(BOOL)isPublishing newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithQuestID:inQuestID focusedCommentID:inScrolledCommentID source:source publishing:isPublishing newPlaybackDataManager:newPlaybackDataManager delegate:delegate];
    if (self)
    {
        _state = isPublishing ? DQGalleryStatePublishingStart : DQGalleryStateStart;
    }
    return self;
}

- (void)dealloc
{
    [self.slidingView removeObserver:self forKeyPath:@"contentSize"];
    [self.dummyView removeObserver:self forKeyPath:@"contentOffset"];
    self.slidingView.delegate = nil;
    self.slidingView.dataSource = nil;
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
            [self reloadData];
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
            [self.view addSubview:self.slidingView];
            [self.view addSubview:self.dummyView];
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
        if (transition == DQGalleryTransitionLoadGallerySucceeded)
        {
            [self.loadingView removeFromSuperview];
            self.loadingView = nil;
            if ([self.galleryObjects count])
            {
                self.state = DQGalleryStateDisplayingGalleryWithCommentUploads;
                [self.view addSubview:self.slidingView];
                [self.view addSubview:self.dummyView];
                [self reloadData];
                if (self.focusedCommentID)
                {
                    [self scrollToCommentWithServerID:self.focusedCommentID];
                }
            }
            else
            {
                self.state = DQGalleryStateDisplayingSparseView;
                __weak typeof(self) weakSelf = self;
                DQGalleryErrorView *sparseView = [[DQGalleryErrorView alloc] initWithFrame:self.view.bounds errorType:DQGalleryErrorViewTypeEmpty buttonTappedBlock:^(DQGalleryErrorView *v){
                    [weakSelf drawButtonTapped:v];
                }];
                [self.view addSubview:sparseView];
            }
        }
        else if (transition == DQGalleryTransitionLoadGalleryNotFound)
        {
            self.state = DQGalleryStateDisplayingNotFoundErrorView;
            [self.loadingView removeFromSuperview];
            self.loadingView = nil;
            DQGalleryErrorView *notFoundView = [[DQGalleryErrorView alloc] initWithFrame:self.view.bounds errorType:DQGalleryErrorViewTypeDrawingNotFound buttonTappedBlock:nil];
            [self.view addSubview:notFoundView];
        }
        else if (transition == DQGalleryTransitionLoadGalleryFailed)
        {
            self.state = DQGalleryStateDisplayingRetryView;
            __weak typeof(self) weakSelf = self;
            DQGalleryErrorView *retryView = [[DQGalleryErrorView alloc] initWithFrame:self.view.bounds errorType:DQGalleryErrorViewTypeRequestFailed buttonTappedBlock:^(DQGalleryErrorView *v) {
                [v removeFromSuperview];
                [weakSelf transition:DQGalleryTransitionLoadGallery];
            }];
            [self.view addSubview:retryView];
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
            self.state = DQGalleryStateDisplayingLoadingView;
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


    else if (self.state == DQGalleryStateDisplayingGalleryWithCommentUploads)
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
            [self showErrorWithTitle:DQLocalizedString(@"Unable to Refresh Gallery", @"Quest gallery refresh failure alert title")
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

#pragma mark UIViewController

- (void)setupViews
{
    DQFlowLayout *flowLayout = [[DQFlowLayout alloc] init];
    [flowLayout setItemSize:kItemSize];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumLineSpacing:kItemSpacing];
    [flowLayout setMinimumInteritemSpacing:kItemSpacing];
    [flowLayout setFooterReferenceSize:CGSizeMake(167.0f, kItemSize.height)];
    [flowLayout setHeaderReferenceSize:CGSizeMake(167.0f, kItemSize.height)];

    self.view.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];

    [self.slidingView removeObserver:self forKeyPath:@"contentSize"]; // DQ-370 - paranoia (it should be nil)
    self.slidingView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0f, 60.0f, self.view.bounds.size.width, kItemSize.height) collectionViewLayout:flowLayout];
    [self.slidingView setShowsHorizontalScrollIndicator:NO];
    [self.slidingView setShowsVerticalScrollIndicator:NO];
    [self.slidingView setBackgroundColor:[UIColor clearColor]];
    [self.slidingView setDataSource:self];
    [self.slidingView setDelegate:self];
    [self.slidingView setAllowsSelection:YES];
    [self.slidingView setDelaysContentTouches:NO];
    CGFloat pageSize = kItemSize.width + kItemSpacing;
    self.slidingView.contentInset = UIEdgeInsetsMake(0, (CGRectGetWidth(self.view.bounds) - pageSize) / 2, 0, (CGRectGetWidth(self.view.bounds) - pageSize) / 2);
    self.slidingView.decelerationRate = UIScrollViewDecelerationRateFast;

    [self.slidingView registerClass:[DQGalleryCell class] forCellWithReuseIdentifier:DQGalleryCellReuseIdentifier];
    [self.slidingView registerClass:[DQGalleryLoadingMoreView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:DQGalleryFooterReuseIdentifer];
    [self.slidingView registerClass:[DQGalleryLoadingMoreView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DQGalleryFooterReuseIdentifer];
    [self.slidingView addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];

    // The purpose of this dummy view is to sit on top of the collection view to assist us with paging the
    // collection view behind it.
    // This works by defining the frame of the dummy scrollview to be equal to that of the collection view below.
    // The dummy scrollview on top of the collection view is responsible for paging, while the collection view
    // does not.
    // We then disable the collection view's pan gesture recognizer, and attach the scrollview's pan gesture
    // recognizer to the collectionview, this lets us pass the pan motions in areas the dummy's frame doesn't
    // cover. All other forms of touch that don't interact with the pan gesture recognizer will be sent to the
    // collection view itself.
    // Finally, when the user scrolls, we move both the dummy and the collection view.
    // When the collection view has its contentSize changed, we change the size of the dummyView to be slightly
    // larger (pageSize * width of dummy view). This gives us the paging behaviour we want.
    [self.dummyView removeObserver:self forKeyPath:@"contentOffset"]; // DQ-370 - paranoia (it should be nil)
    self.dummyView = [[UIScrollView alloc] initWithFrame:self.slidingView.frame];
    self.dummyView.pagingEnabled = YES;
    self.dummyView.delegate = self;
    self.dummyView.hidden = YES;
    self.slidingView.panGestureRecognizer.enabled = NO;
    [self.slidingView addGestureRecognizer:self.dummyView.panGestureRecognizer];
    self.dummyView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self.dummyView addObserver:self forKeyPath:@"contentOffset" options:0 context:NULL];

    // Right Button Item
    UIView *drawOffsetView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 24.0f, 24.0f)];
    UIButton *drawButton = [UIButton buttonWithType:UIButtonTypeCustom];
    drawButton.frame = drawOffsetView.bounds;
    [drawOffsetView addSubview:drawButton];
    [drawButton setImage:[UIImage imageNamed:@"button_draw_pencil"] forState:UIControlStateNormal];
    [drawButton addTarget:self action:@selector(drawButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.drawButtonItem = [[UIBarButtonItem alloc] initWithCustomView:drawOffsetView];
    self.navigationItem.rightBarButtonItem = self.drawButtonItem;

    DQTitleView *titleView = [[DQTitleView alloc] initWithStyle:DQTitleViewStyleNavigationBar];
    self.navigationItem.titleView = titleView;
    titleView.text = self.title;

    [self transition:DQGalleryTransitionLoadCommentUploads];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // We should get rid of the xib,
    // but until then, we can pretend is't not there:
    UIView *newBackground = [[UIView alloc] initWithFrame:self.view.bounds];
    newBackground.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
    [self.view addSubview:newBackground];

    [self transition:DQGalleryTransitionLoadView];

    if (self.makeSharingControllerBlock)
    {
        self.sharingController = self.makeSharingControllerBlock(self);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    //Put things back in place
    self.slidingView.frame = CGRectMake(0.0f, 60.0f, self.view.bounds.size.width, kItemSize.height);
    CGFloat pageSize = kItemSize.width + kItemSpacing;
    self.slidingView.contentInset = UIEdgeInsetsMake(0, (CGRectGetWidth(self.view.bounds) - pageSize) / 2, 0, (CGRectGetWidth(self.view.bounds) - pageSize) / 2);
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.sharingController = nil;
        self.quest = nil;
        self.galleryObjects = nil;
        self.prevPage = 0;
        self.nextPage = 0;
        self.prevPageRequest = nil;
        self.nextPageRequest = nil;
        self.nextPageFailedToLoad = NO;
        self.prevPageFailedToLoad = NO;
        self.drawButtonItem = nil;
        self.titleLabel = nil;
        self.loadingView = nil;
        self.slidingView.delegate = nil;
        self.slidingView.dataSource = nil;
        [self.slidingView removeObserver:self forKeyPath:@"contentSize"];
        self.slidingView = nil;
        [self.dummyView removeObserver:self forKeyPath:@"contentOffset"];
        self.dummyView = nil;
        self.lastOffset = CGPointZero;
        [self transition:DQGalleryTransitionUnloadView];
    }
    [super didReceiveMemoryWarning];
}

#pragma mark CollectionView Methods

- (void)galleryCellDidFocus:(DQGalleryCell *)cell
{
    id commentObject = objc_getAssociatedObject(cell.tableView, kDQGalleryCellTableViewCommentKey);
    DQComment *comment = [commentObject isKindOfClass:[DQComment class]] ? commentObject : nil;
    NSInteger index = [self.galleryObjects indexOfObject:commentObject];

    if (comment && self.commentViewedBlock)
    {
        self.commentViewedBlock(self, comment.serverID);
    }

    if (index > ([self.galleryObjects count] - DQGalleryViewControllerLoadMoreTriggerOffset)) {
        [self loadNextPage];
    } else if (index < DQGalleryViewControllerLoadMoreTriggerOffset) {
        [self loadPreviousPage];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    DQGalleryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DQGalleryCellReuseIdentifier forIndexPath:indexPath];
    cell.delegate = self;

    UITableView *tableView = cell.tableView;
    DQComment *comment = [self.galleryObjects objectAtIndex:indexPath.item];
    objc_setAssociatedObject(tableView, kDQGalleryCellTableViewCommentKey, comment, OBJC_ASSOCIATION_RETAIN);
    cell.tableViewDataSource = self;

    DQGalleryCellTableHeader *headerView = (DQGalleryCellTableHeader *)tableView.tableHeaderView;

    // do not refer to comment in the dq_notificationHandlerBlock as this cell's comment can be changed by refreshCell
    NSString *commentID = comment.serverID;
    [[NSNotificationCenter defaultCenter] addObserver:cell selector:@selector(dq_notificationHandler:) name:DQCommentRefreshedNotification object:nil];
    cell.dq_notificationHandlerBlock = ^(DQGalleryCell *cell, NSNotification *notification) {
        if (notification)
        {
            DQComment *newComment = [notification object];
            if ([newComment.serverID isEqualToString:commentID])
            {
                [weakSelf refreshCell:cell atIndexPath:indexPath withComment:newComment];
            }
        }
        else
        {
            [[NSNotificationCenter defaultCenter] removeObserver:cell name:DQCommentRefreshedNotification object:nil];
        }
    };
    DQModelObject *currentObject = [self.galleryObjects objectAtIndex:indexPath.item];
    if ([currentObject isKindOfClass:[DQCommentUpload class]]) {
        DQCommentUpload *commentUpload = (DQCommentUpload *)currentObject;
        [headerView initializeWithCommentUpload:commentUpload loggedInUsername:self.loggedInAccount.username loggedInAvatarURL:self.loggedInAccount.avatarURL];
        headerView.tappedRetryUploadButtonBlock = ^(UIButton *retryButton) {
            [weakSelf tappedRetryButton:retryButton forCommentUpload:commentUpload];
        };
        headerView.tappedCancelUploadButtonBlock = ^(UIButton *cancelButton) {
            [weakSelf tappedCancelButton:cancelButton forCommentUpload:commentUpload withDeletionBlock:^{
                [weakSelf.galleryObjects removeObject:commentUpload];
                [weakSelf reloadData];
            }];
        };
    } else {
        DQComment *currentComment = (DQComment *)currentObject;
        [headerView initializeWithComment:currentComment];
        headerView.footerView.starButton.commentID = currentComment.serverID;

        __weak typeof(self) weakSelf = self;
        headerView.footerView.playbackButtonTappedBlock = ^{
            [weakSelf playbackButtonTappedForComment:currentComment];
        };

        headerView.footerView.flagButtonTappedBlock = ^{
            [weakSelf flagButtonTappedForComment:currentComment];
        };

        headerView.footerView.deleteButtonTappedBlock = ^{
            [weakSelf deleteButtonTappedForComment:currentComment];
        };

        headerView.footerView.facebookButtonTappedBlock = ^{
            [weakSelf facebookButtonTappedForComment:currentComment];
        };

        headerView.footerView.twitterButtonTappedBlock = ^{
            [weakSelf twitterButtonTappedForComment:currentComment];
        };

        headerView.footerView.tumblrButtonTappedBlock = ^{
            [weakSelf tumblrButtonTappedForComment:currentComment];
        };

        headerView.footerView.cameraRollButtonTappedBlock = ^(UIView *view) {
            [weakSelf cameraRollButtonTappedForComment:currentComment fromView:view];
        };

        headerView.footerView.avatarImageOrUserNameTappedBlock = ^{
            [weakSelf displayProfileForUserWithUsername:currentComment.authorName fromGalleryObject:currentComment];
        };

        headerView.footerView.shouldShowDeleteButtonBlock = ^{
            return [currentComment.authorID isEqualToString:self.loggedInAccount.accountID];
        };
        headerView.footerView.shouldShowCameraButtonBlock = ^BOOL {
            id url = [currentComment imageURLForKey:DQImageKeyCameraRoll];
            return [currentComment.authorID isEqualToString:self.loggedInAccount.accountID] && [url isKindOfClass:[NSString class]] && [(NSString *)url length];
        };
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.galleryObjects count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DQGalleryCell *cell = (DQGalleryCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (collectionView.scrollEnabled && !cell.focused)
    {
        NSLog(@"scrolling to selected cell WITH animation (C)");
        [self scrollToItemAtIndexPath:indexPath animated:YES];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    DQGalleryLoadingMoreView *reuseableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:DQGalleryFooterReuseIdentifer forIndexPath:indexPath];
    [reuseableView setSectionType:kind];

    __weak typeof(self) weakSelf = self;
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.nextPageRequest) {
            [reuseableView setGalleryState:DQGalleryLoadingMoreViewStateLoading];
        } else if (self.nextPageFailedToLoad) {
            [reuseableView setGalleryState:DQGalleryLoadingMoreViewStateLoadFailed];
        } else {
            [reuseableView setGalleryState:DQGalleryLoadingMoreViewStateLoaded];
        }
        reuseableView.loadMoreButtonTappedBlock = ^(DQGalleryLoadingMoreView *view){
            weakSelf.nextPageFailedToLoad = NO;
            [weakSelf loadNextPage];
            [view setGalleryState:DQGalleryLoadingMoreViewStateLoading];
        };
    } else {
        if (self.prevPageRequest) {
            [reuseableView setGalleryState:DQGalleryLoadingMoreViewStateLoading];
        } else if (self.prevPageFailedToLoad) {
            [reuseableView setGalleryState:DQGalleryLoadingMoreViewStateLoadFailed];
        } else {
            [reuseableView setGalleryState:DQGalleryLoadingMoreViewStateLoaded];
        }
        reuseableView.loadMoreButtonTappedBlock = ^(DQGalleryLoadingMoreView *view){
            weakSelf.prevPageFailedToLoad = NO;
            [weakSelf loadPreviousPage];
            [view setGalleryState:DQGalleryLoadingMoreViewStateLoading];
        };
    }

    return (UICollectionReusableView *)reuseableView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.dummyView) {
        self.lastOffset = self.slidingView.contentOffset;

        for (DQGalleryCell *cell in self.slidingView.visibleCells) {
            [cell.tableView setContentOffset:CGPointMake(0.0f, -62.0f) animated:NO];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.slidingView) {
        [self.slidingView.collectionViewLayout invalidateLayout];
    }
    else if (scrollView == self.dummyView) {
        [self.slidingView.collectionViewLayout invalidateLayout];
        //        CGPoint contentOffset = scrollView.contentOffset;
        //        contentOffset.x = contentOffset.x - 167.0f;
        //        NSLog(@"contentOffset.x = %g", contentOffset.x);
        //        self.slidingView.contentOffset = contentOffset;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == self.slidingView)
    {
        // NSLog(@"did end scrolling animation");
        scrollView.userInteractionEnabled = YES;
    }
}

#pragma mark Retrieving the focused cell and object

- (DQGalleryCell *)focusedCell
{
    DQGalleryCell *result = nil;
    for (DQGalleryCell *cell in [self.slidingView visibleCells])
    {
        if (cell.focused)
        {
            result = cell;
            break;
        }
    }
    return result;
}

- (DQModelObject *)focusedObject
{
    DQModelObject *result = nil;
    if ([self focusedCell].tableView)
    {
        result = objc_getAssociatedObject([self focusedCell].tableView, kDQGalleryCellTableViewCommentKey);
    }
    return result;
}

#pragma mark Indexes

- (NSInteger)indexForGalleryObject:(DQModelObject *)galleryObject
{
    if ([self.galleryObjects count])
    {
        return (NSInteger)[self.galleryObjects indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
            if (obj == galleryObject)
            {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
    }
    return NSNotFound;
}

- (NSInteger)indexForCommentWithServerID:(NSString *)inServerID
{
    if ([self.galleryObjects count])
    {
        NSInteger index = 0;
        for (DQModelObject *currentObject in self.galleryObjects)
        {
            if ([currentObject isKindOfClass:[DQComment class]] && [currentObject.serverID isEqualToString:inServerID]) {
                return index;
            }
            index++;
        }
    }
    return NSNotFound;
}

#pragma mark Scrolling

// used by pagination to scroll to the focused object when pagination loads finish
// this isn't ideal, but it's the only easy to thing right now
- (void)scrollToGalleryObject:(DQModelObject *)galleryObject
{
    if (self.galleryObjects.count)
    {
        NSInteger index = [self indexForGalleryObject:galleryObject];
        if (index != NSNotFound)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            [self scrollToItemAtIndexPath:indexPath animated:NO];
        }
    }
}

// used by the FSM to scroll to the focusedCommentID
- (void)scrollToCommentWithServerID:(NSString *)inServerID
{
    if (self.galleryObjects.count)
    {
        NSInteger index = [self indexForCommentWithServerID:inServerID];
        if (index != NSNotFound)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            [self scrollToItemAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    // NSLog(@"starting scrolling animation");
    if (animated) {
        self.slidingView.userInteractionEnabled = NO;
    }
    CGFloat pageWidth = CGRectGetWidth(self.dummyView.frame);
    [self.dummyView setContentOffset:(CGPoint){ .x = indexPath.item * pageWidth, .y = 0 } animated:animated];
}

#pragma mark Data Source

- (void)fetchQuestAndCommentUploads
{
    self.quest = [self.dataStoreController questForServerID:self.questID];
    if (self.quest)
    {
        self.title = self.quest.title;
        ((DQTitleView *)self.navigationItem.titleView).text = self.title;
    }
    NSArray *sortedCommentUploads = [self.dataStoreController sortedCommentUploadsForQuest:self.quest];
    NSMutableOrderedSet *newGallery = [[NSMutableOrderedSet alloc] initWithArray:sortedCommentUploads ?: @[]];
    self.galleryObjects = newGallery;
}

- (void)loadGallery
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestCommentsForQuestWithServerID:self.questID forcedCommentID:self.focusedCommentID completionBlock:^(DQHTTPRequest *request) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *commentList = responseDictionary.dq_comments;
        NSDictionary *questDict = responseDictionary.dq_quest;

        [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:weakSelf.questID fromJSONList:commentList questJSONDictionary:questDict inBackground:YES resultsBlock:^(NSArray *objects) {
            [weakSelf handleGalleryLoadResponseForRequest:request JSONDict:responseDictionary objects:objects];
        }];
    } failureBlock:^(DQHTTPRequest *request) {
        [weakSelf handleGalleryLoadResponseForRequest:request JSONDict:nil objects:nil];
    }];
}

- (void)handleGalleryLoadResponseForRequest:(DQHTTPRequest *)request JSONDict:(NSDictionary *)JSONDict objects:(NSArray *)objects
{
    if (request.error)
    {
        if (request.responseStatusCode == 404)
        {
            [self transition:DQGalleryTransitionLoadGalleryNotFound
                    userInfo:
             @{
               @"error":request.error,
               @"errorTitle":DQLocalizedString(@"Unable to Refresh Gallery", @"Quest gallery refresh failure alert title")
               }];
        }
        else
        {
            [self transition:DQGalleryTransitionLoadGalleryFailed
                    userInfo:
             @{
               @"error":request.error,
               @"errorTitle":DQLocalizedString(@"Unable to Refresh Gallery", @"Quest gallery refresh failure alert title")
               }];
        }
    }
    else
    {
        if (!self.quest.content)
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
            ((DQTitleView *)self.navigationItem.titleView).text = self.title;
            self.prevPage = [JSONDict.dq_paginationPage.dq_paginationPreviousPage integerValue];
            self.nextPage = [JSONDict.dq_paginationPage.dq_paginationNextPage integerValue];
            [self.galleryObjects addObjectsFromArray:objects];
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

- (void)loadPreviousPage
{
    if ( ! (self.prevPage == 0 || self.prevPageRequest || self.prevPageFailedToLoad))
    {
        NSLog(@"requesting previous page");
        NSInteger page = self.prevPage;
        __weak typeof(self) weakSelf = self;
        self.prevPageRequest = [self.publicServiceController requestCommentsForQuestWithServerID:self.quest.serverID forcedCommentID:nil offset:@(page) direction:DQOffsetDirectionPrevious completionBlock:^(DQHTTPRequest *request) {
            weakSelf.prevPageFailedToLoad = NO;
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *commentList = responseDictionary.dq_comments;
            NSDictionary *questDict = responseDictionary.dq_quest;

            [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:weakSelf.questID fromJSONList:commentList questJSONDictionary:questDict inBackground:YES resultsBlock:^(NSArray *objects) {
                DQModelObject *focusedObject = [weakSelf focusedObject];
                NSMutableOrderedSet *newGallery = [[NSMutableOrderedSet alloc] initWithArray:objects];
                [newGallery addObjectsFromArray:[weakSelf.galleryObjects array]];
                weakSelf.galleryObjects = newGallery;

                NSInteger prevPage = [responseDictionary.dq_paginationPage.dq_paginationPreviousPage integerValue];
                weakSelf.prevPage = (weakSelf.prevPage || prevPage) ? prevPage : 0;

                [weakSelf reloadData];
                [weakSelf scrollToGalleryObject:focusedObject];
                [weakSelf pageRequestCompleted];
            }];
            weakSelf.prevPageRequest = nil;
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.prevPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            [weakSelf reloadData];
            weakSelf.prevPageRequest = nil;
        }];
    }
}

- (void)loadNextPage
{
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
                    [weakSelf.galleryObjects addObjectsFromArray:objects];
                }

                NSInteger nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];
                weakSelf.nextPage = (weakSelf.nextPage || nextPage) ? nextPage : 0;

                [weakSelf reloadData];
                [weakSelf pageRequestCompleted];
            }];
            weakSelf.nextPageRequest = nil;
        } failureBlock:^(DQHTTPRequest *request) {
            weakSelf.nextPageFailedToLoad = YES;
            [weakSelf showErrorWithTitle:DQLocalizedString(@"Unable to load page", @"Request for current page failed alert title") andDescription:request.error.dq_displayDescription];
            [weakSelf reloadData];
            weakSelf.nextPageRequest = nil;
        }];
    }
}

- (void)playbackButtonTappedForComment:(DQComment *)comment
{
    if (self.displayPlaybackBlock)
    {
        // set the focusedCommentID so that if we get a memory warning, when the
        // gallery reloads, it will load with this as the focusedComment instead
        // of the one passed into the initializer (ie: you won't "lose your place")
        self.focusedCommentID = comment.serverID;
        self.displayPlaybackBlock(self, self.quest, comment);
    }
}

- (void)drawButtonTapped:(id)sender
{
    if (self.quest)
    {
        if (self.drawThisQuestBlock)
        {
            self.drawThisQuestBlock(self);
        }
    }
    else
    {
        [self showErrorWithTitle:DQLocalizedString(@"Unable to Load Quest", @"Quest gallery load failure alert title") andDescription:DQLocalizedString(@"There was a problem loading this quest. Please return to the quest archive and try loading the the gallery again.", @"Quest gallery load failure alert message")];
        return;
    }
}

- (void)facebookButtonTappedForComment:(DQComment *)comment
{
    [self.sharingController showFacebookShareForComment:comment fromViewController:self source:(self.source ? [self.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
}

- (void)twitterButtonTappedForComment:(DQComment *)comment
{
    [self.sharingController showTwitterShareForComment:comment fromViewController:self source:(self.source ? [self.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
}

- (void)tumblrButtonTappedForComment:(DQComment *)comment
{
    [self.sharingController showTumblrShareForComment:comment fromViewController:self source:(self.source ? [self.source stringByAppendingString:@"/Gallery"] : @"Gallery")];
}

- (void)commentFlagged:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    [self.galleryObjects removeObject:comment];
    [self reloadData];
}

- (void)commentDeleted:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    [self.galleryObjects removeObject:comment];
    [self reloadData];
}

- (void)commentPlayed:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if (comment)
    {
        NSUInteger item = [self indexForCommentWithServerID:comment.serverID];
        if (item != NSNotFound)
        {
            NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:0];
            DQGalleryCell *cell = (DQGalleryCell *)[self.slidingView cellForItemAtIndexPath:path];
            [self refreshCell:cell atIndexPath:path withComment:comment];
        }
    }
}

- (void)refreshCell:(DQGalleryCell *)cell atIndexPath:(NSIndexPath *)indexPath withComment:(DQComment *)newComment
{
    if (cell && indexPath && newComment)
    {
        NSUInteger index = indexPath.item;
        if (index < [self.galleryObjects count] && [self.galleryObjects[index] isEqual:newComment])
        {
            self.galleryObjects[index] = newComment;
            UITableView *tableView = cell.tableView;
            if (tableView)
            {
                objc_setAssociatedObject(tableView, kDQGalleryCellTableViewCommentKey, newComment, OBJC_ASSOCIATION_RETAIN);
                // TODO: refactor these lines into -[DQGalleryCell takeStarCount:playbackCount:]
                DQGalleryCellTableHeader *headerView = (DQGalleryCellTableHeader *)tableView.tableHeaderView;
                headerView.footerView.starCount = [@(newComment.numberOfStars) description];
                headerView.footerView.playbackCount = [@(newComment.numberOfPlaybacks) description];
                [tableView reloadData];
            }
        }
    }
}

- (void)commentUploadCompleted:(NSNotification *)notification
{
    DQCommentUpload *commentUpload = [[notification userInfo] objectForKey:DQCommentUploadObjectNotificationKey];
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];

    NSUInteger index = [self.galleryObjects indexOfObject:commentUpload];
    if (index != NSNotFound)
    {
        [self.galleryObjects setObject:comment atIndexedSubscript:index];
        [self reloadData];
    }
}

- (void)reloadData
{
    [self.slidingView reloadData];
}

#pragma mark UITableViewDataSource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)inTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)inTableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.galleryObjects.count) {
        return 0;
    }


    DQModelObject *currentObject = objc_getAssociatedObject(inTableView, kDQGalleryCellTableViewCommentKey);
    if (![currentObject isKindOfClass:[DQComment class]]) {
        return 0;
    }

    DQComment *currentComment = (DQComment *)currentObject;
    return currentComment.numberOfReactions;
}

- (UITableViewCell *)tableView:(UITableView *)inTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DQGalleryActivityTableViewCell *cell = (DQGalleryActivityTableViewCell *)[inTableView dequeueReusableCellWithIdentifier:DQGalleryCommentCellReuseIdentifier];
    if (!cell) {
        cell = [[DQGalleryActivityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DQGalleryCommentCellReuseIdentifier];
    }

    DQComment *currentComment = (DQComment *)objc_getAssociatedObject(inTableView, kDQGalleryCellTableViewCommentKey);
    if (indexPath.row < currentComment.numberOfReactions)
    {
        NSDictionary *reactionInfo = [currentComment.sortedReactions objectAtIndex:indexPath.row];
        [cell initializeWithReactionInfo:reactionInfo];
    }
    cell.forCurrentUser = [currentComment.authorID isEqualToString:self.loggedInAccount.accountID];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we're assuming the comment uploads can't have anything their table view then?
    id obj = objc_getAssociatedObject(tableView, kDQGalleryCellTableViewCommentKey);
    if ([obj isKindOfClass:[DQComment class]])
    {
        DQComment *currentComment = (DQComment *)obj;

        NSDictionary *reactionInfo = nil;
        if (indexPath.row < currentComment.numberOfReactions)
        {
            reactionInfo = [currentComment.sortedReactions objectAtIndex:indexPath.row];
            [self displayProfileForUserWithUsername:reactionInfo.dq_userInfo.dq_userName fromGalleryObject:currentComment];
        }
    }
    else
    {
        // TODO: display an error mesage?
    }
}

- (CGFloat)tableView:(UITableView *)inTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 68.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // avoid crashes
    if ( ! ([self isViewLoaded] && (self.view.window != nil)) )
    {
        return;
    }
    if (object == self.slidingView && [keyPath isEqualToString:@"contentSize"]) {
        CGFloat ratio = (kItemSize.width + kItemSpacing) / CGRectGetWidth(self.slidingView.frame);
        self.dummyView.contentSize = CGSizeMake(self.slidingView.contentSize.width / ratio - 167, self.slidingView.contentSize.height);
    }
    else if(object == self.dummyView && [keyPath isEqualToString:@"contentOffset"]) {
        CGFloat ratio = (kItemSize.width + kItemSpacing) / CGRectGetWidth(self.slidingView.frame);
        CGPoint newOffset = CGPointMake(self.dummyView.contentOffset.x * ratio, self.dummyView.contentOffset.y);
        self.slidingView.contentOffset = newOffset;
        self.slidingView.userInteractionEnabled = YES;
    }
}

- (void)pageRequestCompleted
{
    DQModelObject *focusedObject = [self focusedObject];
    [self scrollToGalleryObject:focusedObject];
}

@end

