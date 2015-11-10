//
//  CVSPadEditorViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPadEditorViewController.h"

#import "UIColor+DQAdditions.h"

@interface CVSPadEditorViewController ()

@end

@implementation CVSPadEditorViewController

#pragma mark -

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // James hasn't been using tintColor throughout the app :(
    self.navigationController.view.tintColor = [UIColor dq_editorTabColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
}

- (void)animateInterfaceHidden:(BOOL)visible
{
    [super animateInterfaceHidden:visible];

    [self.toolbarView setStowed:!visible withDuration:0.2f distance:CGRectGetHeight(self.toolbarView.frame)];
}

- (void)initAutolayout
{
    [super initAutolayout];

    // Layout the Toolbar
    NSDictionary *editorSubviews = @{@"toolbar": self.toolbarView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|" options:0 metrics:nil views:editorSubviews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolbar(toolbarHeight)]" options:0 metrics:@{@"toolbarHeight": @(kCVSPadToolbarHeight)} views:editorSubviews]];
    self.toolbarView.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.toolbarView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
    [self.view addConstraint:self.toolbarView.bottomConstraint];
}

- (CGFloat)toolbarHeight
{
    return kCVSPadToolbarHeight;
}

- (void)updateEditorForBrushType:(CVSBrushType)inBrushType
{
    [super updateEditorForBrushType:inBrushType];

    if (inBrushType == CVSBrushTypeEraser)
    {
        [self.brushPicker deselectAll];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [super scrollViewDidEndZooming:scrollView withView:view atScale:scale];

    // Snap to 100%
    CGFloat threshold = 0.05;
    if (scale >= 1.0 - threshold && scale <= 1.0 + threshold && scale != 1.0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *subView = [scrollView.subviews objectAtIndex:0];
            subView.center = CGPointMake(scrollView.contentSize.width * 0.5, scrollView.contentSize.height * 0.5);
            scrollView.contentInset = UIEdgeInsetsZero;
            [scrollView setZoomScale:1.0];
        });
    }
}

@end
