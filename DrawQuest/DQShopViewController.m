//
//  DQShopViewController.m
//  DrawQuest
//
//  Created by David Mauro on 7/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <StoreKit/StoreKit.h>

// Controllers
#import "DQAbstractServiceController.h"
#import "DQNotifications.h"

// View Controllers
#import "DQShopViewController.h"
#import "DQPadShopViewController.h"
#import "DQPhoneShopViewController.h"

// Views
#import "DQAlertView.h"
#import "DQSegmentedControl.h"
#import "DQPhoneCoinsLabel.h"
#import "DQPhoneShopColorPackCell.h"
#import "DQPhoneShopColorCell.h"
#import "DQPhoneShopCoinCell.h"
#import "DQPhoneShopBrushCell.h"
#import "CVSBrushView.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"
#import "UIColor+DQAdditions.h"

NSString *DQShopViewControllerColorPackCell = @"colorPackCell";
NSString *DQShopViewControllerColorCell = @"colorCell";
NSString *DQShopViewControllerCoinCell = @"coinCell";
NSString *DQShopViewControllerBrushCell = @"brushCell";

@interface DQShopViewController ()

@property (nonatomic, weak) DQPhoneCoinsLabel *coinsLabel;
@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, assign, readwrite) DQShopViewControllerTab startingTab;
@property (nonatomic, assign, readwrite) DQShopViewControllerTab defaultTab;
@property (nonatomic, copy) dispatch_block_t failWithErrorBlock;

@end

@implementation DQShopViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationCoinBalanceUpdatedNotication object:nil];
}

- (id)initWithTab:(DQShopViewControllerTab)inTab source:(NSString *)source delegate:(id<DQShopViewControllerDelegate>)delegate dataSource:(id<DQShopViewControllerDataSource>)dataSource
{
    if ([self class] == [DQShopViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadShopViewController alloc] initWithTab:inTab source:source delegate:delegate dataSource:dataSource];
        }
        else
        {
            self = [[DQPhoneShopViewController alloc] initWithTab:inTab source:source delegate:delegate dataSource:dataSource];
        }
    }
    else
    {
        self = [super initWithNibName:nil bundle:nil];
        if (self)
        {
            _delegate = delegate;
            _dataSource = dataSource;
            _source = [source copy];
            _startingTab = inTab;

            DQPhoneCoinsLabel *coinsLabel = [[DQPhoneCoinsLabel alloc] initWithFrame:CGRectZero];
            coinsLabel.textColor = [UIColor whiteColor];
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:coinsLabel];
            self.coinsLabel = coinsLabel;

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coinBalanceUpdated:) name:DQApplicationCoinBalanceUpdatedNotication object:nil];
        }
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.delegate shopViewController:self logEvent:DQAnalyticsEventViewShop withParameters:[self viewEventLoggingParameters]];

    if (self.failWithErrorBlock)
    {
        self.failWithErrorBlock();
        self.failWithErrorBlock = nil;
    }
    self.viewHasAppeared = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ( ! self.viewHasAppeared)
    {
        [self requestShopData];
    }
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.viewHasAppeared = NO;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Private

