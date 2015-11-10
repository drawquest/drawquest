//
//  DQPhoneShopColorCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQPhoneShopColorCell : UICollectionViewCell

@property (nonatomic, assign) BOOL isPurchased;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, copy) void (^cellTappedBlock)(DQPhoneShopColorCell *cell);

- (void)setColor:(UIColor *)color;

@end
