//
//  RCSAsyncTests.m
//  RCSAsyncTests
//
//  Created by Jim Roepcke on 2012-09-16.
//  Copyright (c) 2012 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSAsyncTests.h"
#import "RCSAsync.h"
#import "RCSIndexSetIteration.h"
#import "RCSArrayIteration.h"
#import "RCSAsyncOperation.h"
#import "RCSIndexSetIterationContext.h"
#import "RCSArrayIterationContext.h"

@implementation RCSAsyncTests
{
    BOOL _isDone;

}
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _isDone = NO;
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testIndexSet
{
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10)];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    RCSIndexSetIteration *iter = [RCSIndexSetIteration iterationWithIndexes:indexes
                                                                               toQueue:queue];
    [iter eachIndex:^(NSUInteger idx, RCSIndexSetIterationContext *context) {
        NSLog(@"running: %lu", (unsigned long)idx);
        [context next];
    } done:^(RCSIndexSetIterationContext *context) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"done");
            _isDone = YES;
        });
    } failed:^(NSError *error, RCSIndexSetIterationContext *context) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"failed");
            _isDone = YES;
        });
    }];

    while (!_isDone)
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        NSLog(@"%@ is polling...", NSStringFromSelector(_cmd));
    }
}

- (void)testArray
{
    NSArray *objects = @[ @"0", @"1", @"2", @"3" ];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    RCSArrayIteration *iter = [RCSArrayIteration iterationWithObjects:objects toQueue:queue];
    [iter eachObject:^(id object, RCSArrayIterationContext *context) {
        NSLog(@"running: %@", object);
        [context next];
    } done:^(RCSArrayIterationContext *context) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"done");
            _isDone = YES;
        });
    } failed:^(NSError *error, RCSArrayIterationContext *context) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"failed");
            _isDone = YES;
        });
    }];

    while (!_isDone)
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        NSLog(@"%@ is polling...", NSStringFromSelector(_cmd));
    }
}

- (void) async000:(NSNotification*)notification;
{
    _isDone = YES;
}

- (void)testOperation
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];

    RCSAsyncOperation *operation1 = [[RCSAsyncOperation alloc] init];
    __block BOOL operation1Executed = NO;
    operation1.executionBlock = ^(RCSAsyncOperation *op) {
        [op done];
        operation1Executed = YES;
    };

    RCSAsyncOperation *operation2 = [[RCSAsyncOperation alloc] init];
    __block BOOL operation2Executed = NO;
    operation2.executionBlock = ^(RCSAsyncOperation *op) {
        [op done];
        operation2Executed = YES;
    };

    NSBlockOperation *sentinel = [NSBlockOperation blockOperationWithBlock:^{
        _isDone = YES;
    }];

    [queue addOperation:operation1];
    [queue addOperation:operation2];
    [queue addOperation:sentinel];
    while (!_isDone)
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        NSLog(@"%@ is polling...", NSStringFromSelector(_cmd));
    }

    STAssertTrue(operation1Executed, @"operation1Executed");
    STAssertTrue(operation2Executed, @"operation1Executed");
    STAssertTrue(_isDone, @"operation1Executed");
}

@end
