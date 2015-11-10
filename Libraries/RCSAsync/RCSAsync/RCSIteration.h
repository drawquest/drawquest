//
//  RCSIteration.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSIterationContext.h"

@interface RCSIteration : NSObject

@property (nonatomic, readonly, strong) dispatch_queue_t queue;

- (id)initToQueue:(dispatch_queue_t)queue;

- (instancetype)next:(RCSIterationContext *)context;
- (instancetype)stop:(RCSIterationContext *)context;
- (instancetype)failed:(RCSIterationContext *)context withError:(NSError *)error;

@end
