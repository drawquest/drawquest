//
//  CVSPadBrushPickerViewController.m
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPadBrushPickerViewController.h"

#import "CVSBrushesViewCell.h"

#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface CVSPadBrushPickerViewController ()

@property (nonatomic, weak) UIView *backgroundView;

@end

@implementation CVSPadBrushPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    backgroundView.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
    [self.view addSubview:backgroundView];
    self.backgroundView = backgroundView;
    [self.view sendSubviewToBack:backgroundView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.backgroundView.frame = CGRectMake(0.0f, 15.0f, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 15.0f);
}

- (void)didSelectBrushAtIndexPath:(NSIndexPath *)indexPath
{
    CVSBrushesViewCell *cell = (CVSBrushesViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell != self.activeBrushCell && ! cell.isLocked)
    {
        if (self.activeBrushCell)
        {
            self.activeBrushCell.popped = NO;
        }
        self.activeBrushCell = cell;
        cell.popped = YES;
    }
}

- (void)deselectAll
{
    if (self.activeBrushCell)
    {
        self.activeBrushCell.popped = NO;
        self.activeBrushCell = nil;
    }
}

- (void)setStowed:(BOOL)stowed
{
    if (self.activeBrushCell)
    {
        self.activeBrushCell.popped = ! stowed;
    }
}

#pragma mark - UICollectionViewDataSource Methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CVSBrushesViewCell *cell = (CVSBrushesViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    CVSBrushType brushType = [super brushTypeForIndexPath:indexPath];

    if (brushType == self.selectedBrush)
    {
        self.activeBrushCell = cell;
        [cell setPoppedUnanimated:YES];
    }

    // Align tops
    cell.frameY = 20.0f;

    return cell;
}

@end
