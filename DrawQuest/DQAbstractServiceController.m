//
//  DQAbstractServiceController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractServiceController.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAccount.h"
#import "DQHTTPRequestQueue.h"
#import "DQPapertrailLogger.h"

// Headers
NSString *DQAPIHeaderSessionID = @"X-SESSIONID";

// Constants
NSString *DQDefaultServiceQueueName = @"as.canv.DrawQuest.APIRequestQueue";

// Notifications
NSString *DQServiceErrorNotification = @"DQServiceErrorNotification";

// Notification Keys
NSString *DQServiceNotificationKeyError = @"Error";

// Defaults Keys
NSString *DQRouterSpecifiedAPIURL = @"DQRouterSpecifiedAPIURL";
NSString *DQRouterSpecifiedRTURL = @"DQRouterSpecifiedRTURL";
NSString *DQRouterSpecifiedRouterURL = @"DQRouterSpecifiedRouterURL";
NSString *DQRouterSpecifiedWebURL = @"DQRouterSpecifiedWebURL";
NSString *DQRouterSpecifiedSearchURL = @"DQRouterSpecifiedSearchURL";

// Info Dictionary Keys
NSString *DQServiceControllerDefaultHTTPEndpointInfoDictKey = @"DefaultHTTPEndpoint";
NSString *DQServiceControllerDefaultWebEndpointInfoDictKey = @"DefaultWebEndpoint";
NSString *DQServiceControllerDefaultSearchEndpointInfoDictKey = @"DefaultSearchEndpoint";

@interface DQAbstractServiceController ()

@property (nonatomic, readwrite, strong) DQHTTPRequestQueue *serviceQueue;

@end

@implementation DQAbstractServiceController

+ (NSString *)httpEndpoint
{
    return [self settingForKey:DQRouterSpecifiedAPIURL fallbackKey:DQServiceControllerDefaultHTTPEndpointInfoDictKey];
}

#pragma mark Life Cycle

- (void)reset
{
    // Reset the queue state.
    _serviceQueue = nil;
}

#pragma mark Accessors

- (NSString *)serviceQueueName
{
    return DQDefaultServiceQueueName;
}

- (DQHTTPRequestQueue *)serviceQueue
{
    if (!_serviceQueue) {
        _serviceQueue = [[DQHTTPRequestQueue alloc] initWithQueueName:[self serviceQueueName]];
        _serviceQueue.baseURL = [[self class] httpEndpoint];
    }

    return _serviceQueue;
}

#pragma mark Generic HTTP Response Handlers

- (void)httpRequestDidStart:(DQHTTPRequest *)request
{
}

- (void)httpRequestDidFinish:(DQHTTPRequest *)inRequest
{
    //NSLog(@"Request (command: %@; tag: %@) finished with response data: %@", inRequest.command, inRequest.tag, inRequest.responseJSONObject);
}

- (void)httpRequestDidFail:(DQHTTPRequest *)inRequest
{
    NSError *requestError = inRequest.error;

    if (requestError.code == DQAPIErrorCodeServiceError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:requestError, DQServiceNotificationKeyError, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DQServiceErrorNotification object:nil userInfo:userInfo];
        });
    }

    NSLog(@"Request (command: %@; tag: %@) failed with error: %@", inRequest.command, inRequest.tag, inRequest.error);
}

#pragma mark Convenience methods

- (DQHTTPRequest *)requestWithMethod:(DQHTTPRequestMethod)method forCommand:(NSString *)command completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self.serviceQueue requestWithCommand:command];
    request.requestMethod = method;
    request.requestDidFinishBlock = inCompletionBlock;
    request.requestDidFailBlock = inFailureBlock;
    return request;
}

- (NSString *)papertrailLoggerComponentPrefix
{
    return @"abstract";
}

- (BOOL)shouldAddSessionIDHeader
{
    return YES;
}

- (BOOL)shouldLogError:(NSError *)error
{
    return YES;
}

