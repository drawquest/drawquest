//
//  DQRouterServiceController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 1/9/2014.
//  Copyright (c) 2014 Canvas. All rights reserved.
//

#import "DQRouterServiceController.h"
#import "RCSArrayIteration.h"
#import "RCSArrayIterationContext.h"
#import "NSUserDefaults+STAdditions.h"
#import "DQPapertrailLogger.h"

// Info Dictionary Keys
NSString *DQServiceControllerDefaultRouterHTTPEndpointInfoDictKey = @"DefaultAPIRouterHTTPEndpoint";

NSString *DQAPIMethodRouter = @"base_url";

@implementation DQRouterServiceController
{
    NSUInteger _attempt;
}

- (instancetype)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _attempt = 1;
    }
    return self;
}

+ (NSString *)httpEndpointTemplate
{
    return [self settingForKey:DQRouterSpecifiedRouterURL fallbackKey:DQServiceControllerDefaultRouterHTTPEndpointInfoDictKey];
}

+ (NSString *)httpEndpointForAttempt:(NSNumber *)attempt
{
    NSString *result = [self httpEndpointTemplate];
    return [result stringByReplacingOccurrencesOfString:@"?" withString:[attempt stringValue]];
}

// this is called by [super serviceQueue] when lazily instanciating the serviceQueue
+ (NSString *)httpEndpoint
{
    return [self httpEndpointForAttempt:@1];
}

#pragma mark -
#pragma mark Template Methods

- (NSString *)serviceQueueName
{
    return @"as.canv.DrawQuest.APIRouterRequestQueue";
}

- (NSString *)papertrailLoggerComponentPrefix
{
    return @"router";
}

#pragma mark -
#pragma mark Public API

- (void)requestConfiguration:(dispatch_block_t)completionBlock
{
    NSInteger first = MAX(1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DQRouterFirstAttemptNumber"]);
    NSArray *attempts = @[@(first), @(first+1), @(first+2), @(first+3), @(first+4)];

    RCSArrayIteration *iter = [[RCSArrayIteration alloc] initWithObjects:attempts toQueue:dispatch_get_main_queue()];
    [iter eachObject:^(NSNumber *attemptNumber, RCSArrayIterationContext *context) {
        self.serviceQueue.baseURL = [[self class] httpEndpointForAttempt:attemptNumber];
        [self requestURLsWithCompletionBlock:^(DQHTTPRequest *request) {
            NSDictionary *dict = request.dq_responseDictionary;
            NSString *api = dict[@"api_url"];
            NSString *rt = dict[@"rt_url"];
            NSString *search = dict[@"search_url"];
            NSString *web = dict[@"web_url"];
            if ([api length] && [rt length])
            {
                [[NSUserDefaults standardUserDefaults] setObject:attemptNumber forKey:@"DQRouterFirstAttemptNumber"];
                [[NSUserDefaults standardUserDefaults] setObject:api forKey:DQRouterSpecifiedAPIURL];
                [[NSUserDefaults standardUserDefaults] setObject:rt forKey:DQRouterSpecifiedRTURL];
                if ([search length])
                {
                    [[NSUserDefaults standardUserDefaults] setObject:search forKey:DQRouterSpecifiedSearchURL];
                }
                else
                {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQRouterSpecifiedSearchURL];
                }
                if ([web length])
                {
                    [[NSUserDefaults standardUserDefaults] setObject:web forKey:DQRouterSpecifiedWebURL];
                }
                else
                {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQRouterSpecifiedWebURL];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
                [context stop];
            }
            else
            {
                [context next];
            }
        } failureBlock:^(DQHTTPRequest *request) {
            [context next];
        }];
    } done:^(RCSArrayIterationContext *context) {
        if (completionBlock)
        {
            completionBlock();
        }
    } failed:^(NSError *error, RCSArrayIterationContext *context) {
        if (completionBlock)
        {
            completionBlock();
        }
    }];
}

#pragma mark -
#pragma mark API Router

- (DQHTTPRequest *)requestURLsWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodRouter completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    [self startHTTPRequest:request];
    return request;
}

@end
