//
//  RCSTaskQueue.h
//  Created by Jim Roepcke.
//  See license below.
//

#import <Foundation/Foundation.h>
#import "RCSTask.h"

@class RCSTaskQueue;

@protocol RCSTaskQueueDelegate <NSObject>

- (void)taskQueue:(RCSTaskQueue *)queue didCancelTask:(RCSTask *)task;
- (void)taskQueue:(RCSTaskQueue *)queue didCompleteTask:(RCSTask *)task;
- (void)taskQueueDidPauseDueToExhaustedAttempts:(RCSTaskQueue *)queue;

@end

@interface RCSTaskQueueState : RCSBaseState

+ (RCSTaskQueueState *)state;

@end

// this is an abstract class
// it must be subclasses and taskWithDictionaryRepresentation: must be overridden

@interface RCSTaskQueue : NSObject <RCSStateContext, RCSTaskDelegate>

@property (nonatomic, weak) id<RCSTaskQueueDelegate> delegate;
@property (nonatomic, weak) RCSTaskQueueState *state;
@property (nonatomic, readonly, assign) NSUInteger numberOfTasks;
@property (nonatomic, readonly, copy) NSArray *tasks;

- (id)initWithDelegate:(id<RCSTaskQueueDelegate>)delegate;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict delegate:(id<RCSTaskQueueDelegate>)delegate;
- (NSMutableDictionary *)mutableDictionaryRepresentation;

// subclasses must override this
- (RCSTask *)taskWithDictionaryRepresentation:(NSDictionary *)dict;

- (void)wake;
- (void)enqueueTask:(RCSTask *)task;
- (void)pause;
- (void)resume;
- (void)background;
- (void)foreground;

- (void)enumerateTasksUsingBlock:(void (^)(RCSTask *task, NSUInteger idx, BOOL *stop))block;

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
