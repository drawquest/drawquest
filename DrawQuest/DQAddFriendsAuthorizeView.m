//
//  DQAddFriendsAuthorizeView.m
//  DrawQuest
//
//  Created by David Mauro on 6/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAddFriendsAuthorizeView.h"

#import "DQPadAddFriendsAuthorizeView.h"
#import "DQPhoneAddFriendsAuthorizeView.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQAddFriendsAuthorizeView ()

@property (nonatomic, strong) UILabel *message;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation DQAddFriendsAuthorizeView

- (id)initWithFrame:(CGRect)frame
{
    if ([self class] == [DQAddFriendsAuthorizeView class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadAddFriendsAuthorizeView alloc] initWithFrame:frame];
        }
        else
        {
            self = [[DQPhoneAddFriendsAuthorizeView alloc] initWithFrame:frame];
        }
    }
    else
    {
        self = [super initWithFrame:frame];
        if (self)
        {
            _message = [[UILabel alloc] initWithFrame:CGRectZero];
            [self addSubview:_message];

            _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            _activityIndicator.hidesWhenStopped = YES;
            [self addSubview:_activityIndicator];
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect contentRect = CGRectInset(self.bounds, 0.0f, 30.0f);

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = self.message.lineBreakMode;
    self.message.frameWidth = contentRect.size.width - 20.0f;
    [self.message sizeToFit];
    self.message.frameCenterX = self.boundsCenterX;
    self.message.frameY = contentRect.origin.y;

    self.button.frame = CGRectMake(CGRectGetMinX(contentRect) + (int)((CGRectGetWidth(contentRect) - CGRectGetWidth(self.button.frame))/2),
                                   CGRectGetMaxY(self.message.frame) + 20.0f,
                                   CGRectGetWidth(self.button.frame),
                                   CGRectGetHeight(self.button.frame));

    self.activityIndicator.center = CGPointMake(CGRectGetMidX(self.bounds) - CGRectGetWidth(self.activityIndicator.frame)/2, CGRectGetMidY(self.bounds) - CGRectGetHeight(self.activityIndicator.frame)/2);

    UIView *gradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frameWidth, 1)];
    gradientView.backgroundColor = [UIColor colorWithRed:(232/255.0) green:(232/255.0) blue:(232/255.0) alpha:1.0];
    [self addSubview:gradientView];

}

#pragma mark - Setters

- (void)setButton:(UIButton *)button
{
    if (_button)
    {
        [_button removeFromSuperview];
    }
    _button = button;
    if (_button)
    {
        [self addSubview:_button];
    }
}

#pragma mark - External

- (void)showActivityIndicator
{
    [self.activityIndicator startAnimating];
    self.message.text = nil;
    self.button = nil;
}

- (void)setMessage:(NSString *)inMessage withButton:(UIButton *)inButton
{
    [self.activityIndicator stopAnimating];
    self.message.text = inMessage;
    self.button = inButton;
    [self setNeedsLayout];
}

@end
