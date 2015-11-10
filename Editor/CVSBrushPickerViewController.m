//
//  CVSBrushPickerViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSBrushPickerViewController.h"

// View Controllers
#import "CVSPadBrushPickerViewController.h"
#import "CVSPhoneBrushPickerViewController.h"

// Views
#import "CVSBrushesViewCell.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

const CGFloat kCVSBrushPickerViewControllerDesiredHeight = 85.0f;
const CGFloat kCVSBrushPickerViewControllerDesiredOffsetFromBottom = -30.0f;

static NSString *kCVSBrushPickerViewControllerCellIdentifier = @"CVSBrushPickerViewControllerCellIdentifier";
static NSArray *kCVSBrushPickerViewControllerOrderedBrushTypes = nil;

@interface CVSBrushPickerViewController ()

@property (nonatomic, strong) NSIndexSet *ownedBrushes;
@property (nonatomic, assign) CVSBrushType selectedBrush;
@property (nonatomic, weak, readwrite) UICollectionView *collectionView;
@property (nonatomic, weak) id<CVSBrushPickerViewControllerDelegate> delegate;

@end

@implementation CVSBrushPickerViewController

- (id)initWithDelegate:(id<CVSBrushPickerViewControllerDelegate>)delegate
{
    if ([self class] == [CVSBrushPickerViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[CVSPadBrushPickerViewController alloc] initWithDelegate:delegate];
        }
        else
        {
            self = [[CVSPhoneBrushPickerViewController alloc] initWithDelegate:delegate];
        }
    }
    else
    {
        self = [super initWithNibName:nil bundle:nil];
        if (self)
        {
            _delegate = delegate;
            _hidden = YES;

            NSArray *globalBrushesInfoArray = [self.delegate globalBrushesForBrushPickerViewController:self];
            if ([globalBrushesInfoArray count])
            {
                NSMutableArray *brushTypes = [[NSMutableArray alloc] init];
                for (NSDictionary *brushInfo in globalBrushesInfoArray)
                {
                    CVSBrushType brushType = CVSBrushTypeForCanonicalName(brushInfo.dq_brushCanonicalName);
                    // Don't include Eraser in iPhone because it is in the toolbar, not the brushPicker
                    if (brushType != CVSBrushTypeNotFound && ! (brushType == CVSBrushTypeEraser && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone))
                    {
                        [brushTypes addObject:@(brushType)];
                    }
                }
                kCVSBrushPickerViewControllerOrderedBrushTypes = [NSArray arrayWithArray:brushTypes];
            }
            else
            {
                // Default
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                {
                    kCVSBrushPickerViewControllerOrderedBrushTypes =  @[@(CVSBrushTypeMarker), @(CVSBrushTypePen), @(CVSBrushTypePaintbrush), @(CVSBrushTypeEraser)];
                }
                else
                {
                    kCVSBrushPickerViewControllerOrderedBrushTypes =  @[@(CVSBrushTypeMarker), @(CVSBrushTypePen), @(CVSBrushTypePaintbrush)];
                }
            }

            [self updateOwnedBrushes];

            for (NSNumber *number in kCVSBrushPickerViewControllerOrderedBrushTypes)
            {
                CVSBrushType brushType = [number unsignedIntegerValue];
                if ([self.ownedBrushes containsIndex:brushType])
                {
                    _selectedBrush = brushType;
                    break;
                }
            }
        }
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsZero;
    flowLayout.minimumInteritemSpacing = 0.0f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout = flowLayout;
    UICollectionView *brushesView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    brushesView.scrollEnabled = NO;
    brushesView.backgroundColor = [UIColor clearColor];
    brushesView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    brushesView.delegate = self;
    brushesView.dataSource = self;
    [brushesView registerClass:[CVSBrushesViewCell class] forCellWithReuseIdentifier:kCVSBrushPickerViewControllerCellIdentifier];
    [view addSubview:brushesView];
    self.collectionView = brushesView;
    
    self.view = view;
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark - Accessors

- (void)setActiveColor:(UIColor *)activeColor
{
    _activeColor = activeColor;
    for (NSUInteger index = 0; index < [self collectionView:self.collectionView numberOfItemsInSection:0]; index++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        CVSBrushesViewCell *cell = (CVSBrushesViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.brushView.activeColor = activeColor;
    }
}

#pragma mark -

- (CGFloat)widthOfBrushes
{
    CGFloat width = 0.0f;
    for (NSNumber *brushNumber in kCVSBrushPickerViewControllerOrderedBrushTypes)
    {
        CVSBrushType brushType = [brushNumber integerValue];
        width += [CVSBrushView sizeForBrushType:brushType].width;
    }
    return width;
}

- (NSInteger)numberOfBrushes
{
    return [kCVSBrushPickerViewControllerOrderedBrushTypes count];
}

- (void)updateOwnedBrushes
{
    NSMutableIndexSet *ownedBrushes = [[NSMutableIndexSet alloc] init];

    NSArray *userBrushes = [self.delegate ownedBrushesForBrushPickerViewController:self];

    for (NSDictionary *brush in userBrushes)
    {
        CVSBrushType brushType = CVSBrushTypeForCanonicalName(brush.dq_brushCanonicalName);
        if (brushType != CVSBrushTypeNotFound)
        {
            [ownedBrushes addIndex:brushType];
        }
    }

    self.ownedBrushes = [[NSIndexSet alloc] initWithIndexSet:ownedBrushes];

    [self.collectionView reloadData];
}

- (void)deselectAll
{
}

- (void)setHidden:(BOOL)hidden withDuration:(CGFloat)duration
{
    _hidden = hidden;

    self.bottomConstraint.constant = hidden ? kCVSBrushPickerViewControllerDesiredHeight : kCVSBrushPickerViewControllerDesiredOffsetFromBottom;
    [self.view.superview setNeedsUpdateConstraints];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view.superview layoutIfNeeded];
    }];
}

