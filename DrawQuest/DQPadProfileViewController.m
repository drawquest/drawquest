//
//  DQPadProfileViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadProfileViewController.h"
#import <MessageUI/MessageUI.h>

// Additions
#import "DQAnalyticsConstants.h"
#import "STUtils.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

// Model
#import "DQAccount.h"
#import "DQComment.h"
#import "DQUser.h"
#import "DQQuest.h"

// Controllers
#import "DQDataStoreController.h"
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"
#import "STHTTPResourceController.h"

// Views
#import "DQPadProfileHeaderView.h"
#import "DQGridViewCell.h"
#import "DQProfileInfoView.h"
#import "STGridView.h"
#import "DQTitleView.h"
#import "DQLoadingView.h"
#import "DQImageView.h"
#import "DQHUDView.h"
#import "DQGridSectionHeader.h"
#import "DQGridSectionFooter.h"
#import "DQWebProfileLinksView.h"
#import "DQPhoneFollowButton.h"

NSString *DQProfileViewControllerReloadDataNotification = @"DQProfileViewControllerReloadDataNotification";

@interface DQPadProfileViewController () <STGridViewDataSource, STGridViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) IBOutlet STGridView *gridView;
@property (nonatomic, strong) DQPadProfileHeaderView *topHeaderView;
@property (nonatomic, strong) DQLoadingView *loadingView;
@property (nonatomic, strong) UIView *sparseView;
@property (nonatomic, assign) BOOL finishedLoading;
@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UIBarButtonItem *shopButtonItem;
@property (nonatomic, strong) DQGridSectionHeader *sectionHeader;
@property (nonatomic, strong) DQGridSectionFooter *sectionFooter;
@property (nonatomic, strong) NSArray *rightBarButtons;

@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *inviteFriendButton;


@property (nonatomic, assign) NSInteger nextPage;
@property (nonatomic, assign) BOOL loadingNextPage;
@property (nonatomic, assign) BOOL nextPageFailedToLoad;

@end

@implementation DQPadProfileViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQFollowStateChangedNotification object:nil];
}

- (void)initializeHeaderForUser
{
    if (!self.user)
    {
        return;
    }

    ((DQTitleView *)self.navigationItem.titleView).text = DQLocalizedString(@"Profile", @"Label for the user's own profile");

    self.topHeaderView.nameLabel.text = self.user.userName;
    self.topHeaderView.coinsLabel.text = [self.user.coinCount stringValue];

    NSString *drawingsTitle = DQLocalizedString(@"Drawings", @"Label for a colleciton of drawings");
    NSString *followersTitle = DQLocalizedString(@"Followers", @"Label for a collection of users a particular user is following");
    NSString *followingTitle = DQLocalizedStringWithDefaultValue(@"FollowingUserListLabel", nil, nil, @"Following", @"Label for a collection of users following a particular user");
    [self.topHeaderView.drawingsButton setTitle:[NSString stringWithFormat:[drawingsTitle stringByAppendingString:@"\n%@"], self.user.commentsCount] forState:UIControlStateNormal];
    [self.topHeaderView.followersButton setTitle:[NSString stringWithFormat:[followersTitle stringByAppendingString:@"\n%@"], self.user.followerCount] forState:UIControlStateNormal];
    [self.topHeaderView.followingButton setTitle:[NSString stringWithFormat:[followingTitle stringByAppendingString:@"\n%@"], self.user.followingCount] forState:UIControlStateNormal];
    
    self.topHeaderView.bioText = self.user.bio;

    self.topHeaderView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.topHeaderView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.topHeaderView.layer.shadowOpacity = 0.05f;
    self.topHeaderView.layer.shadowRadius = 0.0f;

    if (!self.isForLoggedInUser) {
        self.navigationItem.rightBarButtonItem = nil;

        if (self.loggedInAccount)
        {
            UIView *rightItemsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _rightBarButtons.count * 30, 25)];
            for (int i = 0; i < _rightBarButtons.count; i++) {
                UIView *view = _rightBarButtons[i];
                view.frameX = 30 * i;
                [rightItemsView addSubview:view];
            }
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItemsView];
        }
    } else {
        if (!self.user.bio.length) {
            self.topHeaderView.bioText = DQLocalizedString(@"Tap here to say something about yourself!", @"User biographical field placeholder text prompting user to tap the field");
        }

        UIView *rightItemsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _rightBarButtons.count * 45, 25)];
        for (int i = 0; i < _rightBarButtons.count; i++) {
            UIView *view = _rightBarButtons[i];
            view.frameX = 45 * i + 15.0f;
            [rightItemsView addSubview:view];
        }
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItemsView];
        

        UITapGestureRecognizer *bioGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSettingsGesture:)];
        [self.topHeaderView.bioLabel addGestureRecognizer:bioGestureRecognizer];

        UITapGestureRecognizer *avatarGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSettingsGesture:)];
        [self.topHeaderView.userImageView addGestureRecognizer:avatarGestureRecognizer];
    }

    [self.topHeaderView.userImageView setImageWithURL:self.user.avatarURL placeholderImage:nil completionBlock:nil failureBlock:nil];
    [self.topHeaderView.nameView setNeedsLayout];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.comments = nil;
        self.finishedLoading = NO;
        self.view = nil;
        self.loadingView = nil;
        self.sparseView = nil;
        self.topHeaderView = nil;
        self.backgroundView = nil;
        self.sectionHeader = nil;
        self.sectionFooter = nil;
        self.shopButtonItem = nil;
        self.navigationItem.titleView = nil;
        self.nextPage = 0;
        self.loadingNextPage = NO;
        self.nextPageFailedToLoad = NO;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark - Accessors

