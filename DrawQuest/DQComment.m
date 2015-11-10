//
//  DQComment.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQComment.h"
#import "DQQuest.h"
#import "DQUser.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"

NSString *const DQCommentRefreshedNotification = @"DQCommentRefreshedNotification";

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

@interface DQComment ()

@property (weak, nonatomic, readonly) NSArray *reactionsSortDescriptors;

@end

@implementation DQComment

@dynamic numberOfReactions;

#pragma mark Initialization

- (NSArray *)reactionsSortDescriptors
{
    static NSArray *reactionsSortDescriptors;
    if (!reactionsSortDescriptors) {
        reactionsSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    }
    
    return reactionsSortDescriptors;
}

// FIXME: sort them when they're given to us so they don't have to be sorted all the time
- (NSArray *)sortedReactions
{
    return [self.reactions sortedArrayUsingDescriptors:self.reactionsSortDescriptors];
}

- (NSUInteger)numberOfReactions
{
    return self.numberOfStars + self.numberOfPlaybacks;
}

@end
