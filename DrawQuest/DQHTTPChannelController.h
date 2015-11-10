//
//  DQHTTPChannelController.h
//  DrawQuest
//
//  Created by Buzz Andersen on 11/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQController.h"

@class DQAccount;

extern NSString *DQHTTPChannelControllerQuestOfTheDayUpdatedNotification;
extern NSString *DQHTTPChannelControllerUserActivityUpdatedNotification;
extern NSString *DQHTTPChannelControllerCoinBalanceUpdatedNotification;
extern NSString *DQHTTPChannelControllerCoinBalanceNotificationKey;
extern NSString *DQHTTPChannelControllerTabBadgesNotification;
extern NSString *DQHTTPChannelControllerTabBadgeUpdateKey;

@interface DQHTTPChannelController : DQController

@property (nonatomic, assign) BOOL monitoring;

// Life Cycle
- (void)reset;
- (void)updateChannelInfoFromSyncJSONInfo:(NSDictionary *)inJSONInfo;

@end
