//
//  DQPlaybackImageView.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-30.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQImageView.h"

@class CVSDrawing;

@interface DQPlaybackImageView : DQImageView

@property (nonatomic, copy) NSString *commentID;

- (id)initForCommentWithServerID:(NSString *)commentID frame:(CGRect)frame;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initForCommentWithServerID:frame:);
- (id)initWithCoder:(NSCoder *)aDecoder MSDesignatedInitializer(initForCommentWithServerID:frame:);
- (id)init MSDesignatedInitializer(initForCommentWithServerID:frame:);

- (void)playbackDrawing:(CVSDrawing *)drawing withTemplateImage:(UIImage *)templateImage completionBlock:(dispatch_block_t)completionBlock;

- (void)startPlayback;
- (void)pausePlayback;
- (void)stopPlayback;

- (BOOL)isPlayingOrPaused;

- (void)startDisplayingSpinner;
- (void)stopDisplayingSpinner;

- (void)showPlayIcon;
- (void)showPauseIcon;
- (void)showStarIcon; // FIXME: the call to this has been removed, figure out an alternative

@end
