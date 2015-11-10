//
//  DQShopController.m
//  DrawQuest
//
//  Created by David Mauro on 8/12/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQShopController.h"
#import "DQPaymentObserver.h"
#import "DQAnalyticsConstants.h"
#import "DQPrivateServiceController.h"
#import "DQAlertView.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQPapertrailLogger.h"

static NSString *const DQShopControllerIAPItems = @"DQShopControllerIAPItems";

@interface DQShopController () <SKProductsRequestDelegate>

@property (nonatomic, strong) DQAccountController *accountController;
@property (nonatomic, strong) NSString *colorPacksHeader;
@property (nonatomic, strong) NSString *colorsHeader;
@property (nonatomic, strong) NSArray *coinProducts;
@property (nonatomic, strong) NSArray *coinInfo;
@property (nonatomic, strong) NSArray *brushProducts;
@property (nonatomic, strong) NSArray *brushInfo;
@property (nonatomic, strong) NSArray *colorPacks;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *shopTabs;
@property (nonatomic, strong) NSMutableDictionary *purchaseCancellationBlocks;
@property (nonatomic, strong) NSMutableDictionary *purchaseCompletionBlocks;
@property (nonatomic, strong) NSMutableDictionary *purchaseFailureBlocks;
@property (nonatomic, strong) SKProductsRequest *coinProductsRequest;
@property (nonatomic, strong) SKProductsRequest *brushProductsRequest;
@property (nonatomic, copy) dispatch_block_t shopLoadedBlock;
@property (nonatomic, copy) void(^shopFailedBlock)(NSError *error);

@end

@implementation DQShopController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPaymentObserverDidCancelTransaction object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPaymentObserverDidUpdateTransaction object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQPaymentObserverFailedToUpdateTransaction object:nil];
    self.coinProductsRequest.delegate = nil;
    self.brushProductsRequest.delegate = nil;
    [self.coinProductsRequest cancel];
    [self.brushProductsRequest cancel];
}

- (id)initWithDelegate:(id<DQShopControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _purchaseCancellationBlocks = [[NSMutableDictionary alloc] init];
        _purchaseCompletionBlocks = [[NSMutableDictionary alloc] init];
        _purchaseFailureBlocks = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionCancelled:) name:DQPaymentObserverDidCancelTransaction object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionUpdated:) name:DQPaymentObserverDidUpdateTransaction object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionFailed:) name:DQPaymentObserverFailedToUpdateTransaction object:nil];
    }
    return self;
}

- (id<DQShopControllerDelegate>)delegate
{
    return (id<DQShopControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQShopControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

#pragma mark - Actions

- (void)transactionCancelled:(NSNotification *)notification
{
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:DQPaymentObserverTransactionKeyString];
    [self callCancellationBlockForTransaction:transaction];
}

- (void)transactionUpdated:(NSNotification *)notification
{
    NSDictionary *responseDictionary = [notification.userInfo objectForKey:DQPaymentObserverResponseDictionaryKeyString];
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:DQPaymentObserverTransactionKeyString];
    NSString *productIdentifier = transaction.payment.productIdentifier;
    
    // Check if they purchased coins
    for (SKProduct *product in self.coinProducts)
    {
        if ([product.productIdentifier isEqual:productIdentifier])
        {
            NSNumber *coinBalance = responseDictionary.dq_coinBalance;
            [self logEvent:DQAnalyticsEventPurchaseCoins withParameters:nil];
            [self.delegate shopController:self updateCoinBalanceForLoggedInUser:coinBalance];
            break;
        }
    }
    
    // Check if they purchased a brush
    for (NSDictionary *brush in self.brushInfo)
    {
        if ([brush.dq_brushIAPIdentifier isEqual:productIdentifier])
        {
            self.brushInfo = responseDictionary.dq_shopBrushes;
            [self.delegate shopController:self addOwnedBrush:brush];
            [self logEvent:DQAnalyticsEventPurchaseBrush withParameters:nil];
            break;
        }
    }
    
    [self callCompletionBlockForTransaction:[notification.userInfo objectForKey:DQPaymentObserverTransactionKeyString]];
}

- (void)transactionFailed:(NSNotification *)notification
{
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:DQPaymentObserverTransactionKeyString];
    BOOL willRetry = [notification.userInfo boolForKey:DQPaymentObserverWillRetryKeyString];
    NSError *error = [notification.userInfo objectForKey:DQPaymentObserverErrorKeyString];
    [DQPapertrailLogger component:@"shop-controller" category:@"transaction-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
        return @{@"product-identifier": transaction.payment.productIdentifier ?: [NSNull null]};
    }];

    [self callFailureBlockForTransaction:transaction withError:error willRetry:willRetry];
}

