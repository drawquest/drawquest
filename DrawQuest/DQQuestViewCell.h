//
//  DQQuestViewCell.h
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQCircularMaskImageView;
@class DQImageView;

static const CGFloat kDQQuestViewCellHeight = 86.0f; // Thumbnail height + 2 x vertical padding

@interface DQQuestViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *questTitleLabel;
@property (nonatomic, strong) DQImageView *questTemplateImageView;

@end
