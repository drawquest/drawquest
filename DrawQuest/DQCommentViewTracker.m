//
//  DQCommentViewTracker.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentViewTracker.h"
#import "DQPublicServiceController.h"
#import "DQHTTPRequest.h"

NSString *DQCommentViewTrackerTrackedCommentIDs = @"DQCommentViewTrackerTrackedCommentIDs";

@implementation DQCommentViewTracker
{
    BOOL _started;
    NSMutableArray *_serverIDs;
    NSMutableArray *_serverIDsBeingSent;
    NSTimer *_timer;
    DQHTTPRequest *_request;
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _serverIDs = [NSMutableArray new];
        _serverIDsBeingSent = [NSMutableArray new];
    }
    return self;
}

- (void)start
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _started = YES;
        NSArray *items = [[NSUserDefaults standardUserDefaults] objectForKey:DQCommentViewTrackerTrackedCommentIDs] ?: @[];
        [_serverIDs addObjectsFromArray:items];
        [self __onMainThreadTriggerSend];
    });
}

- (void)stop
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_request cancel];
        _request = nil;

        [_timer invalidate];
        _timer = nil;

        [_serverIDsBeingSent addObjectsFromArray:_serverIDs];
        _serverIDs = _serverIDsBeingSent;
        _serverIDsBeingSent = [NSMutableArray new];
        [[NSUserDefaults standardUserDefaults] setObject:_serverIDs forKey:DQCommentViewTrackerTrackedCommentIDs];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _started = NO;
    });
}

- (void)trackViewOfCommentWithServerID:(NSString *)serverID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_started && self.uploadInterval)
        {
            [_serverIDs addObject:serverID];
            [self __onMainThreadTriggerSend];
        }
    });
}

- (void)__onMainThreadTriggerSend
{
    if ( !_timer && [_serverIDs count] && _started && self.uploadInterval)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)[self.uploadInterval doubleValue]
                                                  target:self
                                                selector:@selector(__onMainThreadSend)
                                                userInfo:nil
                                                 repeats:NO];
    }
}

- (void)__onMainThreadSend
{
    if ([_serverIDs count] && _started && self.uploadInterval)
    {
        [_serverIDsBeingSent addObjectsFromArray:_serverIDs];
        [_serverIDs removeAllObjects];
        __weak typeof(self) weakSelf = self;
        [_request cancel];
        _request = [self.publicServiceController requestTrackViewedCommentsWithServerIDs:_serverIDsBeingSent completionBlock:^(DQHTTPRequest *request) {
            [weakSelf sendSucceeded];
        } failureBlock:^(DQHTTPRequest *request) {
            [weakSelf sendFailed];
        }];
    }
}

- (void)sendSucceeded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_timer)
        {
            _timer = nil;
            _request = nil;
            [_serverIDsBeingSent removeAllObjects];
            [self __onMainThreadTriggerSend];
        }
        else
        {
            _request = nil;
        }
    });
}

- (void)sendFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _timer = nil;
        _request = nil;
        [_serverIDsBeingSent addObjectsFromArray:_serverIDs];
        _serverIDs = _serverIDsBeingSent;
        _serverIDsBeingSent = [NSMutableArray new];
    });
}

@end
