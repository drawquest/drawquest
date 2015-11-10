//
//  DQShopViewController.h
//  DrawQuest
//
//  Created by David Mauro on 7/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <StoreKit/SKProduct.h>

typedef NS_ENUM(NSUInteger, DQShopViewControllerTab) {
    DQShopViewControllerTabColors,
    DQShopViewControllerTabCoins,
    DQShopViewControllerTabBrushes,
    DQShopViewControllerTabDefault,
    DQShopViewControllerTabNotFound = NSNotFound
};

extern NSString *DQShopViewControllerColorPackCell;
extern NSString *DQShopViewControllerColorCell;
extern NSString *DQShopViewControllerCoinCell;
extern NSString *DQShopViewControllerBrushCell;

@class DQShopViewController, DQButton, DQSegmentedControl;

@protocol DQShopViewControllerDelegate <NSObject>

- (void)shopViewController:(DQShopViewController *)vc logViewForTab:(DQShopViewControllerTab)tab withParameters:(NSDictionary *)parameters;
- (void)shopViewController:(DQShopViewController *)vc requestShopDataWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)shopViewController:(DQShopViewController *)vc purchaseColorPackAtRow:(NSInteger)row completionBlock:(dispatch_block_t)completionBlock addCoinsBlock:(dispatch_block_t)addCoinsBlock;
- (void)shopViewController:(DQShopViewController *)vc purchaseColorAtIndex:(NSInteger)index completionBlock:(dispatch_block_t)completionBlock failureBlock:(dispatch_block_t)failureBlock addCoinsBlock:(dispatch_block_t)addCoinsBlock;
- (void)shopViewController:(DQShopViewController *)vc logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;
- (void)shopViewController:(DQShopViewController *)vc purchaseCoinProductAtRow:(NSInteger)row cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock;
- (void)shopViewController:(DQShopViewController *)vc purchaseBrushProductAtRow:(NSInteger)row cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock;

@end

@protocol DQShopViewControllerDataSource <NSObject>

- (NSNumber *)coinCountForShopViewController:(DQShopViewController *)vc;
- (NSArray *)shopTabsForShopViewController:(DQShopViewController *)vc;
- (NSDictionary *)shopViewController:(DQShopViewController *)vc infoForTab:(DQShopViewControllerTab)tab indexPath:(NSIndexPath *)indexPath;
- (SKProduct *)shopViewController:(DQShopViewController *)vc productForTab:(DQShopViewControllerTab)tab indexPath:(NSIndexPath *)indexPath;
- (NSInteger)shopViewController:(DQShopViewController *)vc numberOfItemsForTab:(DQShopViewControllerTab)tab section:(NSInteger)section;
- (NSString *)shopViewController:(DQShopViewController *)vc headerTitleForTab:(DQShopViewControllerTab)tab inSection:(NSInteger)section;

@end

@interface DQShopViewController : UIViewController

@property (nonatomic, strong) NSArray *shopTabs;
@property (nonatomic, strong) NSArray *tabNames;
@property (nonatomic, strong) UILabel *tabMessageLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) DQSegmentedControl *segmentedControl;
@property (nonatomic, weak, readonly) id<DQShopViewControllerDelegate> delegate;
@property (nonatomic, weak, readonly) id<DQShopViewControllerDataSource> dataSource;
@property (nonatomic, assign, readonly) DQShopViewControllerTab startingTab;
@property (nonatomic, assign, readonly) DQShopViewControllerTab defaultTab;
@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy) void (^restorePurchasesBlock)(DQShopViewController *vc, DQButton *restoreButton);

- (id)initWithTab:(DQShopViewControllerTab)inTab source:(NSString *)source delegate:(id<DQShopViewControllerDelegate>)delegate dataSource:(id<DQShopViewControllerDataSource>)dataSource;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithinTab:source:delegate:dataSource:);
- (id)init MSDesignatedInitializer(initWithTab:source:delegate:dataSource:);
- (DQShopViewControllerTab)activeTab;
- (void)showTab:(DQShopViewControllerTab)tab withMessage:(NSString *)message;

- (void)shopReady;
- (void)reloadData;

- (NSDictionary *)viewEventLoggingParameters;
- (void)addCoins;


#pragma mark -
#pragma mark Colors Segment Methods

- (NSInteger)numberOfContentSectionsInColorsTab;
- (NSInteger)numberOfItemsInColorsTabSection:(NSInteger)section;
- (UICollectionViewCell *)cellForItemInColorsTabAtIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView;
- (CGSize)sizeForItemInColorsTabAtIndexPath:(NSIndexPath *)indexPath;
- (UIEdgeInsets)insetsForColorsTabSection:(NSInteger)section;

#pragma mark -
#pragma mark Coins Segment Methods

- (NSInteger)numberOfContentSectionsInCoinsTab;
- (NSInteger)numberOfItemsInCoinsTab;
- (UICollectionViewCell *)cellForItemInCoinsTabAtIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView;
- (CGSize)sizeForItemInCoinsTab;
- (UIEdgeInsets)insetsForCoinsTab;

#pragma mark -
#pragma mark Brushes Segment Methods

- (NSInteger)numberOfContentSectionsInBrushesTab;
- (NSInteger)numberOfItemsInBrushesTab;
- (UICollectionViewCell *)cellForItemInBrushesTabAtIndexPath:(NSIndexPath *)indexPath withCollectionView:(UICollectionView *)collectionView;
- (CGSize)sizeForItemInBrushesTab;
- (UIEdgeInsets)insetsForBrushesTab;

@end
