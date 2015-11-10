//
//  RCSAsync.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RCSFailureBlock)(NSError *error);
typedef void (^RCSOperationBlock)(NSOperation *operation);
typedef void (^RCSStringBlock)(NSString *result);
typedef void (^RCSArrayBlock)(NSArray *result);
typedef void (^RCSDictionaryBlock)(NSDictionary *result);

@interface RCSAsync : NSObject

// return a block that dispatches the specified block asynchronously on the specified queue
+ (dispatch_block_t)block:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue;
+ (RCSFailureBlock)failureBlock:(RCSFailureBlock)failureBlock onQueue:(dispatch_queue_t)queue;

// dispatch the specified block to the specified queue, with a result if applicable
+ (void)dispatch:(dispatch_block_t)block toQueue:(dispatch_queue_t)queue;
+ (void)dispatch:(RCSFailureBlock)block withError:(NSError *)error toQueue:(dispatch_queue_t)queue;
+ (void)dispatch:(RCSOperationBlock)block withOperation:(NSOperation *)operation toQueue:(dispatch_queue_t)queue;
+ (void)dispatch:(RCSStringBlock)block withString:(NSString *)result toQueue:(dispatch_queue_t)queue;
+ (void)dispatch:(RCSArrayBlock)block withArray:(NSArray *)result toQueue:(dispatch_queue_t)queue;
+ (void)dispatch:(RCSDictionaryBlock)block withDictionary:(NSDictionary *)result toQueue:(dispatch_queue_t)queue;

@end
