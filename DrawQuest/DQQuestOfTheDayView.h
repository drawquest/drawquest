//
//  DQQuestOfTheDayView.h
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const DQQuestOfTheDayViewDidMoveToWindowNotification;

// This is the height it will appear at before it's height is determined by autoLayout
static const CGFloat kDQQuestOfTheDayViewHeightEstimate = 333.0f;

@class DQCircularMaskImageView;
@class DQImageView;
@class DQTimestampView;

@interface DQQuestOfTheDayView : UIView

@property (nonatomic, strong) UILabel *attributionLabel;
@property (nonatomic, strong) UILabel *questTitleLabel;
@property (nonatomic, strong) DQTimestampView *timestampLabel;
@property (nonatomic, strong) DQImageView *questTemplateImageView;
@property (nonatomic, strong) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, copy) dispatch_block_t drawQuestBlock;
@property (nonatomic, copy) dispatch_block_t viewQuestBlock;
@property (nonatomic, copy) dispatch_block_t showProfileBlock;

@end
