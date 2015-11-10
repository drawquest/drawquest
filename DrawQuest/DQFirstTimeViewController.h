//
//  DQFirstTimeViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 12/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQFirstTimeViewController : DQViewController

@property (nonatomic, copy) void (^showAuthBlock)(DQFirstTimeViewController *c);
@property (nonatomic, copy) dispatch_block_t showFirstQuestBlock;

@end
