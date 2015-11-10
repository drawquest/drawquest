//
//  DQProgressView.h
//  DrawQuest
//
//  Created by David Mauro on 10/28/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQProgressView : UIView

@property (nonatomic, strong) UIColor *progressColor;
@property (nonatomic, strong) UIColor *trackColor;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) BOOL tintColorForProgressColor;

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end
