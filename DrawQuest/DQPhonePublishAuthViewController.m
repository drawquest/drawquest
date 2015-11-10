//
//  DQPhonePublishAuthViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhonePublishAuthViewController.h"

// Views
#import "DQButton.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQPhonePublishAuthViewController ()

@property (nonatomic, weak) UIImageView *illustrationImageView;
@property (nonatomic, weak) UILabel *messageLabel;
@property (nonatomic, weak) UIView *switchWrapperView;
@property (nonatomic, weak) UIButton *switchButton;

@property (nonatomic, weak) UIButton *facebookButton;
@property (nonatomic, weak) UIButton *twitterButton;
@property (nonatomic, weak) UIButton *emailButton;

@end

@implementation DQPhonePublishAuthViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    UIImageView *illustrationImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"join_drawquest_spot_phone"]];
    [self.view addSubview:illustrationImageView];
    self.illustrationImageView = illustrationImageView;

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    messageLabel.text = DQLocalizedString(@"Sign up for DrawQuest to post your drawing and collect your first 25 coins!", @"Prompt to sign up, post, and collect the 25 coin reward for doing so");
    messageLabel.font = [UIFont dq_phoneAuthSignUpMessageFont];
    messageLabel.textColor = [UIColor dq_phoneGrayTextColor];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.numberOfLines = 0;
    [self.view addSubview:messageLabel];
    self.messageLabel = messageLabel;

    DQButton *facebookButton = [DQButton buttonWithImage:[UIImage imageNamed:@"button_facebook_long"]];
    [facebookButton addTarget:self action:@selector(facebook:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:facebookButton];
    self.facebookButton = facebookButton;

    DQButton *twitterButton = [DQButton buttonWithImage:[UIImage imageNamed:@"button_twitter_long"]];
    [twitterButton addTarget:self action:@selector(twitter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:twitterButton];
    self.twitterButton = twitterButton;

    // Auto layout items

    UIView *switchWrapperView = [[UIView alloc] initWithFrame:CGRectZero];
    switchWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    switchWrapperView.backgroundColor = [UIColor dq_phoneDivider];
    [self.view addSubview:switchWrapperView];
    self.switchWrapperView = switchWrapperView;

    DQButton *emailButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_signUP_icon_mail"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [emailButton setImage:[[UIImage imageNamed:@"button_signUP_icon_mail"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateHighlighted];
    emailButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    emailButton.translatesAutoresizingMaskIntoConstraints = NO;
    emailButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    emailButton.titleLabel.minimumScaleFactor = 0.5f;
    emailButton.layer.cornerRadius = 4.0f;
    emailButton.backgroundColor = [UIColor dq_phoneLightGrayTextColor];
    emailButton.titleLabel.font = [UIFont dq_phoneAuthSwitchButtonFont];
    emailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    emailButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 6.0f, 0.0f, 0.0f);
    emailButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 0.0f);
    [emailButton addTarget:self action:@selector(email:) forControlEvents:UIControlEventTouchUpInside];
    [emailButton setTitle:DQLocalizedString(@"Sign Up Using Email", @"Sign up using email button title") forState:UIControlStateNormal];
    [switchWrapperView addSubview:emailButton];
    self.emailButton = emailButton;

    UIButton *switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    switchButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    switchButton.titleLabel.minimumScaleFactor = 0.5f;
    switchButton.contentEdgeInsets = UIEdgeInsetsMake(6.0f, 12.0f, 6.0f, 12.0f);
    switchButton.layer.cornerRadius = 4.0f;
    switchButton.backgroundColor = [UIColor dq_phoneLightGrayTextColor];
    switchButton.titleLabel.font = [UIFont dq_phoneAuthSwitchButtonFont];
    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [switchButton setTitle:DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account") forState:UIControlStateNormal];
    [switchButton addTarget:self action:@selector(loginButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [switchWrapperView addSubview:switchButton];
    self.switchButton = switchButton;

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(switchWrapperView, emailButton, switchButton);
    NSDictionary *metrics = @{@"padding": @(18), @"priority": @(UILayoutPriorityDefaultHigh)};

    DQVisualConstraints(self.view, @"H:|[switchWrapperView]|");
    DQVisualConstraints(self.view, @"V:[switchWrapperView]|");

    DQVisualConstraints(switchWrapperView, @"H:|-padding-[emailButton]-10-[switchButton]-padding-|");
    DQVisualConstraints(switchWrapperView, @"V:|-padding@priority-[emailButton]-padding@priority-|");
    DQVisualConstraints(switchWrapperView, @"V:|-padding@priority-[switchButton]-padding@priority-|");

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.illustrationImageView.frameCenterX = self.view.frameCenterX;
    self.illustrationImageView.frameY = -5.0f;

    self.messageLabel.frameWidth = self.view.frameWidth - 50.0f;
    [self.messageLabel sizeToFit];
    self.messageLabel.frameCenterX = self.view.frameCenterX;
    self.messageLabel.frameY = self.illustrationImageView.frameMaxY - 15.0f;

    self.facebookButton.frameCenterX = self.view.frameCenterX;
    self.facebookButton.frameY = self.messageLabel.frameMaxY + 25.0f;

    self.twitterButton.frameCenterX = self.view.frameCenterX;
    self.twitterButton.frameY = self.facebookButton.frameMaxY + 15.0f;
}

@end
