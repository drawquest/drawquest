//
//  DQPhoneShopCoinCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DQButton.h"

@interface DQPhoneShopCoinCell : UICollectionViewCell

@property (nonatomic, strong, readonly) DQButton *purchaseButton;

- (void)flashSuccessView;
- (void)setAmount:(NSString *)amount;

@end
