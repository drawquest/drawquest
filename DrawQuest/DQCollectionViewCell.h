//
//  DQCollectionViewCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL hasDivider;
@property (nonatomic, copy) void (^cellTappedBlock)(DQCollectionViewCell *cell);

@end
