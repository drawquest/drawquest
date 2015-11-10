//
//  DQDrawingDetailHeaderView.h
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQCircularMaskImageView.h"

// This is the height it will appear at before it's height is determined by autoLayout
static const CGFloat kDQDrawingDetailHeaderViewHeightEstimate = 325.0f;

@class DQPlaybackImageView;
@class DQButton;
@class DQStarButton;
@class DQTimestampView;

@interface DQDrawingDetailHeaderView : UIView

@property (nonatomic, strong) DQPlaybackImageView *playbackImageView;
@property (nonatomic, strong) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) DQStarButton *starButton;
@property (nonatomic, strong) DQTimestampView *timestampView;
@property (nonatomic, assign) NSInteger notesCount;
@property (nonatomic, copy) dispatch_block_t moreOptionsSelectedBlock;
@property (nonatomic, copy) void (^playbackButtonTappedBlock)(DQDrawingDetailHeaderView *view, DQButton *playbackButton);
@property (nonatomic, copy) void (^imageTappedBlock)(DQDrawingDetailHeaderView *view);
@property (nonatomic, copy) void (^shareButtonTappedBlock)(DQDrawingDetailHeaderView *view);
@property (nonatomic, copy) dispatch_block_t showProfileBlock;

- (void)displayFollowButtonForUsername:(NSString *)username;

@end
