//
//  DQPhoneShopViewController.m
//  DrawQuest
//
//  Created by David Mauro on 11/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneShopViewController.h"

// View Controllers
#import "DQSegmentedCollectionViewController.h"
#import "DQAbstractServiceController.h"

// Views
#import "DQPhoneCoinsLabel.h"
#import "DQPhoneShopColorPackCell.h"
#import "DQPhoneShopColorCell.h"
#import "DQPhoneShopCoinCell.h"
#import "DQPhoneShopBrushCell.h"
#import "DQSegmentedControl.h"
#import "DQAlertView.h"
#import "CVSBrushView.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQAnalyticsConstants.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQPhoneShopViewController () <DQSegmentedCollectionViewControllerDataSource, DQSegmentedControlDataSource, DQSegmentedControlDelegate>

@property (nonatomic, strong) DQSegmentedCollectionViewController *collectionViewController;
@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, weak) DQPhoneCoinsLabel *coinsLabel;
@property (nonatomic, weak) UIView *centeredView;
@property (nonatomic, weak) DQButton *restorePurchasesButton;

@end

@implementation DQPhoneShopViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    UIView *centeredView = [[UIView alloc] initWithFrame:CGRectZero];
    centeredView.layer.borderWidth = 1.0f;
    centeredView.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
    [self.view addSubview:centeredView];
    self.centeredView = centeredView;

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator setHidesWhenStopped:YES];
    [activityIndicator startAnimating];
    [self.centeredView addSubview:activityIndicator];
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
    [self.centeredView addSubview:restorePurchasesButton];
    self.restorePurchasesButton = restorePurchasesButton;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Temp hack for landscape shop
    self.centeredView.frameWidth = [[UIScreen mainScreen] bounds].size.width;
    self.centeredView.frameHeight = self.view.frameHeight;
    self.centeredView.frameCenterX = self.view.boundsCenterX;

    self.activityIndicator.center = self.centeredView.boundsCenter;
    self.collectionViewController.view.frame = self.centeredView.bounds;

    [self.restorePurchasesButton sizeToFit];
    self.restorePurchasesButton.frameWidth = self.centeredView.frameWidth - 40.0f;
    self.restorePurchasesButton.frameCenterX = self.centeredView.boundsCenterX;
    self.restorePurchasesButton.frameMaxY = self.centeredView.frameHeight - 20.0f;
    [self.centeredView bringSubviewToFront:self.restorePurchasesButton];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.collectionViewController = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)reloadData
{
    [super reloadData];

    [self.collectionViewController reloadData];
}

- (void)shopReady
{
    [super shopReady];

    // Set up Collection View Controller
    UILabel *tabMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    tabMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    tabMessageLabel.numberOfLines = 0;
    tabMessageLabel.textAlignment = NSTextAlignmentCenter;
    tabMessageLabel.font = [UIFont dq_galleryErrorMessageFont];
    tabMessageLabel.textColor = [UIColor dq_modalPrimaryTextColor];
    self.tabMessageLabel = tabMessageLabel;

    self.collectionViewController = [[DQSegmentedCollectionViewController alloc] initWithHeaderView:nil errorView:tabMessageLabel];
    self.collectionViewController.dataSource = self;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 0.0f;
    self.collectionViewController.collectionView.collectionViewLayout = layout;
    self.flowLayout = layout;

    [self.collectionViewController.collectionView registerClass:[DQPhoneShopColorPackCell class] forCellWithReuseIdentifier:DQShopViewControllerColorPackCell];
    [self.collectionViewController.collectionView registerClass:[DQPhoneShopColorCell class] forCellWithReuseIdentifier:DQShopViewControllerColorCell];
    [self.collectionViewController.collectionView registerClass:[DQPhoneShopCoinCell class] forCellWithReuseIdentifier:DQShopViewControllerCoinCell];
    [self.collectionViewController.collectionView registerClass:[DQPhoneShopBrushCell class] forCellWithReuseIdentifier:DQShopViewControllerBrushCell];

    [self addChildViewController:self.collectionViewController];
    [self.collectionViewController didMoveToParentViewController:self];
    [self.centeredView addSubview:self.collectionViewController.view];
}

- (void)showTab:(DQShopViewControllerTab)tab withMessage:(NSString *)message
{
    [super showTab:tab withMessage:message];

    // Reset the contentInsets
    self.collectionViewController.collectionView.contentInset = UIEdgeInsetsZero;

    if (message && [message length])
    {
        self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl | DQSegmentedCollectionViewControllerStatusDisplayErrorView;
    }
    else
    {
        self.collectionViewController.displayStatus = DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl;
    }
}

#pragma mark -
#pragma mark DQSegmentedCollectionViewControllerDataSource Methods

- (UIView *)segmentedControlForCollectionViewController:(DQSegmentedCollectionViewController *)viewController
{
    DQSegmentedControl *segmentedControl = [[DQSegmentedControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, kDQSegmentedControlDesiredHeight)];
    segmentedControl.delegate = self;
    segmentedControl.dataSource = self;
    self.segmentedControl = segmentedControl;
    segmentedControl.selectedSegmentIndex = self.startingTab;
    return segmentedControl;
}

#pragma mark -
// These all just forward to their segments' methods

- (NSInteger)numberOfContentSectionsInCollectionViewController:(DQSegmentedCollectionViewController *)viewController
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

- (NSInteger)collectionViewController:(DQSegmentedCollectionViewController *)viewController numberOfItemsInSection:(NSInteger)section
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

- (UICollectionViewCell *)collectionViewController:(DQSegmentedCollectionViewController *)viewController cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    DQShopViewControllerTab tab = [self activeTab];
    if (tab == DQShopViewControllerTabColors)
    {
        cell = [self cellForItemInColorsTabAtIndexPath:indexPath withCollectionView:viewController.collectionView];
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        cell = [self cellForItemInCoinsTabAtIndexPath:indexPath withCollectionView:viewController.collectionView];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        cell = [self cellForItemInBrushesTabAtIndexPath:indexPath withCollectionView:viewController.collectionView];
    }
    return cell;
}

- (UIEdgeInsets)collectionViewController:(DQSegmentedCollectionViewController *)viewController insetForSection:(NSInteger)section forLayout:(UICollectionViewFlowLayout *)layout
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

- (CGSize)collectionViewController:(DQSegmentedCollectionViewController *)viewController sizeForItemAtIndexPath:(NSIndexPath *)indexPath forLayout:(UICollectionViewFlowLayout *)layout
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
}

@end
