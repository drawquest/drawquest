//
//  DQUser.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/29/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQModelObject.h"

@interface DQUser : DQModelObject

@property (nonatomic, readonly, copy) NSString *bio;
@property (nonatomic, readonly, copy) NSString *followerCount;
@property (nonatomic, readonly, copy) NSString *followingCount;
@property (nonatomic, readonly, assign) BOOL isFollowing;
@property (nonatomic, readonly, copy) NSString *questCompletionCount;
@property (nonatomic, readonly, copy) NSNumber *coinCount;
@property (nonatomic, readonly, copy) NSString *userName;
@property (nonatomic, readonly, copy) NSString *avatarURL;
@property (nonatomic, readonly, copy) NSString *galleryAvatarURL;
@property (nonatomic, readonly, copy) NSString *commentsCount;
@property (nonatomic, readonly, copy) NSString *questsCount;
@property (nonatomic, readonly, copy) NSString *facebookURL;
@property (nonatomic, readonly, copy) NSString *twitterURL;
@property (nonatomic, readonly, copy) NSString *drawQuestURL;
@property (nonatomic, readonly, copy) NSString *tumblrURL;

@end
