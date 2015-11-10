//
//  DQSignUpViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractAuthViewController.h"

@interface DQSignUpViewController : DQAbstractAuthViewController

@property (nonatomic, copy) void (^facebookBlock)(DQSignUpViewController *c);
@property (nonatomic, copy) void (^twitterBlock)(DQSignUpViewController *c, UIView *sender);
@property (nonatomic, copy) void (^finishBlock)(DQSignUpViewController *c, NSString *username, NSString *password, NSString *email);
@property (nonatomic, copy) void (^switchBlock)(DQSignUpViewController *c);

@end
