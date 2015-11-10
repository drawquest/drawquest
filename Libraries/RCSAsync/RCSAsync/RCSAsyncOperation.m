//
//  RCSAsyncOperation.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-10-08.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSAsyncOperation.h"

@implementation RCSAsyncOperation
{
    BOOL _executing; // for concurrent NSOperation
    BOOL _finished; // for concurrent NSOperation
}

+ (instancetype)execute:(void (^)(RCSAsyncOperation *operation))block
{
    RCSAsyncOperation *result = [[[self class] alloc] initWithExecutionBlock:block onQueue:NULL];
    return result;
}

+ (instancetype)execute:(void (^)(RCSAsyncOperation *operation))block onQueue:(dispatch_queue_t)queue
{
    RCSAsyncOperation *result = [[[self class] alloc] initWithExecutionBlock:block onQueue:queue];
    return result;
}

- (id)initWithExecutionBlock:(void (^)(RCSAsyncOperation *operation))executionBlock onQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self)
    {
        _executionBlock = [executionBlock copy];
        if (!queue)
        {
            queue = [self defaultQueue];
        }
        _queue = queue;
    }
    return self;
}

- (id)init
{
    self = [self initWithExecutionBlock:nil onQueue:nil];
    return self;
}

- (dispatch_queue_t)defaultQueue
{
    return dispatch_get_main_queue();
}

- (void)setQueue:(dispatch_queue_t)queue
{
    if (!queue)
    {
        queue = [self defaultQueue];
    }
    if (_queue != queue)
    {
        _queue = queue;
    }
}

- (void)start
{
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
    else
    {
        [self main];
    }
}

- (void)main
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    [self execute];
}

- (void)execute
{
    if (self.queue && self.executionBlock)
    {
        dispatch_async(self.queue, ^{
            self.executionBlock(self);
        });
    }
    else
    {
        [self done];
    }
}

#pragma mark -
#pragma mark Completing the operation

- (void)done
{
    [self willChangeValueForKey: @"isFinished"];
    [self willChangeValueForKey: @"isExecuting"];

    _executing = NO;
    _finished = YES;

    [self didChangeValueForKey: @"isExecuting"];
    [self didChangeValueForKey: @"isFinished"];
}

#pragma mark -
#pragma mark Concurrent NSOperation support

- (BOOL) isConcurrent { return YES; }
- (BOOL) isExecuting { return _executing; }
- (BOOL) isFinished  { return _finished; }

@end
