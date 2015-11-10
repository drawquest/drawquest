//
//  DQRewardTableViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/29/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQRewardTableViewCellIconTypeCheckmark,
    DQRewardTableViewCellIconTypeFire
} DQRewardTableViewCellIconType;

@class DQCoinsLabel;

@interface DQRewardTableViewCell : UITableViewCell

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) DQCoinsLabel *coinsLabel;
@property (assign, nonatomic) DQRewardTableViewCellIconType iconType;

@end
