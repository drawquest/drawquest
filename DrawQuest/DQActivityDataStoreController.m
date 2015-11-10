//
//  DQActivityDataStoreController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQActivityDataStoreController.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQActivityItem.h"

@interface DQActivityDataStoreController ()

// note: access to serverMap and unreadItems is @synchronized to make it thread safe
// yes, locks suck, but this code isn't a hotspot and it's a simple way to ensure safety
@property (nonatomic, strong) NSMutableDictionary *serverMap;
@property (nonatomic, strong) NSMutableArray *unreadItems;

@end

@implementation DQActivityDataStoreController

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _serverMap = [NSMutableDictionary new];
        _unreadItems = [NSMutableArray new];
    }
    return self;
}

#pragma mark Activity Item CRUD

- (NSArray *)newActivityItemsFromJSONList:(NSArray *)inJSONList markedAsReadIfOlderThan:(NSDate *)timestampOfNewestReadActivity
{
    return [self activityItemsFromJSONList:inJSONList justNewActivities:YES markedAsReadIfOlderThan:timestampOfNewestReadActivity];
}

- (NSArray *)activityItemsFromJSONList:(NSArray *)inJSONList markedAsReadIfOlderThan:(NSDate *)timestampOfNewestReadActivity
{
    return [self activityItemsFromJSONList:inJSONList justNewActivities:NO markedAsReadIfOlderThan:timestampOfNewestReadActivity];
}

- (NSArray *)activityItemsFromJSONList:(NSArray *)inJSONList justNewActivities:(BOOL)justNewActivities markedAsReadIfOlderThan:(NSDate *)timestampOfNewestReadActivity
{
    NSArray *result = @[];
    if ([inJSONList count])
    {
        NSMutableArray *activities = [[NSMutableArray alloc] initWithCapacity:[inJSONList count]];
        for (NSDictionary *currentActivityItemInfo in inJSONList)
        {
            if ([currentActivityItemInfo count])
            {
                NSString *serverID = currentActivityItemInfo.dq_serverID;
                if ([serverID length])
                {
                    @synchronized (self)
                    {
                        DQActivityItem *item = self.serverMap[serverID];
                        if (item)
                        {
                            if (justNewActivities)
                            {
                                continue;
                            }
                            else
                            {
                                [activities addObject:item];
                            }
                        }
                        else
                        {
                            item = [[DQActivityItem alloc] initWithJSONDictionary:currentActivityItemInfo markedAsReadIfOlderThan:timestampOfNewestReadActivity];
                            self.serverMap[item.serverID] = item;
                            if (!item.readFlag)
                            {
                                NSLog(@"new unread activity: %@", item);
                                [self.unreadItems addObject:item];
                            }
                            [activities addObject:item];
                        }
                    }
                }
            }
        }
        result = activities;
    }
    return result;
}

- (void)markAllActivityItemsRead
{
    @synchronized (self)
    {
        for (DQActivityItem *item in self.unreadItems)
        {
            item.readFlag = YES;
        }
        self.unreadItems = [NSMutableArray new];
    }
}

#pragma mark Activity Item Queries

- (NSUInteger)numberOfUnreadActivityItems
{
    NSUInteger result = 0;
    @synchronized (self)
    {
        result = [self.unreadItems count];
    }
    return result;
}

@end
