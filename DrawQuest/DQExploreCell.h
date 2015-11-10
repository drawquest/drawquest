//
//  DQExploreCell.h
//  DrawQuest
//
//  Created by Dirk on 4/15/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "DQExploreComment.h"
#import "DQImageView.h"

typedef enum {
    DQExploreCellSizeSmall,
    DQExploreCellSizeLarge
    } DQExploreCellSize;

@interface DQExploreCell : UICollectionViewCell
@property (nonatomic, strong) DQExploreComment *comment;
@property (nonatomic, weak) DQImageView *imageView;
@property (nonatomic, assign) DQExploreCellSize cellSize;

- (void)setCellSize:(DQExploreCellSize)cellSize backgroundColorPatternImage:(UIColor *)backgroundColorPatternImage;
- (void)setCellSize:(DQExploreCellSize)size;

@end
