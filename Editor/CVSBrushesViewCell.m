//
//  CVSBrushesViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSBrushesViewCell.h"

#import "UIView+STAdditions.h"
#import "UIColor+DQAdditions.h"

@interface CVSBrushesViewCell ()

@property (nonatomic, strong) UIView *lockedImageView;

@end

@implementation CVSBrushesViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        // Locked Icon
        UIImage *lockImage = [UIImage imageNamed:@"icon_locked"];
        CGFloat imageSize = lockImage.size.width + 14.0f;
        _lockedImageView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, imageSize, imageSize)];
        _lockedImageView.layer.cornerRadius = imageSize/2.0f;
        _lockedImageView.backgroundColor = [UIColor dq_editorTabColor];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:lockImage];
        imageView.frameCenterX = _lockedImageView.boundsCenterX;
        imageView.frameY = 4.0f;
        [_lockedImageView addSubview:imageView];
        _lockedImageView.hidden = YES;
        [self.contentView addSubview:_lockedImageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.lockedImageView.frameCenterX = self.boundsCenterX;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.lockedImageView.frameY = 20.0f;
    }
    else
    {
        self.lockedImageView.frameY = 40.0f;
    }
}

- (void)setBrushView:(CVSBrushView *)brushView
{
    if (brushView != _brushView)
    {
        [_brushView removeFromSuperview];
        [self.contentView addSubview:brushView];
        _brushView = brushView;
        self.bounds = brushView.bounds;
        [self.contentView bringSubviewToFront:self.lockedImageView];
    }
}

- (void)setIsLocked:(BOOL)isLocked
{
    _isLocked = isLocked;
    self.lockedImageView.hidden = !isLocked;
    self.brushView.alpha = isLocked ? 0.4f : 1.0f;
}

- (void)setPopped:(BOOL)popped
{
    if (popped != _popped)
    {
        _popped = popped;
        
        CGFloat offset = 0.0f;
        if (popped)
        {
            offset = - 20.0f;
        }
        else
        {
            offset = 20.0f;
        }
        [UIView animateWithDuration:0.2f animations:^{
            self.brushView.frameY += offset;
        }];
    }
}

- (void)setPoppedUnanimated:(BOOL)popped
{
    _popped = popped;

    CGFloat offset = 20.0f;
    if (popped)
    {
        self.brushView.frameY -= offset;
    }
    else
    {
        self.brushView.frameY += offset;
    }
}

@end
