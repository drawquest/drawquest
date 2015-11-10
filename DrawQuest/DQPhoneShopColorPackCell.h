//
//  DQPhoneShopColorPackCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DQButton.h"

@interface DQPhoneShopColorPackCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *saleLabel;
@property (nonatomic, strong, readonly) DQButton *purchaseButton;
@property (nonatomic, assign) BOOL isPurchased;

- (void)setColors:(NSArray *)colors;

@end
