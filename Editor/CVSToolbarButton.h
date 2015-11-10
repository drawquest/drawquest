//
//  CVSToolbarButton.h
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVSToolbarButton : UIButton

@property (nonatomic, strong) UIView *customView;
@property (nonatomic, assign) BOOL customViewCanOverlap;

- (void)setCustomViewCanOverlap:(BOOL *)customViewCanOverlap animated:(BOOL)animated;

@end
