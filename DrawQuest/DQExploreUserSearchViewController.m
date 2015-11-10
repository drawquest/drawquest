//
//  DQExploreUserSearchViewController.m
//  DrawQuest
//
//  Created by Dirk on 4/19/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQExploreUserSearchViewController.h"
#import "DQLoadingView.h"
#import "DQTitleView.h"
#import "DQExploreSearchBar.h"
#import "UIColor+DQAdditions.h"
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"
#import "DQDataStoreController.h"
#import "DQExploreUserCell.h"
#import "DQUser.h"
#import "DQHUDView.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAccount.h"
#import "DQAnalyticsConstants.h"

typedef enum {
    DQExploreUserSearchFollowStateIndeterminate,
    DQExploreUserSearchFollowStateNotFollowing,
    DQExploreUserSearchFollowStateFollowing,
} DQExploreUserSearchFollowState;

static CGRect kSearchBarRect = { { 0.0f, 0.0f }, { 294.0f, 29.0f } };
static const CGSize kItemSize = { 502.0f, 60.0f };

static NSString *cellIdentifier = @"drawquest.explorer.userSearch.CellIdentifier";

@interface DQExploreUserSearchViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, DQExploreUserCellDelegate>
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) DQLoadingView *loadingView;
@property (nonatomic, weak) UIButton *searchButton;
@property (nonatomic, weak) UITextField *searchBar;
@property (nonatomic, strong) NSArray *users;
@end

@implementation DQExploreUserSearchViewController

- (void)dealloc
{
    self.searchBar.delegate = nil;
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1]];
    
    // Title Bar
    DQTitleView *titleView = [[DQTitleView alloc] initWithStyle:DQTitleViewStyleNavigationBar];
    NSString *title = @"               ";
    titleView.text = [title stringByAppendingString:DQLocalizedString(@"Explore", @"Title for section where users can explore for new content")];
    self.navigationItem.titleView = titleView;
    
    UIView *backOffsetView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 57.0f)];
    backOffsetView.backgroundColor = [UIColor clearColor];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = backOffsetView.bounds;
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    [backOffsetView addSubview:backButton];
    [backButton setImage:[UIImage imageNamed:@"button_topNav_back"] forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backOffsetView];

    DQExploreSearchBar *searchBar = [[DQExploreSearchBar alloc] initWithFrame:kSearchBarRect];
    [searchBar setDelegate:self];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
    [self.navigationItem.rightBarButtonItem setStyle:UIBarButtonItemStylePlain];
    self.searchBar = searchBar;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:kItemSize];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setMinimumLineSpacing:0.0f];
    [flowLayout setSectionInset:UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f)];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:flowLayout];
    [collectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [collectionView setDelegate:self];
    [collectionView setDataSource:self];
    [collectionView setBackgroundColor:[UIColor clearColor]];
    [collectionView setContentOffset:CGPointMake(0, -10)];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    
    [self.collectionView registerClass:[DQExploreUserCell class] forCellWithReuseIdentifier:cellIdentifier];
    
    // Loading View
    DQLoadingView *loadingView = [[DQLoadingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height)];
    [loadingView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
    [self.view addSubview:loadingView];
    self.loadingView = loadingView;
    [loadingView setHidden:YES];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:[UIImage imageNamed:@"search_Users_button"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake(0, 20, self.view.bounds.size.width, 66)];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if (DQSystemVersionAtLeast(@"7.0"))
    {
        CGRect frame = button.frame;
        frame.origin.y += 44;
        button.frame = frame;
    }
#endif
    [button setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [button setTitle:DQLocalizedString(@"Search for...", @"Search for user button title") forState:UIControlStateNormal];
    [button setTitleColor:[UIColor dq_userSearchAutocompleteFontColor] forState:UIControlStateNormal];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setContentEdgeInsets:UIEdgeInsetsMake(0.0f, 450.0f, 0.0f, 0.0f)];
    [button addTarget:self action:@selector(textFieldShouldReturn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.searchButton = button;

    [self.searchBar becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewSearchUsers withParameters:nil];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DQExploreUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setUser:self.users[indexPath.item] loggedInUsername:self.loggedInAccount.username];
    [cell setDelegate:self];

    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.users count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.displayProfileBlock)
    {
        DQUser *user = self.users[indexPath.item];
        self.displayProfileBlock(self, user.userName);
    }
}

#pragma mark - UISearchBarDelegate


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.searchButton setTitle:[NSString stringWithFormat:DQLocalizedString(@"Search for '%@'", @"Search for user autocomplete button title"), newText] forState:UIControlStateNormal];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.searchButton setHidden:NO];
    [self.collectionView reloadData];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.searchButton setHidden:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.searchButton setHidden:YES];
    [self.searchBar resignFirstResponder];
    
    [self.loadingView setHidden:NO];
    
    [self logEvent:DQAnalyticsEventSearchUsers withParameters:@{@"query": (self.searchBar.text ?: @"")}];
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestExploreUserSearchWithQuery:self.searchBar.text completionBlock:^(DQHTTPRequest *request) {
        typeof(self) _self = weakSelf;
        if (_self)
        {
            if (request.error)
            {
                [_self showError:request.error];
            }
            else
            {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSArray *userList = responseDictionary.dq_users;
                
                [_self.dataStoreController createOrUpdateUsersFromJSONList:userList inBackground:YES withCompletionBlock:^(NSArray *objects) {
                    _self.users = objects;
                    [_self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
                    [_self.collectionView reloadData];
                    [_self.loadingView setHidden:YES];
                }];
            }
        }
    }];
    
    return FALSE;
}


#pragma mark Follow / Unfollow

- (void)exploreUserCellDidTapFollowUser:(DQExploreUserCell *)cell
{
    DQUser *user = cell.user;
    
    if ([self.loggedInAccount.username isEqualToString:user.userName]) {
        if (self.displayProfileBlock)
        {
            self.displayProfileBlock(self, user.userName);
        }
        return;
    }
    

    DQHUDView *hudView = [[DQHUDView alloc] initWithFrame:self.view.bounds];
    [hudView showInView:self.view animated:YES];
    hudView.text = !user.isFollowing ? DQLocalizedStringWithDefaultValue(@"FollowingRequestPending", nil, nil, @"Following", @"Request fo follow a user is being completed indicator label") : DQLocalizedString(@"Unfollowing", @"Request to unfollow a user is being completed indicator label");

    [self logEvent:(user.isFollowing ? DQAnalyticsEventUnfollow : DQAnalyticsEventFollow) withParameters:@{@"source": @"Search-Users"}];
    __weak typeof(self) weakSelf = self;
    [self.privateServiceController requestFollow:!user.isFollowing forUserWithName:user.userName completionBlock:^(DQHTTPRequest *request, id JSONObject) {
        [hudView hideAnimated:YES];
        if (request)
        {
            if (request.error)
            {
                [weakSelf showErrorWithTitle:!user.isFollowing ? DQLocalizedString(@"Unable to Follow", @"Follow error alert title") : DQLocalizedString(@"Unable to Unfollow", @"Unfollow error alert title") description:request.error.dq_displayDescription];
            }
            else
            {
                [weakSelf.dataStoreController saveIsFollowing:!user.isFollowing forUser:user];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[weakSelf.users indexOfObject:user] inSection:0];
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }
        }
    }];
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
