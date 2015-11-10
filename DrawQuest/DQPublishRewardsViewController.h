//
//  DQPublishRewardsViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

#import "DQProgressView.h"

@interface DQPublishRewardsViewController : DQViewController

@property (nonatomic, strong) NSDictionary *rewardsDictionary;
@property (nonatomic, strong) NSArray *shareFlags;
@property (nonatomic, copy) NSString *questID;
@property (nonatomic, copy) void (^dismissBlock)(DQPublishRewardsViewController *vc);

- (void)ready;

@end

@interface DQPublishRewardView : UIView

@property (nonatomic, strong, readonly) UILabel *rewardLabel;
@property (nonatomic, strong, readonly) UILabel *amountLabel;

@end

@interface DQPublishStreakView: UIView

@property (nonatomic, strong, readonly) UILabel *streakLabel;
@property (nonatomic, strong, readonly) DQProgressView *progressView;

@end
