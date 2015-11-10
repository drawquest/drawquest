//
//  RCSIndexSetIterationContext.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSIterationContext.h"
#import "RCSIndexSetIterationContextBlocks.h"
#import "RCSIndexSetIteration.h"

@interface RCSIndexSetIterationContext : RCSIterationContext

// the iteration doesn't retain the context, rather, the other way around
// this way the iteration doesn't have to be retained throughout the process,
// meaning there's no cleanup for it, and there's no retain loop
@property (nonatomic, readonly, strong) RCSIndexSetIteration *iteration;
@property (nonatomic, readonly, assign) NSUInteger idx;
@property (nonatomic, readonly, copy) RCSIndexSetIterationEachBlock eachBlock;
@property (nonatomic, readonly, copy) RCSIndexSetIterationCompletionBlock completionBlock;
@property (nonatomic, readonly, copy) RCSIndexSetIterationFailureBlock failureBlock;

#pragma mark -
#pragma mark Should only be called by the iteration
// TODO: make a category for these

+ (instancetype)contextFor:(RCSIndexSetIteration *)iteration
                     index:(NSUInteger)index
                    length:(NSUInteger)length
                       idx:(NSUInteger)idx
                   isFirst:(BOOL)first
                    isLast:(BOOL)last
                 isStopped:(BOOL)stopped
                     error:(NSError *)error
                 eachBlock:(RCSIndexSetIterationEachBlock)eachBlock
           completionBlock:(RCSIndexSetIterationCompletionBlock)completionBlock
              failureBlock:(RCSIndexSetIterationFailureBlock)failureBlock;
- (instancetype)nextContextWithIndex:(NSUInteger)nextIndex;

@end
