//
//  DQAddCoinsTableViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/2/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQButton.h"

@class DQCoinsLabel;

@interface DQAddCoinsTableViewCell : UITableViewCell

@property (strong, nonatomic) DQCoinsLabel *coinsLabel;
@property (strong, nonatomic) DQButton *purchaseButton;

@end
