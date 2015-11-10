//
//  DQPadPublishAuthViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadPublishAuthViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@interface DQPadPublishAuthViewController ()

@property (nonatomic, weak) UIView *wrapperView;
@property (nonatomic, weak) UIView *bottomWrapperView;

@property (nonatomic, weak) UIImageView *illustrationImageView;
@property (nonatomic, weak) UILabel *coinsLabel;
@property (nonatomic, weak) UIImageView *signUpHeaderImageView;

@property (nonatomic, weak) UIButton *facebookButton;
@property (nonatomic, weak) UIButton *twitterButton;
@property (nonatomic, weak) UIButton *emailButton;
@property (nonatomic, weak) UIButton *loginButton;

@end

@implementation DQPadPublishAuthViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
                            
    UIView *wrapperView = [[UIView alloc] initWithFrame:CGRectZero];
    [view addSubview:wrapperView];
    self.wrapperView = wrapperView;
    
    UIView *bottomWrapperView = [[UIView alloc] initWithFrame:CGRectZero];
    bottomWrapperView.backgroundColor = [UIColor colorWithRed:(229/255.0) green:(229/255.0) blue:(229/255.0) alpha:1];
    [view addSubview:bottomWrapperView];
    self.bottomWrapperView = bottomWrapperView;

    UIImageView *illustrationImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"publishauth_spot_illustration_coins"]];
    [wrapperView addSubview:illustrationImageView];
    self.illustrationImageView = illustrationImageView;

    UILabel *coinsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    coinsLabel.numberOfLines = 2;
    coinsLabel.backgroundColor = [UIColor clearColor];
    coinsLabel.font = [UIFont dq_publishAuthHeaderFont];
    coinsLabel.textColor = [UIColor colorWithRed:(180/255.0f) green:(180/255.0f) blue:(180/255.0f) alpha:1];
    coinsLabel.textAlignment = NSTextAlignmentCenter;
    coinsLabel.text = DQLocalizedString(@"Sign up for DrawQuest to post your drawing and collect your first 25 coins!", @"Prompt to sign up, post, and collect the 25 coin reward for doing so");
    [wrapperView addSubview:coinsLabel];
    self.coinsLabel = coinsLabel;

    UIButton *facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [facebookButton addTarget:self action:@selector(facebook:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *facebookButtonImage = [UIImage imageNamed:@"button_facebook_long"];
    [facebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
    [wrapperView addSubview:facebookButton];
    self.facebookButton = facebookButton;

    UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [twitterButton addTarget:self action:@selector(twitter:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *twitterButtonImage = [UIImage imageNamed:@"button_twitter_long"];
    [twitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
    [wrapperView addSubview:twitterButton];
    self.twitterButton = twitterButton;

    UIButton *emailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [emailButton setTitle:DQLocalizedString(@"Sign Up Using Email", @"Sign up using email button title") forState:UIControlStateNormal];
    emailButton.backgroundColor = [UIColor colorWithRed:(196/255.0) green:(196/255.0) blue:(196/255.0) alpha:1];
    emailButton.layer.cornerRadius = 5;
    emailButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    emailButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15.0];
    [emailButton addTarget:self action:@selector(email:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomWrapperView addSubview:emailButton];
    self.emailButton = emailButton;
    
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [loginButton setTitle:DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account") forState:UIControlStateNormal];
    loginButton.backgroundColor = [UIColor colorWithRed:(196/255.0) green:(196/255.0) blue:(196/255.0) alpha:1];
    loginButton.layer.cornerRadius = 5;
    loginButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    loginButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15.0];

    [loginButton addTarget:self action:@selector(loginButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomWrapperView addSubview:loginButton];
    self.loginButton = loginButton;
    
    self.view = view;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.wrapperView.frame = CGRectInset(self.view.bounds, kDQFormWrapperInsetHorizontal, kDQFormWrapperInsetVertical);
    CGFloat centerX = self.wrapperView.boundsCenterX;
    
    self.bottomWrapperView.frame = CGRectMake(0, self.wrapperView.frame.size.height, self.view.frame.size.width, 65);
    
    self.illustrationImageView.frameCenterX = centerX;
    self.illustrationImageView.frameY = 20;
    
    self.coinsLabel.boundsSize = CGSizeMake(320.0f, 50.0f);
    self.coinsLabel.frameCenterX = centerX;
    self.coinsLabel.frameY = self.illustrationImageView.frameMaxY - 7.0;
    
    UIImage *facebookButtonImage = [UIImage imageNamed:@"button_facebook_long"];
    self.facebookButton.frame = CGRectMake(centerX - ( facebookButtonImage.size.width / 2), CGRectGetMaxY(self.coinsLabel.frame) + 30.0, facebookButtonImage.size.width, facebookButtonImage.size.height);
    
    UIImage *twitterButtonImage = [UIImage imageNamed:@"button_twitter_long"];
    self.twitterButton.frame = CGRectMake(centerX - (twitterButtonImage.size.width / 2), CGRectGetMaxY(self.facebookButton.frame) + 20, twitterButtonImage.size.width, twitterButtonImage.size.height);
    
    UIImageView *emailIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button_signUP_icon_mail"]];
    emailIconImageView.frame = CGRectMake(8, 0, 27, 30);
    [self.emailButton addSubview:emailIconImageView];
    self.emailButton.frame = CGRectMake(120, 15, 195, 30);
    self.emailButton.contentEdgeInsets = UIEdgeInsetsMake(0, 32, 0, 0);
    
    self.loginButton.frame = CGRectMake(self.emailButton.frame.origin.x + self.emailButton.frame.size.width + 13, 15, 77, 30);
}
    
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Actions

- (void)loginButtonTouchDown:(id)sender
{
    

}

- (void)loginButtonTouchUpOutside:(id)sender
{
    }

- (void)loginButtonTouchUpInside:(id)sender
{
   
    [super loginButtonTouchUpInside:(id)sender];
}

@end