#pragma mark - Transaction Helpers

- (void)callCancellationBlockForTransaction:(SKPaymentTransaction *)transaction
{
    SKPayment *payment = transaction.payment;
    NSString *identifier = payment.productIdentifier;
    dispatch_block_t cancellationBlock = [self.purchaseCancellationBlocks objectForKey:identifier];
    if (cancellationBlock)
    {
        cancellationBlock();
        [self.purchaseCancellationBlocks removeObjectForKey:identifier];
        [self.purchaseCompletionBlocks removeObjectForKey:identifier];
        [self.purchaseFailureBlocks removeObjectForKey:identifier];
    }
}

- (void)callCompletionBlockForTransaction:(SKPaymentTransaction *)transaction
{
    SKPayment *payment = transaction.payment;
    NSString *identifier = payment.productIdentifier;
    dispatch_block_t completionBlock = [self.purchaseCompletionBlocks objectForKey:identifier];
    if (completionBlock)
    {
        completionBlock();
        [self.purchaseCancellationBlocks removeObjectForKey:identifier];
        [self.purchaseCompletionBlocks removeObjectForKey:identifier];
        [self.purchaseFailureBlocks removeObjectForKey:identifier];
    }
    else
    {
        [DQPapertrailLogger component:@"shop-controller" category:@"transaction-missing-completion-block" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"product-identifier": identifier ?: [NSNull null]};
        }];
    }
}

- (void)callFailureBlockForTransaction:(SKPaymentTransaction *)transaction withError:(NSError *)error willRetry:(BOOL)willRetry
{
    SKPayment *payment = transaction.payment;
    NSString *identifier = payment.productIdentifier;
    void (^failureBlock)(NSError *) = [self.purchaseFailureBlocks objectForKey:identifier];
    if (failureBlock)
    {
        failureBlock(error);
        if ( ! willRetry)
        {
            // Only delete these blocks if they definitely won't get called later
            [self.purchaseCancellationBlocks removeObjectForKey:identifier];
            [self.purchaseCompletionBlocks removeObjectForKey:identifier];
            [self.purchaseFailureBlocks removeObjectForKey:identifier];
        }
    }
    else
    {
        [DQPapertrailLogger component:@"shop-controller" category:@"transaction-missing-failure-block" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"product-identifier": identifier ?: [NSNull null]};
        }];
    }
}

- (void)purchaseProduct:(SKProduct *)product cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    if ([SKPaymentQueue canMakePayments])
    {
        NSString *productIdentifier = product.productIdentifier;
        NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
        BOOL hasQueuedTransactions = [transactions count] > 0;
        BOOL purchaseIsAlreadyEnqueued = NSNotFound != [transactions indexOfObjectPassingTest:^BOOL(SKPaymentTransaction *transaction, NSUInteger idx, BOOL *stop) {
            return [transaction.payment.productIdentifier isEqualToString:productIdentifier];
        }];

        [self.purchaseCancellationBlocks setObject:[cancellationBlock copy] forKey:productIdentifier];
        [self.purchaseCompletionBlocks setObject:[completionBlock copy] forKey:productIdentifier];
        [self.purchaseFailureBlocks setObject:[failureBlock copy] forKey:productIdentifier];
        
        if (purchaseIsAlreadyEnqueued || hasQueuedTransactions)
        {
            if (self.runPendingTransactionsBlock)
            {
                self.runPendingTransactionsBlock();
            }
        }
        
        if ( ! purchaseIsAlreadyEnqueued)
        {
            [DQPapertrailLogger component:@"shop-controller" category:@"add-payment" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"product-identifier": productIdentifier ?: [NSNull null],
                         @"has-queued-transactions": @(hasQueuedTransactions)};
            }];
            SKPayment *payment = [SKPayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }
    else
    {
        DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"In-App Purchase Failed", @"In-App Purchase failure error alert tile") message:DQLocalizedString(@"In-App Purchases have been disabled on this device.", @"In-App Purchases disabled on device error alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
        [alert show];
        if (failureBlock)
        {
            failureBlock(nil);
        }
    }
}

