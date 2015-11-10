//
//  DQUser+DataStore.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQUser+DataStore.h"
#import "DQModelObject+DataStore.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQFollowConstants.h"

@interface DQUser ()

@property (nonatomic, readwrite, copy) NSString *bio;
@property (nonatomic, readwrite, copy) NSString *followerCount;
@property (nonatomic, readwrite, copy) NSString *followingCount;
@property (nonatomic, readwrite, assign) BOOL isFollowing;
@property (nonatomic, readwrite, copy) NSString *questCompletionCount;
@property (nonatomic, readwrite, copy) NSNumber *coinCount;
@property (nonatomic, readwrite, copy) NSString *userName;
@property (nonatomic, readwrite, copy) NSString *avatarURL;
@property (nonatomic, readwrite, copy) NSString *galleryAvatarURL;
@property (nonatomic, readwrite, copy) NSString *commentsCount;
@property (nonatomic, readwrite, copy) NSString *questsCount;
@property (nonatomic, readwrite, copy) NSString *facebookURL;
@property (nonatomic, readwrite, copy) NSString *twitterURL;
@property (nonatomic, readwrite, copy) NSString *drawQuestURL;
@property (nonatomic, readwrite, copy) NSString *tumblrURL;

@end

@implementation DQUser (DataStore)

+ (NSString *)yapCollectionName
{
    return @"users";
}

- (NSString *)equalityIdentifier
{
    return self.userName;
}

- (instancetype)initWithUserName:(NSString *)userName
{
    self = [super init];
    if (self)
    {
        self.userName = userName;
    }
    return self;
}

- (NSString *)serverIDFromJSONDictionary:(NSDictionary *)inDictionary
{
    return inDictionary.dq_userInfo.dq_serverID;
}

- (BOOL)initializeWithJSONDictionary:(NSDictionary *)inDictionary
{
    BOOL changed = [super initializeWithJSONDictionary:inDictionary];

    NSDictionary *userInfo = inDictionary.dq_userInfo;
    NSString *commentCount = [NSString stringWithFormat:@"%ld", (long)inDictionary.dq_commentCount];
    NSString *questCount = [NSString stringWithFormat:@"%ld", (long)inDictionary.dq_questCount];
    DQModelObjectSetProperty(bio, inDictionary.dq_userBio, changed);
    DQModelObjectSetProperty(followerCount, [inDictionary.dq_userFollowerCount stringValue], changed);
    DQModelObjectSetProperty(followingCount, [inDictionary.dq_userFollowingCount stringValue], changed);
    NSNumber *viewerIsFollowing = inDictionary.dq_viewerIsFollowing;
    if (viewerIsFollowing)
    {
        BOOL isFollowing = [viewerIsFollowing boolValue];
        DQModelObjectSetPrimProp(BOOL, isFollowing, isFollowing, changed);
        [self updateFollowState];
    }
    DQModelObjectSetProperty(userName, userInfo.dq_userName, changed);
    DQModelObjectSetProperty(avatarURL, userInfo.dq_profileUserAvatarURL, changed);
    DQModelObjectSetProperty(galleryAvatarURL, userInfo.dq_galleryUserAvatarURL, changed);
    DQModelObjectSetProperty(commentsCount, commentCount, changed);
    DQModelObjectSetProperty(questsCount, questCount, changed);
    DQModelObjectSetProperty(facebookURL, inDictionary.dq_userFacebookURL, changed);
    DQModelObjectSetProperty(twitterURL, inDictionary.dq_userTwitterURL, changed);
    DQModelObjectSetProperty(drawQuestURL, inDictionary.dq_userDrawQuestURL, changed);
    DQModelObjectSetProperty(tumblrURL, inDictionary.dq_userTumblrURL, changed);
    return changed;
}

- (void)updateFollowState
{
    DQRequestUpdateFollowState(self.userName, self.isFollowing ? DQFollowStateFollowing : DQFollowStateNotFollowing);
}

- (void)saveCoinCount:(NSNumber *)coinCount inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.coinCount = coinCount;
    [self saveInTransaction:transaction];
}

- (void)setIsFollowing:(BOOL)isFollowing inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.isFollowing = isFollowing;
    self.followingCount = [@([self.followingCount integerValue] + (isFollowing ? 1 : -1 )) stringValue];
    [self saveInTransaction:transaction];
    [self updateFollowState];
}

@end
