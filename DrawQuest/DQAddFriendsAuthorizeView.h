//
//  DQAddFriendsAuthorizeView.h
//  DrawQuest
//
//  Created by David Mauro on 6/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQAddFriendsAuthorizeView : UIView

@property (nonatomic, strong, readonly) UILabel *message;
@property (nonatomic, strong, readonly) UIButton *button;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicator;

- (void)showActivityIndicator;
- (void)setMessage:(NSString *)inMessage withButton:(UIButton *)inButton;

@end
