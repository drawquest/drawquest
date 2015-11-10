//
//  DQHTTPRequest.h
//
//  Created by Buzz Andersen on 3/8/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STUtils.h"


@class DQHTTPRequest;

extern NSString *DQHTTPRequestAuthorizationHeaderKey;

extern NSString *DQHTTPRequestErrorDomain;
extern const NSInteger DQHTTPRequestCancelledError;

extern NSString *DQHTTPRequestXAuthUsernameParameterKey;
extern NSString *DQHTTPRequestXAuthPasswordParameterKey ;
extern NSString *DQHTTPRequestXauthAuthModeKey;

extern NSString *DQHTTPRequestJSONContentType;
extern NSString *DQHTTPRequestPropertyListContentType;

extern NSString *DQHTTPRequestFileInfoParameterNameKey;
extern NSString *DQHTTPRequestFileInfoFilenameKey;
extern NSString *DQHTTPRequestFileInfoFileDataKey;
extern NSString *DQHTTPRequestFileInfoFilePathKey;
extern NSString *DQHTTPRequestFileInfoContentTypeKey;
extern NSString *DQHTTPRequestFileInfoUUIDKey;

extern NSString *DQHTTPRequestCacheSubdirectory;

extern const NSInteger DQHTTPRequestNoNetworkStatusCode;
extern const NSInteger DQHTTPRequestNoCachedDataStatusCode;
extern const NSInteger DQHTTPRequestLoadedCachedDataStatusCode;
extern const NSInteger DQHTTPRequestSuccessStatusCode;
extern const NSInteger DQHTTPRequestUnauthorizedStatusCode;
extern const NSInteger DQHTTPRequestForbiddenStatusCode;
extern const NSInteger DQHTTPRequestMinClientErrorStatusCode;
extern const NSInteger DQHTTPRequestMaxClientErrorStatusCode;
extern const NSInteger DQHTTPRequestMinServerErrorStatusCode;
extern const NSInteger DQHTTPRequestMaxServerErrorStatusCode;


typedef enum {
    DQHTTPRequestMethodGET,
    DQHTTPRequestMethodPOST,
    DQHTTPRequestMethodPUT,
    DQHTTPRequestMethodDELETE,
    DQHTTPRequestMethodHEAD
} DQHTTPRequestMethod;

typedef enum {
    DQHTTPRequestStatusIdle,
    DQHTTPRequestStatusIgnoreThisObsoleteStatus,
    DQHTTPRequestStatusLoading,
    DQHTTPRequestStatusComplete,
    DQHTTPRequestStatusFailed
} DQHTTPRequestStatus;

typedef enum {
    DQHTTPRequestPOSTBodyFormatMultipart,
    DQHTTPRequestPOSTBodyFormatJSON,
    DQHTTPRequestPOSTBodyFormatURLEncoded
} DQHTTPRequestPOSTBodyFormat;

typedef enum {
    DQHTTPRequestAuthenticationTypeNone,
    DQHTTPRequestAuthenticationTypeBasic,
    DQHTTPRequestAuthenticationTypeOAuth1,
    DQHTTPRequestAuthenticationTypeOAuth2
} DQHTTPRequestAuthenticationType;

typedef enum {
    DQHTTPRequestRetryMethodNone,
    DQHTTPRequestRetryMethodFixed,
    DQHTTPRequestRetryMethodExponentialBackoff,
    DQHTTPRequestRetryMethodRandomizedBackoff
} DQHTTPRequestRetryMethod;

typedef void (^DQHTTPRequestStatusBlock)(DQHTTPRequest *);
typedef NSError *(^DQHTTPRequestValidationBlock)(DQHTTPRequest *);

@protocol DQHTTPRequestDelegate <NSObject>

- (void)httpRequestDidStart:(DQHTTPRequest *)request;
- (void)httpRequestDidFinish:(DQHTTPRequest *)request;
- (void)httpRequestDidFail:(DQHTTPRequest *)request;

@end

@interface DQHTTPRequest : NSOperation {
    NSURL *URL;
    
    NSString *baseURL;
    NSString *command;

    NSString *tag;
    NSString *identifier;
    
