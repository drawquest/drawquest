//
//  DQGridViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "STGridViewCell.h"

#import "DQImageView.h"
#import "DQTimestampView.h"

@interface DQGridViewCell : STGridViewCell

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) DQTimestampView *timestampLabel;
@property (strong, nonatomic) DQImageView *imageView;

@end
