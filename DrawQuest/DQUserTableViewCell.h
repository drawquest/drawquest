//
//  DQUserTableViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/31/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQImageView;

@interface DQUserTableViewCell : UITableViewCell

@property (strong, nonatomic) DQImageView *avatarView;
@property (strong, nonatomic) UILabel *usernameLabel;

@end
