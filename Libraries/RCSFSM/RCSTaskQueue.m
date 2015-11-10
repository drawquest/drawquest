//
//  RCSTaskQueue.m
//  Created by Jim Roepcke.
//  See license below.
//

#import "RCSTaskQueue.h"

@interface RCSTaskQueueState (Transitions)

- (void)wake:(RCSTaskQueue *)taskQueue;

- (void)taskQueue:(RCSTaskQueue *)taskQueue enqueueTask:(RCSTask *)task;

- (void)taskQueue:(RCSTaskQueue *)taskQueue taskCancelled:(RCSTask *)task;

- (void)taskQueue:(RCSTaskQueue *)taskQueue dequeueTask:(RCSTask *)task;

- (void)empty:(RCSTaskQueue *)taskQueue;

- (void)pause:(RCSTaskQueue *)taskQueue;
- (void)resumeTask:(RCSTaskQueue *)taskQueue;

- (void)background:(RCSTaskQueue *)taskQueue;
- (void)foreground:(RCSTaskQueue *)taskQueue;

@end

@implementation RCSTaskQueue
{
    // these ivars back properties
    id<RCSTaskQueueDelegate> __weak _delegate;
    RCSTaskQueueState __weak *_state;

    // these ivars do not back properties
    NSMutableArray *_tasks;
    RCSTask *_currentTask;
}

@synthesize delegate = _delegate;
@synthesize state = _state;
@dynamic numberOfTasks;
@dynamic tasks;

- (void)dealloc
{
    _delegate = nil;
    _state = nil;
    _tasks = nil;
    _currentTask = nil;
}

+ (void)initialize
{
    if (self == [RCSTaskQueue class])
    {
        id<RCSState> Base = [RCSTaskQueueState state];
        id<RCSState> Empty = [Base stateNamed:@"Empty"];
        id<RCSState> NotEmpty = [Base stateNamed:@"NotEmpty"];
        id<RCSState> PausedEmpty = [Base stateNamed:@"PausedEmpty"];
        id<RCSState> PausedNotEmpty = [Base stateNamed:@"PausedNotEmpty"];
        id<RCSState> BackgroundedNotEmpty = [Base stateNamed:@"BackgroundedNotEmpty"];

        SEL taskQueueEnqueueTask = [Base transitionToErrorStateWhen:@selector(taskQueue:enqueueTask:)];
        SEL taskQueueTaskCancelled = [Base transitionToErrorStateWhen:@selector(taskQueue:taskCancelled:)];
        SEL taskQueueDequeueTask = [Base transitionToErrorStateWhen:@selector(taskQueue:dequeueTask:)];
        SEL empty = [Base transitionToErrorStateWhen:@selector(empty:)];
        SEL pause = [Base transitionToErrorStateWhen:@selector(pause:)];
        SEL resume = [Base transitionToErrorStateWhen:@selector(resumeTask:)];
        SEL background = [Base doNothingWhen:@selector(background:)];
        SEL foreground = [Base doNothingWhen:@selector(foreground:)];
        SEL wake = [Base when:@selector(wake:) perform:@selector(_wake)];

        [Empty when:taskQueueEnqueueTask transitionTo:NotEmpty before:@selector(_start) after:@selector(_enqueueTask:)];
        [Empty when:pause transitionTo:PausedEmpty];

        [PausedEmpty when:taskQueueEnqueueTask transitionTo:PausedNotEmpty after:@selector(_enqueueTask:)];
        [PausedEmpty when:resume transitionTo:Empty];

        [NotEmpty when:empty transitionTo:Empty];
        [NotEmpty when:taskQueueEnqueueTask perform:@selector(_enqueueTask)];
        [NotEmpty when:taskQueueTaskCancelled perform:@selector(_taskCancelled:)];
        [NotEmpty when:taskQueueDequeueTask perform:@selector(_dequeue)];
        [NotEmpty when:pause transitionTo:PausedNotEmpty after:@selector(_pause)];
        [NotEmpty when:background transitionTo:BackgroundedNotEmpty after:@selector(_background)];

        [PausedNotEmpty when:empty transitionTo:PausedEmpty];
        [PausedNotEmpty when:taskQueueEnqueueTask perform:@selector(_enqueueTask:)];
        [PausedNotEmpty when:taskQueueTaskCancelled perform:@selector(_taskCancelled:)];
        [PausedNotEmpty when:resume transitionTo:NotEmpty before:@selector(_resume)];

        [BackgroundedNotEmpty when:wake transitionTo:NotEmpty before:@selector(_wake)];
        [BackgroundedNotEmpty when:foreground transitionTo:NotEmpty before:@selector(_foreground)];
    }
}