- (void)shopViewController:(DQShopViewController *)vc purchaseCoinProductAtRow:(NSInteger)row cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock;
{
    SKProduct *product = [self.coinProducts objectAtIndex:row];
    [self purchaseProduct:product cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)shopViewController:(DQShopViewController *)vc purchaseBrushProductAtRow:(NSInteger)row cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    SKProduct *product = [self.brushProducts objectAtIndex:row];
    [self purchaseProduct:product cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

#pragma mark - DQShopViewControllerDelegate Methods

- (void)shopViewController:(DQShopViewController *)vc logViewForTab:(DQShopViewControllerTab)tab withParameters:(NSDictionary *)parameters
{
    if (tab == DQShopViewControllerTabColors)
    {
        [self logEvent:DQAnalyticsEventViewColorPurchaseDialog withParameters:parameters];
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        [self logEvent:DQAnalyticsEventViewCoinPurchaseDialog withParameters:parameters];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        [self logEvent:DQAnalyticsEventViewBrushPurchaseDialog withParameters:parameters];
    }
}

- (void)shopViewController:(DQShopViewController *)vc requestShopDataWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    self.shopLoadedBlock = completionBlock;
    self.shopFailedBlock = failureBlock;
    
    __weak typeof(self) weakSelf = self;
    [self.privateServiceController requestShopItemsWithCompletionBlock:^(DQHTTPRequest *request, id JSONObject) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        
        NSNumber *coinBalance = responseDictionary.dq_coinBalance;
        [weakSelf.delegate shopController:weakSelf updateCoinBalanceForLoggedInUser:coinBalance];
        
        NSDictionary *coinProductsInfo = responseDictionary.dq_coinProductsInfo;
        NSDictionary *brushProductsInfo = responseDictionary.dq_brushProductsInfo;
        
        NSArray *coinProductIdentifiers = [coinProductsInfo sortedKeysByNumericValues];
        NSArray *brushProductIdentifiers = [brushProductsInfo allKeys];

        if (weakSelf.coinProductsRequest)
        {
            weakSelf.coinProductsRequest.delegate = nil;
            [weakSelf.coinProductsRequest cancel];
            weakSelf.coinProductsRequest = nil;
        }
        if (weakSelf.brushProductsRequest)
        {
            weakSelf.brushProductsRequest.delegate = nil;
            [weakSelf.brushProductsRequest cancel];
            weakSelf.brushProductsRequest = nil;
        }

        [DQPapertrailLogger component:@"shop-controller" category:@"coin-products-request" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"product-identifiers": coinProductIdentifiers ?: [NSNull null]};
        }];
        weakSelf.coinProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:coinProductIdentifiers]];
        weakSelf.coinProductsRequest.delegate = weakSelf;
        [weakSelf.coinProductsRequest start];
        
        [DQPapertrailLogger component:@"shop-controller" category:@"brush-products-request" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"product-identifiers": brushProductIdentifiers ?: [NSNull null]};
        }];
        weakSelf.brushProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:brushProductIdentifiers]];
        weakSelf.brushProductsRequest.delegate = weakSelf;
        [weakSelf.brushProductsRequest start];
        
        weakSelf.colorPacks = responseDictionary.dq_shopColorPacks;
        weakSelf.colors = responseDictionary.dq_shopColors;
        
        weakSelf.coinInfo = [coinProductsInfo sortedArrayUsingNumericKeyValues];
        
        weakSelf.shopTabs = responseDictionary.dq_shopTabs;
        weakSelf.colorPacksHeader = responseDictionary.dq_shopColorPacksHeader;
        weakSelf.colorsHeader = responseDictionary.dq_shopColorsHeader;
        
        // We can't trust the brush ownership information from the server
        // so we have to check with our accountController's ownedBrushes
        NSArray *localBrushes = [self.delegate ownedBrushesForShopController:self];
        NSArray *serverBrushes = responseDictionary.dq_shopBrushes;
        NSMutableArray *newLocalBrushes = [serverBrushes mutableCopy];
        [serverBrushes enumerateObjectsUsingBlock:^(NSDictionary *serverBrush, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary *mutableServerBrush = [serverBrush mutableCopy];
            BOOL isBrushOwnedOnServer = mutableServerBrush.dq_brushIsPurchased;
            
            if ( ! isBrushOwnedOnServer)
            {
                for (NSDictionary *locallyOwnedBrush in localBrushes)
                {
                    if ([locallyOwnedBrush.dq_brushIAPIdentifier isEqual:serverBrush.dq_brushIAPIdentifier])
                    {
                        isBrushOwnedOnServer = YES;
                        break;
                    }
                }
                [mutableServerBrush setObject:@(isBrushOwnedOnServer) forKey:DQAPIKeyStringBrushIsPurchased];
                [newLocalBrushes replaceObjectAtIndex:idx withObject:mutableServerBrush];
            }
        }];
        self.brushInfo = newLocalBrushes;
    } failureBlock:^(DQHTTPRequest *request) {
        failureBlock(request.error);
    }];
}

