//
//  DQFriendListViewController.m
//  DrawQuest
//
//  Created by David Mauro on 6/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFriendListViewController.h"

// Frameworks
#import <QuartzCore/QuartzCore.h>

// View Controllers
#import "DQPadFriendListViewController.h"
#import "DQPhoneFriendListViewController.h"

// Views
#import "DQPadFriendListCell.h"

// Additions
#import "UIColor+DQAdditions.h"

@implementation DQFriendListViewController

- (id)initWithDataSource:(id<DQFriendListViewControllerDataSource>)dataSource delegate:(id<DQFriendListViewControllerDelegate>)delegate
{
    if ([self class] == [DQFriendListViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadFriendListViewController alloc] initWithDataSource:dataSource delegate:delegate];
        }
        else
        {
            self = [[DQPhoneFriendListViewController alloc] initWithDataSource:dataSource delegate:delegate];
        }
    }
    else
    {
        self = [super initWithStyle:UITableViewStylePlain];
        if (self)
        {
            _dataSource = dataSource;
            _delegate = delegate;
        }
    }
    return self;
}

- (void)replaceAccessoryViewAtIndex:(NSUInteger)index withView:(UIView *)accessoryView
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.accessoryView = accessoryView;
}

- (void)reloadAccessoryViewAtIndex:(NSUInteger)index
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.accessoryView = [self.delegate friendListViewController:self accessoryViewAtIndex:index];
}

- (void)hasPermissions:(void (^)(BOOL))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate friendListViewController:self hasPermissionsWithCompletionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestPermissionsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock fromView:(UIView *)view
{
    [self.delegate friendListViewController:self requestPermissionsWithCancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock accountSelectedBlock:accountSelectedBlock fromView:view];
}

- (void)loadFriendsWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock noFriendsBlock:(dispatch_block_t)noFriendsBlock
{
    [self.delegate friendListViewController:self loadFriendsWithCompletionBlock:completionBlock failureBlock:failureBlock noFriendsBlock:noFriendsBlock];
}

- (DQButton *)requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock
{
    return [self.delegate friendListViewController:self requestAccessButtonWithTappedBlock:tappedBlock];
}

- (NSString *)authorizationRequestMessage
{
    return [self.dataSource authorizationRequestMessageForFriendListViewController:self];
}

- (NSString *)emptyFriendListMessage
{
    return [self.dataSource emptyFriendListMessageForFriendListViewController:self];
}

- (NSString *)authorizationFailedMessage
{
    return [self.dataSource authorizationFailedMessageForFriendListViewController:self];
}

- (NSUInteger)numberOfInvitesSentOrPending
{
    return [self.dataSource numberOfInvitesSentOrPendingForFriendListViewController:self];
}

- (void)sendPendingRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    [self.delegate friendListViewController:self sendPendingRequestsWithCancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfRowsInFriendListViewController:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    return [self.delegate friendListViewController:self didSelectFriendAtIndex:indexPath.row accessoryView:cell.accessoryView];
}

@end