- (void)setUser:(DQUser *)user
{
    [super setUser:user];
    self.topHeaderView.followButton.username = user.userName;
    [self updateViewState];
}

- (void)setIsForLoggedInUser:(BOOL)isForLoggedInUser
{
    [super setIsForLoggedInUser:isForLoggedInUser];
    self.topHeaderView.isForLoggedInUser = isForLoggedInUser;
}

#pragma mark - Actions

- (void)showSettingsGesture:(UIGestureRecognizer *)recognizer
{
    [self settingsButtonPressed:nil];
}

- (void)settingsButtonPressed:(id)sender
{
    if (self.displaySettingsBlock)
    {
        self.displaySettingsBlock(self);
    }
}

- (void)shopButtonPressed:(id)sender
{
    if (self.shopBlock)
    {
        self.shopBlock(self);
    }
}

- (void)followUnfollowButtonPressed:(NSNotification *)notification
{
    NSString *username = [notification object];
    if ([self.user.userName isEqualToString:username] || [self.userName isEqualToString:username])
    {
        [self refreshProfileInfo];
    }
}

- (void)inviteFriendsButtonPressed:(id)sender
{
    if (self.inviteFriendsBlock)
    {
        self.inviteFriendsBlock(self);
    }
}

- (void)followingViewTapped:(UITapGestureRecognizer *)recognizer
{
    if (self.displayFollowingBlock)
    {
        self.displayFollowingBlock(self);
    }
}