- (void)shopViewController:(DQShopViewController *)vc purchaseColorPackAtRow:(NSInteger)row completionBlock:(dispatch_block_t)completionBlock addCoinsBlock:(dispatch_block_t)addCoinsBlock
{
    NSDictionary *colorPack = [self.colorPacks objectAtIndex:row];
    NSNumber *colorPackCost = colorPack.dq_colorPackCost;
    NSNumber *coinCount = self.loggedInAccount.coinCount;
    
    if ([colorPackCost integerValue] > [coinCount integerValue])
    {
        if (addCoinsBlock)
        {
            addCoinsBlock();
        }
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [self.privateServiceController requestPurchaseColorPackID:colorPack.dq_colorPackID completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            weakSelf.colorPacks = responseDictionary.dq_shopColorPacks;
            weakSelf.colors = responseDictionary.dq_shopColors;
            NSArray *userColors = responseDictionary.dq_userColors;
            NSNumber *coinBalance = responseDictionary.dq_coinBalance;
            [weakSelf.delegate shopController:weakSelf updateCoinBalanceForLoggedInUser:coinBalance];
            [weakSelf.delegate shopController:weakSelf updateColorsForLoggedInUser:userColors];
            if (completionBlock)
            {
                completionBlock();
            }
        } failureBlock:^(DQHTTPRequest *request) {
            NSString *errorReason = request.error.localizedFailureReason;
            NSArray *errors = [request.error.userInfo objectForKey:DQAPIErrorDictionaryKey];
            if (errors.count) {
                errorReason = [errors firstObject];
            }
            
            NSString *errorTitle = DQLocalizedString(@"Unable to Purchase", @"Unable to purchase shop item error alert title");
            NSString *errorString = [NSString stringWithFormat:DQLocalizedString(@"Unable to purchase due to error: %@", @"Unable to purchase shop item error alert message prefix"), errorReason, nil];
            
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:errorTitle message:errorString delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
            
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
}

- (void)shopViewController:(DQShopViewController *)vc purchaseColorAtIndex:(NSInteger)index completionBlock:(dispatch_block_t)completionBlock failureBlock:(dispatch_block_t)failureBlock addCoinsBlock:(dispatch_block_t)addCoinsBlock
{
    NSDictionary *color = [self.colors objectAtIndex:index];
    NSNumber *colorCost = color.dq_colorPackCost;
    NSNumber *coinCount = self.loggedInAccount.coinCount;
    
    if ([colorCost integerValue] > [coinCount integerValue])
    {
        if (addCoinsBlock)
        {
            addCoinsBlock();
        }
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [self.privateServiceController requestPurchaseColorID:color.dq_colorID completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            weakSelf.colorPacks = responseDictionary.dq_shopColorPacks;
            weakSelf.colors = responseDictionary.dq_shopColors;
            NSArray *userColors = responseDictionary.dq_userColors;
            NSNumber *coinBalance = responseDictionary.dq_coinBalance;
            [weakSelf.delegate shopController:weakSelf updateCoinBalanceForLoggedInUser:coinBalance];
            [weakSelf.delegate shopController:weakSelf updateColorsForLoggedInUser:userColors];
            if (completionBlock)
            {
                completionBlock();
            }
        } failureBlock:^(DQHTTPRequest *request) {
            NSString *errorReason = request.error.localizedFailureReason;
            NSArray *errors = [request.error.userInfo objectForKey:DQAPIErrorDictionaryKey];
            if (errors.count) {
                errorReason = [errors firstObject];
            }
            
            NSString *errorTitle = DQLocalizedString(@"Unable to Purchase", @"Unable to purchase shop item error alert title");
            NSString *errorString = [NSString stringWithFormat:DQLocalizedString(@"Unable to purchase due to error: %@", @"Unable to purchase shop item error alert message prefix"), errorReason, nil];
            
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:errorTitle message:errorString delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
            
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
}

- (void)shopViewController:(DQShopViewController *)vc logEvent:(NSString *)event withParameters:(NSDictionary *)parameters
{
    [self logEvent:event withParameters:parameters];
}

#pragma mark - DQShopViewControllerDataSource Methods

- (NSString *)shopViewController:(DQShopViewController *)vc headerTitleForTab:(DQShopViewControllerTab)tab inSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    if (tab == DQShopViewControllerTabColors)
    {
        if (section == 0)
        {
            // Color Packs
            headerTitle = self.colorPacksHeader;
        }
        else if (section == 1)
        {
            // Colors
            headerTitle = self.colorsHeader;
        }
    }
    return headerTitle;
}

- (NSNumber *)coinCountForShopViewController:(DQShopViewController *)vc
{
    return self.loggedInAccount.coinCount;
}

- (NSArray *)shopTabsForShopViewController:(DQShopViewController *)vc
{
    return self.shopTabs;
}

- (NSInteger)shopViewController:(DQShopViewController *)vc numberOfItemsForTab:(DQShopViewControllerTab)tab section:(NSInteger)section
{
    NSInteger itemCount = 0;
    if (tab == DQShopViewControllerTabColors)
    {
        if (section == 0)
        {
            // Color Packs
            itemCount = [self.colorPacks count];
        }
        else if (section == 1)
        {
            // Colors
            itemCount = [self.colors count];
        }
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        itemCount = [self.coinProducts count];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        itemCount = [self.brushProducts count];
    }
    return itemCount;
}

- (NSDictionary *)shopViewController:(DQShopViewController *)vc infoForTab:(DQShopViewControllerTab)tab indexPath:(NSIndexPath *)indexPath
{
    NSDictionary *info = nil;
    if (tab == DQShopViewControllerTabColors)
    {
        if (indexPath.section == 0)
        {
            info = [self.colorPacks objectAtIndex:indexPath.item];
        }
        else if (indexPath.section == 1)
        {
            info = [self.colors objectAtIndex:indexPath.item];
        }
    }
    else if (tab == DQShopViewControllerTabCoins)
    {
        if (indexPath.item < [self.coinInfo count])
        {
            info = [self.coinInfo objectAtIndex:indexPath.item];
        }
        else
        {
            NSMutableArray *coinIdentifiers = [[NSMutableArray alloc] init];
            for (SKProduct *product in self.coinProducts)
            {
                [coinIdentifiers addObject:(product.productIdentifier ?: [NSNull null])];
            }
            __weak typeof(self) weakSelf = self;
            [DQPapertrailLogger component:@"shop-controller" category:@"coin-index-out-of-bounds" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"coin-info": weakSelf.coinInfo ?: [NSNull null],
                         @"coin-identifiers": coinIdentifiers ?: [NSNull null]};
            }];
        }
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        if (indexPath.item < [self.brushInfo count])
        {
            info = [self.brushInfo objectAtIndex:indexPath.item];
        }
        else
        {
            NSMutableArray *brushIdentifiers = [[NSMutableArray alloc] init];
            for (SKProduct *product in self.brushProducts)
            {
                [brushIdentifiers addObject:(product.productIdentifier ?: [NSNull null])];
            }
            __weak typeof(self) weakSelf = self;
            [DQPapertrailLogger component:@"shop-controller" category:@"brush-index-out-of-bounds" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"brush-info": weakSelf.brushInfo ?: [NSNull null],
                         @"brush-identifiers": brushIdentifiers ?: [NSNull null]};
            }];
        }
    }
    return info;
}

