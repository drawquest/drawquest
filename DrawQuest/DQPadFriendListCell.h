//
//  DQPadFriendListCell.h
//  DrawQuest
//
//  Created by David Mauro on 6/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQPadFriendListCell : UITableViewCell

@property (nonatomic, copy)dispatch_block_t actionButtonTappedBlock;

- (void)setAvatarImageURL:(NSString *)imageURL;
- (void)setDisplayName:(NSString *)displayName;
- (void)setDrawQuestUsername:(NSString *)dqUsername;

@end