- (void)followersViewTapped:(UITapGestureRecognizer *)recognizer
{
    if (self.displayFollowersBlock)
    {
        self.displayFollowersBlock(self);
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultSent) {
        [self logEvent:DQAnalyticsEventSendInviteEmail withParameters:[self eventLoggingParameters]];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Data Store

- (void)refreshProfileInfo
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestProfileInfoForUsername:self.userName completionBlock:^(DQHTTPRequest *request) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *infoArray = [NSArray arrayWithObject:responseDictionary];

        [weakSelf.dataStoreController createOrUpdateUsersFromJSONList:infoArray inBackground:YES withCompletionBlock:^(NSArray *objects) {
            DQUser *user = [objects firstObject];
            [self updateUserFromNetwork:user];
            // Get Profile URLs directly for now
            UIView *webProfileLinksView = [[DQWebProfileLinksView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.topHeaderView.frameWidth, 35.0f)
                                                                                 dqURL:[responseDictionary stringForKey:@"web_profile_url"]
                                                                                 fbURL:[responseDictionary stringForKey:@"facebook_url"]
                                                                                 twURL:[responseDictionary stringForKey:@"twitter_url"]];
            [weakSelf.topHeaderView.socialButtonsView addSubview:webProfileLinksView];
            [weakSelf.topHeaderView.socialButtonsView bringSubviewToFront:webProfileLinksView];
            weakSelf.finishedLoading = YES;
        }];
    } failureBlock:^(DQHTTPRequest *request) {
        weakSelf.finishedLoading = YES;
        NSString *errorDescription = request.error.dq_displayDescription;
        if (request.responseStatusCode == 404)
        {
            errorDescription = DQLocalizedString(@"Sorry that profile no longer exists.", @"User profile not found on server error alert message");
        }
        [weakSelf showErrorWithTitle:DQLocalizedString(@"Profile error:", @"Profile error alert title") description:errorDescription];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)updateUserFromNetwork:(DQUser *)user
{
    if (!self.userName.length) {
        return;
    }

    if (!user) {
        [self updateViewState];
        return;
    }

    self.user = user;
    [self initializeHeaderForUser];
}

- (void)updateUserFromCache
{
    if (!self.userName.length) {
        return;
    }

    DQUser *cachedUser = [self.dataStoreController userForUserName:self.userName];
    if (!cachedUser) {
        [self updateViewState];
        return;
    }

    self.user = cachedUser;
    [self initializeHeaderForUser];
}

#pragma mark - Notifications

- (void)usersUpdated:(NSNotification *)inNotification
{
    [self updateUserFromCache];
}

- (void)profileUpdated:(NSNotification *)inNotification
{
    [self refreshProfileInfo];
}

- (void)coinBalanceUpdated:(NSNotification *)inNotification
{
    self.topHeaderView.nameView.bottomLabel.text = [self.user.coinCount stringValue];
}

- (void)commentDeleted:(NSNotification *)inNotification
{
    if (self.comments)
    {
        DQComment *comment = [[inNotification userInfo] objectForKey:DQCommentObjectNotificationKey];
        NSUInteger indexOfComment = [self.comments indexOfObjectIdenticalTo:comment];
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, [self.comments count])];
        [indexes removeIndex:indexOfComment];
        self.comments = [self.comments objectsAtIndexes:indexes];
        [self.gridView reloadData];
    }
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    __weak typeof(self) weakSelf = self;

    [super viewDidLoad];
    self.gridView.dataSource = self;
    self.gridView.delegate = self;

    self.view.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
    self.gridView.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];

    // Loading View
    self.loadingView = [[DQLoadingView alloc] initWithFrame:self.view.bounds];

    // Sparse View
    UIView *sparseView = [[UIView alloc] initWithFrame:self.view.bounds];
    sparseView.backgroundColor = [UIColor clearColor];
    _sparseView = sparseView;

    // Header View
    self.topHeaderView = [[DQPadProfileHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.gridView.bounds), 333.0f)];
    self.topHeaderView.showShopBlock = ^(DQPadProfileHeaderView *view) {
        if (weakSelf.showShopBlock)
        {
            weakSelf.showShopBlock(weakSelf);
        }
    };
    self.gridView.gridHeaderView = self.topHeaderView;
    self.gridView.frameY = 74.0f;

    UITapGestureRecognizer *followingTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followingViewTapped:)];
    [self.topHeaderView.followingButton addGestureRecognizer:followingTapRecognizer];

    UITapGestureRecognizer *followersTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followersViewTapped:)];
    [self.topHeaderView.followersButton addGestureRecognizer:followersTapRecognizer];

    self.topHeaderView.isForLoggedInUser = self.isForLoggedInUser;

    // Background View
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    self.backgroundView = view;

    self.sectionHeader = [[DQGridSectionHeader alloc] initWithFrame:CGRectZero];

  
    [self.sectionHeader.titleLabel setText:@""];
    self.sectionFooter = [[DQGridSectionFooter alloc] initWithFrame:CGRectZero];

    [self.sectionFooter addTarget:self action:@selector(loadMorePressed:) forControlEvents:UIControlEventTouchUpInside];

    if (self.loggedInAccount)
    {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        if (self.isForLoggedInUser) {
            // Settings Button Item
            UIImage *settingsImage = [UIImage imageNamed:@"button_topNav_settings"];
            UIView *settingsOffsetView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, settingsImage.size.width, settingsImage.size.height)];
            settingsOffsetView.backgroundColor = [UIColor clearColor];
            _settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _settingsButton.frame = settingsOffsetView.bounds;
            [_settingsButton addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [settingsOffsetView addSubview:_settingsButton];
            [_settingsButton setImage:settingsImage forState:UIControlStateNormal];
            _settingsButton.imageView.contentMode = UIViewContentModeCenter;
            
            // Invite Friends Item
            UIImage *friendsImage = [UIImage imageNamed:@"button_topNav_addPeople"];
            UIView *friendsOffsetView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, friendsImage.size.width, friendsImage.size.height)];
            friendsOffsetView.backgroundColor = [UIColor clearColor];
            _inviteFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _inviteFriendButton.frame = friendsOffsetView.bounds;
            [_inviteFriendButton addTarget:self action:@selector(inviteFriendsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [friendsOffsetView addSubview:_inviteFriendButton];
            [_inviteFriendButton setImage:friendsImage forState:UIControlStateNormal];
            _inviteFriendButton.imageView.contentMode = UIViewContentModeCenter;
            
            [items addObjectsFromArray:@[settingsOffsetView, friendsOffsetView]];
        }

        
        // Shop Button Item
        UIImage *shopImage = [UIImage imageNamed:@"button_topNav_shop"];
        UIView *shopOffsetView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, shopImage.size.width, shopImage.size.height)];
        shopOffsetView.backgroundColor = [UIColor clearColor];
        UIButton *shopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shopButton.frame = shopOffsetView.bounds;
        [shopButton addTarget:self action:@selector(shopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [shopOffsetView addSubview:shopButton];
        [shopButton setImage:shopImage forState:UIControlStateNormal];
        shopButton.imageView.contentMode = UIViewContentModeCenter;
        
        [items addObject:shopOffsetView];
        
        self.rightBarButtons = items;
    }

    // Title Bar
    DQTitleView *titleView = [[DQTitleView alloc] initWithStyle:DQTitleViewStyleNavigationBar];
    titleView.text = @"";
    self.navigationItem.titleView = titleView;

    [self.publicServiceController requestCommentsForUsername:self.userName page:nil completionBlock:^(DQHTTPRequest *request) {
        if (weakSelf)
        {
            NSDictionary *responseDictionary = request.dq_responseDictionary;

            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:responseDictionary.dq_comments inBackground:YES resultsBlock:^(NSArray *objects) {
                weakSelf.nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];
                weakSelf.comments = objects ? [NSArray arrayWithArray:objects] : @[];
                [weakSelf updateViewState];
                [weakSelf.gridView reloadData];
            }];
        }
    } failureBlock:^(DQHTTPRequest *request) {
        if (weakSelf)
        {
            // TODO: error handling?
            [weakSelf updateViewState];
            [weakSelf.gridView reloadData];
        }
    }];

    [self updateViewState];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(followUnfollowButtonPressed:) name:DQFollowStateChangedNotification object:nil];

    [self updateUserFromCache];
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.gridView.contentInset = UIEdgeInsetsMake(-17, 0, 0, 0);

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    [self refreshProfileInfo];

    // This is getting set to 81 the first time we go back to a profile using the back button
    UIEdgeInsets contentInset = self.gridView.contentInset;
    contentInset.top = 0.0f;
    self.gridView.contentInset = contentInset;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQFollowStateChangedNotification object:nil];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Grid View