    NSMutableDictionary *userInfo;
    
    NSString *userAgent;
    NSDate *time;

    DQHTTPRequestPOSTBodyFormat postBodyFormat;
    BOOL streamsPOSTBodyFromDisk;
    NSInputStream *POSTBodyInputStream;
        
    BOOL persistable;
    BOOL persistsHeaders;
    NSArray *nonPersistableHeaderList;

    DQHTTPRequestMethod requestMethod;
    DQHTTPRequestStatus loadStatus;
    NSTimeInterval timeoutInterval;
    NSError *error;
   
    DQHTTPRequestRetryMethod retryMethod;
    NSInteger retryCount;
    NSInteger maximumRetryCount;
    
    NSMutableDictionary *headers;
    NSMutableDictionary *queryParameters;
    NSMutableDictionary *postBodyParameters;
    NSMutableDictionary *postBodyFiles;
    NSMutableData *postBodyData;
    NSFileHandle *postBodyFileHandle;
    
    DQHTTPRequestAuthenticationType authenticationType;
    
    NSString *basicAuthUsername;
    NSString *basicAuthPassword;
    NSString *basicAuthKeychainServiceName;
    
    NSString *OAuthConsumerKey;
    NSString *OAuthSecretKey;
    NSString *OAuthToken;
    NSString *OAuthTokenSecret;
    NSMutableDictionary *additionalOAuthParameters;
    
    NSURLConnection *connection;

    float uploadPercentComplete;
    
    NSHTTPURLResponse *response;
    NSInteger responseStatusCode;
    NSString *responseMIMEType;
    NSMutableData *responseData;
    id responseJSONObject;
    NSString *responseString;
    NSMutableDictionary *responseURLEncodedDictionary;
    
    NSNumber *responsePercentComplete;
    
    DQHTTPRequestStatusBlock requestDidStartBlock;
    DQHTTPRequestStatusBlock requestDidFinishBlock;
    DQHTTPRequestStatusBlock requestDidUploadDataBlock;
    DQHTTPRequestStatusBlock requestDidDownloadDataBlock;
    DQHTTPRequestStatusBlock requestDidFailBlock;
    DQHTTPRequestValidationBlock responseValidationBlock;
    
#if TARGET_OS_IPHONE
    BOOL spinsActivityIndicator;
#endif
}

@property (nonatomic, strong, readonly) NSURL *URL;

@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *command;
@property (weak, nonatomic, readonly) NSString *queryString;
@property (nonatomic, strong) NSMutableDictionary *queryParameters;

@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, strong, readonly) NSDate *time;

@property (nonatomic, assign) DQHTTPRequestPOSTBodyFormat postBodyFormat;
@property (nonatomic, strong) NSMutableDictionary *postBodyParameters;

@property (nonatomic, assign) DQHTTPRequestAuthenticationType authenticationType;
@property (nonatomic, readonly) BOOL requiresOAuth;
@property (nonatomic, readonly) BOOL hasBasicAuthCredentials;

@property (nonatomic, strong) NSString *basicAuthUsername;
@property (nonatomic, strong) NSString *basicAuthPassword;
@property (nonatomic, strong) NSString *basicAuthKeychainServiceName;

@property (nonatomic, strong) NSString *OAuthConsumerKey;
@property (nonatomic, strong) NSString *OAuthSecretKey;
@property (nonatomic, strong) NSString *OAuthToken;
@property (nonatomic, strong) NSString *OAuthTokenSecret;
@property (nonatomic, strong) NSMutableDictionary *additionalOAuthParameters;

@property (nonatomic, assign) BOOL persistsHeaders;
@property (nonatomic, strong) NSArray *nonPersistableHeaderList;

@property (nonatomic, assign) BOOL streamsPOSTBodyFromDisk;
@property (nonatomic, assign) BOOL gzippedPOSTBody;

@property (nonatomic, assign, readonly, getter=isRetryable) BOOL retryable;
@property (nonatomic, assign) DQHTTPRequestRetryMethod retryMethod;
@property (nonatomic, readonly) NSInteger retryCount;
@property (nonatomic, assign) NSInteger maximumRetryCount;

