//
//  RCSIteration.m
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSIteration.h"

@implementation RCSIteration
{
    dispatch_queue_t _queue;
}

- (id)initToQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self)
    {
        _queue = queue ? queue : dispatch_get_main_queue();
    }
    return self;
}

- (instancetype)next:(RCSIterationContext *)context
{
    return self;
}

- (instancetype)stop:(RCSIterationContext *)context
{
    return self;
}

- (instancetype)failed:(RCSIterationContext *)context withError:(NSError *)error
{
    return self;
}

@end
