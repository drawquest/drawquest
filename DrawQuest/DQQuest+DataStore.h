//
//  DQQuest+DataStore.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuest.h"

@interface DQQuest (DataStore)

- (instancetype)initWithServerID:(NSString *)serverID title:(NSString *)title;

- (void)markCompletedByUser;
- (void)markFlaggedByUser;

@end
