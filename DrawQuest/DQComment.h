//
//  DQComment.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQModelObject.h"
#import "DQActivityItem.h"

extern NSString *const DQCommentRefreshedNotification;

@interface DQComment : DQModelObject

@property (nonatomic, readonly, copy) NSString *authorID;
@property (nonatomic, readonly, copy) NSString *authorName;
@property (nonatomic, readonly, copy) NSString *authorAvatarURL;

@property (nonatomic, readonly, copy) NSString *questID;
@property (nonatomic, readonly, copy) NSString *questTitle;
@property (nonatomic, readonly, copy) NSArray *reactions;
@property (nonatomic, readonly, assign) NSUInteger numberOfStars;
@property (nonatomic, readonly, assign) NSUInteger numberOfPlaybacks;

@property (nonatomic, readonly, assign) BOOL flagged;

// derived

@property (nonatomic, readonly, weak) NSArray *sortedReactions;
@property (nonatomic, readonly, assign) NSUInteger numberOfReactions;

@end
