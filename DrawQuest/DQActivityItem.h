//
//  DQActivityItem.h
//  DrawQuest
//
//  Created by Jim Roepcke on 25/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DQActivityConstants.h"

@interface DQActivityItem : NSObject

- (instancetype)initWithJSONDictionary:(NSDictionary *)inDictionary
               markedAsReadIfOlderThan:(NSDate *)dateOfMostRecentlyReadActivity;

@property (nonatomic, copy) NSDate *timestamp;
@property (nonatomic, copy) NSString *serverID;
@property (nonatomic, copy) NSDictionary *content;

@property (nonatomic) DQActivityItemType activityType;
@property (nonatomic, copy) NSString *thumbnailURL;

@property (nonatomic, assign) BOOL readFlag;

@property (nonatomic, copy) NSString *commentID;
@property (nonatomic, copy) NSString *questID;

// Actor information
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, readonly, copy) NSString *phoneAvatarURL;
@property (nonatomic, copy) NSString *creatorUserName;
@property (nonatomic, copy) NSString *creatorUserID;
@property (nonatomic, assign) BOOL viewerIsFollowing;

@end
