//
//  RCSArrayIterationContext.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSIterationContext.h"
#import "RCSArrayIteration.h"
#import "RCSArrayIterationContextBlocks.h"

@interface RCSArrayIterationContext : RCSIterationContext

// the iteration doesn't retain the context, rather, the other way around
// this way the iteration doesn't have to be retained throughout the process,
// meaning there's no cleanup for it, and there's no retain loop
@property (nonatomic, readonly, strong) RCSArrayIteration *iteration;
@property (nonatomic, readonly, weak) id object;
@property (nonatomic, readonly, copy) RCSArrayIterationEachBlock eachBlock;
@property (nonatomic, readonly, copy) RCSArrayIterationCompletionBlock completionBlock;
@property (nonatomic, readonly, copy) RCSArrayIterationFailureBlock failureBlock;

#pragma mark -
#pragma mark Should only be called by the iteration
// TODO: make a category for these

+ (instancetype)contextFor:(RCSArrayIteration *)iteration
                     index:(NSUInteger)index
                    length:(NSUInteger)length
                    object:(id)object
                   isFirst:(BOOL)first
                    isLast:(BOOL)last
                 isStopped:(BOOL)stopped
                     error:(NSError *)error
                 eachBlock:(RCSArrayIterationEachBlock)eachBlock
           completionBlock:(RCSArrayIterationCompletionBlock)completionBlock
              failureBlock:(RCSArrayIterationFailureBlock)failureBlock;
- (instancetype)nextContextWithObject:(id)nextObject;

@end
