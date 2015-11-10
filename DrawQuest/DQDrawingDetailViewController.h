//
//  DQDrawingDetailViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

// Models
@class DQComment;
@class DQQuest;

// Controllers
@class DQPlaybackDataManager;
@class DQSharingController;

// Views
@class DQButton;
@class DQPlaybackImageView;

@interface DQDrawingDetailViewController : DQViewController

@property (nonatomic, copy) dispatch_block_t dismissBlock;

@property (nonatomic, copy) DQSharingController *(^makeSharingControllerBlock)(DQDrawingDetailViewController *vc);

- (id)initWithComment:(DQComment *)comment inQuest:(DQQuest *)quest newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithComment:inQuest:newPlaybackDataManager:source:delegate:);

@end
