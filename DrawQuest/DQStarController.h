//
//  DQStarController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "DQStarConstants.h"

@class STBasementViewController;

@interface DQStarController : DQController

@property (nonatomic, weak) STBasementViewController *basementViewController;
@property (nonatomic, weak) UITabBarController *tabBarController;

- (void)reset;

@end
