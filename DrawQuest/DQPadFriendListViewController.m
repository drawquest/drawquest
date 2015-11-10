//
//  DQPadFriendListViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadFriendListViewController.h"

// Views
#import "DQPadFriendListCell.h"

// Additions
#import "UIColor+DQAdditions.h"

@interface DQPadFriendListViewController ()

@end

@implementation DQPadFriendListViewController

- (id)initWithDataSource:(id<DQFriendListViewControllerDataSource>)dataSource delegate:(id<DQFriendListViewControllerDelegate>)delegate
{
    self = [super initWithDataSource:dataSource delegate:delegate];
    if (self)
    {
        self.tableView.backgroundColor = [UIColor dq_modalTableCellBackgroundColor];
        self.tableView.backgroundView = nil;
        self.tableView.layer.cornerRadius = 9.0f;
        self.tableView.rowHeight = 68.0f;
        self.tableView.layer.borderWidth = 1.0f;
        self.tableView.layer.borderColor = [[UIColor dq_modalTableSeperatorColor] CGColor];
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(5.0f, 0.0f, 5.0f, 1.0f);
    }
    return self;
}

#pragma mark - UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"FriendCell";

    DQPadFriendListCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (!cell)
    {
        cell = [[DQPadFriendListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    cell.avatarImageURL = [self.dataSource friendListViewController:self avatarImageURLAtIndex:indexPath.row];
    cell.displayName = [self.dataSource friendListViewController:self displayNameAtIndex:indexPath.row];
    cell.drawQuestUsername = [self.dataSource friendListViewController:self dqUsernameAtIndex:indexPath.row];

    cell.accessoryView = [self.delegate friendListViewController:self accessoryViewAtIndex:indexPath.row];

    return cell;
}

@end