- (void)setStowed:(BOOL)stowed withDuration:(CGFloat)duration distance:(CGFloat)distance
{
    self.bottomConstraint.constant = stowed ? distance : kCVSBrushPickerViewControllerDesiredOffsetFromBottom;
    [self.view.superview setNeedsUpdateConstraints];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view.superview layoutIfNeeded];
    }];
}

- (CVSBrushType)brushTypeForIndexPath:(NSIndexPath *)indexPath
{
    return (CVSBrushType)[[kCVSBrushPickerViewControllerOrderedBrushTypes objectAtIndex:indexPath.item] unsignedIntegerValue];
}

#pragma mark - UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CVSBrushType brushType = [self brushTypeForIndexPath:indexPath];
    return CGSizeMake([CVSBrushView sizeForBrushType:brushType].width, collectionView.frameHeight);
}


#pragma mark - UICollectionViewDelegate Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [kCVSBrushPickerViewControllerOrderedBrushTypes count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CVSBrushType brushType = [self brushTypeForIndexPath:indexPath];
    if ([self.ownedBrushes containsIndex:brushType])
    {
        self.selectedBrush = brushType;
        if (self.brushSelectedBlock)
        {
            self.brushSelectedBlock(self, brushType);
        }
    }
    else
    {
        if (self.lockedBrushTappedBlock)
        {
            self.lockedBrushTappedBlock(self, brushType);
        }
    }
    [self didSelectBrushAtIndexPath:indexPath];
}

- (void)didSelectBrushAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)setStowed:(BOOL)stowed
{
}

#pragma mark - UICollectionViewDataSource Methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CVSBrushType brushType = [self brushTypeForIndexPath:indexPath];
    CVSBrushesViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCVSBrushPickerViewControllerCellIdentifier forIndexPath:indexPath];
    CVSBrushView *brushView = [[CVSBrushView alloc] initWithBrushType:brushType activeColor:self.activeColor hasSmile:YES];
    cell.brushView = brushView;
    cell.isLocked = ! [self.ownedBrushes containsIndex:brushType];
    
    // Align tops
    cell.frameY = 0.0f;
    
    return cell;
}

@end
