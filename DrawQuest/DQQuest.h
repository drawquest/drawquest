//
//  DQQuest.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQModelObject.h"

@interface DQQuest : DQModelObject

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *commentsURL;
@property (nonatomic, readonly, copy) NSNumber *authorCount;
@property (nonatomic, readonly, copy) NSNumber *drawingCount;
@property (nonatomic, readonly, copy) NSString *attributionCopy;
@property (nonatomic, readonly, copy) NSString *attributionUsername;
@property (nonatomic, readonly, copy) NSString *attributionAvatarUrl;
@property (nonatomic, readonly, copy) NSString *authorUsername;
@property (nonatomic, readonly, copy) NSString *authorAvatarUrl;
@property (nonatomic, readonly, assign) BOOL completedByUser;

@property (nonatomic, readonly, assign) BOOL flagged;

@end
