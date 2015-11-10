//
//  DQCollectionViewGridCell.h
//  DrawQuest
//
//  Created by David Mauro on 9/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQImageView.h"
#import "DQViewMetricsConstants.h"

@interface DQCommentGridCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly, strong) DQImageView *imageView;
@property (nonatomic, copy) dispatch_block_t cellTappedBlock;

@end
