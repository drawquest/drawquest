//
//  DQButton.h
//  DrawQuest
//
//  Created by David Mauro on 6/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQButton;

typedef void (^DQButtonBlock)(DQButton *button);

@interface DQButton : UIButton

@property (nonatomic, assign) BOOL tintColorForTitle;
@property (nonatomic, assign) BOOL tintColorForBackground;
@property (nonatomic, copy) DQButtonBlock tappedBlock;
@property (nonatomic, copy) void (^selectedBlock)(DQButton *button, BOOL isSelected);

+ (instancetype)buttonWithImage:(UIImage *)normalImage selectedImage:(UIImage *)selectedImage;
+ (instancetype)buttonWithImage:(UIImage *)image;

- (void)disableWithActivityIndicator;
- (void)enableAndRemoveActivityIndicator;

@end
