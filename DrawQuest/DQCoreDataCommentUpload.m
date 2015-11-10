//
//  DQCommentUpload.m
//  DrawQuest
//
//  Created by Buzz Andersen on 11/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCoreDataCommentUpload.h"

#import <objc/runtime.h>

#import "DQCoreDataQuest.h"
#import "STUtils.h"

@implementation DQCoreDataCommentUpload

@dynamic shareFlags;
@dynamic questID;
@dynamic facebookToken;
@dynamic twitterToken;
@dynamic twitterTokenSecret;
@dynamic uploadProgress;
@dynamic quest;
@dynamic contentID;

#pragma mark NSManagedObject

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    self.timestamp = [NSDate date];
    self.status = DQCommentUploadStatusNew;
}

#pragma mark Accessors

- (void)setStatus:(DQCommentUploadStatus)status
{
    [self setUnsignedInteger:status forKey:@"status"];
}

- (DQCommentUploadStatus)status
{
    return (DQCommentUploadStatus)[self unsignedIntegerForKey:@"status"];
}

@end
