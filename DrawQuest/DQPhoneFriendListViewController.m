//
//  DQPhoneFriendListViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneFriendListViewController.h"

#import "DQPhoneFriendListCell.h"

#import "UIColor+DQAdditions.h"

@interface DQPhoneFriendListViewController ()

@end

@implementation DQPhoneFriendListViewController

- (id)initWithDataSource:(id<DQFriendListViewControllerDataSource>)dataSource delegate:(id<DQFriendListViewControllerDelegate>)delegate
{
    self = [super initWithDataSource:dataSource delegate:delegate];
    if (self)
    {
        // Set up tableView
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = [UIColor dq_phoneBackgroundColor];
        self.tableView.separatorColor = [UIColor dq_phoneTableSeperatorColor];
        self.tableView.rowHeight = kDQPhoneFriendListCellDesiredHeight;
    }
    return self;
}

#pragma mark - UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"FriendCell";

    DQPhoneFriendListCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (!cell)
    {
        cell = [[DQPhoneFriendListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }

    if ([self.dataSource respondsToSelector:@selector(friendListViewController:avatarImageAtIndex:)])
    {
        cell.avatarImageView.image = [self.dataSource friendListViewController:self avatarImageAtIndex:indexPath.row];
    }
    else
    {
        cell.avatarImageView.imageURL = [self.dataSource friendListViewController:self avatarImageURLAtIndex:indexPath.row];
    }
    [cell setDisplayName:[self.dataSource friendListViewController:self displayNameAtIndex:indexPath.row]];
    [cell setUserName:[self.dataSource friendListViewController:self dqUsernameAtIndex:indexPath.row]];

    cell.accessoryView = [self.delegate friendListViewController:self accessoryViewAtIndex:indexPath.row];

    return cell;
}

#pragma mark - UITableViewDelegate Methods (don't show dividers that shouldn't be there)

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

@end
