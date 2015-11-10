//
//  DQPlaybackViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQPlaybackViewController.h"

// Models
#import "CVSDrawing.h"
#import "DQComment.h"
#import "DQQuest.h"

// Controllers
#import "DQPlaybackDataManager.h"

// Views
#import "DQPlaybackView.h"
#import "DQButton.h"

// Additions
#import "UIColor+DQAdditions.h"

#import "CVSTemplateImage.h"

@interface DQPlaybackViewController () <DQPlaybackViewDelegate>

@property (nonatomic, strong) CVSDrawing *drawing;
@property (nonatomic, strong) DQComment *comment;
@property (nonatomic, strong) DQQuest *quest;
@property (nonatomic, strong) DQPlaybackView *playbackView;
@property (nonatomic, strong) DQButton *playToggleButton;
@property (nonatomic, strong) UIImage *templateImage;
@property (nonatomic, strong) DQPlaybackDataManager *playbackDataManager;

@property (nonatomic, assign, getter = isPlaying) BOOL playing;
@property (nonatomic, assign, getter = hasPlayed) BOOL played;

@end

@implementation DQPlaybackViewController

- (id)initWithComment:(DQComment *)comment inQuest:(DQQuest *)quest newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _comment = comment;
        _quest = quest;
        _playbackDataManager = newPlaybackDataManager;

    }
    return self;
}

- (void)requestPreparePlaybackFromViewController:(UIViewController *)presentingViewController completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.playbackDataManager requestDrawingAndTemplateImageForComment:self.comment inQuest:self.quest fromViewController:presentingViewController resultBlock:^(CVSDrawing *drawing, UIImage *templateImage) {
        self.drawing = drawing;
        self.templateImage = templateImage;
        if (completionBlock)
        {
            completionBlock();
        }
    } failureBlock:failureBlock];
}

#pragma mark - Accessors

- (void)setPlaying:(BOOL)playing
{
    if (_playing == playing) {
        return;
    }
    
    _playing = playing;
    
    if (_playing) {
        if (self.hasPlayed) {
            self.played = NO;
            [self.playbackView clear];
        }
        
        [self.playbackView startPlayback];
    } else {
        [self.playbackView pausePlayback];
    }
}

#pragma mark - UIViewController

- (void)loadView
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f)];
    self.view = containerView;
    // it's possible to create a quest without a template image. use the (blank) fallback in this case.
    CVSTemplateImage * const image = self.templateImage ? [CVSTemplateImage templateImageWithUIImage:self.templateImage] : [CVSTemplateImage templateImageWithEmptyTemplateImage];
    _playbackView = [[DQPlaybackView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f) templateImage:image];
    _playbackView.drawing = self.drawing;
    _playbackView.delegate = self;
    [self.view addSubview:_playbackView];

    CGFloat buttonSize = 48.0f;
    _playToggleButton = [[DQButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.view.bounds) - 15.0f - buttonSize, CGRectGetMaxY(self.view.bounds) - 15.0f - buttonSize, buttonSize, buttonSize)];
    _playToggleButton.layer.cornerRadius = buttonSize/2.0f;
    _playToggleButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    _playToggleButton.layer.borderWidth = 2.0f;
    _playToggleButton.backgroundColor = [UIColor dq_greenColor];
    [_playToggleButton setImage:[UIImage imageNamed:@"button_icon_play"] forState:UIControlStateNormal];
    [_playToggleButton setImage:[UIImage imageNamed:@"button_icon_pause"] forState:UIControlStateSelected];
    __weak typeof(self) weakSelf = self;
    _playToggleButton.tappedBlock = ^(DQButton *button) {
        button.selected = !button.selected;
        weakSelf.playing = weakSelf.playToggleButton.selected;
    };
    [self.view addSubview:_playToggleButton];
    
    DQButton *dismissButton = [[DQButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.view.bounds) - 15.0f - buttonSize, CGRectGetMinY(self.view.bounds) + 15.0f, buttonSize, buttonSize)];
    dismissButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.playing) {
            [weakSelf.playbackView stopPlayback];
        }

        if (weakSelf.dismissBlock)
        {
            weakSelf.dismissBlock(self);
        }
    };
    [dismissButton setImage:[UIImage imageNamed:@"button_icon_close"] forState:UIControlStateNormal];
    dismissButton.layer.cornerRadius = buttonSize/2.0f;
    dismissButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    dismissButton.layer.borderWidth = 2.0f;
    dismissButton.backgroundColor = [UIColor dq_phoneButtonOffColor];

    [self.view addSubview:dismissButton];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.playing = YES;
    self.playToggleButton.selected = YES;
    [self.playbackDataManager requestLogPlaybackForComment:self.comment withCompletionBlock:nil];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - DQPlaybackViewDelegate

- (void)playbackViewDidFinishPlayback:(DQPlaybackView *)playbackView
{
    self.played = YES;
    self.playToggleButton.selected = NO;
}

@end