- (void)requestShopData
{
    __weak typeof(self) weakSelf = self;
    [_delegate shopViewController:self requestShopDataWithCompletionBlock:^{
        // Decide which tab we will start on
        NSArray *shopTabs = [self.dataSource shopTabsForShopViewController:self];
        self.defaultTab = [shopTabs indexOfObjectPassingTest:^BOOL(NSDictionary *tab, NSUInteger idx, BOOL *stop) {
            return tab.dq_shopTabIsDefault;
        }];
        self.startingTab = (self.startingTab == DQShopViewControllerTabDefault) ? self.defaultTab : self.startingTab;

        [weakSelf shopReady];
    } failureBlock:^(NSError *error) {
        // Show an alert when the view has appeared
        dispatch_block_t failWithErrorBlock = ^{
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Shop Error", @"Shop related error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
            [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        };
        if (weakSelf.viewHasAppeared)
        {
            failWithErrorBlock();
        }
        else
        {
            weakSelf.failWithErrorBlock = failWithErrorBlock;
        }

        [weakSelf shopFailed];
    }];
}

#pragma mark -
#pragma mark Public

- (DQShopViewControllerTab)activeTab
{
    DQShopViewControllerTab activeTab = DQShopViewControllerTabNotFound;
    if (self.segmentedControl && self.segmentedControl.selectedSegmentIndex > -1 && self.segmentedControl.selectedSegmentIndex < [self.shopTabs count])
    {
        activeTab = [[self.shopTabs objectAtIndex:self.segmentedControl.selectedSegmentIndex] integerValue];
    }
    else
    {
        activeTab = self.startingTab;
    }
    return activeTab;
}

- (void)addCoins
{
    [self showTab:DQShopViewControllerTabCoins withMessage:DQLocalizedString(@"You don't have enough coins, why not buy some first?", @"The user doesn't have enough coins to purchase what they tried to purchase, prompt them to purchase some coins first")];
}

- (NSDictionary *)viewEventLoggingParameters
{
    return self.source ? @{@"source": self.source} : nil;
}

- (void)reloadData
{
    // Subclasses should reload the data of their collectionView's
}

#pragma mark - Actions

- (void)coinBalanceUpdated:(NSNotification *)notification
{
    NSNumber *coinCount = [self.dataSource coinCountForShopViewController:self];
    self.coinsLabel.text = [coinCount stringValue];
    [self.coinsLabel sizeToFit];
}

- (void)showTab:(DQShopViewControllerTab)tab withMessage:(NSString *)message
{
    self.segmentedControl.selectedSegmentIndex = tab;
    if (message && [message length])
    {
        // Vertical white space buffer by manipulating the text
        message = [NSString stringWithFormat:@"%@%@%@", @"\n", message, @"\n "];
    }
    self.tabMessageLabel.text = message;
    [self.tabMessageLabel sizeToFit];
}

- (void)shopReady
{
    [self.activityIndicator stopAnimating];

    // Set up tabs for data source
    NSMutableArray *shopTabs = [[NSMutableArray alloc] init];
    for (NSDictionary *tab in [self.dataSource shopTabsForShopViewController:self])
    {
        if ([tab.dq_shopTabName isEqual:DQAPIValueShopColorsTab])
        {
            [shopTabs addObject:@(DQShopViewControllerTabColors)];
        }
        else if ([tab.dq_shopTabName isEqual:DQAPIValueShopCoinsTab])
        {
            [shopTabs addObject:@(DQShopViewControllerTabCoins)];
        }
        else if ([tab.dq_shopTabName isEqual:DQAPIValueShopBrushesTab])
        {
            [shopTabs addObject:@(DQShopViewControllerTabBrushes)];
        }
    }
    self.shopTabs = [NSArray arrayWithArray:shopTabs];

    NSMutableArray *tabNames = [[NSMutableArray alloc] init];
    for (NSNumber *tab in self.shopTabs)
    {
        if ([tab integerValue] == DQShopViewControllerTabColors)
        {
            [tabNames addObject:DQLocalizedString(@"Colors", @"A collection of colors that can be used to draw in the editor")];
        }
        else if ([tab integerValue] == DQShopViewControllerTabCoins)
        {
            [tabNames addObject:DQLocalizedString(@"Coins", @"Plural form of our DrawQuest specific currency of 'Coin'")];
        }
        else if ([tab integerValue] == DQShopViewControllerTabBrushes)
        {
            [tabNames addObject:DQLocalizedString(@"Brushes", @"A collection of tools that can be used to draw in the editor")];
        }
    }
    self.tabNames = tabNames;
}

- (void)shopFailed
{
    [self.activityIndicator stopAnimating];
}

#pragma mark -
#pragma mark Colors Segment Methods

- (NSInteger)numberOfContentSectionsInColorsTab
{
    return 2;
}

- (NSInteger)numberOfItemsInColorsTabSection:(NSInteger)section
{
    return [self.dataSource shopViewController:self numberOfItemsForTab:DQShopViewControllerTabColors section:section];
}

- (UICollectionViewCell *)cellForItemInColorsTabAtIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView
{
    UICollectionViewCell *cell = nil;
    if (indexPath.section == 0)
    {
        // Color Packs
        DQPhoneShopColorPackCell *colorPackCell = [collectionView dequeueReusableCellWithReuseIdentifier:DQShopViewControllerColorPackCell forIndexPath:indexPath];
        NSDictionary *currentColorPackInfo = [self.dataSource shopViewController:self infoForTab:DQShopViewControllerTabColors indexPath:indexPath];
        colorPackCell.titleLabel.text = currentColorPackInfo.dq_colorPackName;
        colorPackCell.saleLabel.text = currentColorPackInfo.dq_colorPackSaleText;
        [colorPackCell.purchaseButton setTitle:[currentColorPackInfo.dq_colorPackCost stringValue] forState:UIControlStateNormal];
        colorPackCell.isPurchased = currentColorPackInfo.dq_colorPackIsPurchased;
        [colorPackCell setColors:currentColorPackInfo.dq_colorPackColors];
        __weak typeof(self) weakSelf = self;
        __weak typeof(colorPackCell) weakCell = colorPackCell;
        colorPackCell.purchaseButton.tappedBlock = ^(DQButton *button) {
            if (!currentColorPackInfo)
            {
                // hack to disable purchasing items that we didn't get info for
                return;
            }
            [button disableWithActivityIndicator];
            [weakSelf.delegate shopViewController:self logEvent:DQAnalyticsEventPurchaseColorPack withParameters:[self viewEventLoggingParameters]];
            [weakSelf.delegate shopViewController:self purchaseColorPackAtRow:indexPath.item completionBlock:^{
                [button enableAndRemoveActivityIndicator];
                [weakSelf reloadData];
            } addCoinsBlock:^{
                weakCell.isPurchased = NO;
                [weakSelf addCoins];
            }];
        };

        cell = colorPackCell;
    }
    else if (indexPath.section == 1)
    {
        // Colors
        DQPhoneShopColorCell *colorCell = [collectionView dequeueReusableCellWithReuseIdentifier:DQShopViewControllerColorCell forIndexPath:indexPath];
        NSDictionary *currentColorInfo = [self.dataSource shopViewController:self infoForTab:DQShopViewControllerTabColors indexPath:indexPath];
        [colorCell setColor:[UIColor dq_colorWithRGBArray:currentColorInfo.dq_colorRGBInfo]];
        colorCell.isPurchased = currentColorInfo.dq_colorIsPurchased;
        colorCell.isNew = currentColorInfo.dq_colorIsNew;
        if ( ! currentColorInfo.dq_colorIsPurchased)
        {
            __weak typeof(self) weakSelf = self;
            colorCell.cellTappedBlock = ^(DQPhoneShopColorCell *cell) {
                DQAlertView *purchaseConfirmation = [[DQAlertView alloc] initWithTitle:currentColorInfo.dq_colorName message:[NSString stringWithFormat:DQLocalizedString(@"Cost: %@ coins", @"Cost of shop items in coin currency"), currentColorInfo.dq_colorCost] delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Purchase", @"Coin based shop purchase alert confirmation button title"), nil];
                purchaseConfirmation.backgroundColor = [UIColor redColor];
                purchaseConfirmation.dq_completionBlock = ^(DQAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex != [alertView cancelButtonIndex])
                    {
                        cell.isPurchased = YES;
                        [self.delegate shopViewController:self logEvent:DQAnalyticsEventPurchaseColor withParameters:[self viewEventLoggingParameters]];
                        [self.delegate shopViewController:self purchaseColorAtIndex:indexPath.item completionBlock:nil failureBlock:^{
                            // If the purchase fails, revert the cell to unpurchased
                            cell.isPurchased = NO;
                        } addCoinsBlock:^{
                            cell.isPurchased = NO;
                            [weakSelf addCoins];
                        }];
                    }
                };
                [purchaseConfirmation show];
            };
        }

        cell = colorCell;
    }
    return cell;
}

- (CGSize)sizeForItemInColorsTabAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;
    if (indexPath.section == 0)
    {
        // Color Packs
        size = CGSizeMake(320.0f, 100.0f);
    }
    else if (indexPath.section == 1)
    {
        // Colors
        size = CGSizeMake(60.0f, 70.0f);
    }
    return size;
}

