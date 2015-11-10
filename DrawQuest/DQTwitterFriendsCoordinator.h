//
//  DQTwitterFriendsCoordinator.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/18/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFriendListViewController.h"

@class DQTwitterController, DQPublicServiceController, DQPrivateServiceController, DQHTTPRequest;

@interface DQTwitterFriendsCoordinator : NSObject <DQFriendListViewControllerDataSource, DQFriendListViewControllerDelegate>

@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSDictionary *friendsOnDrawQuest;
@property (nonatomic, strong) NSDictionary *followersOnDrawQuest;
@property (nonatomic, strong) NSMutableIndexSet *followingOrInvitedFriends;
@property (nonatomic, strong, readonly) DQPublicServiceController *publicServiceController;
@property (nonatomic, strong, readonly) DQPrivateServiceController *privateServiceController;
@property (nonatomic, strong, readonly) NSMutableIndexSet *selectedFriends;
@property (nonatomic, assign) NSUInteger *invitesSent;
@property (nonatomic, copy) void (^messageForInviteBlock)(NSString *inChannel, void (^completionBlock)(NSString *));

- (instancetype)initWithTwitterController:(DQTwitterController *)twitterController publicServiceController:(DQPublicServiceController *)publicServiceController privateServiceController:(DQPrivateServiceController *)privateServiceController;

- (void)followUserAtIndex:(NSInteger)index withCompletionBlock:(void (^)(DQHTTPRequest *))completionBlock;
- (void)inviteUserAtIndex:(NSInteger)index withCompletionBlock:(void (^)(DQHTTPRequest *request))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end

@interface DQTwitterFriendsCoordinator (TemplateMethods)

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index;
- (UIView *)accessoryViewForFriendsInvitedWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index;
- (UIControl *)accessoryViewForFriendsNotInvitedWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index;

@end
