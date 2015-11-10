//
//  DQMenuViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/13/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"

@class DQActivityItem;

@interface DQMenuViewController : DQViewController

@property (nonatomic, copy) dispatch_block_t homeBlock;
@property (nonatomic, copy) void (^aboutBlock)(DQMenuViewController *menuViewController);
@property (nonatomic, copy) void (^exploreWithCommentIDBlock)(NSString *commentID);
@property (nonatomic, copy) void (^galleryBlock)(NSString *questID, NSString *commentID);
@property (nonatomic, copy) void (^profileBlock)(NSString *userName);
@property (nonatomic, copy) void (^unknownActivityItemTappedBlock)(DQActivityItem *activityItem);
@property (nonatomic, copy) dispatch_block_t loadMoreActivitiesBlock;
@property (nonatomic, copy) void (^shopColorsBlock)(DQMenuViewController *c);

- (void)replaceActivities:(NSArray *)activities;
- (void)appendActivities:(NSArray *)activities;
- (void)prependActivities:(NSArray *)activities;

- (void)loadMoreActivitiesFailed;

@end
