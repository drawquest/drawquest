//
//  DQFollowController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "DQFollowConstants.h"

@class STBasementViewController;

@interface DQFollowController : DQController

@property (nonatomic, weak) STBasementViewController *basementViewController;
@property (nonatomic, weak) UITabBarController *tabBarController;

- (void)reset;

@end
