//
//  DQHUDView.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/26/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQHUDView : UIView

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) NSString *text;

- (void)showInView:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end
