//
//  DQPlaybackViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"

// Models
@class CVSDrawing;
@class DQComment;
@class DQQuest;

// Controllers
@class DQPlaybackDataManager;

@interface DQPlaybackViewController : DQViewController

@property (nonatomic, copy) void (^dismissBlock)(DQPlaybackViewController *vc);

// designated initializer
- (id)initWithComment:(DQComment *)comment inQuest:(DQQuest *)quest newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager delegate:(id<DQViewControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithComment:forQuest:newPlaybackDataManager:delegate:);

- (void)requestPreparePlaybackFromViewController:(UIViewController *)presentingViewController completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end
