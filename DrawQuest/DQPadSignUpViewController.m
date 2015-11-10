//
//  DQPadSignUpViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadSignUpViewController.h"

@interface DQPadSignUpViewController ()

@end

@implementation DQPadSignUpViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        self.title = DQLocalizedString(@"Join DrawQuest", @"Sign up modal title");
    }
    return self;
}

// FIXME: Is this even being used?
- (NSString *)textForTopLabel
{
    return DQLocalizedString(@"Join DrawQuest", @"Sign up modal title");
}

- (NSString *)headerImageName
{
    return DQLocalizedString(@"You Can Also Sign Up Using:", @"Label preceeding alernative services that can be used to sign up");
}

- (NSString *)switchQuestionText
{
    return DQLocalizedString(@"Already have an account?", @"Sign in button title as alternative to signing up");
}

- (NSString *)switchActionText
{
    return DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account");
}

@end
