//
//  RCSIndexSetIterationContext.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSIndexSetIterationContext.h"
#import "RCSIndexSetIteration.h"

@interface RCSIndexSetIterationContext ()

@property (nonatomic, readwrite, strong) RCSIndexSetIteration *iteration;
@property (nonatomic, readwrite, assign) NSUInteger idx;
@property (nonatomic, readwrite, copy) RCSIndexSetIterationEachBlock eachBlock;
@property (nonatomic, readwrite, copy) RCSIndexSetIterationCompletionBlock completionBlock;
@property (nonatomic, readwrite, copy) RCSIndexSetIterationFailureBlock failureBlock;

@end

@implementation RCSIndexSetIterationContext

@dynamic iteration; // inherit ivar from superclass

- (RCSIndexSetIteration *)iteration
{
    return (RCSIndexSetIteration *)[super iteration];
}

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
              failureBlock:(RCSIndexSetIterationFailureBlock)failureBlock
{
    RCSIndexSetIterationContext *result = [self contextFor:iteration index:index length:length isFirst:first isLast:last isStopped:stopped error:error];
    result->_idx = idx;
    result.eachBlock = eachBlock;
    result.completionBlock = completionBlock;
    result.failureBlock = failureBlock;
    return result;
}

- (instancetype)nextContextWithIndex:(NSUInteger)nextIndex
{
    RCSIndexSetIterationContext *nextContext = [self nextContext];
    nextContext->_idx = nextIndex;
    nextContext.eachBlock = self.eachBlock;
    nextContext.completionBlock = self.completionBlock;
    nextContext.failureBlock = self.failureBlock;
    return nextContext;
}

@end