- (UIEdgeInsets)insetsForColorsTabSection:(NSInteger)section
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (section == 1)
    {
        // Colors
        insets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 10.0f);
    }
    return insets;
}

#pragma mark -
#pragma mark Coins Segment Methods

- (NSInteger)numberOfContentSectionsInCoinsTab
{
    return 1;
}

- (NSInteger)numberOfItemsInCoinsTab
{
    return [self.dataSource shopViewController:self numberOfItemsForTab:DQShopViewControllerTabCoins section:0];
}

- (UICollectionViewCell *)cellForItemInCoinsTabAtIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView
{
    NSDictionary *coinInfo = [self.dataSource shopViewController:self infoForTab:DQShopViewControllerTabCoins indexPath:indexPath];
    SKProduct *product = [self.dataSource shopViewController:self productForTab:DQShopViewControllerTabCoins indexPath:indexPath];

    DQPhoneShopCoinCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DQShopViewControllerCoinCell forIndexPath:indexPath];
    [cell setAmount:coinInfo.dq_coinProductAmount];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
    NSString *priceString = [formatter stringFromNumber:product.price];
    [cell.purchaseButton setTitle:priceString forState:UIControlStateNormal];

    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.purchaseButton.tappedBlock = ^(DQButton *button) {
        if (!coinInfo)
        {
            // hack to disable purchasing items that we didn't get info for
            return;
        }
        [button disableWithActivityIndicator];

        [weakSelf.delegate shopViewController:self purchaseCoinProductAtRow:indexPath.row cancellationBlock:^{
            [button enableAndRemoveActivityIndicator];
        } completionBlock:^{
            [button enableAndRemoveActivityIndicator];
            [weakCell flashSuccessView];
        } failureBlock:^(NSError *error) {
            [button enableAndRemoveActivityIndicator];
            DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Purchase Error", @"Store purchase failure error title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alertView show];
        }];
    };

    return cell;
}

