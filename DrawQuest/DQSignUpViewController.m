//
//  DQSignUpViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSignUpViewController.h"

// View Controllers
#import "DQPadSignUpViewController.h"
#import "DQPhoneSignUpViewController.h"

// Additions
#import "DQAbstractAuthViewController+TemplateMethods.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

typedef NS_ENUM(NSUInteger, DQSignUpField) {
    DQSignUpFieldUsername = 0,
    DQSignUpFieldEmail,
    DQSignUpFieldPassword,
    DQSignUpFieldCount
};

@implementation DQSignUpViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    if ([self class] == [DQSignUpViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadSignUpViewController alloc] initWithDelegate:delegate];
        }
        else
        {
            self = [[DQPhoneSignUpViewController alloc] initWithDelegate:delegate];
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
        NSString *email = self.email;
        self.finishBlock(self, username, password, email);
    }
}

#pragma mark - Configuration

- (NSUInteger)numberOfFields
{
    return DQSignUpFieldCount;
}

- (NSUInteger)indexOfUsernameField
{
    return DQSignUpFieldUsername;
}

- (NSUInteger)indexOfPasswordField
{
    return DQSignUpFieldPassword;
}

- (NSUInteger)indexOfEmailField
{
    return DQSignUpFieldEmail;
}

- (void)customizeField:(UITextField *)textField atIndex:(NSUInteger)index
{
    if (index == DQSignUpFieldEmail)
    {
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }

    if (index == DQSignUpFieldPassword)
    {
        textField.secureTextEntry = YES;
    }
    
}

- (NSString *)placeholderForFieldAtIndex:(NSUInteger)field
{
    NSString *placeholder = nil;
    switch (field) {
        case DQSignUpFieldUsername:
            placeholder = DQLocalizedString(@"Username", @"The user's DrawQuest specific username");
            break;
        case DQSignUpFieldEmail:
            placeholder = DQLocalizedString(@"Email", @"Email");
            break;
        case DQSignUpFieldPassword:
            placeholder = DQLocalizedString(@"Password", @"The user's DrawQuest specific password");
            break;
        default:
            break;
    }

    return placeholder;
}

#pragma mark - Validation

- (BOOL)validateFormAndReportErrors
{
    NSString *description = nil;

    NSString *requiresUsernameError = DQLocalizedString(@"Please enter a valid username.", @"User needs to enter a valid username indicator label");
    NSString *requiresPasswordError = DQLocalizedString(@"Please enter a valid password.", @"User needs to enter a valid password indicator label");
    NSString *requiresEmailError = DQLocalizedString(@"Please enter a valid email address.", @"User needs to enter a valid email address indicator label");

    NSString *email = self.email;
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
    else if (!email.length)
    {
        description = requiresEmailError;
    }

    if (description)
    {
        [self showErrorWithDescription:description];
        return NO;
    }

    return YES;
}

@end
