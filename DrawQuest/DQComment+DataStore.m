//
//  DQComment+DataStore.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQComment+DataStore.h"
#import "DQModelObject+DataStore.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQFollowConstants.h"
#import "DQStarConstants.h"

@interface DQComment ()

@property (nonatomic, readwrite, copy) NSString *authorID;
@property (nonatomic, readwrite, copy) NSString *authorName;
@property (nonatomic, readwrite, copy) NSString *authorAvatarURL;
@property (nonatomic, readwrite, copy) NSString *questID;
@property (nonatomic, readwrite, copy) NSString *questTitle;
@property (nonatomic, readwrite, copy) NSArray *reactions;
@property (nonatomic, readwrite, assign) NSUInteger numberOfStars;
@property (nonatomic, readwrite, assign) NSUInteger numberOfPlaybacks;
@property (nonatomic, readwrite, assign) BOOL flagged;

@end

@implementation DQComment (DataStore)

+ (NSString *)yapCollectionName
{
    return @"comments";
}

- (BOOL)initializeWithJSONDictionary:(NSDictionary *)inDictionary
{
    BOOL changed = [super initializeWithJSONDictionary:inDictionary];

    NSDictionary *userInfo = inDictionary.dq_userInfo;
    DQModelObjectSetProperty(questID, [inDictionary dq_commentQuestID], changed);
    DQModelObjectSetProperty(questTitle, [inDictionary dq_commentQuestTitle], changed);
    // FIXME: optimize this by checking for a different number of reactions instead of comparing
    DQModelObjectSetProperty(reactions, [inDictionary dq_commentReactions], changed);
    DQModelObjectSetPrimProp(NSUInteger, numberOfStars, [inDictionary dq_numberOfStars], changed);
    DQModelObjectSetPrimProp(NSUInteger, numberOfPlaybacks, [inDictionary dq_numberOfPlaybacks], changed);
    DQModelObjectSetProperty(authorAvatarURL, userInfo.dq_galleryUserAvatarURL, changed);
    DQModelObjectSetProperty(authorID, userInfo.dq_serverID, changed);
    DQModelObjectSetProperty(authorName, userInfo.dq_userName, changed);
    NSNumber *viewerIsFollowing = userInfo.dq_viewerIsFollowing;
    if (viewerIsFollowing)
    {
        DQRequestUpdateFollowState(self.authorName, [viewerIsFollowing boolValue] ? DQFollowStateFollowing : DQFollowStateNotFollowing);
    }
    NSNumber *viewerHasStarred = inDictionary.dq_viewerHasStarred;
    if (viewerHasStarred)
    {
        DQRequestUpdateStarState(self.serverID, [viewerHasStarred boolValue] ? DQStarStateStarred : DQStarStateNotStarred);
    }
    if (changed)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:DQCommentRefreshedNotification object:self userInfo:nil];
        });
    }
    return changed;
}

- (void)markFlaggedByUser
{
    self.flagged = YES;
}

@end
