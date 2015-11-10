//
//  DQAnalyticsController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/19/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQController.h"

@interface DQAnalyticsController : DQController

- (void)startSession;
- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;

@end
