//
//  DQQuest+DataStore.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuest+DataStore.h"
#import "DQModelObject+DataStore.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQQuest ()

@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *commentsURL;
@property (nonatomic, readwrite, copy) NSNumber *authorCount;
@property (nonatomic, readwrite, copy) NSNumber *drawingCount;
@property (nonatomic, readwrite, copy) NSString *attributionCopy;
@property (nonatomic, readwrite, copy) NSString *attributionUsername;
@property (nonatomic, readwrite, copy) NSString *attributionAvatarUrl;
@property (nonatomic, readwrite, copy) NSString *authorUsername;
@property (nonatomic, readwrite, copy) NSString *authorAvatarUrl;
@property (nonatomic, readwrite, assign) BOOL completedByUser;

@property (nonatomic, readwrite, assign) BOOL flagged;

@end

@implementation DQQuest (DataStore)

+ (NSString *)yapCollectionName
{
    return @"quests";
}

- (instancetype)initWithServerID:(NSString *)serverID title:(NSString *)title
{
    self = [super initWithServerID:serverID];
    if (self)
    {
        self.title = title;
    }
    return self;
}

- (BOOL)initializeWithJSONDictionary:(NSDictionary *)inDictionary
{
    BOOL changed = [super initializeWithJSONDictionary:inDictionary];
    DQModelObjectSetProperty(title, [inDictionary dq_questTitle], changed);
    DQModelObjectSetProperty(drawingCount, [inDictionary dq_questDrawingCount], changed);
    DQModelObjectSetProperty(authorCount, [inDictionary dq_questAuthorCount], changed);
    DQModelObjectSetProperty(commentsURL, [inDictionary dq_questCommentsURL], changed);
    DQModelObjectSetProperty(attributionCopy, [inDictionary dq_attributionCopy], changed);
    DQModelObjectSetProperty(attributionUsername, [inDictionary dq_attributionUsername], changed);
    DQModelObjectSetProperty(attributionAvatarUrl, [inDictionary dq_attributionAvatarURL], changed);
    DQModelObjectSetProperty(authorUsername, [[inDictionary dq_userInfo] dq_userName], changed);
    DQModelObjectSetProperty(authorAvatarUrl, [[inDictionary dq_userInfo] dq_galleryUserAvatarURL], changed);
    return changed;
}

- (void)markCompletedByUser
{
    self.completedByUser = YES;
}

- (void)markFlaggedByUser
{
    self.flagged = YES;
}

@end
