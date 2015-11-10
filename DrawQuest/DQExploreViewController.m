//
//  DQExploreViewController.m
//  DrawQuest
//
//  Created by Dirk on 4/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQExploreViewController.h"
#import "DQExploreLayout.h"
#import "DQPublicServiceController.h"
#import "DQLoadingView.h"
#import "DQTitleView.h"
#import "DQExploreCell.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQGalleryViewController.h"
#import "DQExploreSearchBar.h"
#import "DQAnalyticsConstants.h"

static CGRect kSearchBarRect = { { 0.0f, 0.0f }, { 294.0f, 29.0f } };
static CGRect kRefreshButtonRect = { { 0.0f, 0.0f }, { 21.0f, 21.0f } };

static NSString *cellIdentifier = @"drawquest.ExplorerCellIdentifier";

@interface DQExploreViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate>

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) DQLoadingView *loadingView;
@property (nonatomic, weak) UITextField *searchBar;
@property (nonatomic, strong) NSArray *exploreComments;
@property (nonatomic, strong) NSArray *displayedExploreComments;
@property (nonatomic, assign) NSInteger displaySize;
@property (nonatomic, assign) BOOL searchEnabled;

@end

@implementation DQExploreViewController

- (void)dealloc
{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

- (id)initWithSearchEnabled:(BOOL)searchEnabled delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _searchEnabled = searchEnabled;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1]];
    
    // Title Bar
    DQTitleView *titleView = [[DQTitleView alloc] initWithStyle:DQTitleViewStyleNavigationBar];
    NSString *title = @"                           ";
    titleView.text = [title stringByAppendingString:DQLocalizedString(@"Explore", @"Title for section where users can explore for new content")];
    self.navigationItem.titleView = titleView;

    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton setImage:[UIImage imageNamed:@"button_refresh_light"] forState:UIControlStateNormal];
    [refreshButton setFrame:kRefreshButtonRect];
    [refreshButton addTarget:self action:@selector(refreshButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *refreshButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];

    if (self.searchEnabled)
    {
        DQExploreSearchBar *searchBar = [[DQExploreSearchBar alloc] initWithFrame:kSearchBarRect];
        [searchBar setDelegate:self];
        UIBarButtonItem *searchBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
        searchBarButtonItem.style = UIBarButtonItemStylePlain;

        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 10;

        self.navigationItem.rightBarButtonItems = @[searchBarButtonItem, fixedSpace, refreshButtonItem];
        self.searchBar = searchBar;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = refreshButtonItem;
    }
    
    DQExploreLayout *exploreLayout = [[DQExploreLayout alloc] init];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:exploreLayout];
    [collectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [collectionView setDelegate:self];
    [collectionView setDataSource:self];
    [collectionView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    
    [self.collectionView registerClass:[DQExploreCell class] forCellWithReuseIdentifier:cellIdentifier];
    [self.collectionView setHidden:YES];
    
    // Loading View
    DQLoadingView *loadingView = [[DQLoadingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height)];
    [loadingView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
    [self.view addSubview:loadingView];
    self.loadingView = loadingView;

    [self loadComments];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewExplore withParameters:nil];
}

- (void)loadComments
{
    [self.publicServiceController requestExploreCommentsWithCompletionBlock:^(DQHTTPRequest *request) {

        [self.loadingView setHidden:YES];
        [self.collectionView setHidden:NO];

        if (request.error) {
            [self showError:request.error];
            return;
        }

        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *commentList = responseDictionary.dq_comments;

        NSMutableArray *comments = [NSMutableArray new];
        for (NSDictionary *currentCommentInfo in commentList) {
            @autoreleasepool {
                DQExploreComment *comment = [[DQExploreComment alloc] initWithJSONDictionary:currentCommentInfo];
                [comments addObject:comment];
            }
        }

        self.displaySize = (NSInteger)[comments count];
        self.exploreComments = comments;

        if (self.exploreComments)
        {
            [self displayComments];
        }
        else
        {
            [self showErrorWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") description:DQLocalizedString(@"There are no featured drawings to show right now. Try again later.", @"Empty explore page message")];
        }
    }];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DQExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    int position = indexPath.item % 10;
    
    if (position == 0 || position == 9) {
        [cell setCellSize:DQExploreCellSizeLarge];
    } else {
        [cell setCellSize:DQExploreCellSizeSmall];
    }

    [cell setComment:self.displayedExploreComments[indexPath.item]];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.displayedExploreComments count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tappedCommentBlock)
    {
        DQExploreComment *comment = self.displayedExploreComments[indexPath.item];
        self.tappedCommentBlock(self, comment.questID, comment.commentID);
    }
}

- (void)refreshButtonTapped
{
    [self logEvent:DQAnalyticsEventRefreshExplore withParameters:nil];
    [self loadComments];
}

- (void)displayComments
{
    if (self.exploreComments)
    {
        NSMutableArray *displayItems = [self.exploreComments mutableCopy];
        
        if (self.forcedCommentID) {
            NSIndexSet *indexes = [displayItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if ([[obj commentID] isEqualToString:self.forcedCommentID]) {
                    if (NULL != stop) {
                        *stop = YES;
                    }
                    return YES;
                } else {
                    return NO;
                }
            }];
            
            NSInteger index = [indexes firstIndex];
            if (index != NSNotFound)
            {
                id o = displayItems[index];
                [displayItems removeObjectAtIndex:index];
                [displayItems insertObject:o atIndex:0];
            }
            self.forcedCommentID = nil;
        }
        
        self.displayedExploreComments = displayItems;

        [self.collectionView reloadData];
        [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
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

#pragma mark - UISearchBarDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.searchBar endEditing:TRUE];
    if (self.displaySearchBlock)
    {
        self.displaySearchBlock(self);
    }
    return NO;
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end
