//
//  DQHTTPChannelController.m
//  DrawQuest
//
//  Created by Buzz Andersen on 11/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQHTTPChannelController.h"
#import "DQAccount.h"
#import "DQAbstractServiceController.h"
#import "DQHTTPRequestQueue.h"
#import "DQHTTPRequest.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"
#import "STRandomization.h"
#import "DQPapertrailLogger.h"

NSString *DQHTTPChannelControllerQueueName = @"as.canv.DrawQuest.ChannelQueue";

NSString *DQHTTPChannelControllerQuestOfTheDayUpdatedNotification = @"DQHTTPChannelControllerQuestOfTheDayUpdatedNotification";
NSString *DQHTTPChannelControllerUserActivityUpdatedNotification = @"DQHTTPChannelControllerUserActivityUpdatedNotification";
NSString *DQHTTPChannelControllerCoinBalanceUpdatedNotification = @"DQHTTPChannelControllerCoinBalanceUpdatedNotification";
NSString *DQHTTPChannelControllerTabBadgesNotification = @"DQHTTPChannelControllerTabBadgesNotification";

NSString *DQHTTPChannelControllerCoinBalanceNotificationKey = @"CoinBalance";
NSString *DQHTTPChannelControllerTabBadgeUpdateKey = @"TabBadgeUpdate";


NSUInteger DQHTTPChannelControllerMaximumRetryCount = 15;
NSTimeInterval DQHTTPChannelControllerDefaultTimeoutInterval = 21600;
NSTimeInterval DQHTTPChannelControllerDefaultRetryInterval = 30.0;

// Info Dictionary Keys
NSString *DQHTTPChannelControllerDefaultChannelEndpointInfoDictKey = @"DefaultChannelEndpoint";

@interface DQHTTPChannelController () <DQHTTPRequestDelegate>

@property (nonatomic, strong) DQHTTPRequestQueue *channelQueue;
@property (nonatomic, strong) NSString *channelURL;
@property (nonatomic, strong) NSMutableArray *channelList;
@property (nonatomic, strong) NSMutableDictionary *channelStateInfo;

@property (nonatomic, assign) NSInteger retryCount;
@property (readonly) int64_t currentRetryInterval;

@end


@implementation DQHTTPChannelController

#pragma mark Initialization


#pragma mark Life Cycle

- (void)reset
{
    self.monitoring = NO;
    
    _channelURL = nil;
    
    _channelQueue = nil;    
}

#pragma mark Accessors

- (void)setChannelURL:(NSString *)channelURL
{
    _channelURL = channelURL;    
}

- (DQHTTPRequestQueue *)channelQueue
{
    if (!_channelQueue) {
        _channelQueue = [[DQHTTPRequestQueue alloc] initWithQueueName:DQHTTPChannelControllerQueueName];
        _channelQueue.baseURL = [[self class] channelEndpoint];
        
        if ([self.loggedInAccount hasAuthCredentialsForSource:@"channel-queue"])
        {
            self.channelQueue.basicAuthUsername = self.loggedInAccount.username;
            self.channelQueue.basicAuthPassword = [self.loggedInAccount authTokenForSource:@"channel-queue"];
        }
    }
    
    return _channelQueue;
}

- (NSMutableArray *)channelList
{
    if (!_channelList) {
        _channelList = [[NSMutableArray alloc] init];
    }
    
    return _channelList;
}

- (NSMutableDictionary *)channelStateInfo
{
    if (!_channelStateInfo) {
        _channelStateInfo = [[NSMutableDictionary alloc] init];
    }
    
    return _channelStateInfo;
}

- (int64_t)currentRetryInterval
{
    return ceil((pow(2, self.retryCount) - 1) / 2);
}

#pragma mark Channel Monitoring

- (void)setMonitoring:(BOOL)monitoring
{
    if (monitoring == _monitoring)
    {
        return;
    }

    _monitoring = monitoring;
    
    if (!monitoring)
    {
        return;
    }
    
    _retryCount = 0;
    [self sendNextChannelRequest:nil];
}

- (void)retry
{
    if (self.retryCount > DQHTTPChannelControllerMaximumRetryCount) {
        self.monitoring = NO;
        return;
    }

    self.retryCount = self.retryCount + 1;
    int64_t currentRetryInterval = self.currentRetryInterval;
    
    NSLog(@"Channel request retrying %ld in %lld", (long)self.retryCount, currentRetryInterval);
    
    // Retry the request with exponential backoff
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, currentRetryInterval * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self sendChannelRequest];
    });
}

