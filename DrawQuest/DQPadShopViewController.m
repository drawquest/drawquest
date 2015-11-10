//
//  DQPadShopViewController.m
//  DrawQuest
//
//  Created by David Mauro on 11/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadShopViewController.h"

// Controllers
#import "DQAbstractServiceController.h"

// Views
#import "DQSegmentedControl.h"
#import "DQPhoneShopColorPackCell.h"
#import "DQPhoneShopColorCell.h"
#import "DQPhoneShopCoinCell.h"
#import "DQPhoneShopBrushCell.h"
#import "DQAlertView.h"
#import "CVSBrushView.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQAnalyticsConstants.h"
#import "NSDictionary+DQAPIConveniences.h"

static NSString *DQPadShopViewControllerHeaderView = @"headerView";

@interface DQPadShopViewController () <DQSegmentedControlDataSource, DQSegmentedControlDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, weak) DQButton *restorePurchasesButton;

@end

@implementation DQPadShopViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // TODO: Fix this throughout iPad
    self.navigationController.view.tintColor = [UIColor dq_greenColor];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator setHidesWhenStopped:YES];
    [activityIndicator startAnimating];
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;

    DQButton *restorePurchasesButton = [DQButton buttonWithType:UIButtonTypeCustom];
    restorePurchasesButton.hidden = YES;
    restorePurchasesButton.tintColorForBackground = YES;
    [restorePurchasesButton setTitle:DQLocalizedString(@"Restore Purchases", @"Restore all shop purchases previously made button title") forState:UIControlStateNormal];
    restorePurchasesButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
    restorePurchasesButton.layer.cornerRadius = 4.0f;
    __weak typeof(self) weakSelf = self;
    restorePurchasesButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.restorePurchasesBlock)
        {
            weakSelf.restorePurchasesBlock(weakSelf, button);
        }
    };
    [self.view addSubview:restorePurchasesButton];
    self.restorePurchasesButton = restorePurchasesButton;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.activityIndicator.center = self.view.boundsCenter;

    [self.restorePurchasesButton sizeToFit];
    self.restorePurchasesButton.frameWidth = self.view.frameWidth - 340.0f;
    self.restorePurchasesButton.frameCenterX = self.view.boundsCenterX;
    self.restorePurchasesButton.frameMaxY = self.view.frameHeight - 20.0f;
    [self.view bringSubviewToFront:self.restorePurchasesButton];
}

#pragma mark -

- (void)reloadData
{
    [super reloadData];

    [self.collectionView reloadData];
}

- (void)shopReady
{
    [super shopReady];

    // Set up views needed for shop
    UILabel *tabMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    tabMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    tabMessageLabel.numberOfLines = 0;
    tabMessageLabel.textAlignment = NSTextAlignmentCenter;
    tabMessageLabel.font = [UIFont dq_galleryErrorMessageFont];
    tabMessageLabel.textColor = [UIColor dq_modalPrimaryTextColor];
    self.tabMessageLabel = tabMessageLabel;

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.flowLayout = flowLayout;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor dq_phoneBackgroundColor];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    collectionView.frameWidth = self.view.frameWidth;
    collectionView.frameHeight = self.view.frameHeight - kDQSegmentedControlDesiredHeight;
    collectionView.frameX = 0.0f;
    collectionView.frameY = kDQSegmentedControlDesiredHeight;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    self.collectionView = collectionView;

    DQSegmentedControl *segmentedControl = [[DQSegmentedControl alloc] initWithFrame:CGRectZero];
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.frameWidth = self.view.frameWidth;
    segmentedControl.frameHeight = kDQSegmentedControlDesiredHeight;
    segmentedControl.delegate = self;
    segmentedControl.dataSource = self;
    self.segmentedControl = segmentedControl;

    [self.collectionView registerClass:[DQPhoneShopColorPackCell class] forCellWithReuseIdentifier:DQShopViewControllerColorPackCell];
    [self.collectionView registerClass:[DQPhoneShopColorCell class] forCellWithReuseIdentifier:DQShopViewControllerColorCell];
    [self.collectionView registerClass:[DQPhoneShopCoinCell class] forCellWithReuseIdentifier:DQShopViewControllerCoinCell];
    [self.collectionView registerClass:[DQPhoneShopBrushCell class] forCellWithReuseIdentifier:DQShopViewControllerBrushCell];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DQPadShopViewControllerHeaderView];

    [self.view addSubview:collectionView];
    [self.view addSubview:segmentedControl];
}

