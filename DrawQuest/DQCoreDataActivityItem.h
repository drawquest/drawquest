//
//  DQActivityItem.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DQCoreDataModelObject.h"
#import "DQActivityItem.h"

@class DQCoreDataComment;

@interface DQCoreDataActivityItem : DQCoreDataModelObject

@property (nonatomic) DQActivityItemType activityType;
@property (nonatomic, copy) NSString *creatorUserName;
@property (nonatomic, copy) NSString *creatorUserID;
@property (nonatomic, copy) NSString *commentID;
@property (nonatomic, copy) NSString *questID;
@property (nonatomic, copy) NSString *thumbnailURL;
@property (nonatomic, strong) DQCoreDataComment *comment;
@property (nonatomic, assign) BOOL appearsInActivityStream;
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, assign) BOOL readFlag;

@end
