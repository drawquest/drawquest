//
//  DQActivityItem.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCoreDataActivityItem.h"
#import "DQCoreDataComment.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"


@implementation DQCoreDataActivityItem

@dynamic activityType;
@dynamic commentID;
@dynamic questID;
@dynamic creatorUserName;
@dynamic creatorUserID;
@dynamic comment;
@dynamic thumbnailURL;
@dynamic avatarURL;

#pragma mark Initialization

- (void)initializeWithJSONDictionary:(NSDictionary *)inDictionary
{
    [super initializeWithJSONDictionary:inDictionary];
    
    self.serverID = inDictionary.dq_serverID;
    self.activityType = inDictionary.dq_activityItemActivityType;
    self.thumbnailURL = inDictionary.dq_activityItemThumbnailURL;
    
    self.commentID = inDictionary.dq_activityItemCommentID;
    self.questID = inDictionary.dq_activityItemQuestID;
    
    NSDictionary *actorInfo = inDictionary.dq_activityItemActorInfo;
    if (actorInfo) {
        self.creatorUserName = actorInfo.dq_userName;
        self.creatorUserID = actorInfo.dq_serverID;
        self.avatarURL = actorInfo.dq_galleryUserAvatarURL;
    }
}

#pragma mark Accessors

- (void)setActivityType:(DQActivityItemType)inActivityType
{
    [self setUnsignedInteger:inActivityType forKey:@"activityType"];
}

- (DQActivityItemType)activityType
{
    return (DQActivityItemType)[self unsignedIntegerForKey:@"activityType"];
}

- (void)setAppearsInActivityStream:(BOOL)inAppearsInActivityStream
{
    [self setBool:inAppearsInActivityStream forKey:@"appearsInActivityStream"];
}

- (BOOL)appearsInActivityStream
{
    return [self boolForKey:@"appearsInActivityStream"];
}

- (void)setReadFlag:(BOOL)inReadFlag
{
    [self setBool:inReadFlag forKey:@"readFlag"];
}

- (BOOL)readFlag
{
    return [self boolForKey:@"readFlag"];
}

@end
