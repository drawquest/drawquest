//
//  DQQuest.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DQCoreDataModelObject.h"

@class DQCoreDataComment;
@class DQCoreDataCommentUpload;


@interface DQCoreDataQuest : DQCoreDataModelObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *commentsURL;
@property (nonatomic, strong) NSNumber *authorCount;
@property (nonatomic, strong) NSNumber *drawingCount;
@property (nonatomic, copy) NSString *attributionCopy;
@property (nonatomic, copy) NSString *attributionUsername;
@property (nonatomic, copy) NSString *attributionAvatarUrl;
@property (nonatomic, strong) NSSet *comments;

@property (nonatomic, strong) NSSet *commentUploads;

@property (nonatomic, assign) BOOL completedByUser;

@property (nonatomic, assign) BOOL appearsOnHomeScreen;

@end

@interface DQCoreDataQuest (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(DQCoreDataComment *)value;
- (void)removeCommentsObject:(DQCoreDataComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addCommentUploadsObject:(DQCoreDataCommentUpload *)value;
- (void)removeCommentUploadsObject:(DQCoreDataCommentUpload *)value;
- (void)addCommentUploads:(NSSet *)values;
- (void)removeCommentUploads:(NSSet *)values;

@end
