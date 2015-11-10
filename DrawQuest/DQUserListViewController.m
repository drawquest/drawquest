//
//  DQUserListViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/31/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQUserListViewController.h"

#import "DQUserTableViewCell.h"
#import "DQImageView.h"
#import "DQPublicServiceController.h"
#import "DQHTTPRequest.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "UIColor+DQAdditions.h"
#import "DQViewMetricsConstants.h"
#import "DQAnalyticsConstants.h"

static const CGFloat kDQUserListViewControllerRowHeight = 79.0f;

@interface DQUserListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) DQUserListType type;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSArray *usersInfo;

@end

@implementation DQUserListViewController

- (id)initWithUserName:(NSString *)inUserName userListType:(DQUserListType)type delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        _type = type;
        _userName = inUserName;
    }
    return self;
}

#pragma mark - UIViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor whiteColor];

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.backgroundView = nil;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = kDQUserListViewControllerRowHeight;

    tableView.backgroundView = nil;
    //tableView.scrollIndicatorInsets = UIEdgeInsetsMake(5.0f, 0.0f, 5.0f, 1.0f);
    [view addSubview:tableView];
    self.tableView = tableView;
    self.view = view;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    CGRect bounds = self.view.bounds;
    bounds = CGRectInset(bounds, 0, 0);
    self.tableView.frame = bounds;
    self.tableView.contentInset = UIEdgeInsetsMake(30.0f, 0.0f, 0.0f, 0.0f);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUserListFromServer];
    [self logEvent:DQAnalyticsEventViewUserList withParameters:@{@"type": (self.type == DQUserListTypeFollowers ? @"followers" : @"following")}];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark Accessors

- (void)setUsersInfo:(NSArray *)usersInfo
{
    _usersInfo = usersInfo;
    [self.tableView reloadData];
}

#pragma mark - Private Methods

- (void)updateUserListFromServer
{
    DQServiceCompletionBlock completionBlock = ^(DQHTTPRequest *request, id JSONObject) {
        self.usersInfo = (NSArray *)JSONObject;
    };

    DQServiceStatusBlock failureBlock = ^(DQHTTPRequest *request) {
        // TODO: handle errors
    };

    switch (self.type) {
        case DQUserListTypeFollowers:
            [self.publicServiceController requestFollowersForUserName:self.userName withCompletionBlock:completionBlock failureBlock:failureBlock];
            break;
        case DQUserListTypeFollowing:
            [self.publicServiceController requestFollowingForUserName:self.userName withCompletionBlock:completionBlock failureBlock:failureBlock];
            break;
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellID = @"UserCell";
    DQUserTableViewCell *cell = (DQUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[DQUserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID];
    }
    
    NSDictionary *currentUserInfo = [self.usersInfo objectAtIndex:indexPath.row];
    cell.usernameLabel.text = currentUserInfo.dq_userName;
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_pad"]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.usersInfo.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DQUserTableViewCell *userCell = (DQUserTableViewCell *)cell;
    
    NSDictionary *userInfo = [self.usersInfo objectAtIndex:indexPath.row];
    
    userCell.avatarView.imageURL = userInfo.dq_galleryUserAvatarURL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *userInfo = [self.usersInfo objectAtIndex:indexPath.row];
    if (self.displayProfileBlock)
    {
        self.displayProfileBlock(self, [userInfo dq_userName]);
    }
}


@end
