//
//  DQQuestUploadController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"

#import "DQQuestUpload.h"

@class DQAccountController;

@interface DQQuestUploadController : DQController

// designated initializer
- (id)initWithDraftsPath:(NSString *)uploadsPath accountController:(DQAccountController *)accountController delegate:(id<DQControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate MSDesignatedInitializer(initWithDraftsPath:accountController:delegate:);
- (id)init MSDesignatedInitializer(initWithDraftsPath:accountController:delegate:);

- (BOOL)uploadQuestUpload:(DQQuestUpload *)questUpload;

- (void)retryQuestUpload:(DQQuestUpload *)commentUpload;

@end