- (void)sendNextChannelRequest:(dispatch_block_t)completionBlock
{
    [self.channelQueue hasOperations:^(BOOL hasOperations) {
        if (hasOperations)
        {
            if (completionBlock)
            {
                completionBlock();
            }
        }
        else
        {
            // Wait for a random interval between 0 and 200 MS
            // before recycling the request
            NSTimeInterval delayInMilliseconds = (float)STRandomIntegerWithMax(200);

            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMilliseconds * NSEC_PER_MSEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self sendChannelRequest];
            });
            if (completionBlock)
            {
                completionBlock();
            }
        }
    }];
}

- (void)sendChannelRequest
{
    if (!self.monitoring || !self.channelURL) {
        return;
    }
        
    DQHTTPRequest *channelRequest = [DQHTTPRequest requestWithBaseURL:self.channelURL];
    channelRequest.requestMethod = DQHTTPRequestMethodGET;
    channelRequest.timeoutInterval = DQHTTPChannelControllerDefaultTimeoutInterval;
    channelRequest.spinsActivityIndicator = NO;
    channelRequest.delegate = self;
    channelRequest.responseValidationBlock = ^NSError* (DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
        NSError *result = nil;
        if ([responseDictionary count])
        {
            if ( ! responseDictionary.dq_isOK)
            {
                result = [NSError errorWithDomain:DQAPIErrorDomain code:DQAPIErrorCodeUnknown userInfo:nil];
                [DQPapertrailLogger component:@"channel-api" category:[@"failed-" stringByAppendingString:inRequest.command ?: @"unknown"] error:result dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"args": inRequest.papertrailLoggerDataBlock ? inRequest.papertrailLoggerDataBlock() : [NSNull null],
                             @"reason": responseDictionary.dq_errorReason ?: [NSNull null],
                             @"message": responseDictionary.dq_errorMessage ?: [NSNull null]};
                }];
            }
        }
        else
        {
            result = [NSError errorWithDomain:DQAPIErrorDomain code:(responseDictionary ? DQAPIErrorCodeEmptyResponseDictionary : DQAPIErrorCodeNoResponseDictionary) userInfo:nil];
            [DQPapertrailLogger component:@"channel-api" category:[@"failed-" stringByAppendingString:inRequest.command ?: @"unknown"] error:result dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"args": inRequest.papertrailLoggerDataBlock ? inRequest.papertrailLoggerDataBlock() : [NSNull null]};
            }];
        }
        return result;
    };

    [self.channelQueue enqueueRequest:channelRequest resultBlock:nil];
}

#pragma mark DQHTTPRequest

- (void)httpRequestDidStart:(DQHTTPRequest *)request
{
}

- (void)httpRequestDidFinish:(DQHTTPRequest *)request
{
    NSDictionary *responseDictionary = request.dq_responseDictionary;
    
    [self updateChannelInfoFromChannelJSONInfo:responseDictionary];
    [self dispatchActionsForChannelJSONInfo:responseDictionary];
    
    [self sendNextChannelRequest:nil];
}

- (void)httpRequestDidFail:(DQHTTPRequest *)request
{
    if (request.responseStatusCode == DQHTTPRequestNoNetworkStatusCode || request.responseStatusCode == DQHTTPRequestUnauthorizedStatusCode) {
        self.monitoring = NO;
        return;
    }
    
    [self retry];
}

#pragma mark Dispatch

- (void)dispatchActionsForChannelJSONInfo:(NSDictionary *)inJSONInfo
{
    if (!inJSONInfo) {
        return;
    }
    
    NSArray *channelNames = [inJSONInfo allKeys];
    for (NSString *currentChannelName in channelNames) {
        if ([currentChannelName isEqualToString:@"success"]) {
            continue;
        }
        
        NSString *notificationName = nil;
        NSDictionary *userInfo = nil;
        
        if ([currentChannelName hasPrefix:@"qotd"])
        {
            notificationName = DQHTTPChannelControllerQuestOfTheDayUpdatedNotification;
        }
        else if ([currentChannelName hasPrefix:@"user_activity"])
        {
            notificationName = DQHTTPChannelControllerUserActivityUpdatedNotification;
        }
        else if ([currentChannelName hasSuffix:@"rt_coins"])
        {
            // TODO: move this inside the if (coinBalance) block so the notification
            // doesn't get sent if the payload is missing
            // not doing this right now because it's close to 3.0 launch and I don't
            // want regressions.
            notificationName = DQHTTPChannelControllerCoinBalanceUpdatedNotification;
            NSDictionary *body = [[inJSONInfo arrayForKey:currentChannelName] firstObject];
            
            NSNumber *coinBalance = body.dq_realtimePayload.dq_coinBalance;
            if (coinBalance)
            {
                userInfo = @{DQHTTPChannelControllerCoinBalanceNotificationKey: coinBalance};
            }
        }
        else if ([currentChannelName hasSuffix:@"rt_tab_badges"])
        {
            notificationName = DQHTTPChannelControllerTabBadgesNotification;
            NSDictionary *body = [[inJSONInfo arrayForKey:currentChannelName] firstObject];

            NSString *update = body.dq_realtimePayload[@"tab_badge_update"];
            if (update)
            {
                userInfo = @{DQHTTPChannelControllerTabBadgeUpdateKey: update};
            }
        }
        
        if (notificationName)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:userInfo];
        }
    }
}

