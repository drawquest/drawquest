//
//  DQUserSearchViewController.h
//  DrawQuest
//
//  Created by David Mauro on 11/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQUserSearchViewController : DQViewController

@property (nonatomic, copy) void (^showProfileBlock)(DQUserSearchViewController *vc, NSString *username);

@end
