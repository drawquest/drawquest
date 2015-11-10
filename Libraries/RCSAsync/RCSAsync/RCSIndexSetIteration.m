//
//  RCSIndexSetIteration.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSIndexSetIteration.h"
#import "RCSIndexSetIterationContext.h"

@implementation RCSIndexSetIteration
{
    NSIndexSet *_indexes;
}

- (id)initWithIndexes:(NSIndexSet *)indexes toQueue:(dispatch_queue_t)queue
{
    self = [super initToQueue:queue];
    if (self)
    {
        _indexes = [indexes copy];
    }
    return self;
}

+ (instancetype)iterationWithIndexes:(NSIndexSet *)indexes toQueue: (dispatch_queue_t)queue
{
    return [[[self class] alloc] initWithIndexes:indexes toQueue:queue];
}

- (instancetype)eachIndex:(RCSIndexSetIterationEachBlock)eachBlock
                     done:(RCSIndexSetIterationCompletionBlock)completionBlock
                   failed:(RCSIndexSetIterationFailureBlock)failureBlock
{
    NSUInteger ct = [_indexes count];
    if (ct)
    {
        NSUInteger firstIndex = [_indexes firstIndex];
        if (eachBlock)
        {
            dispatch_async(self.queue, ^{
                eachBlock(firstIndex, [RCSIndexSetIterationContext contextFor:self
                                                                        index:0
                                                                       length:ct
                                                                          idx:firstIndex
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
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"called eachIndex:done:failed: with a nil eachBlock" userInfo:nil];
        }
    }
    else
    {
        if (completionBlock)
        {
            dispatch_async(self.queue, ^{
                completionBlock([self completionContextForNullSetWithEachBlock:eachBlock
                                                               completionBlock:completionBlock
                                                                  failureBlock:failureBlock]); // TODO: @try
            });
        }
    }
    return self;
}

- (instancetype)next:(RCSIndexSetIterationContext *)context
{
    if (context.stopped)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"called next: on a stopped index set iteration" userInfo:nil];
    }
    else
    {
        if (context.last)
        {
            if (context.completionBlock)
            {
                dispatch_async(self.queue, ^{
                    context.completionBlock([RCSIndexSetIterationContext contextFor:self
                                                                              index:NSNotFound
                                                                             length:context.length
                                                                                idx:NSNotFound
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
                    NSUInteger nextIndex = [_indexes indexGreaterThanIndex:context.idx];
                    context.eachBlock(nextIndex, [context nextContextWithIndex:nextIndex]); // TODO: @try
                });
            }
        }
    }
    return self;
}

- (instancetype)stop:(RCSIndexSetIterationContext *)context
{
    if (context.completionBlock)
    {
        dispatch_async(self.queue, ^{
            context.completionBlock([RCSIndexSetIterationContext contextFor:self
                                                                      index:context.index
                                                                     length:context.length
                                                                        idx:context.idx
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

- (instancetype)failed:(RCSIndexSetIterationContext *)context withError:(NSError *)error
{
    if (context.failureBlock)
    {
        dispatch_async(self.queue, ^{
            context.failureBlock(error, [RCSIndexSetIterationContext contextFor:self
                                                                          index:context.index
                                                                         length:context.length
                                                                            idx:context.idx
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

- (RCSIndexSetIterationContext *)completionContextForNullSetWithEachBlock:(RCSIndexSetIterationEachBlock)eachBlock
                                                          completionBlock:(RCSIndexSetIterationCompletionBlock)completionBlock
                                                             failureBlock:(RCSIndexSetIterationFailureBlock)failureBlock
{
    return [RCSIndexSetIterationContext contextFor:self
                                             index:NSNotFound
                                            length:0
                                               idx:NSNotFound
                                           isFirst:YES
                                            isLast:YES
                                         isStopped:NO
                                             error:nil
                                         eachBlock:eachBlock
                                   completionBlock:completionBlock
                                      failureBlock:failureBlock];
}

@end
