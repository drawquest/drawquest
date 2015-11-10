//
//  DQPadSignInViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadSignInViewController.h"

// Additions
#import "DQAbstractAuthViewController+TemplateMethods.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

@implementation DQPadSignInViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        self.title = DQLocalizedString(@"Welcome Back", @"Greeting for users signing in that have previously registered");
    }
    return self;
}

- (NSString *)textForTopLabel
{
    return DQLocalizedString(@"Welcome Back", @"Greeting for users signing in that have previously registered");
}

- (NSString *)headerImageName
{
    return DQLocalizedString(@"You Can Also Sign In Using:", @"Label preceeding alernative services that can be used to sign in");
}

- (NSString *)switchQuestionText
{
    return DQLocalizedString(@"Don't have an account?", @"Sign up button title as alternative to signing in");
}

- (NSString *)switchActionText
{
    return DQLocalizedString(@"Sign Up", @"Prompt for the user to sign up for DrawQuest");
}

@end
