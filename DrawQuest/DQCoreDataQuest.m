//
//  DQQuest.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCoreDataQuest.h"
#import "DQCoreDataComment.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"

@implementation DQCoreDataQuest

@dynamic title;
@dynamic commentsURL;
@dynamic comments;
@dynamic authorCount;
@dynamic drawingCount;
@dynamic commentUploads;
@dynamic attributionCopy;
@dynamic attributionUsername;
@dynamic attributionAvatarUrl;

- (void)setAppearsOnHomeScreen:(BOOL)inAppearsOnHomeScreen
{
    [self setBool:inAppearsOnHomeScreen forKey:@"appearsOnHomeScreen"];
}

- (BOOL)appearsOnHomeScreen
{
    return [self boolForKey:@"appearsOnHomeScreen"];
}

- (void)setCompletedByUser:(BOOL)inCompletedByUser
{
    [self setBool:inCompletedByUser forKey:@"completedByUser"];
}

- (BOOL)completedByUser
{
    return [self boolForKey:@"completedByUser"];
}

@end
