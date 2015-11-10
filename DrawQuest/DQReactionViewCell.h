//
//  DQReactionViewCell.h
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQCircularMaskImageView.h"

static const CGFloat kDQReactionViewCellHeight = 60.0f;

typedef NS_ENUM(NSUInteger, DQReactionViewCellType) {
    DQReactionViewCellTypeStarred,
    DQReactionViewCellTypePlayed,
    DQReactionViewCellTypeCount,
    DQReactionViewCellTypeNotFound = NSNotFound
};

@interface DQReactionViewCell : UITableViewCell

@property (nonatomic, strong, readonly) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, strong, readonly) UILabel *usernameLabel;
@property (nonatomic, assign) DQReactionViewCellType reactionType;

- (void)setTimestamp:(NSDate *)timestamp;
- (NSDate *)timestamp;

@end
