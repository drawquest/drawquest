//
//  DQComment.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCoreDataComment.h"
#import "STUtils.h"

@implementation DQCoreDataComment

@dynamic questID;
@dynamic authorID;
@dynamic authorName;
@dynamic authorAvatarURL;
@dynamic quest;
@dynamic reactions;
@dynamic user;
@dynamic questTitle;

- (void)setFlagged:(BOOL)inFlagged
{
    [self setBool:inFlagged forKey:@"flagged"];
}

- (BOOL)flagged
{
    return [self boolForKey:@"flagged"];
}

- (void)setReactions:(NSArray *)inReactions
{
    [self willChangeValueForKey:@"reactions"];
    [self setPrimitiveValue:inReactions forKey:@"reactions"];
    [self didChangeValueForKey:@"reactions"];
}

@end
