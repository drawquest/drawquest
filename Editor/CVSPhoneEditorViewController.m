//
//  CVSPhoneEditorViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPhoneEditorViewController.h"
#import "CVSEditorView.h"
#import "CVSColorPickerViewController.h"
#import "CVSBrushPickerViewController.h"
#import "CVSToolbar.h"
#import "DQAccount.h"
#import "DQButton.h"
#import "UIView+STAdditions.h"

static UIInterfaceOrientation kCVSPhoneEditorViewControllerLastRotatedFrom = NSNotFound;
static const CGFloat estimatedStatusBarHeight = 44.0f;

@interface CVSPhoneEditorViewController ()

@property (nonatomic, assign) BOOL alreadyAppeared;
@end

@implementation CVSPhoneEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.alreadyAppeared = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Zoom to fit the first time the view will appear
    if ( ! self.alreadyAppeared)
    {
        [self zoomToFitAnimated:NO];
        // Prevent the image from jumping
        self.scrollView.frameY -= estimatedStatusBarHeight;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Zoom to fit the first time the view did appear
    if ( ! self.alreadyAppeared)
    {
        self.alreadyAppeared = YES;
        // Prevent the image from jumping
        self.scrollView.frameY += estimatedStatusBarHeight;
    }
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.brushPicker = nil;
    }
    [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Hack to deal with didRotate coming in twice
    if (fromInterfaceOrientation != kCVSPhoneEditorViewControllerLastRotatedFrom)
    {
        [self layoutShowInterfaceButton];
        
        // ColorPicker doesn't have a parent view controller so we need to tell it that it rotated
        [self.colorPicker didRotateFromInterfaceOrientation:fromInterfaceOrientation];
        
        [self zoomToFit];
    }
    kCVSPhoneEditorViewControllerLastRotatedFrom = fromInterfaceOrientation;

    if (self.didRotateDeviceBlock)
    {
        self.didRotateDeviceBlock(self);
    }
    [self.toolbarView setNeedsLayout];
}

#pragma mark -

- (CGFloat)toolbarHeight
{
    return kCVSPhoneToolbarHeight;
}

- (CGFloat)toolbarEnabledHeightDifference
{
    return kCVSPhoneToolbarDisabledBottomConstant;
}

- (void)initAutolayout
{
    [super initAutolayout];

    // Add the brush picker's view to our view
    UIView *brushPicker = self.brushPicker.view;
    brushPicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:brushPicker];
    [self.view bringSubviewToFront:self.toolbarView];

    // Layout Brush Picker
    NSDictionary *editorSubviews = @{@"brushPicker": self.brushPicker.view};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[brushPicker]|" options:0 metrics:nil views:editorSubviews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[brushPicker(brushPickerHeight)]" options:0 metrics:@{@"brushPickerHeight": @(kCVSBrushPickerViewControllerDesiredHeight)} views:editorSubviews]];
    self.brushPicker.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.brushPicker.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:kCVSBrushPickerViewControllerDesiredHeight];
    [self.view addConstraint:self.brushPicker.bottomConstraint];

    // Layout the Toolbar
    editorSubviews = @{@"toolbar": self.toolbarView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|" options:0 metrics:nil views:editorSubviews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolbar(toolbarHeight)]" options:0 metrics:@{@"toolbarHeight": @(kCVSPhoneToolbarHeight)} views:editorSubviews]];
    self.toolbarView.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.toolbarView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
    [self.view addConstraint:self.toolbarView.bottomConstraint];
}

- (void)animateInterfaceHidden:(BOOL)visible
{
    [super animateInterfaceHidden:visible];

    CGFloat duration = 0.2f;
    CGFloat combinedHeight = CGRectGetHeight(self.toolbarView.frame);
    if ( ! self.brushPicker.isStowed && ! self.brushPicker.isHidden)
    {
        combinedHeight = CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.brushPicker.view.frame) + CGRectGetHeight(self.brushPicker.view.frame);
        [self.brushPicker setStowed:!visible withDuration:duration distance:combinedHeight];
    }
    [self.toolbarView setStowed:!visible withDuration:duration distance:combinedHeight];
}

#pragma mark - Zoom

- (void)zoomToFit
{
    [self zoomToFitAnimated:YES];
}

- (void)zoomToFitAnimated:(BOOL)animated
{
    [self.scrollView zoomToRect:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f) animated:animated];
}

@end
