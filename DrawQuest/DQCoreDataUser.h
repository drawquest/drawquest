//
//  DQUser.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/29/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DQCoreDataModelObject.h"

@class DQCoreDataComment;


@interface DQCoreDataUser : DQCoreDataModelObject

@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *followerCount;
@property (nonatomic, strong) NSString *followingCount;
@property (nonatomic, assign) BOOL isFollowing;
@property (nonatomic, strong) NSString *questCompletionCount;
@property (nonatomic, strong) NSNumber *coinCount;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *avatarURL;
@property (nonatomic, strong) NSSet *comments;

@end


@interface DQCoreDataUser (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(DQCoreDataComment *)value;
- (void)removeCommentsObject:(DQCoreDataComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
