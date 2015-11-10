//
//  DQPhoneFriendListCell.h
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTintedTableViewCell.h"

// Views
#import "DQCircularMaskImageView.h"

static const CGFloat kDQPhoneFriendListCellDesiredHeight = 57.0f;

@interface DQPhoneFriendListCell : DQTintedTableViewCell

@property (nonatomic, strong, readonly) DQCircularMaskImageView *avatarImageView;

- (void)setDisplayName:(NSString *)displayName;
- (void)setUserName:(NSString *)userName;

@end
