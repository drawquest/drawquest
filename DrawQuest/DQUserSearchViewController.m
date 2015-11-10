//
//  DQUserSearchViewController.m
//  DrawQuest
//
//  Created by David Mauro on 11/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQUserSearchViewController.h"

// Models
#import "DQUser.h"

// Controllers
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"

// Views
#import "DQView.h"
#import "DQTableView.h"
#import "DQPhoneUserTableViewCell.h"
#import "DQAlertView.h"

// Additions
#import "DQAnalyticsConstants.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQUserSearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UITextField *textField;
@property (nonatomic, weak) DQTableView *tableView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;

@end

@implementation DQUserSearchViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 260.0f, 30.0f)];
        searchBar.delegate = self;
        self.textField = [[(UIView *)([searchBar.subviews objectAtIndex:0]) subviews] objectAtIndex:1];
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:DQLocalizedString(@"Search People", @"Search for users search field placeholder text") attributes:@{NSForegroundColorAttributeName: [UIColor dq_phoneLightGrayTextColor], NSFontAttributeName: [UIFont dq_phoneSearchPlaceholderFont]}];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
        self.searchBar = searchBar;
    }
    return self;
}

- (void)loadView
{
    DQView *view = [[DQView alloc] initWithFrame:CGRectZero];
    view.dq_tintColorDidChangeBlock = ^(DQView *view) {
        self.textField.textColor = view.tintColor;
    };
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
    self.spinner = spinner;

    DQTableView *tableView = [[DQTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 66.0f;
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.spinner.frameCenterX = self.view.boundsCenterX;
    self.spinner.frameY = 30.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    // Hack to override the search icon
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        UIView *searchGlass = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_search_Magnifying_glass"]];
        self.textField.leftView = searchGlass;
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewSearchUsers withParameters:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

/*
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //[self.textField becomeFirstResponder];
    UIView *searchGlass = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_search_Magnifying_glass"]];
    self.textField.leftView = searchGlass;
}
 */

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardBounds;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    CGFloat keyboardHeight = keyboardBounds.size.height - 50.0f; // Keyboard height gets reported too tall
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 0.0f, keyboardHeight, 0.0f);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // The normal text field attributes and such don't seem to work with the search bar's text field
    if ([searchText length])
    {
        self.textField.font = [UIFont dq_phoneSearchFont];
    }
    else
    {
        self.textField.font = [UIFont dq_phoneSearchPlaceholderFont];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    __weak typeof(self) weakSelf = self;

    self.users = @[];
    [self.tableView reloadData];
    [self.spinner startAnimating];
    [self.textField resignFirstResponder];

    [self logEvent:DQAnalyticsEventSearchUsers withParameters:@{@"query": (searchBar.text ?: @"")}];
    [self.publicServiceController requestExploreUserSearchWithQuery:searchBar.text completionBlock:^(DQHTTPRequest *request) {
        [weakSelf.spinner stopAnimating];
        if (weakSelf)
        {
            if (request.error)
            {
                DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") message:request.error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSArray *userList = responseDictionary.dq_users;

                [weakSelf.dataStoreController createOrUpdateUsersFromJSONList:userList inBackground:YES withCompletionBlock:^(NSArray *objects) {
                    weakSelf.users = objects;
                    [weakSelf.tableView reloadData];
                }];
            }
        }
    }];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    DQPhoneUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if ( ! cell)
    {
        cell = [[DQPhoneUserTableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cellID"];
    }
    DQUser *user = [self.users objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = user.userName;
    cell.avatarImageView.imageURL = user.galleryAvatarURL;
    if ( ! [user.userName isEqualToString:self.loggedInAccount.username])
    {
        [cell displayFollowButtonForUsername:user.userName];
    }
    cell.cellTappedBlock = ^(DQPhoneUserTableViewCell *cell) {
        if (weakSelf.showProfileBlock)
        {
            weakSelf.showProfileBlock(weakSelf, user.userName);
        }
    };
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

@end
