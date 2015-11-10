//
//  RCSIterationContext.h
//  RCSAsync
//
//  Created by Jim Roepcke on 2012-09-18.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCSIteration;
@class RCSIterationContext;

@interface RCSIterationContext : NSObject

// the iteration doesn't retain the context, rather, the other way around
// this way the iteration doesn't have to be retained throughout the process,
// meaning there's no cleanup for it, and there's no retain loop
@property (nonatomic, readonly, strong) RCSIteration *iteration;
@property (nonatomic, readonly, assign) NSUInteger index;
@property (nonatomic, readonly, assign) NSUInteger length;
@property (nonatomic, readonly, assign, getter = isFirst) BOOL first;
@property (nonatomic, readonly, assign, getter = isLast) BOOL last;
@property (nonatomic, readonly, assign, getter = isStopped)  BOOL stopped;
@property (nonatomic, readonly, strong) NSError *error;

- (instancetype)next;
- (instancetype)stop;
- (instancetype)failed:(NSError *)error;

#pragma mark -
#pragma mark Should only be called by the iteration
// TODO: make a category for these

+ (instancetype)contextFor:(RCSIteration *)iteration
                     index:(NSUInteger)index
                    length:(NSUInteger)length
                   isFirst:(BOOL)first
                    isLast:(BOOL)last
                 isStopped:(BOOL)stopped
                     error:(NSError *)error;
- (instancetype)nextContext;

@end
