//
//  DQTimestampView.h
//  DrawQuest
//
//  Created by David Mauro on 9/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

static const CGFloat kDQTimestampViewSpacing = 2.0f;

@interface DQTimestampView : UIView

@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) UIImageView *image;
@property (nonatomic, strong) UILabel *label;


@end
