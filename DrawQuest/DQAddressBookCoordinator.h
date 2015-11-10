//
//  DQAddressBookCoordinator.h
//  DrawQuest
//
//  Created by David Mauro on 10/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DQFriendListViewController.h"

@class DQPublicServiceController, DQPrivateServiceController;

@interface DQAddressBookCoordinator : NSObject <DQFriendListViewControllerDataSource, DQFriendListViewControllerDelegate>

@property (nonatomic, copy) NSString *subjectLine;
@property (nonatomic, copy) void (^messageForInviteBlock)(NSString *inChannel, void (^completionBlock)(NSString *));
@property (nonatomic, copy) void (^presentActionSheetBlock)(UIActionSheet *sheet);
@property (nonatomic, copy) void (^presentViewControllerBlock)(UIViewController *vc);
@property (nonatomic, copy) void (^logFollowBlock)(DQAddressBookCoordinator *c);

- (id)initWithPublicServiceController:(DQPublicServiceController *)publicServiceController privateServiceController:(DQPrivateServiceController *)privateServiceController;
- (id)init MSDesignatedInitializer(initWithPublicServiceController:privateServiceController:);

@end

@interface DQAddressBookCoordinator (TemplateMethods)

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index;
- (UIView *)accessoryViewForFriendsNotOnDrawQuestAtIndex:(NSInteger *)index;

@end
