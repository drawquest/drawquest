//
//  RCSIndexSetIterationContextBlocks.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

@class RCSIndexSetIterationContext;

typedef void (^RCSIndexSetIterationEachBlock)(NSUInteger idx, RCSIndexSetIterationContext *context);
typedef void (^RCSIndexSetIterationCompletionBlock)(RCSIndexSetIterationContext *context);
typedef void (^RCSIndexSetIterationFailureBlock)(NSError *error, RCSIndexSetIterationContext *context);
