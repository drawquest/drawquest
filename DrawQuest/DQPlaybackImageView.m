//
//  DQPlaybackImageView.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-30.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPlaybackImageView.h"

// Models
#import "CVSDrawing.h"

// Views
#import "DQPlaybackView.h"

// Additions
#import "UIView+STAdditions.h"
#import "CVSTemplateImage.h"
#import "DQStarConstants.h"

@interface DQPlaybackImageView () <DQPlaybackViewDelegate>

@property (nonatomic, strong) DQPlaybackView *playbackView;
@property (nonatomic, copy) dispatch_block_t playbackCompletionBlock;
@property (nonatomic, strong) UIView *spinnerView;
@property (nonatomic, strong) UIView *iconView;

@end

@implementation DQPlaybackImageView

- (void)dealloc
{
    [self stopPlayback];
    if (_commentID)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:DQSetStarStateRequestNotification
                                                      object:nil];
    }
}

- (id)initForCommentWithServerID:(NSString *)commentID frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _commentID = [commentID copy];
        if (_commentID)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(starStateChanged:)
                                                         name:DQSetStarStateRequestNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)prepareForReuse
{
    self.commentID = nil;
    [super prepareForReuse];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if ( ! self.window)
    {
        [self stopPlayback];
    }
}

- (void)playbackDrawing:(CVSDrawing *)drawing withTemplateImage:(UIImage *)templateImage completionBlock:(dispatch_block_t)completionBlock
{
    self.playbackCompletionBlock = completionBlock;
    if (self.playbackView)
    {
        [self.playbackView pausePlayback];
        [self.playbackView removeFromSuperview];
        self.playbackView = nil;
    }
    CGSize size = self.bounds.size;
    // it's possible to create a quest without a template image. use the (blank) fallback in this case.
    CVSTemplateImage * const image = templateImage ? [CVSTemplateImage templateImageWithUIImage:templateImage] : [CVSTemplateImage templateImageWithEmptyTemplateImage];
    self.playbackView = [[DQPlaybackView alloc] initWithFrame:CGRectMake(0.0, 0.0, size.width, size.height) templateImage:image];
    self.playbackView.delegate = self;
    self.playbackView.drawing = drawing;
    self.playbackView.layer.opacity = 0.0;
    [self addSubview:self.playbackView];
    [UIView animateWithDuration:0.5 animations:^{
        self.playbackView.layer.opacity = 1.0;
    } completion:^(BOOL finished) {
        [self startPlayback];
    }];
    [self bringSubviewToFront:self.iconView];
}

- (void)setCommentID:(NSString *)commentID
{
    if (!(_commentID ? [_commentID isEqualToString:commentID] : !commentID))
    {
        // NSLog(@"playback %p commentID changing from %@ to %@", self, _commentID, commentID);
        if (_commentID)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:DQSetStarStateRequestNotification
                                                          object:nil];
        }
        _commentID = [commentID copy];
        if (_commentID)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(starStateChanged:)
                                                         name:DQSetStarStateRequestNotification
                                                       object:nil];
        }
    }
}

- (void)starStateChanged:(NSNotification *)notification
{
    if ([self window])
    {
        NSString *commentID = [notification object];
        DQStarState state = [[notification userInfo][DQStarStateNotificationStateUserInfoKey] integerValue];
        if ([_commentID isEqualToString:commentID] && (state == DQStarStateStarred))
        {
            [self showStarIcon];
        }
    }
}

- (BOOL)isPlayingOrPaused
{
    return self.playbackView != nil;
}

- (void)startPlayback
{
    [self.playbackView startPlayback];
}

- (void)pausePlayback
{
    [self.playbackView pausePlayback];
}

- (void)stopPlayback
{
    [self.iconView removeFromSuperview];
    self.iconView = nil;
    [self.playbackView pausePlayback];
    [self.playbackView removeFromSuperview];
    self.playbackView = nil;
    self.playbackCompletionBlock = nil;
}

#pragma mark - DQPlaybackViewDelegate

- (void)playbackViewDidFinishPlayback:(DQPlaybackView *)playbackView
{
    [self.playbackView removeFromSuperview];
    self.playbackView = nil;
    if (self.playbackCompletionBlock)
    {
        self.playbackCompletionBlock();
    }
}

#pragma mark -

- (void)showIconNamed:(NSString *)iconName;
{
    if (self.iconView)
    {
        [self.iconView removeFromSuperview];
        self.iconView = nil;
    }
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconName]];
    iconImageView.alpha = 0.0f;
    iconImageView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    iconImageView.center = self.boundsCenter;
    [self addSubview:iconImageView];
    self.iconView = iconImageView;

    [UIView animateKeyframesWithDuration:0.15f delay:0.0f options:UIViewAnimationCurveEaseIn animations:^{
        iconImageView.alpha = 1.0f;
        iconImageView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        [UIView animateKeyframesWithDuration:0.25f delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{
            iconImageView.alpha = 0.0f;
        } completion:nil];
    }];

    [UIView animateKeyframesWithDuration:0.4f delay:0.0f options:UIViewAnimationCurveLinear animations:^{
        iconImageView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    } completion:^(BOOL finished) {
        if (iconImageView == self.iconView)
        {
            self.iconView = nil;
        }
        [iconImageView removeFromSuperview];
    }];
}

- (void)showPlayIcon
{
    [self showIconNamed:@"ghosted_icon_play"];
}

- (void)showPauseIcon
{
    [self showIconNamed:@"ghosted_icon_pause"];
}

- (void)showStarIcon
{
    [self showIconNamed:@"ghosted_icon_star"];
}

- (void)startDisplayingSpinner
{
    self.spinnerView = [[UIView alloc] initWithFrame:self.bounds];
    self.spinnerView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.15f];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = self.spinnerView.bounds;
    [spinner startAnimating];
    [self.spinnerView addSubview:spinner];
    [self addSubview:self.spinnerView];
    [self bringSubviewToFront:self.spinnerView];
}

- (void)stopDisplayingSpinner
{
    [self.spinnerView removeFromSuperview];
    self.spinnerView = nil;
}

@end
