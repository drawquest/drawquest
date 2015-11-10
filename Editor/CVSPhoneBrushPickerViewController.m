//
//  CVSPhoneBrushPickerViewController.m
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPhoneBrushPickerViewController.h"

static CGFloat kCVSBrushPickerViewControllerBackgroundOffset = 60.0f;

@interface CVSPhoneBrushPickerViewController ()

@property (nonatomic, weak) UIView *backgroundView;

@end

@implementation CVSPhoneBrushPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    backgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:backgroundView];
    self.backgroundView = backgroundView;
    [self.view sendSubviewToBack:backgroundView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.backgroundView.frame = CGRectMake(0.0f, kCVSBrushPickerViewControllerBackgroundOffset, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - kCVSBrushPickerViewControllerBackgroundOffset);
}

@end