- (void)startHTTPRequest:(DQHTTPRequest *)inRequest
{
    if (!self.serviceQueue)
    {
        return;
    }
    if ([self shouldAddSessionIDHeader] && [self.loggedInAccount hasAuthCredentialsForSource:[@"start-http-request-" stringByAppendingString:inRequest.command ?: @"unknown"]])
    {
        [inRequest setHeaderString:[self.loggedInAccount authTokenForSource:[@"start-http-request-" stringByAppendingString:inRequest.command ?: @"unknown"]] forKey:DQAPIHeaderSessionID];
    }

    inRequest.delegate = self;

    if (inRequest.responseValidationBlock == NULL) {
        // This will cause the failure block for the request
        // to get called in the case of an application specific
        // (non-HTTP) error
        inRequest.responseValidationBlock = ^NSError* (DQHTTPRequest *inRequest) {
            // If there's no response dictionary, return
            // a generic error
            NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
            if (![responseDictionary count])
            {
                NSError *error = [NSError errorWithDomain:DQAPIErrorDomain code:(responseDictionary ? DQAPIErrorCodeEmptyResponseDictionary : DQAPIErrorCodeNoResponseDictionary) userInfo:nil];
                [DQPapertrailLogger component:[[self papertrailLoggerComponentPrefix] stringByAppendingString:@"-api"] category:[@"failed-" stringByAppendingString:inRequest.command ?: @"unknown"] error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"args": inRequest.papertrailLoggerDataBlock ? inRequest.papertrailLoggerDataBlock() : [NSNull null]};
                }];
                return error;
            }

            // If the response is successful, return no error
            if (responseDictionary.dq_isOK) {
                return nil;
            }

            // Attempt to return a specialized error based on the
            // error type
            NSString *errorTypeString = responseDictionary.dq_errorType;
            NSInteger errorCode = DQAPIErrorCodeUnknown;

            if ([errorTypeString isEqualToString:DQAPIErrorTypeValidation]) {
                errorCode = DQAPIErrorCodeValidationFailure;
            } else if ([errorTypeString isEqualToString:DQAPIErrorTypeService]) {
                errorCode = DQAPIErrorCodeServiceError;
            } else if ([errorTypeString isEqualToString:DQAPIErrorTypeInvalidFacebookToken]) {
                errorCode = DQAPIErrorInvalidFacebookTokenError;
            } else if ([errorTypeString isEqualToString:DQAPIErrorTypeInvalidTwitterToken]) {
                errorCode = DQAPIErrorInvalidTwitterTokenError;
            } else if ([errorTypeString isEqualToString:DQAPIErrorTypeResponseTooLarge]) {
                errorCode = DQAPIErrorCodeResponseTooLarge;
            }

            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];

            NSString *reasonString = responseDictionary.dq_errorReason;
            if (reasonString) {
                [userInfo setObject:reasonString forKey:NSLocalizedFailureReasonErrorKey];
            }

            NSDictionary *errorDictionary = responseDictionary.dq_errorDictionary;
            if (errorDictionary.count) {
                [userInfo setObject:errorDictionary forKey:DQAPIErrorDictionaryKey];
            }

            NSError *returnError = [NSError errorWithDomain:DQAPIErrorDomain code:errorCode userInfo:userInfo];
            if ([self shouldLogError:returnError])
            {
                [DQPapertrailLogger component:[[self papertrailLoggerComponentPrefix] stringByAppendingString:@"-api"] category:[@"failed-" stringByAppendingString:inRequest.command ?: @"unknown"] error:returnError dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    if ([userInfo count])
                    {
                        return @{@"userInfo":userInfo ?: [NSNull null],
                                 @"args": inRequest.papertrailLoggerDataBlock ? inRequest.papertrailLoggerDataBlock() : [NSNull null]};
                    }
                    else
                    {
                        return @{@"args": inRequest.papertrailLoggerDataBlock ? inRequest.papertrailLoggerDataBlock() : [NSNull null]};
                    }
                }];
            }
            return returnError;
        };
    }

    [self.serviceQueue enqueueRequest:inRequest resultBlock:nil];
}

@end

@implementation DQHTTPRequest (DQAPIConveniences)

- (NSDictionary *)dq_responseDictionary;
{
    if (!self.responseJSONObject || ![self.responseJSONObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    return (NSDictionary *)self.responseJSONObject;
}

@end

#pragma mark -
#pragma mark Convenience Category Implementations

@implementation NSError (DQAPIConveniences)

- (NSString *)dq_displayDescription
{
    NSString *description = [NSString stringWithFormat:@"%@: %ld", self.domain, (long)self.code];

    NSString *errorReasonsString = self.dq_errorReasonsString;
    if (errorReasonsString.length) {
        description = errorReasonsString;
    } else if (self.localizedDescription) {
        description = self.localizedDescription;
    } else if (self.localizedFailureReason) {
        description = self.localizedFailureReason;
    }

    return description;
}

- (NSString *)dq_errorReasonsString
{
    if (!self.userInfo) {
        return nil;
    }

    NSDictionary *reasons = [self.userInfo objectForKey:DQAPIErrorDictionaryKey];
    if (![reasons count])
    {
        return nil;
    }

    NSMutableString *fullReasonsString = [[NSMutableString alloc] init];
    [reasons enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *reasonsString = nil;

        if ([obj isKindOfClass:[NSArray class]]) {
            reasonsString = [(NSArray *)obj componentsJoinedByString:@"\n\n"];
        } else if ([obj isKindOfClass:[NSString class]]) {
            reasonsString = (NSString *)obj;
        }

        if (reasonsString) {
            [fullReasonsString appendFormat:@"%@\n\n", reasonsString];
        }
    }];

    return fullReasonsString;
}

@end
