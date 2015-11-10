//
//  DQComment.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DQActivityItem.h"
#import "DQCoreDataModelObject.h"

@class DQActivityItem, DQCoreDataQuest, DQCoreDataUser;


@interface DQCoreDataComment : DQCoreDataModelObject

@property (nonatomic, strong) NSString *authorID;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorAvatarURL;

@property (nonatomic, strong) DQCoreDataQuest *quest;
@property (nonatomic, strong) NSString *questID;
@property (nonatomic, strong) NSString *questTitle;

@property (nonatomic, strong) DQCoreDataUser *user;

@property (nonatomic, strong) NSArray *reactions;

@property (nonatomic, assign) BOOL flagged;

@end
