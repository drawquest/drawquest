//
//  DQAlmostThereViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSignUpViewController.h"

@interface DQAlmostThereViewController : DQSignUpViewController

@property (nonatomic, copy) void (^finishBlock)(DQAlmostThereViewController *c, NSString *username, NSString *password, NSString *email);

@end
