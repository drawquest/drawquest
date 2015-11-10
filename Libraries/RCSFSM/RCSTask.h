//
//  RCSTask.h
//  Created by Jim Roepcke.
//  See license below.
//

#import <Foundation/Foundation.h>
#import "RCSState.h"

@class RCSTask;

@protocol RCSTaskDelegate <NSObject>

- (void)taskCancelled:(RCSTask *)task;
- (void)taskCompleted:(RCSTask *)task;
- (void)taskExhaustedAttempts:(RCSTask *)task;

@end

@interface RCSTaskState : RCSBaseState

+ (RCSTaskState *)state;

@end

@interface RCSTask : NSObject <RCSStateContext>

@property (nonatomic, readonly, copy) NSString *taskID;
@property (nonatomic, readwrite, weak) id<RCSTaskDelegate> delegate;
@property (nonatomic, readwrite, weak) RCSTaskState *state;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (NSMutableDictionary *)mutableDictionaryRepresentation;

// by default these trigger their eponymous transitions
- (void)cancel;
- (void)start;
- (void)wake;
- (void)pause;
- (void)resume;
- (void)foreground;
- (void)background;

// standard private method to be called when a task fails
// this is called after transitioning to the errorState
// put logging or whatever other code you want here
// the default implementation currently does nothing,
// but it might in the future, so call super if you override it
- (void)_stateContextDidEnterErrorState;

// standard private method to be called when a task is cancelled
// this is called after transitioning to the cancelledState
// the default implementation tells delegate taskCancelled:
- (void)_cancelled;

// standard private method to be called when a task is completed
// your state machine must call this, as completion state(s) are not modelled by RCSTask
// the default implementation tells delegate taskCompleted:
- (void)_completed;

- (BOOL)_mayReattempt; // YES if numberOfAttempts < maximumNumberOfAttempts;
- (void)_markAttempt; // increments numberOfAttempts
- (void)_clearAttempts; // resets numberOfAttempts to 0
- (void)_exhaustedAttempts; // tells delegate taskExhaustedAttempts:. The delegate is expected to pause the task.
- (void)_retryUsingBlock:(dispatch_block_t)block;

@end

/*
 * Copyright 2013 Jim Roepcke <jim@roepcke.com>. All rights reserved.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
