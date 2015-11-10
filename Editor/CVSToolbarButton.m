//
//  CVSToolbarButton.m
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSToolbarButton.h"
#import "UIView+STAdditions.h"

static const CGFloat kCVSToolbarButtonOverlap = -15.0f;
static const CGFloat kCVSToolbarButtonInset = 5.0f;

@interface CVSToolbarButton ()

@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;

@end

@implementation CVSToolbarButton

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.customView.center = self.boundsCenter;
    
    // Make sure this looks good wrt subpixels on non-retina
    if (fmodf(self.customView.frameWidth, 2.0f) > 0.0f && fmodf(self.frameWidth, 2.0) == 0.0f)
    {
        self.customView.frameCenterX += 0.5f;
    }
    if (fmodf(self.customView.frameHeight, 2.0f) > 0.0f && fmodf(self.frameHeight, 2.0) == 0.0f)
    {
        self.customView.frameCenterY += 0.5f;
    }

    CGFloat threshold = (self.customViewCanOverlap) ? kCVSToolbarButtonOverlap : kCVSToolbarButtonInset;
    if (self.customView.frameY < threshold)
    {
        self.customView.frameY = threshold;
    }
}

- (void)setCustomViewCanOverlap:(BOOL *)customViewCanOverlap animated:(BOOL)animated
{
    _customViewCanOverlap = customViewCanOverlap;
    
    if (animated)
    {
        CGRect customViewFrame = self.customView.frame;
        customViewFrame.origin.y = customViewCanOverlap ? kCVSToolbarButtonOverlap : kCVSToolbarButtonInset;
        
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2f animations:^{
            weakSelf.customView.frame = customViewFrame;
        }];
    }
}

- (void)setCustomView:(UIView *)customView
{
    [_customView removeGestureRecognizer:self.tapRecognizer];
    [_customView removeFromSuperview];
    _customView = customView;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(customViewTapped:)];
    [_customView addGestureRecognizer:tapGestureRecognizer];
    self.tapRecognizer = tapGestureRecognizer;
    [self addSubview:_customView];
}

- (void)customViewTapped:(id)sender
{
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end
