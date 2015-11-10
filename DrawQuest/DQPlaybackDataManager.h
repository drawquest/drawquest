//
//  DQPlaybackDataManager.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/13/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQController.h"

// Models
@class CVSDrawing;
@class DQComment;
@class DQQuest;

// Controllers
@class STHTTPResourceController;

@interface DQPlaybackDataManager : DQController

- (id)initWithImageController:(STHTTPResourceController *)imageController delegate:(id<DQControllerDelegate>)delegate;
- (id)initWithDelegate:(id<DQControllerDelegate>)delegate MSDesignatedInitializer(initWithImageController:delegate:);

- (void)reset;

- (CVSDrawing *)drawingForPlaybackData:(NSDictionary *)playbackData;

- (void)requestDrawingAndTemplateImageForComment:(DQComment *)comment inQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController resultBlock:(void (^)(CVSDrawing *drawing, UIImage *templateImage))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void)requestLogPlaybackForComment:(DQComment *)comment withCompletionBlock:(void (^)(DQComment *newComment))completionBlock;

@end
