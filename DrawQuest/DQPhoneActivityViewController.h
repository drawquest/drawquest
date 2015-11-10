//
//  DQPhoneActivityViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

extern NSString *const DQPhoneActivityViewControllerClearBadgeNotification;

@class DQActivityItem;

@interface DQPhoneActivityViewController : DQViewController

@property (nonatomic, copy) dispatch_block_t homeBlock;
@property (nonatomic, copy) void (^profileBlock)(NSString *userName);
@property (nonatomic, copy) void (^unknownActivityItemTappedBlock)(DQActivityItem *activityItem);
@property (nonatomic, copy) dispatch_block_t refreshBlock;
@property (nonatomic, copy) dispatch_block_t reloadActivitiesBlock;
@property (nonatomic, copy) dispatch_block_t loadMoreActivitiesBlock;
@property (nonatomic, copy) void (^shopColorsBlock)(DQPhoneActivityViewController *c);
@property (nonatomic, copy) NSInteger (^getUnreadCountBlock)(DQPhoneActivityViewController *vc);
@property (nonatomic, assign) NSInteger unreadCount;

- (void)replaceActivities:(NSArray *)activities;
- (void)appendActivities:(NSArray *)activities;
- (void)prependActivities:(NSArray *)activities;

- (void)loadActivitiesFailed;
- (void)loadMoreActivitiesFailed;

@end
