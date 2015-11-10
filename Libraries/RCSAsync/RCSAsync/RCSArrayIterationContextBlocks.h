//
//  RCSArrayIterationContextBlocks.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

@class RCSArrayIterationContext;

typedef void (^RCSArrayIterationEachBlock)(id object, RCSArrayIterationContext *context);
typedef void (^RCSArrayIterationCompletionBlock)(RCSArrayIterationContext *context);
typedef void (^RCSArrayIterationFailureBlock)(NSError *error, RCSArrayIterationContext *context);
