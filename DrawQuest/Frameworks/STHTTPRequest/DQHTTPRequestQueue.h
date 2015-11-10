//
//  DQHTTPRequestQueue.h
//
//  Created by Buzz Andersen on 3/8/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DQHTTPRequest;

@interface DQHTTPRequestQueue : NSObject
{
    NSString *queueName;
    
    NSString *baseURL;

    NSString *userAgent;
    
    NSString *OAuthConsumerKey;
    NSString *OAuthSecretKey;
    NSString *OAuthToken;
    NSString *OAuthTokenSecret;
    
    NSString *basicAuthUsername;
    NSString *basicAuthPassword;
    NSString *basicAuthKeychainServiceName;
}

@property (nonatomic, strong) NSString *queueName;
@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *userAgent;

@property (nonatomic, readonly) BOOL hasBasicAuthCredentials;
@property (nonatomic, strong) NSString *basicAuthUsername;
@property (nonatomic, strong) NSString *basicAuthPassword;
@property (nonatomic, strong) NSString *basicAuthKeychainServiceName;

@property (nonatomic, readonly) BOOL hasOAuthCredentials;
@property (nonatomic, strong) NSString *OAuthConsumerKey;
@property (nonatomic, strong) NSString *OAuthSecretKey;
@property (nonatomic, strong) NSString *OAuthToken;
@property (nonatomic, strong) NSString *OAuthTokenSecret;

// Initialization

// designated initializer
- (id)initWithQueueName:(NSString *)inQueueName;

- (id)init MSDesignatedInitializer(initWithQueueName:);

// Request Creation
- (DQHTTPRequest *)requestWithURL:(NSString *)inURL;
- (DQHTTPRequest *)requestWithCommand:(NSString *)inCommand;
- (DQHTTPRequest *)requestWithCommand:(NSString *)inCommand tag:(NSString *)inTag userInfo:(NSDictionary *)inUserInfo;

// Request Lookup
- (void)hasRequestForIdentifier:(NSString *)inIdentifier resultBlock:(void (^)(BOOL found))resultBlock;
- (void)hasRequestsForURL:(NSString *)inURL resultBlock:(void (^)(BOOL found))resultBlock;
- (void)hasRequestsForCommand:(NSString *)inCommand resultBlock:(void (^)(BOOL found))resultBlock;
- (void)hasRequestsForTag:(NSString *)inTag resultBlock:(void (^)(BOOL found))resultBlock;
- (void)hasRequestsForCommand:(NSString *)inCommand tag:(NSString *)inTag resultBlock:(void (^)(BOOL found))resultBlock;

// Cancellation
- (void)cancelRequestsForURL:(NSString *)inURL completionBlock:(dispatch_block_t)completionBlock;

// Queue
- (void)hasOperations:(void (^)(BOOL hasOperations))resultBlock;
- (void)maxConcurrentOperationCount:(void (^)(NSInteger result))resultBlock;
- (void)setMaxConcurrentOperationCount:(NSInteger)cnt completionBlock:(dispatch_block_t)completionBlock;
- (void)enqueueRequest:(DQHTTPRequest *)request resultBlock:(void (^)(BOOL enqueued))resultBlock;

@end
