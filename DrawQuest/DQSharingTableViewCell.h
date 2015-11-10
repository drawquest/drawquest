//
//  DQSharingTableViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQSharingTableViewCell : UITableViewCell

@property (nonatomic, assign, getter = isSharing) BOOL sharing;
@property (nonatomic, copy) void (^toggledBlock)(DQSharingTableViewCell *cell, BOOL toggleOn);

- (void)configureForFacebookIsSharing:(BOOL)sharing;
- (void)configureForTwitterIsSharing:(BOOL)sharing;
- (void)setSharing:(BOOL)sharing animated:(BOOL)animated;
- (void)setRewardAmount:(NSString *)rewardAmount;

@end
