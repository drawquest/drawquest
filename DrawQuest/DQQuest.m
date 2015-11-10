//
//  DQQuest.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQQuest.h"

@interface DQQuest ()

@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *commentsURL;
@property (nonatomic, readwrite, copy) NSNumber *authorCount;
@property (nonatomic, readwrite, copy) NSNumber *drawingCount;
@property (nonatomic, readwrite, copy) NSString *attributionCopy;
@property (nonatomic, readwrite, copy) NSString *attributionUsername;
@property (nonatomic, readwrite, copy) NSString *attributionAvatarUrl;
@property (nonatomic, readwrite, copy) NSString *authorUsername;
@property (nonatomic, readwrite, copy) NSString *authorAvatarUrl;
@property (nonatomic, readwrite, assign) BOOL completedByUser;

@property (nonatomic, readwrite, assign) BOOL flagged;

@end

@implementation DQQuest

@end
