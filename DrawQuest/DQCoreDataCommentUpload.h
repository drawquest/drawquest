//
//  DQCommentUpload.h
//  DrawQuest
//
//  Created by Buzz Andersen on 11/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DQCoreDataModelObject.h"
#import "DQCommentUpload.h"

@class DQCoreDataQuest;

@interface DQCoreDataCommentUpload : DQCoreDataModelObject

@property (nonatomic, strong) id shareFlags;
@property (nonatomic, assign) DQCommentUploadStatus status;
@property (nonatomic, strong) NSString *questID;
@property (nonatomic, strong) NSString *facebookToken;
@property (nonatomic, strong) NSString *twitterToken;
@property (nonatomic, strong) NSString *twitterTokenSecret;
@property (nonatomic, strong) NSNumber *uploadProgress;
@property (nonatomic, strong) DQCoreDataQuest *quest;
@property (nonatomic, strong) NSString *contentID;

@end
