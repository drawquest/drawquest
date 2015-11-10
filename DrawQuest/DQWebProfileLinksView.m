//
//  DQWebProfileLinksView.m
//  DrawQuest
//
//  Created by David Mauro on 7/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQWebProfileLinksView.h"
#import "DQButton.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQWebProfileLinksView ()

@property (nonatomic, strong) DQButton *drawquestButton;
@property (nonatomic, strong) DQButton *facebookButton;
@property (nonatomic, strong) DQButton *twitterButton;

@end

@implementation DQWebProfileLinksView

- (id)initWithFrame:(CGRect)frame dqURL:(NSString *)dqURL fbURL:(NSString *)fbURL twURL:(NSString *)twURL
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.tintColor = [UIColor colorWithRed:(253/255.0) green:(124/255.0) blue:(149/255.0) alpha:1];
        
        if (dqURL)
        {
            _drawquestButton = [DQButton buttonWithType:UIButtonTypeCustom];
            [_drawquestButton setImage:[[UIImage imageNamed:@"icon_socialProfile_DrawQuest"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            _drawquestButton.tappedBlock = ^(DQButton *button) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dqURL]];
            };
            [_drawquestButton sizeToFit];
            [self addSubview:_drawquestButton];
        }

        if (fbURL)
        {
            _facebookButton = [DQButton buttonWithType:UIButtonTypeCustom];
            [_facebookButton setImage:[[UIImage imageNamed:@"icon_socialProfile_facebook"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            _facebookButton.tappedBlock = ^(DQButton *button) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbURL]];
            };
            [_facebookButton sizeToFit];
            [self addSubview:_facebookButton];
        }

        if (twURL)
        {
            _twitterButton = [DQButton buttonWithType:UIButtonTypeCustom];
            [_twitterButton setImage:[[UIImage imageNamed:@"icon_socialProfile_twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            _twitterButton.tappedBlock = ^(DQButton *button) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twURL]];
            };
            [_twitterButton sizeToFit];
            [self addSubview:_twitterButton];
        }
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat padding = 10.0f;
    
    CGRect bounds = self.bounds;
    CGFloat maxX = CGRectGetMinX(bounds);
    if (self.drawquestButton)
    {
        self.drawquestButton.frameOrigin = CGPointMake(maxX, 0);
        maxX = CGRectGetMaxX(self.drawquestButton.frame);
        maxX += padding;
    }
    
    if (self.facebookButton)
    {
        self.facebookButton.frameOrigin = CGPointMake(maxX, 0);
        maxX = CGRectGetMaxX(self.facebookButton.frame);
        maxX += padding;
    }
    if (self.twitterButton)
    {
        self.twitterButton.frameOrigin = CGPointMake(maxX, 0);
    }
}

@end
