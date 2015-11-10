//
//  DQActivityItem.m
//  DrawQuest
//
//  Created by Jim Roepcke on 25/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQActivityItem.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"
#import "DQFollowConstants.h"

@implementation DQActivityItem

@dynamic phoneAvatarURL;

- (instancetype)initWithJSONDictionary:(NSDictionary *)inDictionary
               markedAsReadIfOlderThan:(NSDate *)dateOfMostRecentlyReadActivity
{
    self = [super init];
    if (self)
    {
        _serverID = [inDictionary.dq_serverID copy];
        _timestamp = [inDictionary.dq_timestamp copy];
        _content = [inDictionary.dq_content copy];

        _activityType = inDictionary.dq_activityItemActivityType;
        _thumbnailURL = [inDictionary.dq_activityItemThumbnailURL copy];

        _commentID = [inDictionary.dq_activityItemCommentID copy];
        _questID = [inDictionary.dq_activityItemQuestID copy];

        NSDictionary *actorInfo = inDictionary.dq_activityItemActorInfo;
        if (actorInfo)
        {
            _creatorUserName = [actorInfo.dq_userName copy];
            _creatorUserID = [actorInfo.dq_serverID copy];
            _avatarURL = [actorInfo.dq_galleryUserAvatarURL copy];
        }
        if (_activityType == DQActivityItemTypeFollow)
        {
            NSNumber *n = inDictionary.dq_viewerIsFollowing;
            if (n)
            {
                _viewerIsFollowing = [n boolValue];
                DQRequestUpdateFollowState(_creatorUserName, _viewerIsFollowing ? DQFollowStateFollowing : DQFollowStateNotFollowing);
            }
        }
        if (_timestamp && dateOfMostRecentlyReadActivity)
        {
            _readFlag = [_timestamp compare:dateOfMostRecentlyReadActivity] != NSOrderedDescending;
        }
    }
    return self;
}

- (NSString *)description
{
    NSString *result = [super description];
    NSString *info = [NSString stringWithFormat:@", serverID: %@, type: %@, creatorUserName: %@, timestamp: %@, read: %@>", self.serverID, [self activityTypeString], self.creatorUserName, self.timestamp, @(self.readFlag)];
    result = [result stringByReplacingCharactersInRange:NSMakeRange([result length] - 1, 1) withString:info];
    return result;
}

- (NSString *)activityTypeString
{
    switch (self.activityType)
    {
        case DQActivityItemTypeOther:
            return DQActivityItemTypeStringOther;
        case DQActivityItemTypeStar:
            return DQAPIValueActivityTypeStar;
        case DQActivityItemTypeRemix:
            return DQAPIValueActivityTypeRemix;
        case DQActivityItemTypePlayback:
            return DQAPIValueActivityTypePlayback;
        case DQActivityItemTypeFollow:
            return DQAPIValueActivityTypeFollow;
        case DQActivityItemTypePost:
            return DQAPIValueActivityTypePost;
        case DQActivityItemTypeWelcome:
            return DQAPIValueActivityTypeWelcome;
        case DQActivityItemTypeFacebookFriendJoined:
            return DQAPIValueActivityTypeFacebookFriendJoined;
        case DQActivityItemTypeTwitterFriendJoined:
            return DQAPIValueActivityTypeTwitterFriendJoined;
        case DQActivityItemTypeFeaturedInExplore:
            return DQAPIValueActivityTypeFeaturedInExplore;
        case DQActivityItemTypeNewColors:
            return DQAPIValueActivityTypeNewColors;
        case DQActivityItemTypeUGQ:
            return DQAPIValueActivityTypeUGQ;
        case DQActivityItemTypeUnknown:
        default:
            return @"unknown";
            break;
    }
}

- (NSString *)phoneAvatarURL
{
    NSString *result = self.avatarURL ?: [[[NSBundle mainBundle] URLForResource:@"questbot_small@2x" withExtension:@"png"] description];
    return result;
}

@end
