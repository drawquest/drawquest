//
//  DQUser.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/29/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQUser.h"

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

@implementation DQUser

@end
