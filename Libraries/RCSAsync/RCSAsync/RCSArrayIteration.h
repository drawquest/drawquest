//
//  RCSArrayIteration.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSIteration.h"
#import "RCSArrayIterationContextBlocks.h"

@class RCSArrayIterationContext;

@interface RCSArrayIteration : RCSIteration

+ (instancetype)iterationWithObjects:(NSArray *)indexes toQueue:(dispatch_queue_t)queue;

// designated initializer
- (id)initWithObjects:(NSArray *)objects toQueue:(dispatch_queue_t)queue;

- (instancetype)eachObject:(RCSArrayIterationEachBlock)eachBlock
                      done:(RCSArrayIterationCompletionBlock)completionBlock
                    failed:(RCSArrayIterationFailureBlock)failureBlock;

// these methods should only be called by contexts
// TODO: move these methods into a category
- (instancetype)next:(RCSArrayIterationContext *)context;
- (instancetype)stop:(RCSArrayIterationContext *)context;
- (instancetype)failed:(RCSArrayIterationContext *)context withError:(NSError *)error;

@end
