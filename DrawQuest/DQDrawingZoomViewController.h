//
//  DQDrawingZoomViewController.h
//  DrawQuest
//
//  Created by David Mauro on 11/8/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQDrawingZoomViewController : DQViewController

@property (nonatomic, strong) DQComment *comment;
@property (nonatomic, weak) UIView *sourceView;
@property (nonatomic, copy) void (^closeWindowBlock)(DQDrawingZoomViewController *vc);

@end
