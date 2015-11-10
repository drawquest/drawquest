//
//  DQPlaybackView.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/24/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CVSDrawing;
@class CVSStrokeArray;
@class CVSTemplateImage;
@protocol DQPlaybackViewDelegate;

@interface DQPlaybackView : UIView

// designated initializer
- (id)initWithFrame:(CGRect)pFrame templateImage:(CVSTemplateImage *)pTemplateImage;

@property (nonatomic, weak) id <DQPlaybackViewDelegate> delegate;
@property (strong, nonatomic) CVSDrawing *drawing;

- (void)startPlayback;
- (void)pausePlayback;
- (void)stopPlayback;

- (void)clear;

@end

@protocol DQPlaybackViewDelegate <NSObject>

- (void)playbackViewDidFinishPlayback:(DQPlaybackView *)playbackView;

@end
