//
//  DQCoinsLabel.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQCoinsLabelCoinPositionLeft,
    DQCoinsLabelCoinPositionRight
} DQCoinsLabelCoinPosition;

@interface DQCoinsLabel : UILabel

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL selected;

// designated initializer
- (id)initWithFrame:(CGRect)frame coinPosition:(DQCoinsLabelCoinPosition)coinPosition;

- (id)initWithFrame:(CGRect)frame; // defaults to DQCoinsLabelCoinPositionRight
- (id)init; // defaults to DQCoinsLabelCoinPositionRight, with CGRectZero frame

- (CGFloat)height;

@end
