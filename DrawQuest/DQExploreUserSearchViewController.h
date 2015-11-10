//
//  DQExploreUserSearchViewController.h
//  DrawQuest
//
//  Created by Dirk on 4/19/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQExploreUserSearchViewController : DQViewController

@property (nonatomic, copy) void (^displayProfileBlock)(DQExploreUserSearchViewController *c, NSString *userName);

@end
