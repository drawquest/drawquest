//
//  RCSArrayIterationContext.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSArrayIterationContext.h"

@interface RCSArrayIterationContext ()

@property (nonatomic, readwrite, strong) RCSArrayIteration *iteration;
@property (nonatomic, readwrite, weak) id object;
@property (nonatomic, readwrite, copy) RCSArrayIterationEachBlock eachBlock;
@property (nonatomic, readwrite, copy) RCSArrayIterationCompletionBlock completionBlock;
@property (nonatomic, readwrite, copy) RCSArrayIterationFailureBlock failureBlock;

@end

@implementation RCSArrayIterationContext

@dynamic iteration; // inherit ivar from superclass

- (RCSArrayIteration *)iteration
{
    return (RCSArrayIteration *)[super iteration];
}

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
              failureBlock:(RCSArrayIterationFailureBlock)failureBlock
{
    RCSArrayIterationContext *result = [self contextFor:iteration index:index length:length isFirst:first isLast:last isStopped:stopped error:error];
    result.object = object;
    result.eachBlock = eachBlock;
    result.completionBlock = completionBlock;
    result.failureBlock = failureBlock;
    return result;
}

- (instancetype)nextContextWithObject:(id)nextObject
{
    RCSArrayIterationContext *nextContext = [self nextContext];
    nextContext.object = nextObject;
    nextContext.eachBlock = self.eachBlock;
    nextContext.completionBlock = self.completionBlock;
    nextContext.failureBlock = self.failureBlock;
    return nextContext;
}

@end
