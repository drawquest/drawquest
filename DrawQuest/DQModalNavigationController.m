//
//  DQModalNavigationController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-05-31.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQModalNavigationController.h"

@implementation DQModalNavigationController

- (id)initWithDelegate:(id<DQNavigationControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.modalPresentationStyle = UIModalPresentationFormSheet;
        }
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController delegate:(id<DQNavigationControllerDelegate>)delegate
{
    self = [super initWithRootViewController:rootViewController delegate:delegate];
    if (self)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.modalPresentationStyle = UIModalPresentationFormSheet;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

@end