- (void)updateViewState
{
    if (!self.user) {
        [self.gridView removeFromSuperview];

        if (self.finishedLoading) {
            [self.loadingView removeFromSuperview];
            [self.view addSubview:self.sparseView];
        } else {
            [self.sparseView removeFromSuperview];
            [self.view addSubview:self.loadingView];
        }
    } else {
        [self.loadingView removeFromSuperview];
        [self.sparseView removeFromSuperview];
        [self.view addSubview:self.gridView];
    }
}

- (void)reloadData
{
    [self.gridView reloadData];
}

#pragma mark - Pagination Methods

- (void)loadNextPage
{
    if (!self.nextPage || self.loadingNextPage || self.nextPageFailedToLoad) {
        [self.sectionFooter setSectionState:DQGridSectionFooterStateLoaded];
        self.loadingNextPage = NO;
        return;
    }

    self.loadingNextPage = YES;

    [self.sectionFooter setSectionState:DQGridSectionFooterStateLoading];

    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestCommentsForUsername:self.userName page:@(self.nextPage) completionBlock:^(DQHTTPRequest *request) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:responseDictionary.dq_comments inBackground:YES resultsBlock:^(NSArray *objects) {
            NSInteger nextPage = [responseDictionary.dq_paginationPage.dq_paginationNextPage integerValue];

            weakSelf.comments = weakSelf.comments ? [weakSelf.comments arrayByAddingObjectsFromArray:objects] : [NSArray arrayWithArray:objects];

            if (!nextPage || !weakSelf.nextPage) {
                weakSelf.nextPage = nil;
            } else if (weakSelf.nextPage > nextPage) {
                weakSelf.nextPage = nextPage;
            }

            [weakSelf.gridView reloadData];
            weakSelf.loadingNextPage = NO;

            [weakSelf.sectionFooter setSectionState:DQGridSectionFooterStateLoaded];
        }];
    } failureBlock:^(DQHTTPRequest *request) {
        [weakSelf.sectionFooter setSectionState:DQGridSectionFooterStateLoadFailed];
        [weakSelf.gridView reloadData];
        weakSelf.loadingNextPage = NO;
        weakSelf.nextPageFailedToLoad = YES;
    }];
}

