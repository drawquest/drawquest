//
//  CVSStrokeRecorder.h
//  DrawQuest
//
//  Created by Justin Carlson on 10/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UITouch;

/**
 @protocol this is a destination to send touch events to be recorded
 */
@protocol CVSStrokeRecorder <NSObject>
@required

- (void)startStrokeWithTouch:(UITouch *)pTouch;
- (void)addPointWithTouch:(UITouch *)pTouch;
- (void)endStroke;
- (void)endStrokeForSinglePoint;

- (void)disposeOrCommitActiveStroke;

@end