#pragma mark - Sizes for collectionView cells

- (CGSize)sizeForItemInColorsTabAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;
    if (indexPath.section == 0)
    {
        // Color Packs
        size = CGSizeMake(self.collectionView.frameWidth, 100.0f);
    }
    else if (indexPath.section == 1)
    {
        // Colors
        size = CGSizeMake(60.0f, 70.0f);
    }
    return size;
}

- (CGSize)sizeForItemInCoinsTab
{
    return CGSizeMake(self.collectionView.frameWidth, 100.0f);
}

- (CGSize)sizeForItemInBrushesTab
{
    return CGSizeMake(self.collectionView.frameWidth, 100.0f);
}

#pragma mark - UICollectionViewDelegate Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    CGSize size = CGSizeZero;
    if (section == 0)
    {
        size = self.tabMessageLabel.frame.size;
    }
    return size;
}

#pragma mark - UICollectionViewDataSource Methods

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DQPadShopViewControllerHeaderView forIndexPath:indexPath];
        self.tabMessageLabel.frameCenterX = view.boundsCenterX;
        [view addSubview:self.tabMessageLabel];
    }
    return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    DQShopViewControllerTab tab = [self activeTab];
    if (tab == DQShopViewControllerTabColors)
    {
        cell = [self cellForItemInColorsTabAtIndexPath:indexPath withCollectionView:collectionView];
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        cell = [self cellForItemInCoinsTabAtIndexPath:indexPath withCollectionView:collectionView];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        cell = [self cellForItemInBrushesTabAtIndexPath:indexPath withCollectionView:collectionView];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger count = 0;
    DQShopViewControllerTab tab = [self activeTab];
    if (tab == DQShopViewControllerTabColors)
    {
        count = [self numberOfContentSectionsInColorsTab];
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        count = [self numberOfContentSectionsInCoinsTab];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        count = [self numberOfContentSectionsInBrushesTab];
    }
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = 0;
    DQShopViewControllerTab tab = [self activeTab];
    if (tab == DQShopViewControllerTabColors)
    {
        count = [self numberOfItemsInColorsTabSection:section];
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        count = [self numberOfItemsInCoinsTab];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        count = [self numberOfItemsInBrushesTab];
    }
    return count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    DQShopViewControllerTab tab = [self activeTab];
    if (tab == DQShopViewControllerTabColors)
    {
        insets = [self insetsForColorsTabSection:section];
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        insets = [self insetsForCoinsTab];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        insets = [self insetsForBrushesTab];
    }
    return insets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;
    NSNumber *tab = [self.shopTabs objectAtIndex:self.segmentedControl.selectedSegmentIndex];
    if ([tab integerValue] == DQShopViewControllerTabColors)
    {
        size = [self sizeForItemInColorsTabAtIndexPath:indexPath];
    }
    else if ([tab integerValue] == DQShopViewControllerTabCoins)
    {
        size = [self sizeForItemInCoinsTab];
    }
    else if ([tab integerValue] == DQShopViewControllerTabBrushes)
    {
        size = [self sizeForItemInBrushesTab];
    }
    return size;
}

#pragma mark - DQSegmentedControlDataSource methods

- (NSArray *)itemsForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    return self.tabNames;
}

- (NSUInteger)defaultSegmentIndexForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    DQShopViewControllerTab tab = self.startingTab;
    if (tab == DQShopViewControllerTabDefault)
    {
        tab = self.defaultTab;
    }
    return [self.shopTabs indexOfObject:@(tab)];
}

#pragma mark - DQSegmentedControlDelegate methods

- (void)segmentedControl:(DQSegmentedControl *)segmentedControl didSelectSegmentIndex:(NSUInteger)index
{
    self.restorePurchasesButton.hidden = index != 2;
    [self showTab:index withMessage:nil];
    [self reloadData];
}

@end
