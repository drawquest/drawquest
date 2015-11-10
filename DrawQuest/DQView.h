//
//  DQView.h
//  DrawQuest
//
//  Created by David Mauro on 11/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQView : UIView

@property (nonatomic, copy) void (^dq_tintColorDidChangeBlock)(DQView *view);

@end