@property (nonatomic, assign) DQHTTPRequestMethod requestMethod;
@property (nonatomic, readonly) DQHTTPRequestStatus loadStatus;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@property (nonatomic, readonly) BOOL isLoading;

@property (nonatomic, assign, readonly) float uploadPercentComplete;

@property (nonatomic, assign, readonly) NSInteger responseStatusCode;
@property (nonatomic, strong, readonly) NSString *responseMIMEType;
@property (nonatomic, strong, readonly) NSMutableData *responseData;
@property (nonatomic, strong, readonly) id responseJSONObject;
@property (nonatomic, strong, readonly) NSString *responseString;
@property (nonatomic, strong, readonly) NSNumber *responsePercentComplete;
@property (nonatomic, strong, readonly) NSDictionary *responseURLEncodedDictionary;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, copy) NSDictionary *(^papertrailLoggerDataBlock)();

@property (nonatomic, weak) id<DQHTTPRequestDelegate> delegate;

@property (copy) DQHTTPRequestStatusBlock requestDidStartBlock;
@property (copy) DQHTTPRequestStatusBlock requestDidFinishBlock;
@property (copy) DQHTTPRequestStatusBlock requestDidFailBlock;
@property (copy) DQHTTPRequestStatusBlock requestDidUploadDataBlock;
@property (copy) DQHTTPRequestStatusBlock requestDidDownloadDataBlock;
@property (copy) DQHTTPRequestValidationBlock responseValidationBlock;

#if TARGET_OS_IPHONE
@property (nonatomic, assign) BOOL spinsActivityIndicator;
#endif

- (NSString *)requestMethodStringForRequestMethod:(DQHTTPRequestMethod)inRequestMethod;
- (NSString *)_basicAuthPassword;

// Static Methods
+ (id)requestWithBaseURL:(NSString *)inBaseURL;
+ (id)requestWithBaseURL:(NSString *)inBaseURL command:(NSString *)inCommand;

// Initialization

// designated initializer
- (id)initWithBaseURL:(NSString *)inBaseURL command:(NSString *)inCommand userInfo:(NSDictionary *)inUserInfo;

// convenience initializers
- (id)initWithBaseURL:(NSString *)inBaseURL;
- (id)initWithBaseURL:(NSString *)inBaseURL command:(NSString *)inCommand;

- (id)init MSDesignatedInitializer(initWithBaseURL:command:userInfo:);

// Headers
- (void)addHeadersFromDictionary:(NSDictionary *)inDictionary;
- (void)setHeaderString:(NSString *)inHeaderString forKey:(NSString *)inKey;
- (NSString *)headerStringForKey:(NSString *)inKey;

// Query Parameters
- (void)addQueryParametersFromDictionary:(NSDictionary *)inDictionary;
- (void)setQueryParametersValue:(id)queryParameter forKey:(NSString *)inKey;
- (id)queryParameterValueForKey:(NSString *)inKey;

// POST Body Parameters
- (void)addPostBodyParametersFromDictionary:(NSDictionary *)inDictionary;
- (void)setPostBodyParameterValue:(id)inPostBodyParameter forKey:(NSString *)inKey;
- (id)postBodyParameterValueForKey:(NSString *)inKey;

// OAuth Parameters
- (void)addOAuthParametersFromDictionary:(NSDictionary *)inDictionary;
- (void)setOAuthParameter:(id)inOAuthParameter forKey:(NSString *)inKey;
- (id)OAuthParameterForKey:(NSString *)inKey;

// POST Body Files
- (void)addPostBodyFileWithPath:(NSString *)inFilePath fileInfo:(NSDictionary *)inDictionary;
- (void)setPostBodyFileData:(NSData *)inData forParameterName:(NSString *)inParameterName filename:(NSString *)inFilename contentType:(NSString *)inContentType;
- (NSDictionary *)postBodyFileInfoForParameterName:(NSString *)forParameterName;

// User Info
- (void)addUserInfoFromDictionary:(NSDictionary *)inDictionary;
- (void)setUserInfoValue:(id)inValue forKey:(NSString *)inKey;
- (id)userInfoValueForKey:(NSString *)inKey;

@end