- (CGSize)sizeForItemInCoinsTab
{
    return CGSizeMake(320.0f, 100.0f);
}

- (UIEdgeInsets)insetsForCoinsTab
{
    return UIEdgeInsetsZero;
}

#pragma mark -
#pragma mark Brushes Segment Methods

- (NSInteger)numberOfContentSectionsInBrushesTab
{
    return 1;
}

- (NSInteger)numberOfItemsInBrushesTab
{
    return [self.dataSource shopViewController:self numberOfItemsForTab:DQShopViewControllerTabBrushes section:0];
}

- (UICollectionViewCell *)cellForItemInBrushesTabAtIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView;
{
    NSDictionary *brushInfo = [self.dataSource shopViewController:self infoForTab:DQShopViewControllerTabBrushes indexPath:indexPath];
    SKProduct *product = [self.dataSource shopViewController:self productForTab:DQShopViewControllerTabBrushes indexPath:indexPath];

    DQPhoneShopBrushCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DQShopViewControllerBrushCell forIndexPath:indexPath];
    cell.titleLabel.text = brushInfo.dq_brushPhoneName;
    cell.descriptionLabel.text = brushInfo.dq_brushDescription;
    [cell setIsPurchased:brushInfo.dq_brushIsPurchased];

    // Find brush type from brushInfo
    CVSBrushType brushType = CVSBrushTypeForCanonicalName(brushInfo.dq_brushCanonicalName);
    CVSBrushView *brushView = [[CVSBrushView alloc] initWithBrushType:brushType activeColor:[UIColor dq_colorWithRGBArray:brushInfo.dq_brushColor] hasSmile:YES];
    [cell setBrushView:brushView];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
    NSString *priceString = [formatter stringFromNumber:product.price];
    [cell.purchaseButton setTitle:priceString forState:UIControlStateNormal];

    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.purchaseButton.tappedBlock = ^(DQButton *button) {
        if (!brushInfo)
        {
            // hack to disable purchasing items that we didn't get info for
            return;
        }
        [button disableWithActivityIndicator];

        [weakSelf.delegate shopViewController:self purchaseBrushProductAtRow:indexPath.row cancellationBlock:^{
            [button enableAndRemoveActivityIndicator];
        } completionBlock:^{
            [button enableAndRemoveActivityIndicator];
            [weakCell setIsPurchased:YES];
        } failureBlock:^(NSError *error) {
            [button enableAndRemoveActivityIndicator];
            DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Purchase Error", @"Store purchase failure error title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alertView show];
        }];
    };

    return cell;
}

- (CGSize)sizeForItemInBrushesTab
{
    return CGSizeMake(320.0f, 100.0f);
}

- (UIEdgeInsets)insetsForBrushesTab
{
    return UIEdgeInsetsZero;
}

@end
