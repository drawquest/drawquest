//
//  DQSignInViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractAuthViewController.h"

@interface DQSignInViewController : DQAbstractAuthViewController

@property (nonatomic, weak) UILabel *forgotPasswordLabel;
@property (nonatomic, weak) UIButton *forgotPasswordButton;
@property (nonatomic, copy) void (^facebookBlock)(DQSignInViewController *c);
@property (nonatomic, copy) void (^twitterBlock)(DQSignInViewController *c, UIView *sender);
@property (nonatomic, copy) void (^finishBlock)(DQSignInViewController *c, NSString *username, NSString *password, NSString *email);
@property (nonatomic, copy) void (^switchBlock)(DQSignInViewController *c);

@end
