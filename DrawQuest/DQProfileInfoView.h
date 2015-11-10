//
//  DQProfileInfoView.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQProfileInfoViewAccessoryTypeNone,
    DQProfileInfoViewAccessoryTypeCoin
} DQProfileInfoViewAccessoryType;


@interface DQProfileInfoView : UIView

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;
@property (nonatomic, assign) NSTextAlignment bottomLabelAlignment;
@property (nonatomic, assign) DQProfileInfoViewAccessoryType accessoryType;
@property (strong, nonatomic, readonly) UIImageView *accessoryImageView;
@property (nonatomic, weak) UIView *bottomUIView;

@end
