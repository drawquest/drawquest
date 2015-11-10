//
//  RCSAsyncOperation.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-10-08.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Example:
 *
 * NSOperationQueue *operationQueue = [NSOperationQueue alloc] init];
 * [operationQueue addOperation:[RCSAsyncOperation execute:^(RCSAsyncOperation *operation) {
 *     // this block is invoked asynchronously (on the main queue if none is specified)
 *     // do something
 *     // when the operation is complete, call -done on operation:
 *     [operation done];
 * }]];
 *
 */
@interface RCSAsyncOperation : NSOperation

@property (nonatomic, copy) void (^executionBlock)(RCSAsyncOperation *operation);
@property (nonatomic, strong) dispatch_queue_t queue;

+ (instancetype)execute:(void (^)(RCSAsyncOperation *operation))block; // onQueue:dispatch_get_main_queue()
+ (instancetype)execute:(void (^)(RCSAsyncOperation *operation))block onQueue:(dispatch_queue_t)queue;

// designated initializer
- (id)initWithExecutionBlock:(void (^)(RCSAsyncOperation *operation))executionBlock onQueue:(dispatch_queue_t)queue;

- (void)done;

@end
