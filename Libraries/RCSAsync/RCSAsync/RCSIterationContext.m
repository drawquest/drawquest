//
//  RCSIterationContext.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSIterationContext.h"
#import "RCSIteration.h"

@interface RCSIterationContext ()

@property (nonatomic, readwrite, strong) RCSIteration *iteration;
@property (nonatomic, readwrite, assign) NSUInteger index;
@property (nonatomic, readwrite, assign) NSUInteger length;
@property (nonatomic, readwrite, assign, getter = isFirst) BOOL first;
@property (nonatomic, readwrite, assign, getter = isLast) BOOL last;
@property (nonatomic, readwrite, assign, getter = isStopped)  BOOL stopped;
@property (nonatomic, readwrite, strong) NSError *error;

@end

@implementation RCSIterationContext

- (instancetype)next
{
    // TODO: keep track of the fact next was called, don't let it be called twice
    [self.iteration next:self];
    return self;
}

- (instancetype)stop
{
    // TODO: keep track of the fact stop was called, don't let it be called twice
    [self.iteration stop:self];
    return self;
}

- (instancetype)failed:(NSError *)error
{
    // TODO: keep track of the fact failed: was called, don't let it be called twice
    [self.iteration failed:self withError:error];
    return self;
}

+ (instancetype)contextFor:(RCSIteration *)iteration
                     index:(NSUInteger)index
                    length:(NSUInteger)length
                   isFirst:(BOOL)first
                    isLast:(BOOL)last
                 isStopped:(BOOL)stopped
                     error:(NSError *)error
{
    RCSIterationContext *result = [[self alloc] init];
    result.iteration = iteration;
    result.index = index;
    result.length = length;
    result.first = first;
    result.last = last;
    result.stopped = stopped;
    result.error = error;
    return result;
}

- (instancetype)nextContext
{
    RCSIterationContext *nextContext = [[[self class] alloc] init];
    nextContext.iteration = self.iteration;
    nextContext.index = self.index + 1;
    nextContext.length = self.length;
    nextContext.first = NO;
    nextContext.last = self.index + 2 == self.length;
    nextContext.stopped = NO;
    nextContext.error = nil;
    return nextContext;
}

@end
