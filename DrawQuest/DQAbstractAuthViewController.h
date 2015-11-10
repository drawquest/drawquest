//
//  DQAbstractAuthViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQAbstractAuthViewController : DQViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) NSArray *textFields;

@property (nonatomic, copy) void (^facebookBlock)(DQAbstractAuthViewController *c);
@property (nonatomic, copy) void (^twitterBlock)(DQAbstractAuthViewController *c, UIView *sender);
@property (nonatomic, copy) void (^finishBlock)(DQAbstractAuthViewController *c, NSString *username, NSString *password, NSString *email);
@property (nonatomic, copy) void (^switchBlock)(DQAbstractAuthViewController *c);

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *email;

@property (nonatomic, readonly, assign) BOOL showSocialLoginButtons; // defaults to YES
@property (nonatomic, copy) NSString *submitButtonTitle;

// convenience initializer
- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate showSocialLoginButtons:(BOOL)showSocialLoginButtons;

- (void)showErrorWithDescription:(NSString *)description;

- (void)submit:(id)sender;

@end
