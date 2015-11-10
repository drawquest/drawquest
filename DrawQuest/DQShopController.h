//
//  DQShopController.h
//  DrawQuest
//
//  Created by David Mauro on 8/12/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "DQShopViewController.h"

@class DQShopController;

@protocol DQShopControllerDelegate <DQControllerDelegate>

- (void)shopController:(DQShopController *)shopController updateCoinBalanceForLoggedInUser:(NSNumber *)inCoinBalance;
- (void)shopController:(DQShopController *)shopController updateColorsForLoggedInUser:(NSArray *)colors;
- (void)shopController:(DQShopController *)shopController addOwnedBrush:(NSDictionary *)brush;
- (NSArray *)ownedBrushesForShopController:(DQShopController *)shopController;

@end

@interface DQShopController : DQController <DQShopViewControllerDelegate, DQShopViewControllerDataSource>

@property (nonatomic, weak) id<DQShopControllerDelegate> delegate;
@property (nonatomic, copy) dispatch_block_t runPendingTransactionsBlock;

- (id)initWithDelegate:(id<DQShopControllerDelegate>)delegate;

@end
