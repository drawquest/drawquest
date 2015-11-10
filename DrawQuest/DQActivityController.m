//
//  DQActivityController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-24.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQActivityController.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQDataStoreController.h"
#import "DQPrivateServiceController.h"
#import "DQActivityItem.h"
#import "RCSAsyncOperation.h"
#import "DQActivityDataStoreController.h"
#import "DQAccount.h"

@interface DQActivityController ()

@property (nonatomic, readwrite, strong) DQActivityDataStoreController *dataStoreController;
@property (nonatomic, strong) NSOperationQueue *serialOperationQueue;
@property (nonatomic, strong, readonly) dispatch_queue_t workerQueue;
@property (nonatomic, copy) NSArray *activities;

@end

@implementation DQActivityController

@synthesize dataStoreController = _dataStoreController;

- (void)dealloc
{
    if (_workerQueue)
    {
        dispatch_sync(_workerQueue, ^{ });
    }
}

- (id)initWithDelegate:(id<DQActivityControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        [self reset];
        _workerQueue = dispatch_queue_create("as.canv.drawquest.activity", DISPATCH_QUEUE_SERIAL);
        _serialOperationQueue = [[NSOperationQueue alloc] init];
        _serialOperationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (id<DQActivityControllerDelegate>)delegate
{
    return (id<DQActivityControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQActivityControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

#pragma mark -
#pragma mark Public API

- (void)reset
{
    self.activities = nil;
    self.dataStoreController = [self.delegate newActivityDataStoreControllerForActivityController:self];
}

- (NSUInteger)numberOfUnreadActivityItems
{
    return [self.dataStoreController numberOfUnreadActivityItems];
}

- (void)markAllActivityItemsRead
{
    [self.dataStoreController markAllActivityItemsRead];
    if ([self.activities count])
    {
        self.loggedInAccount.timestampOfNewestReadActivity = ((DQActivityItem *)self.activities[0]).timestamp;
    }
}

- (void)load
{
    dispatch_async(self.workerQueue, ^{
        __weak typeof(self) weakSelf = self;
        __block DQHTTPRequest *cancellableRequest = nil;
        RCSAsyncOperation *op = [[RCSAsyncOperation alloc] initWithExecutionBlock:^(RCSAsyncOperation *operation) {
            if (weakSelf.activities)
            {
                [weakSelf tellDelegateLoadCompletion];
                [operation done];
            }
            else
            {
                cancellableRequest = [self requestLoadWithCompletionBlock:^(NSArray *objects) {
                    weakSelf.activities = objects;
                    [weakSelf tellDelegateLoadCompletion];
                    [operation done];
                } failureBlock:^(NSError *error) {
                    [weakSelf tellDelegateLoadFailure:error];
                    [operation done];
                }];
            }
        } onQueue:weakSelf.workerQueue];
        [self.serialOperationQueue addOperation:op];
    });
}

- (void)update
{
    dispatch_async(self.workerQueue, ^{
        __weak typeof(self) weakSelf = self;
        __block DQHTTPRequest *cancellableRequest = nil;
        RCSAsyncOperation *op = [[RCSAsyncOperation alloc] initWithExecutionBlock:^(RCSAsyncOperation *operation) {
            if (weakSelf.activities)
            {
                cancellableRequest = [weakSelf requestUpdateWithCompletionBlock:^(NSArray *objects, BOOL reloaded) {
                    if (reloaded)
                    {
                        weakSelf.activities = objects;
                        [weakSelf tellDelegateLoadCompletion];
                    }
                    else
                    {
                        weakSelf.activities = [objects arrayByAddingObjectsFromArray:(weakSelf.activities ?: @[])];
                        [weakSelf tellDelegateUpdateCompletion:objects];
                    }
                    [operation done];
                } updateCancellableRequestBlock:^(DQHTTPRequest *request) {
                    cancellableRequest = request;
                } failureBlock:^(NSError *error, BOOL reloaded) {
                    if (reloaded)
                    {
                        [weakSelf tellDelegateLoadFailure:error];
                    }
                    else
                    {
                        [weakSelf tellDelegateUpdateFailure:error];
                    }
                    [operation done];
                }];
            }
            else
            {
                [weakSelf tellDelegateUpdateCompletion:nil];
                [operation done];
            }
        } onQueue:weakSelf.workerQueue];
        [self.serialOperationQueue addOperation:op];
    });
}

- (void)scroll
{
    dispatch_async(self.workerQueue, ^{
        __weak typeof(self) weakSelf = self;
        __block DQHTTPRequest *cancellableRequest = nil;
        RCSAsyncOperation *op = [[RCSAsyncOperation alloc] initWithExecutionBlock:^(RCSAsyncOperation *operation) {
            if (weakSelf.activities)
            {
                cancellableRequest = [self requestScrollWithCompletionBlock:^(NSArray *objects) {
                    weakSelf.activities = [(weakSelf.activities ?: @[]) arrayByAddingObjectsFromArray:objects];
                    [weakSelf tellDelegateScrollCompletion:objects];
                    [operation done];
                } failureBlock:^(NSError *error) {
                    [weakSelf tellDelegateScrollFailure:error];
                    [operation done];
                }];
            }
            else
            {
                [weakSelf tellDelegateScrollCompletion:nil];
                [operation done];
            }
        } onQueue:weakSelf.workerQueue];
        [self.serialOperationQueue addOperation:op];
    });
}

#pragma mark -
#pragma mark Private API

- (DQHTTPRequest *)requestLoadWithCompletionBlock:(void (^)(NSArray *objects))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    double timestamp = [[NSDate date] timeIntervalSince1970];
    return [weakSelf.privateServiceController requestActivityWithCompletionBlock:^(DQHTTPRequest *request, id _) {
        if (request.error)
        {
            if (failureBlock)
            {
                failureBlock(request.error);
            }
        }
        else
        {
            weakSelf.loggedInAccount.activityTabBadgeTimestamp = @(timestamp);
            NSArray *JSONList = request.dq_responseDictionary.dq_activities;
            NSArray *objects = [weakSelf.dataStoreController activityItemsFromJSONList:JSONList markedAsReadIfOlderThan:weakSelf.loggedInAccount.timestampOfNewestReadActivity];
            if (completionBlock)
            {
                completionBlock(objects);
            }
        }
    }];
}

- (DQHTTPRequest *)requestUpdateWithCompletionBlock:(void (^)(NSArray *objects, BOOL reloaded))completionBlock updateCancellableRequestBlock:(void (^)(DQHTTPRequest *request))cancellableRequestBlock failureBlock:(void (^)(NSError *error, BOOL reloaded))failureBlock
{
    __weak typeof(self) weakSelf = self;
    DQActivityItem *first = [self.activities firstObject];
    double timestamp = [[NSDate date] timeIntervalSince1970];
    return [self.privateServiceController requestActivityNewerThan:first.timestamp withCompletionBlock:^(DQHTTPRequest *request, id _) {
        if (request.error)
        {
            if ([[request.error domain] isEqualToString:DQAPIErrorDomain] && [request.error code] == DQAPIErrorCodeResponseTooLarge)
            {
                // switch to a load request, within the context of the same NSOperation
                [weakSelf reset];
                DQHTTPRequest *cancellableRequest = [self requestLoadWithCompletionBlock:^(NSArray *objects) {
                    if (completionBlock)
                    {
                        completionBlock(objects, YES);
                    }
                } failureBlock:^(NSError *error) {
                    if (failureBlock)
                    {
                        failureBlock(error, YES);
                    }
                }];
                if (cancellableRequestBlock)
                {
                    cancellableRequestBlock(cancellableRequest);
                }
            }
            else
            {
                if (failureBlock)
                {
                    failureBlock(request.error, NO);
                }
            }
        }
        else
        {
            weakSelf.loggedInAccount.activityTabBadgeTimestamp = @(timestamp);
            NSArray *JSONList = request.dq_responseDictionary.dq_activities;
            NSArray *objects = [weakSelf.dataStoreController newActivityItemsFromJSONList:JSONList markedAsReadIfOlderThan:weakSelf.loggedInAccount.timestampOfNewestReadActivity];
            if (completionBlock)
            {
                completionBlock(objects, NO);
            }
        }
    }];
}

- (DQHTTPRequest *)requestScrollWithCompletionBlock:(void (^)(NSArray *objects))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __weak typeof(self) weakSelf = self;
    DQActivityItem *last = [weakSelf.activities lastObject];
    return [self.privateServiceController requestActivityOlderThan:last.timestamp withCompletionBlock:^(DQHTTPRequest *request, id _) {
        if (request.error)
        {
            if (failureBlock)
            {
                failureBlock(request.error);
            }
        }
        else
        {
            NSArray *JSONList = request.dq_responseDictionary.dq_activities;
            NSArray *objects = [weakSelf.dataStoreController newActivityItemsFromJSONList:JSONList markedAsReadIfOlderThan:weakSelf.loggedInAccount.timestampOfNewestReadActivity];
            if (completionBlock)
            {
                completionBlock(objects);
            }
        }
    }];
}

#pragma mark -
#pragma mark Delegate support

- (void)tellDelegateLoadFailure:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate activityController:self loadFailedWithError:error];
    });
}

- (void)tellDelegateLoadCompletion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate activityController:self didLoadActivities:self.activities];
    });
}

- (void)tellDelegateUpdateFailure:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate activityController:self updateFailedWithError:error];
    });
}

- (void)tellDelegateUpdateCompletion:(NSArray *)newActivities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate activityController:self didUpdateActivities:newActivities];
    });
}

- (void)tellDelegateScrollFailure:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate activityController:self scrollFailedWithError:error];
    });
}

- (void)tellDelegateScrollCompletion:(NSArray *)newActivities
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate activityController:self didScrollActivities:newActivities];
    });
}

@end
