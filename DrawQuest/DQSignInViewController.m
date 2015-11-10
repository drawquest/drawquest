//
//  DQSignInViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSignInViewController.h"

// View Controllers
#import "DQPadSignInViewController.h"
#import "DQPhoneSignInViewController.h"

// Additions
#import "DQAbstractAuthViewController+TemplateMethods.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "DQAbstractServiceController.h"

typedef NS_ENUM(NSUInteger, DQSignInField) {
    DQSignInFieldUsername = 0,
    DQSignInFieldPassword,
    DQSignInFieldCount
};

@interface DQSignInViewController () <UIAlertViewDelegate>

@end

@implementation DQSignInViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    if ([self class] == [DQSignInViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadSignInViewController alloc] initWithDelegate:delegate];
        }
        else
        {
            self = [[DQPhoneSignInViewController alloc] initWithDelegate:delegate];
        }
    }
    else
    {
        self = [super initWithDelegate:delegate];
        if (self)
        {
        }
    }
    return self;
}

- (void)finish
{
    if (self.finishBlock)
    {
        NSString *username = self.username;
        NSString *password = self.password;
        self.finishBlock(self, username, password, nil);
    }
}

#pragma mark - Configuration

- (NSUInteger)numberOfFields
{
    return DQSignInFieldCount;
}

- (NSUInteger)indexOfUsernameField
{
    return DQSignInFieldUsername;
}

- (NSUInteger)indexOfPasswordField
{
    return DQSignInFieldPassword;
}

- (void)customizeField:(UITextField *)textField atIndex:(NSUInteger)index
{
    if (index == DQSignInFieldPassword)
    {
        textField.secureTextEntry = YES;
        
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
            UIButton *forgotButton = [UIButton buttonWithType:UIButtonTypeCustom];
            forgotButton.frame = CGRectMake(490, 10, 22, 22);
            forgotButton.backgroundColor = [UIColor colorWithRed:(213/255.0) green:(213/255.0) blue:(213/255.0) alpha:1];
            forgotButton.contentEdgeInsets = UIEdgeInsetsMake(1, 0.5f, 0, 0);
            forgotButton.layer.cornerRadius = 11;
            [forgotButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            forgotButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15];
            [forgotButton setTitle:DQLocalizedString(@"?", @"A simple button title for when a user has forgotten their password") forState:UIControlStateNormal];
            [forgotButton addTarget:self action:@selector(forgotPasswordButtonTapped) forControlEvents:UIControlEventTouchUpInside];
            
            [textField addSubview:forgotButton];
            
            
        }
        
    }
}

- (void)forgotPasswordButtonTapped
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Forgot Password?", @"Use tapped button indicating they forgot their password alert title") message:@"" delegate:self cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Forgot", @"Use tapped button indicating they forgot their password alert confirmation button title"), nil];
    alertView.tag = 1313;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey] stringByAppendingString:@"password_reset"]]];
    }
}

- (NSString *)placeholderForFieldAtIndex:(NSUInteger)field
{
    NSString *placeholder = nil;
    switch (field) {
        case DQSignInFieldUsername:
            placeholder = DQLocalizedString(@"Username", @"The user's DrawQuest specific username");
            break;
        case DQSignInFieldPassword:
            placeholder = DQLocalizedString(@"Password", @"The user's DrawQuest specific password");
            break;
        default:
            break;
    }

    return placeholder;
}

- (void)viewDidLayoutSubviewsCustomizeLayoutWithBottomView:(UIView *)bottomView
{
    [super viewDidLayoutSubviewsCustomizeLayoutWithBottomView:bottomView];
    [self.forgotPasswordLabel sizeToFit];
    self.forgotPasswordLabel.center = CGPointMake(self.view.center.x, CGRectGetMaxY(bottomView.frame) + 36.0f);
    self.forgotPasswordButton.frame = self.forgotPasswordLabel.frame;
}

#pragma mark - Actions

- (void)forgotPasswordButtonTouchDown:(id)sender
{
    self.forgotPasswordLabel.highlighted = YES;
}

- (void)forgotPasswordButtonTouchUpOutside:(id)sender
{
    self.forgotPasswordLabel.highlighted = NO;
}

- (void)forgotPasswordButtonTouchUpInside:(id)sender
{
    self.forgotPasswordLabel.highlighted = NO;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey] stringByAppendingString:@"password_reset"]]];
}

#pragma mark - Validation

- (BOOL)validateFormAndReportErrors
{
    NSString *description = nil;

    NSString *requiresUsernameError = DQLocalizedString(@"Please enter a valid username.", @"User needs to enter a valid username indicator label");
    NSString *requiresPasswordError = DQLocalizedString(@"Please enter a valid password.", @"User needs to enter a valid password indicator label");

    NSString *username = self.username;
    NSString *password = self.password;

    if (!username.length)
    {
        description = requiresUsernameError;
    }
    else if (!password.length)
    {
        description = requiresPasswordError;
    }

    if (description)
    {
        [self showErrorWithDescription:description];
        return NO;
    }
    return YES;
}

@end
