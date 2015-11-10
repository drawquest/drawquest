//
//  DQCollectionViewListCell.h
//  DrawQuest
//
//  Created by David Mauro on 9/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQCircularMaskImageView.h"
#import "DQPlaybackImageView.h"
#import "DQStarButton.h"

static const CGFloat kDQCollectionViewListCellWidth = 304.0f;
static const CGFloat kDQCollectionViewListCellHeight = 318.0f;

@class DQButton;
@class DQTimestampView;

@interface DQCommentListCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly, strong) DQPlaybackImageView *playbackImageView;
@property (nonatomic, readonly, strong) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, readonly, strong) UILabel *usernameLabel;
@property (nonatomic, strong) DQTimestampView *timestampView;

@property (nonatomic, assign) NSInteger notesCount;

@property (nonatomic, copy) dispatch_block_t showUserProfileBlock;
@property (nonatomic, copy) dispatch_block_t showDrawingDetailBlock;
@property (nonatomic, copy) dispatch_block_t showMoreOptionsBlock;
@property (nonatomic, copy) void (^shareButtonTappedBlock)(DQCommentListCollectionViewCell *cell);
@property (nonatomic, copy) void (^imageTappedBlock)(DQCommentListCollectionViewCell *cell);

@property (nonatomic, strong) DQButton *playButton;
@property (nonatomic, copy) void (^playbackBlock)(DQButton *playbackButton, DQPlaybackImageView *playbackImageView, DQCommentListCollectionViewCell *cell);

@property (nonatomic, strong) DQStarButton *starButton;

- (void)displayFollowButtonForUsername:(NSString *)username;

@property (nonatomic, copy) void (^dq_notificationHandlerBlock)(DQCommentListCollectionViewCell *cell, NSNotification *notification);
- (void)dq_notificationHandler:(NSNotification *)notification;

@end
