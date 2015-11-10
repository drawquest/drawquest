//
//  DQPhoneSignUpViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneSignUpViewController.h"

@interface DQPhoneSignUpViewController ()

@end

@implementation DQPhoneSignUpViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        self.title = DQLocalizedString(@"Join", @"Title for sign up modal");
    }
    return self;
}

- (NSString *)textForSocialLabel
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
