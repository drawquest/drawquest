//
//  DQNavigationController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-05-31.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQViewController.h"

@protocol DQNavigationControllerDelegate <UINavigationControllerDelegate, DQViewControllerDelegate>

@end

@interface DQNavigationController : UINavigationController <DQViewController>

@property (nonatomic, assign) id<DQNavigationControllerDelegate> delegate;

// designated initializer
- (id)initWithRootViewController:(UIViewController *)rootViewController delegate:(id<DQNavigationControllerDelegate>)delegate;


- (id)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass delegate:(id<DQNavigationControllerDelegate>)delegate;
- (id)initWithDelegate:(id<DQNavigationControllerDelegate>)delegate;

- (id)init MSDesignatedInitializer(initWithRootViewController:delegate:);
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithRootViewController:delegate:);

- (void)enableAutorotate:(BOOL)enable;

@end
