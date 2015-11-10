//
//  DQCollectionViewQuestCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCollectionViewCell.h"

@class DQCircularMaskImageView;
@class DQImageView;

static const CGFloat kDQCollectionViewQuestCellWidth = 320.0f;
static const CGFloat kDQCollectionViewQuestCellHeight = 86.0f; // Thumbnail height + 2 x vertical padding

@interface DQCollectionViewQuestCell : DQCollectionViewCell

@property (nonatomic, strong) UILabel *questTitleLabel;
@property (nonatomic, strong) DQImageView *questTemplateImageView;

@end
