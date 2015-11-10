//
//  RCSArrayIteration.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSArrayIteration.h"
#import "RCSArrayIterationContext.h"

@implementation RCSArrayIteration
{
    NSArray *_objects;
}

- (id)initWithObjects:(NSArray *)objects toQueue:(dispatch_queue_t)queue
{
    self = [super initToQueue:queue];
    if (self)
    {
        _objects = [objects copy];
    }
    return self;
}

+ (instancetype)iterationWithObjects:(NSArray *)objects toQueue: (dispatch_queue_t)queue
{
    return [[[self class] alloc] initWithObjects:objects toQueue:queue];
}

- (instancetype)eachObject:(RCSArrayIterationEachBlock)eachBlock
                      done:(RCSArrayIterationCompletionBlock)completionBlock
                    failed:(RCSArrayIterationFailureBlock)failureBlock
{
    NSUInteger ct = [_objects count];
    if (ct)
    {
        id firstObject = [_objects objectAtIndex:0];
        if (eachBlock)
        {
            dispatch_async(self.queue, ^{
                eachBlock(firstObject, [RCSArrayIterationContext contextFor:self
                                                                      index:0
                                                                     length:ct
                                                                     object:firstObject
                                                                    isFirst:YES
                                                                     isLast:ct==1
                                                                  isStopped:NO
                                                                      error:nil
                                                                  eachBlock:eachBlock
                                                            completionBlock:completionBlock
                                                               failureBlock:failureBlock]); // TODO: @try
            });
        }
        else
        {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"called eachObject:done:failed: with a nil eachBlock" userInfo:nil];
        }
    }
    else
    {
        if (completionBlock)
        {
            dispatch_async(self.queue, ^{
                completionBlock([self completionContextForEmptyArrayWithEachBlock:eachBlock
                                                                  completionBlock:completionBlock
                                                                     failureBlock:failureBlock]); // TODO: @try
            });
        }
    }
    return self;
}

- (instancetype)next:(RCSArrayIterationContext *)context
{
    if (context.stopped)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"called next: on a stopped array iteration" userInfo:nil];
    }
    else
    {
        if (context.last)
        {
            if (context.completionBlock)
            {
                dispatch_async(self.queue, ^{
                    context.completionBlock([RCSArrayIterationContext contextFor:self
                                                                           index:NSNotFound
                                                                          length:context.length
                                                                          object:nil
                                                                         isFirst:context.first
                                                                          isLast:context.last
                                                                       isStopped:NO
                                                                           error:nil
                                                                       eachBlock:context.eachBlock
                                                                 completionBlock:context.completionBlock
                                                                    failureBlock:context.failureBlock]); // TODO: @try
                });
            }
        }
        else
        {
            if (context.eachBlock) // must be true or we wouldn't be here, but check anyway
            {
                dispatch_async(self.queue, ^{
                    id nextObject = [_objects objectAtIndex:context.index + 1];
                    context.eachBlock(nextObject, [context nextContextWithObject:nextObject]); // TODO: @try
                });
            }
        }
    }
    return self;
}

- (instancetype)stop:(RCSArrayIterationContext *)context
{
    if (context.completionBlock)
    {
        dispatch_async(self.queue, ^{
            context.completionBlock([RCSArrayIterationContext contextFor:self
                                                                   index:context.index
                                                                  length:context.length
                                                                  object:context.object
                                                                 isFirst:context.first
                                                                  isLast:context.last
                                                               isStopped:YES
                                                                   error:nil
                                                               eachBlock:context.eachBlock
                                                         completionBlock:context.completionBlock
                                                            failureBlock:context.failureBlock]); // TODO: @try
        });
    }
    else
    {
        // TODO: implement
    }
    return self;
}

- (instancetype)failed:(RCSArrayIterationContext *)context withError:(NSError *)error
{
    if (context.failureBlock)
    {
        dispatch_async(self.queue, ^{
            context.failureBlock(error, [RCSArrayIterationContext contextFor:self
                                                                       index:context.index
                                                                      length:context.length
                                                                      object:context.object
                                                                     isFirst:context.first
                                                                      isLast:context.last
                                                                   isStopped:context.stopped
                                                                       error:error
                                                                   eachBlock:context.eachBlock
                                                             completionBlock:context.completionBlock
                                                                failureBlock:context.failureBlock]);
        });
    }
    else
    {
        // TODO: implement
    }
    return self;
}

- (RCSArrayIterationContext *)completionContextForEmptyArrayWithEachBlock:(RCSArrayIterationEachBlock)eachBlock
                                                          completionBlock:(RCSArrayIterationCompletionBlock)completionBlock
                                                             failureBlock:(RCSArrayIterationFailureBlock)failureBlock
{
    return [RCSArrayIterationContext contextFor:self
                                          index:NSNotFound
                                         length:0
                                         object:nil
                                        isFirst:YES
                                         isLast:YES
                                      isStopped:NO
                                          error:nil
                                      eachBlock:eachBlock
                                completionBlock:completionBlock
                                   failureBlock:failureBlock];
}


@end
