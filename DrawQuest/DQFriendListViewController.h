//
//  DQFriendListViewController.h
//  DrawQuest
//
//  Created by David Mauro on 6/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQButton.h"

@class DQFriendListViewController, DQAddFriendsAuthorizeView, DQButton;

@protocol DQFriendListViewControllerDataSource <NSObject>

- (NSString *)authorizationRequestMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController;
- (NSString *)emptyFriendListMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController;
- (NSString *)authorizationFailedMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController;

- (NSUInteger)numberOfRowsInFriendListViewController:(DQFriendListViewController *)friendListViewController;
- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController displayNameAtIndex:(NSUInteger)index;
- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController avatarImageURLAtIndex:(NSUInteger)index;
- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController dqUsernameAtIndex:(NSUInteger)index;

- (NSUInteger)numberOfInvitesSentOrPendingForFriendListViewController:(DQFriendListViewController *)friendListViewController;

@optional

- (UIImage *)friendListViewController:(DQFriendListViewController *)friendListViewController avatarImageAtIndex:(NSUInteger)index;

@end

@protocol DQFriendListViewControllerDelegate <NSObject>

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController hasPermissionsWithCompletionBlock:(void (^)(BOOL result))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)friendListViewController:(DQFriendListViewController *)friendListViewController requestPermissionsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock fromView:(UIView *)view;
- (void)friendListViewController:(DQFriendListViewController *)friendListViewController loadFriendsWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock noFriendsBlock:(dispatch_block_t)noFriendsBlock;
- (DQButton *)friendListViewController:(DQFriendListViewController *)friendListViewController requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock;

- (UIView *)friendListViewController:(DQFriendListViewController *)friendListViewController accessoryViewAtIndex:(NSUInteger)index;
- (void)friendListViewController:(DQFriendListViewController *)friendListViewController didSelectFriendAtIndex:(NSUInteger)index accessoryView:(UIView *)accessoryView;

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController sendPendingRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end

@interface DQFriendListViewController : UITableViewController // TODO: make a DQTableViewController<DQViewController>

@property (nonatomic, strong) DQAddFriendsAuthorizeView *authorizeView;
@property (nonatomic, strong) id<DQFriendListViewControllerDataSource> dataSource;
@property (nonatomic, strong) id<DQFriendListViewControllerDelegate> delegate;

// designated initializer
- (id)initWithDataSource:(id<DQFriendListViewControllerDataSource>)dataSource delegate:(id<DQFriendListViewControllerDelegate>)delegate;

- (id)initWithStyle:(UITableViewStyle)style MSDesignatedInitializer(initWithDataSource:delegate:);
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithDataSource:delegate:);

- (void)replaceAccessoryViewAtIndex:(NSUInteger)index withView:(UIView *)accessoryView;
- (void)reloadAccessoryViewAtIndex:(NSUInteger)index;

- (void)hasPermissions:(void (^)(BOOL result))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestPermissionsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock fromView:(UIView *)view;
- (void)loadFriendsWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock noFriendsBlock:(dispatch_block_t)noFriendsBlock;
- (DQButton *)requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock;
- (NSString *)authorizationRequestMessage;
- (NSString *)emptyFriendListMessage;
- (NSString *)authorizationFailedMessage;
- (NSUInteger)numberOfInvitesSentOrPending;

- (void)sendPendingRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end
