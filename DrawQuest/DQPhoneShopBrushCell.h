//
//  DQPhoneShopBrushCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DQButton.h"

@interface DQPhoneShopBrushCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *descriptionLabel;
@property (nonatomic, strong, readonly) DQButton *purchaseButton;

- (void)setBrushView:(UIView *)brushView;
- (void)setIsPurchased:(BOOL)isPurchased;

@end
