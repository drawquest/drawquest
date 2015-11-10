//
//  DQProfileViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQFollowConstants.h"

@class DQUser;

@interface DQProfileViewController : DQViewController

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) DQUser *user;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, assign) BOOL isForLoggedInUser;
@property (nonatomic, assign) DQFollowState followState;
@property (nonatomic, copy) void(^showShopBlock)(DQProfileViewController *vc);

// designated initializer
- (id)initWithUserName:(NSString *)inUserName source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithUserName:source:delegate:);

- (NSDictionary *)viewEventLoggingParameters;
- (NSDictionary *)eventLoggingParameters;

- (void)showError:(NSError *)inError;
- (void)showErrorWithTitle:(NSString *)title description:(NSString *)description;

@end
