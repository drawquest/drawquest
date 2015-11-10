// DQPlaybackStrokeView.h
// DrawQuest
// Created by Justin Carlson on 11/2/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <UIKit/UIKit.h>

@class DQPlaybackView;
@class CVSDrawing;
@class CVSStrokeArray;
@class CVSCacheView;
@class CVSTemplateImage;

@interface DQPlaybackStrokeView : UIView

- (id)initWithFrame:(CGRect)pFrame templateImage:(CVSTemplateImage *)pTemplateImage cacheView:(CVSCacheView *)pCacheView;

@property (nonatomic, weak) DQPlaybackView * playbackView;
@property (strong, nonatomic) CVSDrawing * drawing;

- (void)startPlayback;
- (void)pausePlayback;
- (void)stopPlayback;

- (void)clearAllStrokesAndEraseView;

@end
