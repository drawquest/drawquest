//
//  DQAbstractServiceController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "DQHTTPRequest.h"
#import "DQHTTPRequestQueue.h"
#import "DQAccount.h"

typedef enum {
    DQOffsetDirectionUnknown = 0,
    DQOffsetDirectionNext,
    DQOffsetDirectionPrevious
} DQOffsetDirection;

@class DQAccountController;
// Headers
extern NSString *DQAPIHeaderSessionID;

// Notifications
extern NSString *DQServiceErrorNotification;

// Notification Keys
extern NSString *DQServiceNotificationKeyError;

// Defaults Keys
extern NSString *DQRouterSpecifiedAPIURL;
extern NSString *DQRouterSpecifiedRTURL;
extern NSString *DQRouterSpecifiedRouterURL;
extern NSString *DQRouterSpecifiedWebURL;
extern NSString *DQRouterSpecifiedSearchURL;

// Info Dictionary Keys
extern NSString *DQServiceControllerDefaultHTTPEndpointInfoDictKey;
extern NSString *DQServiceControllerDefaultWebEndpointInfoDictKey;
extern NSString *DQServiceControllerDefaultSearchEndpointInfoDictKey;

typedef void (^DQServiceStatusBlock)(DQHTTPRequest *request);
typedef void (^DQServiceCompletionBlock)(DQHTTPRequest *request, id JSONObject);
typedef void (^DQServiceCompletionBlockWithObjects)(DQHTTPRequest *request, id JSONObject, NSArray *objects);
typedef void (^DQServiceImageUploadCompletionBlock)(DQHTTPRequest *request, NSDictionary *contentDictionary, NSString *contentID);
typedef void (^DQServiceFailureBlock)(DQHTTPRequest *request, NSError *error);

@interface DQAbstractServiceController : DQController <DQHTTPRequestDelegate>

@property (nonatomic, readonly, strong) DQHTTPRequestQueue *serviceQueue;

- (void)startHTTPRequest:(DQHTTPRequest *)inRequest;

#pragma mark -
#pragma mark Life Cycle

- (void)reset;

#pragma mark -
#pragma mark Template Methods

- (NSString *)serviceQueueName;
- (NSString *)papertrailLoggerComponentPrefix;
- (BOOL)shouldAddSessionIDHeader;
- (BOOL)shouldLogError:(NSError *)error;

#pragma mark -
#pragma mark Convenience Methods

- (DQHTTPRequest *)requestWithMethod:(DQHTTPRequestMethod)method forCommand:(NSString *)command completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

@end

@interface DQHTTPRequest (DQAPIConveniences)

- (NSDictionary *)dq_responseDictionary;

@end

@interface NSError (DQAPIConveniences)

- (NSString *)dq_displayDescription;
- (NSString *)dq_errorReasonsString;

@end
