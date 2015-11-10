//
//  RCSAsync.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSAsync.h"

@implementation RCSAsync

+ (dispatch_block_t)block:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
{
    dispatch_block_t result = nil;
    if (block)
    {
        result = ^{
            dispatch_async(queue, block);
        };
    }
    return result;
}

+ (RCSFailureBlock)failureBlock:(RCSFailureBlock)failureBlock onQueue:(dispatch_queue_t)queue
{
    RCSFailureBlock result = nil;
    if (failureBlock)
    {
        result = ^(NSError *error) {
            dispatch_async(queue, ^{
                failureBlock(error);
            });
        };
    }
    return result;
}

+ (void)dispatch:(dispatch_block_t)block toQueue:(dispatch_queue_t)queue
{
    if (queue && block)
    {
        dispatch_async(queue, block);
    }
    else if (!queue)
    {
        NSLog(@"had a dispatch_block_t to dispatch but no queue to dispatch it to!");
    }
}

+ (void)dispatch:(RCSFailureBlock)block withError:(NSError *)error toQueue:(dispatch_queue_t)queue
{
    if (queue && block)
    {
        dispatch_async(queue, ^{
            block(error);
        });
    }
    else if (!queue)
    {
        NSLog(@"had a RCSFailureBlock to dispatch but no queue to dispatch it to!");
    }
}

+ (void)dispatch:(RCSOperationBlock)block withOperation:(NSOperation *)operation toQueue:(dispatch_queue_t)queue
{
    if (queue && block)
    {
        dispatch_async(queue, ^{
            block(operation);
        });
    }
    else if (!queue)
    {
        NSLog(@"had a RCSOperationBlock to dispatch but no queue to dispatch it to!");
    }
}

+ (void)dispatch:(RCSStringBlock)block withString:(NSString *)result toQueue:(dispatch_queue_t)queue
{
    if (queue && block)
    {
        dispatch_async(queue, ^{
            block(result);
        });
    }
    else if (!queue)
    {
        NSLog(@"had a RCSStringBlock to dispatch but no queue to dispatch it to!");
    }
}

+ (void)dispatch:(RCSArrayBlock)block withArray:(NSArray *)result toQueue:(dispatch_queue_t)queue
{
    if (queue && block)
    {
        dispatch_async(queue, ^{
            block(result);
        });
    }
    else if (!queue)
    {
        NSLog(@"had a RCSArrayBlock to dispatch but no queue to dispatch it to!");
    }
}

+ (void)dispatch:(RCSDictionaryBlock)block withDictionary:(NSDictionary *)result toQueue:(dispatch_queue_t)queue
{
    if (queue && block)
    {
        dispatch_async(queue, ^{
            block(result);
        });
    }
    else if (!queue)
    {
        NSLog(@"had a RCSDictionaryBlock to dispatch but no queue to dispatch it to!");
    }
}

@end
