//
//  DQCollectionViewUserCell.h
//  DrawQuest
//
//  Created by David Mauro on 10/21/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DQCircularMaskImageView.h"

static const CGFloat kDQCollectionViewUserCellWidth = 320.0f;
static const CGFloat kDQCollectionViewUserCellHeight = 55.0f;

@interface DQCollectionViewUserCell : UICollectionViewCell

@property (nonatomic, strong, readonly) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, strong, readonly) UILabel *usernameLabel;
@property (nonatomic, copy) dispatch_block_t cellTappedBlock;

- (void)displayFollowButtonForUsername:(NSString *)username;

@end
