//
//  RCSTask.m
//  Created by Jim Roepcke.
//  See license below.
//

#import "RCSTask.h"

@interface RCSTaskState (Transitions)

- (void)error:(RCSTask *)task;
- (void)dqCancelTask:(RCSTask *)task;
- (void)start:(RCSTask *)task;
- (void)wake:(RCSTask *)task;

- (void)pause:(RCSTask *)task;
- (void)resumeTask:(RCSTask *)task;

- (void)foreground:(RCSTask *)task;
- (void)background:(RCSTask *)task;

@end

@interface RCSTask ()

@property (nonatomic, readonly, assign) NSUInteger maximumNumberOfAttempts;
@property (nonatomic, readonly, assign) NSUInteger numberOfAttempts;

@end

@implementation RCSTask
{
    NSString *_taskID;
    id<RCSTaskDelegate> __weak _delegate;
    RCSTaskState __weak *_state;
    NSUInteger _maximumNumberOfAttempts;
    NSUInteger _numberOfAttempts;
}

@synthesize taskID = _taskID;
@synthesize delegate = _delegate;

+ (void)initialize
{
    if (self == [RCSTask class])
    {
        id<RCSState> Base = [RCSTaskState state];
        id<RCSState> Error = [Base declareErrorState:[Base stateNamed:@"Error"]];
        id<RCSState> Cancelled = [Base stateNamed:@"Cancelled"];
        [Base declareStartState:[Base stateNamed:@"Start"]];

        [Base when:@selector(error:) transitionTo:Error];
        [Base when:@selector(dqCancelTask:) transitionTo:Cancelled];
        [Base transitionToErrorStateWhen:@selector(start:)];
        [Base doNothingWhen:@selector(wake:)];
        [Base transitionToErrorStateWhen:@selector(pause:)];
        [Base transitionToErrorStateWhen:@selector(resumeTask:)];
        [Base doNothingWhen:@selector(foreground:)];
        [Base doNothingWhen:@selector(background:)];

        [Cancelled whenEnteringPerform:@selector(_cancelled)];
    }
}

- (void)dealloc
{
    _delegate = nil;
    _state = nil;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _taskID = [[self __uuidString] copy];
        _state = [[RCSTaskState state] startState];
        _maximumNumberOfAttempts = 5;
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _taskID = [[dict objectForKey:@"taskID"] copy];
        Class stateClass = NSClassFromString([dict objectForKey:@"state"]);
        _state = (RCSTaskState *)[stateClass state];
        _maximumNumberOfAttempts = 5; // don't restore, in case this has changed between versions
        // don't restore numberOfAttempts, effectively resetting it to zero
    }
    return self;
}

- (NSMutableDictionary *)mutableDictionaryRepresentation
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject:NSStringFromClass([self class]) forKey:@"class"];
    [result setObject:_taskID forKey:@"taskID"];
    [result setObject:NSStringFromClass([_state class]) forKey:@"state"];
    [result setObject:@(_maximumNumberOfAttempts) forKey:@"maximumNumberOfAttempts"];
    [result setObject:@(_numberOfAttempts) forKey:@"numberOfAttempts"];
    return result;
}

- (NSString *)__uuidString
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *result = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return result;
}

- (void)cancel
{
    [self.state dqCancelTask:self];
}

- (void)start
{
    [self.state start:self];
}

- (void)wake
{
    [self.state wake:self];
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

- (void)_stateContextDidEnterErrorState
{
    // this is called when the Error state is entered
    // FIXME: add logging here
}

- (void)_cancelled
{
    [self.delegate taskCancelled:self];
}

- (void)_completed
{
    [self.delegate taskCompleted:self];
}

- (BOOL)_mayReattempt
{
    return self.numberOfAttempts < self.maximumNumberOfAttempts;
}

- (void)_markAttempt
{
    _numberOfAttempts++;
}

- (void)_clearAttempts
{
    _numberOfAttempts = 0;
}

- (void)_exhaustedAttempts
{
    [self _clearAttempts];
    [self.delegate taskExhaustedAttempts:self];
}

- (void)_retryUsingBlock:(dispatch_block_t)block
{
    if (block)
    {
        if ([self _mayReattempt])
        {
            [self _markAttempt];
            block();
        }
        else
        {
            [self _exhaustedAttempts];
        }
    }
}

@end

@implementation RCSTaskState

+ (RCSTaskState *)state
{
    return (RCSTaskState *)[super state];
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