- (id)initWithDelegate:(id<RCSTaskQueueDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _delegate = delegate;
        _state = [[RCSTaskQueueState state] startState];
        _tasks = [NSMutableArray new];
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict delegate:(id<RCSTaskQueueDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _delegate = delegate;
        Class stateClass = NSClassFromString([dict objectForKey:@"state"]);
        _state = (RCSTaskQueueState *)[stateClass state];
        _tasks = [NSMutableArray new];
        NSArray *tasks = [dict objectForKey:@"tasks"];
        for (NSDictionary *taskDict in tasks)
        {
            RCSTask *task = [self taskWithDictionaryRepresentation:taskDict];
            [_tasks addObject:task];
            task.delegate = self;
        }
        NSString *currentTaskTaskID = [dict objectForKey:@"currentTaskTaskID"];
        if (currentTaskTaskID)
        {
            NSUInteger idx = [_tasks indexOfObjectPassingTest:^BOOL(RCSTask *task, NSUInteger idx, BOOL *stop) {
                if ([task.taskID isEqualToString:currentTaskTaskID])
                {
                    *stop = YES;
                    return YES;
                }
                return NO;
            }];
            if (idx == NSNotFound)
            {
                NSLog(@"didn't find currentTask");
                NSLog(@"didn't find currentTask");
            }
            else
            {
                _currentTask = [_tasks objectAtIndex:idx];
            }
        }
    }
    return self;
}

- (NSMutableDictionary *)mutableDictionaryRepresentation
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject:NSStringFromClass([self class]) forKey:@"class"];
    [result setObject:NSStringFromClass([_state class]) forKey:@"state"];
    NSMutableArray *tasks = [NSMutableArray array];
    for (RCSTask *task in _tasks)
    {
        [tasks addObject:[task mutableDictionaryRepresentation]];
    }
    [result setObject:tasks forKey:@"tasks"];
    if (_currentTask)
    {
        [result setObject:_currentTask.taskID forKey:@"currentTaskTaskID"];
    }
    return result;
}

- (RCSTask *)taskWithDictionaryRepresentation:(NSDictionary *)dict
{
    return nil;
}

#pragma mark -
#pragma mark RCSTaskDelegate methods

- (void)taskCancelled:(RCSTask *)task
{
    [self.state taskQueue:self taskCancelled:task];
    [self.delegate taskQueue:self didCancelTask:task];
}

- (void)taskCompleted:(RCSTask *)task
{
    [self.state taskQueue:self dequeueTask:task];
    [self.delegate taskQueue:self didCompleteTask:task];
}

- (void)taskExhaustedAttempts:(RCSTask *)task
{
    [self.state pause:self];
    [self.delegate taskQueueDidPauseDueToExhaustedAttempts:self];
}

#pragma mark -
#pragma mark Public API

- (NSUInteger)numberOfTasks
{
    return [_tasks count];
}

- (NSArray *)tasks
{
    return [NSArray arrayWithArray:_tasks];
}

- (void)wake
{
    [self.state wake:self];
}

- (void)enqueueTask:(RCSTask *)task
{
    [self.state taskQueue:self enqueueTask:task];
}

- (void)pause
{
    [self.state pause:self];
}

- (void)resume
{
    [self.state resumeTask:self];
}

- (void)background
{
    [self.state background:self];
}

- (void)foreground
{
    [self.state foreground:self];
}

- (void)enumerateTasksUsingBlock:(void (^)(RCSTask *task, NSUInteger idx, BOOL *stop))block
{
    if (block)
    {
        [_tasks enumerateObjectsUsingBlock:^(RCSTask *task, NSUInteger idx, BOOL *stop) {
            block(task, idx, stop);
        }];
    }
}

- (void)_stateContextDidEnterErrorState
{
    // this is called when the Error state is entered
    // FIXME: add logging here
}

@end

@implementation RCSTaskQueue (RCSTaskQueueStatePrivate)

- (RCSTask *)_head
{
    return [_tasks count] ? [_tasks objectAtIndex:0] : nil;
}

- (void)_wake
{
    for (RCSTask *task in _tasks)
    {
        [task wake];
    }
}

- (void)_enqueueTask:(RCSTask *)task
{
    [task pause];
    [_tasks addObject:task];
    task.delegate = self;
}

- (void)_start
{
    _currentTask = [self _head];
    [_currentTask resume];
    [_currentTask start];
}

- (void)_pause
{
    for (RCSTask *task in _tasks)
    {
        [task pause];
    }
}

- (void)_resume
{
    for (RCSTask *task in _tasks)
    {
        [task resume];
    }
}

- (void)_background
{
    for (RCSTask *task in _tasks)
    {
        [task background];
    }
}

- (void)_foreground
{
    for (RCSTask *task in _tasks)
    {
        [task foreground];
    }
}

- (void)_taskCancelled:(RCSTask *)task
{
    BOOL cancelledHead = task == _currentTask;
    [self _removeTask:task];
    if (cancelledHead)
    {
        [self _start];
    }
    if ([self _isEmpty])
    {
        [self.state empty:self];
    }
}

- (BOOL)_isEmpty
{
    return [_tasks count] == 0;
}

- (void)_removeTask:(RCSTask *)task
{
    [_tasks removeObjectIdenticalTo:task];
    if (task.delegate == self)
    {
        task.delegate = nil;
    }
    if (task == _currentTask)
    {
         _currentTask = nil;
    }
}

- (void)_dequeue
{
    [self _removeTask:[self _head]];
    if ([self _isEmpty])
    {
        [self.state empty:self];
    }
    else
    {
        [self _start];
    }
}

@end

@implementation RCSTaskQueueState

+ (RCSTaskQueueState *)state
{
    return (RCSTaskQueueState *)[super state];
}

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
