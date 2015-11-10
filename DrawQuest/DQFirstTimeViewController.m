//
//  DQFirstTimeViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 12/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQFirstTimeViewController.h"

// Controllers

// Views
#import "DQButton.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

@implementation DQFirstTimeViewController

#pragma mark - Actions

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f)];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"1stTime_landingPage_blank"]];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    DQButton *firstQuestButton = [DQButton buttonWithType:UIButtonTypeCustom];
    firstQuestButton.translatesAutoresizingMaskIntoConstraints = NO;
    firstQuestButton.backgroundColor = [UIColor dq_pinkColor];
    firstQuestButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:22.0f];
    firstQuestButton.contentEdgeInsets = UIEdgeInsetsMake(15.0f, 30.0f, 15.0f, 30.0f);
    firstQuestButton.layer.cornerRadius = 5.0f;
    [firstQuestButton setTitle:DQLocalizedString(@"I'm ready for my first Quest!", @"Button title indicating the user is ready to begin") forState:UIControlStateNormal];
    firstQuestButton.tappedBlock = ^(DQButton *button) {
        if (self.showFirstQuestBlock)
        {
            self.showFirstQuestBlock();
        }
    };
    [self.view addSubview:firstQuestButton];

    DQButton *signInButton = [DQButton buttonWithType:UIButtonTypeCustom];
    signInButton.translatesAutoresizingMaskIntoConstraints = NO;
    signInButton.backgroundColor = [UIColor colorWithRed:(83/255.0) green:(175/255.0) blue:(186/255.0) alpha:0.8];
    signInButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:22.0f];
    signInButton.contentEdgeInsets = UIEdgeInsetsMake(15.0f, 30.0f, 15.0f, 30.0f);
    [signInButton setTitle:DQLocalizedString(@"Sign In", @"Prompt for the user to sign into their DrawQuest account") forState:UIControlStateNormal];
    signInButton.layer.cornerRadius = 5.0f;
    signInButton.tappedBlock = ^(DQButton *button) {
        if (self.showAuthBlock)
        {
            self.showAuthBlock(self);
        }
    };
    [self.view addSubview:signInButton];

    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    welcomeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    welcomeLabel.textAlignment = NSTextAlignmentCenter;
    welcomeLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:22.0f];
    welcomeLabel.textColor = [UIColor whiteColor];
    welcomeLabel.numberOfLines = 1;
    welcomeLabel.text = DQLocalizedString(@"Welcome to", @"Prefix before the DrawQuest logo welcoming the user on the splash screen");
    [welcomeLabel sizeToFit];
    [self.view addSubview:welcomeLabel];

    UILabel *aboutLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    aboutLabel.translatesAutoresizingMaskIntoConstraints = NO;
    aboutLabel.textAlignment = NSTextAlignmentCenter;
    aboutLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:22.0f];
    aboutLabel.textColor = [UIColor whiteColor];
    aboutLabel.numberOfLines = 0;
    aboutLabel.text = DQLocalizedString(@"Every day, DrawQuesters from around the world complete a daily drawing challenge. Quests don't have a right or wrong answer - use your imagination, and have fun!", @"Introductory phrase explaining how to use the app");
    [aboutLabel sizeToFit];
    [self.view addSubview:aboutLabel];

    UILabel *signInLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    signInLabel.translatesAutoresizingMaskIntoConstraints = NO;
    signInLabel.textAlignment = NSTextAlignmentCenter;
    signInLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:16.0f];
    signInLabel.textColor = [UIColor whiteColor];
    signInLabel.numberOfLines = 1;
    signInLabel.text = DQLocalizedString(@"Already have an account?", @"Sign in button title as alternative to signing up");
    [signInLabel sizeToFit];
    [self.view addSubview:signInLabel];

    UILabel *conductLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    conductLabel.translatesAutoresizingMaskIntoConstraints = NO;
    conductLabel.textAlignment = NSTextAlignmentCenter;
    conductLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:16.0f];
    conductLabel.textColor = [UIColor colorWithRed:(57/255.0) green:(150/255.0) blue:(161/255.0) alpha:1.0];
    conductLabel.numberOfLines = 0;
    conductLabel.text = DQLocalizedString(@"We have Questers of all ages, so please keep your drawings safe-for-work and appropriate for everyone", @"Message encouraging users to keep drawings appropriate for all ages");
    [conductLabel sizeToFit];
    [self.view addSubview:conductLabel];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(firstQuestButton, signInButton, welcomeLabel, aboutLabel, signInLabel, conductLabel);
    NSDictionary *metrics = @{@"aboutLabelWidth": @(540), @"conductLabelWidth": @(460), @"welcomeLabelTopInset": @(125), @"verticalPadding": @(16)};

    DQVisualConstraints(self.view, @"H:|[welcomeLabel]|");
    DQVisualConstraints(self.view, @"H:|[signInLabel]|");
    DQVisualConstraints(self.view, @"H:[aboutLabel(aboutLabelWidth)]");
    DQVisualConstraints(self.view, @"H:[conductLabel(conductLabelWidth)]");

    DQVisualConstraints(self.view, @"V:|-welcomeLabelTopInset-[welcomeLabel]");
    DQVisualConstraintsWithOptions(self.view, @"V:[aboutLabel]-verticalPadding-[firstQuestButton]-verticalPadding-[signInLabel]-verticalPadding-[signInButton]-verticalPadding-[conductLabel]-verticalPadding-|", NSLayoutFormatAlignAllCenterX);

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
}

@end