- (SKProduct *)shopViewController:(DQShopViewController *)vc productForTab:(DQShopViewControllerTab)tab indexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = nil;
    if (tab == DQShopViewControllerTabCoins)
    {
        product = [self.coinProducts objectAtIndex:indexPath.item];
    }
    else if (tab == DQShopViewControllerTabBrushes)
    {
        product = [self.brushProducts objectAtIndex:indexPath.item];
    }
    return product;
}

#pragma mark - SKProductsRequestDelegate

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (request == self.coinProductsRequest)
    {
        [DQPapertrailLogger component:@"shop-controller" category:@"coin-products-request-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{};
        }];
        self.coinProductsRequest = nil;
    }
    else if (request == self.brushProductsRequest)
    {
        [DQPapertrailLogger component:@"shop-controller" category:@"brush-products-request-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{};
        }];
        self.brushProductsRequest = nil;
    }

    if (self.shopFailedBlock)
    {
        self.shopFailedBlock(error);
        self.shopFailedBlock = nil;
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    request.delegate = nil;
    
    if (request == self.coinProductsRequest)
    {
        self.coinProductsRequest = nil;
        
        NSArray *products = response.products;
        products = [products sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSInteger n1 = [[[[(SKProduct*)obj1 productIdentifier] componentsSeparatedByString:@"."] lastObject] integerValue];
            NSInteger n2 = [[[[(SKProduct*)obj2 productIdentifier] componentsSeparatedByString:@"."] lastObject] integerValue];
            
            return n1 > n2;
        }];
        self.coinProducts = products;
    }
    else if (request == self.brushProductsRequest)
    {
        self.brushProductsRequest = nil;
        self.brushProducts = response.products;
    }
    
    if (self.shopLoadedBlock && self.coinProductsRequest == nil && self.brushProductsRequest == nil)
    {
        self.shopLoadedBlock();
        self.shopLoadedBlock = nil;
    }
}

@end