#pragma mark Channel State

- (void)setChannelStateValue:(NSNumber *)inValue forChannelName:(NSString *)inChannelName
{
    if (!inValue || !inChannelName) {
        return;
    }
    
    [self.channelStateInfo setValue:inValue forKey:inChannelName];
}

- (NSNumber *)channelStateValueForChannelName:(NSString *)inChannelName
{
    if (!inChannelName) {
        return nil;
    }
    
    return [self.channelStateInfo objectForKey:inChannelName];
}

- (void)updateChannelInfoFromChannelJSONInfo:(NSDictionary *)inJSONInfo
{
    if (!inJSONInfo) {
        return;
    }
    
    NSArray *channelKeys = [inJSONInfo allKeys];
    NSArray *channelList = self.channelList;
    for (NSString *currentChannelName in channelKeys) {
        if (![channelList containsObject:currentChannelName]) {
            continue;
        }
        
        NSNumber *highestUpdateIDNumber = [self channelStateValueForChannelName:currentChannelName];
        
        NSArray *channelInfo = [inJSONInfo arrayForKey:currentChannelName];
        for (NSDictionary *currentUpdateInfo in channelInfo) {
            NSNumber *updateIDNumber = [currentUpdateInfo numberForKey:@"id"];
            if (highestUpdateIDNumber && [updateIDNumber compare:highestUpdateIDNumber] == NSOrderedDescending) {
                highestUpdateIDNumber = updateIDNumber;
            }
        }
        
        [self setChannelStateValue:highestUpdateIDNumber forChannelName:currentChannelName];
    }
    
    [self updateChannelURL];
}

- (void)updateChannelInfoFromSyncJSONInfo:(NSDictionary *)inJSONInfo
{
    if (!inJSONInfo) {
        return;
    }
    
    NSArray *channelNames = [inJSONInfo allKeys];
    self.channelList = [channelNames mutableCopy];
    
    for (NSString *currentChannelName in channelNames) {
        NSDictionary *currentChannelInfo = [inJSONInfo objectForKey:currentChannelName];
        [self setChannelStateValue:currentChannelInfo.dq_realtimeLastMessageID forChannelName:currentChannelName];
    }
    
    [self updateChannelURL];
}

- (void)updateChannelURL
{
    if (!self.loggedInAccount) {
        return;
    }
    
    if (!self.channelStateInfo) {
        self.channelURL = nil;
    }
    
    NSMutableString *interpolatedParameterString = [[NSMutableString alloc] init];
    
    NSInteger currentIndex = 0;
    for (NSString *currentChannelName in self.channelList) {
        NSString *currentLastID = [[self channelStateValueForChannelName:currentChannelName] stringValue];
        if (!currentLastID) {
            currentLastID = @"0";
        }
        
        [interpolatedParameterString appendFormat:@"c=%@&m=%@", [currentChannelName stringByEscapingQueryParameters], [currentLastID stringByEscapingQueryParameters]];
        
        if (currentIndex < (self.channelList.count - 1)) {
            [interpolatedParameterString appendString:@"&"];
        } else {
            [interpolatedParameterString appendFormat:@"&GUID=%@", [NSString UUIDString]];
        }
        
        currentIndex++;
    }
    
    self.channelURL = [NSString stringWithFormat:@"%@?%@", [[self class] channelEndpoint], interpolatedParameterString];
    
}

+ (NSString *)channelEndpoint
{
    return [self settingForKey:DQRouterSpecifiedRTURL fallbackKey:DQHTTPChannelControllerDefaultChannelEndpointInfoDictKey];
}

@end
