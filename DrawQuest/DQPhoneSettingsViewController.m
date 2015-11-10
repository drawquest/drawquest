//
//  DQPhoneSettingsViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-02.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneSettingsViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

// Models
#import "DQAccount.h"
#import "DQUser.h"

// View Controllers
#import "DQNavigationController.h"

// Views
#import "DQTableViewCell.h"
#import "DQButton.h"

@implementation DQPhoneSettingsViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate accountController:(DQAccountController *)accountController
{
    self = [super initWithDelegate:delegate accountController:accountController];
    if (self)
    {
        self.emailTextField.frameWidth = 240.0;
        self.bioTextField.frameWidth = 240.0;
        self.oldPasswordTextField.frameWidth = 150.0;
        self.passwordTextField.frameWidth = 150.0;
        self.repeatPasswordTextField.frameWidth = 150.0;
    }
    return self;
}

- (void)presentImagePicker:(DQImagePickerController *)imagePicker
{
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.width;
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, kDQSettingsViewControllerBottomInset + keyboardHeight, 0.0f);

    UITextField *activeTextField = (UITextField *)[self.view viewWithTag:self.activeTextField];
    CGRect frame = [self.tableView convertRect:activeTextField.bounds fromView:activeTextField];
    [self.tableView scrollRectToVisible:frame animated:NO];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, kDQSettingsViewControllerBottomInset, 0.0f);
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [super imagePickerController:picker didFinishPickingMediaWithInfo:info];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [super imagePickerControllerDidCancel:picker];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
