//
//  DQNavigationController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/19/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQNavigationController.h"
#import "DQBasementButton.h"

extern NSString *DQActivityCountUpdateNotification;

@class DQMainNavigationController;

@protocol DQMainNavigationControllerDelegate <DQNavigationControllerDelegate>

- (void)mainNavigationController:(DQMainNavigationController *)nc basementButtonTapped:(DQBasementButton *)basementButton;
- (NSUInteger)numberOfUnreadActivityItemsForMainNavigationController:(DQMainNavigationController *)nc;

@end

@interface DQMainNavigationController : DQNavigationController

@property (nonatomic, weak) id<DQMainNavigationControllerDelegate> delegate;

// designated initializer
- (id)initWithRootViewController:(UIViewController *)rootViewController delegate:(id<DQMainNavigationControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQNavigationControllerDelegate>)delegate MSDesignatedInitializer(initWithRootViewController:delegate:);

@end
