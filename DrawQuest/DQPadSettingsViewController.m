//
//  DQPadSettingsViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-02.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadSettingsViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQPadSettingsViewController ()

@property (nonatomic, strong) UIPopoverController *imagePickerPopover;

@end

@implementation DQPadSettingsViewController

- (void)presentImagePicker:(DQImagePickerController *)imagePicker
{
    self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];

    CGRect cellRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self.imagePickerPopover presentPopoverFromRect:cellRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [super imagePickerController:picker didFinishPickingMediaWithInfo:info];
    [self.imagePickerPopover dismissPopoverAnimated:YES];
    self.imagePickerPopover = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [super imagePickerControllerDidCancel:picker];
    [self.imagePickerPopover dismissPopoverAnimated:YES];
    self.imagePickerPopover = nil;
}

@end
