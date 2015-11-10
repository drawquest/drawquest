//
//  DQFacebookFriendsCoordinator.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/18/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQFriendListViewController.h"
#import "DQFacebookController.h"

@class DQFriendListViewController, DQPrivateServiceController;

@interface DQFacebookFriendsCoordinator : NSObject <DQFriendListViewControllerDataSource, DQFriendListViewControllerDelegate>

@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSDictionary *friendsOnDrawQuest;
@property (nonatomic, strong) NSMutableIndexSet *selectedFriends;
@property (nonatomic, strong) NSMutableIndexSet *followingOrInvitedFriends;
@property (nonatomic, strong, readonly) DQPrivateServiceController *privateServiceController;
@property (nonatomic, strong, readonly) NSMutableIndexSet *defaultToFollowFriends;
@property (nonatomic, copy) NSString *questID;
@property (nonatomic, copy) void (^messageForInviteBlock)(NSString *inChannel, void (^completionBlock)(NSString *));

// designated initializer
- (id)initWithFacebookController:(DQFacebookController *)facebookController privateServiceController:(DQPrivateServiceController *)privateServiceController;

- (id)init MSDesignatedInitializer(initWithFacebookController:serviceController:);

- (void)tappedFriendAtIndex:(NSUInteger)index accessoryView:(UIView *)accessoryView;

@end

@interface DQFacebookFriendsCoordinator (TemplateMethods)

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController AtIndex:(NSInteger)index;
- (UIView *)accessoryViewForFriendsInvitedAtIndex:(NSInteger)index;
- (UIControl *)accessoryViewForFriendsNotInvitedAtIndex:(NSInteger)index;

@end
