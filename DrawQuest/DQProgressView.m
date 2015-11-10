//
//  DQProgressView.m
//  DrawQuest
//
//  Created by David Mauro on 10/28/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQProgressView.h"

#import "UIView+STAdditions.h"

@interface DQProgressView ()

@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, assign) CGFloat progress;

@end

@implementation DQProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _trackView = [[UIView alloc] initWithFrame:CGRectZero];
        _trackView.clipsToBounds = YES;
        [self addSubview:_trackView];

        _progressView = [[UIView alloc] initWithFrame:CGRectZero];
        [_trackView addSubview:_progressView];
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    if (self.tintColorForProgressColor)
    {
        self.progressView.backgroundColor = self.tintColor;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.trackView.layer.cornerRadius = self.cornerRadius;
    self.progressView.layer.cornerRadius = self.cornerRadius;

    self.trackView.frame = self.bounds;
    self.progressView.frameHeight = self.trackView.frameHeight;
    self.progressView.frameWidth = self.trackView.frameWidth * self.progress;
    self.progressView.frameX = 0.0f;
}

#pragma mark -

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated
{
    _progress = progress;
    if (animated)
    {
        [UIView animateWithDuration:0.5f animations:^{
            self.progressView.frameWidth = self.trackView.frameWidth * self.progress;
        }];
    }
    else
    {
        self.progressView.frameWidth = self.trackView.frameWidth * self.progress;
    }
}

- (void)setTrackColor:(UIColor *)trackColor
{
    self.trackView.backgroundColor = trackColor;
}

- (UIColor *)trackColor
{
    return self.trackView.backgroundColor;
}

- (void)setProgressColor:(UIColor *)progressColor
{
    self.progressView.backgroundColor = progressColor;
}

- (UIColor *)progressColor
{
    return self.progressView.backgroundColor;
}

@end
