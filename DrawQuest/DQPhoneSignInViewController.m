//
//  DQPhoneSignInViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneSignInViewController.h"
#import "DQButton.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQAbstractAuthViewController+TemplateMethods.h"

@implementation DQPhoneSignInViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        self.title = DQLocalizedString(@"Welcome", @"Sign in modal title welcoming the user back");
    }
    return self;
}

// Add a forgot password button
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.forgotPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.forgotPasswordButton.backgroundColor = [UIColor dq_phoneButtonOffColor];
    self.forgotPasswordButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
    self.forgotPasswordButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 0.0f);
    [self.forgotPasswordButton setTitle:DQLocalizedString(@"?", @"A simple button title for when a user has forgotten their password") forState:UIControlStateNormal];
    [self.forgotPasswordButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    CGFloat size = 20.0f;
    self.forgotPasswordButton.frameWidth = size;
    self.forgotPasswordButton.frameHeight = size;
    self.forgotPasswordButton.layer.cornerRadius = size/2.0f;
    [self.forgotPasswordButton addTarget:self action:@selector(forgotPasswordButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

    NSUInteger idx = [self indexOfPasswordField];
    UITextField *textField = [self.textFields objectAtIndex:idx];
    [textField addSubview:self.forgotPasswordButton];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.forgotPasswordButton.frameMaxX = self.forgotPasswordButton.superview.frameWidth - 10.0f;
    self.forgotPasswordButton.frameCenterY = self.forgotPasswordButton.superview.boundsCenterY;
    [self.forgotPasswordButton.superview bringSubviewToFront:self.forgotPasswordButton];
}

- (NSString *)textForSocialLabel
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
