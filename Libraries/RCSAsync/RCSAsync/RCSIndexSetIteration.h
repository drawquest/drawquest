//
//  RCSIndexSetIteration.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSIteration.h"
#import "RCSIndexSetIterationContextBlocks.h"

@class RCSIndexSetIterationContext;

@interface RCSIndexSetIteration : RCSIteration

+ (instancetype)iterationWithIndexes:(NSIndexSet *)indexes toQueue:(dispatch_queue_t)queue;

// designated initializer
- (id)initWithIndexes:(NSIndexSet *)indexes toQueue:(dispatch_queue_t)queue;

- (instancetype)eachIndex:(RCSIndexSetIterationEachBlock)foreach
                     done:(RCSIndexSetIterationCompletionBlock)completionBlock
                   failed:(RCSIndexSetIterationFailureBlock)failureBlock;

// these methods should only be called by contexts
// TODO: move these methods into a category
- (instancetype)next:(RCSIndexSetIterationContext *)context;
- (instancetype)stop:(RCSIndexSetIterationContext *)context;
- (instancetype)failed:(RCSIndexSetIterationContext *)context withError:(NSError *)error;

@end
