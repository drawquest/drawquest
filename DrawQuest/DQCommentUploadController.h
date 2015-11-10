//
//  DQCommentUploadController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"

#import "DQCommentUpload.h"

@class DQAccountController;

@interface DQCommentUploadController : DQController

// designated initializer
- (id)initWithUploadsPath:(NSString *)uploadsPath accountController:(DQAccountController *)accountController delegate:(id<DQControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate MSDesignatedInitializer(initWithUploadsPath:accountController:delegate:);
- (id)init MSDesignatedInitializer(initWithUploadsPath:accountController:delegate:);

- (BOOL)uploadDraftAtPath:(NSString *)draftPath forQuestWithServerID:(NSString *)questID title:(NSString *)questTitle shareFlags:(NSArray *)shareFlags facebookAccessToken:(NSString *)accessToken twitterAccessToken:(NSString *)twitterAccessToken twitterAccessTokenSecret:(NSString *)twitterAccessTokenSecret emailList:(NSArray *)emailList;

- (void)retryCommentUpload:(DQCommentUpload *)commentUpload;

@end
