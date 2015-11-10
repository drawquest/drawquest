//
//  DQActivityDataStoreController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQDataStoreController.h"

@class DQActivityItem;

@interface DQActivityDataStoreController : DQController

// Activity Item CRUD
- (void)markAllActivityItemsRead;
- (NSArray *)activityItemsFromJSONList:(NSArray *)inJSONList markedAsReadIfOlderThan:(NSDate *)timestampOfNewestReadActivity;
- (NSArray *)newActivityItemsFromJSONList:(NSArray *)inJSONList markedAsReadIfOlderThan:(NSDate *)timestampOfNewestReadActivity;

// Activity Item Queries
- (NSUInteger)numberOfUnreadActivityItems;

@end
