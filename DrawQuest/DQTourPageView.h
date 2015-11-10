//
//  DQTourPageView.h
//  DrawQuest
//
//  Created by David Mauro on 10/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQTourPageView : UIView

@property (nonatomic, strong, readonly) UIButton *button;
@property (nonatomic, copy) dispatch_block_t drawLaterButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t signInButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t imageTappedBlock;
@property (nonatomic, assign) BOOL asksForPushPermissions;
@property (nonatomic, assign) BOOL wideText;

- (id)initWithGradientImage:(UIImage *)gradientImage foregroundImage:(UIImage *)foregroundImage message:(NSString *)message displayExtraOptions:(BOOL)displayExtraOptions button:(UIButton *)button;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithGradientImage:foregroundImage:message:displayExtraOptions:button:);

@end