- (void)loadMorePressed:(id)sender
{
    if (self.nextPageFailedToLoad) {
        self.nextPageFailedToLoad = NO;
        [self loadNextPage];
    }
}

#pragma mark - STGridViewDataSource

- (STGridViewCell *)STGridView:(STGridView *)inGridView cellForIndexPath:(NSIndexPath *)inIndexPath
{
    static NSString *CellID = @"GridCell";
    DQGridViewCell *cell = (DQGridViewCell *)[inGridView dequeueReusableCellWithIdentifier:CellID];
    if(!cell) {
        cell = [[DQGridViewCell alloc] initWithReuseIdentifier:CellID];
    }

    return cell;
}

- (void)STGridView:(STGridView *)tableView willDisplayCell:(STGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == (self.comments.count - 1)) {
        [self loadNextPage];
    }

    DQGridViewCell *gridCell = (DQGridViewCell *)cell;
    BOOL validIndex = indexPath.row < [self.comments count];
    DQComment *currentComment = validIndex ? [self.comments objectAtIndex:indexPath.row] : nil;

    gridCell.titleLabel.text = currentComment.questTitle;
    gridCell.timestampLabel.timestamp = currentComment.timestamp;

    // Load the drawing image
    gridCell.imageView.imageURL = [currentComment imageURLForKey:DQImageKeyArchive];
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
    return [self.comments count];
}

- (NSInteger)numberOfColumnsForSection:(NSInteger)inSection inSTGridView:(STGridView *)inGridView
{
    return 5;
}

- (NSInteger)minimumCellColumnSpanForSection:(NSInteger)inSection inSTGridView:(STGridView *)inGridView
{
    return 1;
}

#pragma mark - STGridViewDelegate

- (CGFloat)STGridView:(STGridView *)inGridView minimumRowHeightForSection:(NSInteger)inSection
{
    return 180.0f;
}

- (CGFloat)STGridView:(STGridView *)inGridView preferredRowHeightForCellAtIndexPath:(NSIndexPath *)inIndexPath
{
    return 190.0f;
}

- (void)STGridView:(STGridView *)inGridView didSelectCellAtIndexPath:(NSIndexPath *)inIndexPath
{
    if (inIndexPath.row < [self.comments count])
    {
        DQComment *selectedComment = [self.comments objectAtIndex:inIndexPath.row];

        if (selectedComment && self.displayGalleryForCommentBlock)
        {
            self.displayGalleryForCommentBlock(self, selectedComment);
        }
    }
}

- (UIView *)STGridView:(STGridView *)gridView viewForHeaderInSection:(NSInteger)inSection
{
     return _gradientView;
}

- (CGFloat)STGridView:(STGridView *)gridView heightForHeaderInSection:(NSInteger)inSection
{
    return 27.0f;
}

- (UIView *)STGridView:(STGridView *)gridView viewForFooterInSection:(NSInteger)inSection
{
    return [self.comments count] ? self.sectionFooter : nil;
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
    return UIEdgeInsetsMake(0.0f, 0.0f, 75.0f, 0.0f);
}

@end
