//
//  DQBrushTableViewCell.h
//  DrawQuest
//
//  Created by David Mauro on 7/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQButton.h"

@interface DQBrushTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *descriptionLabel;
@property (nonatomic, strong, readonly) DQButton *purchaseButton;

@property (nonatomic, copy) void(^purchaseButtonTappedBlock)(DQButton *button);

- (void)setBrushView:(UIView *)brushView;
- (void)setIsPurchased:(BOOL)isPurchased;

@end
