//
//  DQHTTPRequest.m
//
//  Created by Buzz Andersen on 3/8/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

// TO DO Use GCD IO for POST body streaming

#import "DQHTTPRequest.h"
#import "Reachability.h"
#import "STUtils.h"
#import "STKeychain.h"
#import "STNetworkActivityIndicator.h"
#import "ASIDataCompressor.h"
#import "DQPapertrailLogger.h"

// Constants
NSString *DQHTTPRequestUserAgentHeaderKey = @"User-Agent";
NSString *DQHTTPRequestTimeZoneHeaderKey = @"Time-Zone";
NSString *DQHTTPRequestContentTypeHeaderKey = @"Content-Type";
NSString *DQHTTPRequestContentLengthHeaderKey = @"Content-Length";
NSString *DQHTTPRequestAcceptLanguageHeaderKey = @"Accept-Language";
NSString *DQHTTPRequestAuthorizationHeaderKey = @"Authorization";
NSString *DQAPIIdiomHeaderKey = @"X-Idiom";
NSString *DQAPIIdentifierForVendorHeaderKey = @"X-IFV";
NSString *DQHTTPRequestContentEncodingHeaderKey = @"Content-Encoding";
NSString *DQHTTPRequestTextHTMLContentType = @"text/html";
NSString *DQHTTPRequestTextPlainContentType = @"text/plain";
NSString *DQHTTPRequestJSONContentType = @"application/json";
NSString *DQHTTPRequestPropertyListContentType = @"application/x-plist";
NSString *DQHTTPRequestJavascriptContentType = @"text/javascript";
NSString *DQHTTPRequestApplicationJavascriptContentType = @"application/javascript";
NSString *DQHTTPRequestURLEncodedContentType = @"application/x-www-form-urlencoded";
NSString *DQHTTPRequestMultipartContentType = @"multipart/form-data; boundary=\"%@\"";
NSString *DQHTTPRequestOctetStreamContentType = @"application/octet-stream";

NSString *DQHTTPRequestMultipartBoundaryString = @"0xKhTmLbOuNdArY";

NSString *DQHTTPRequestCacheSubdirectory = @"DQHTTPRequest";
NSString *DQHTTPRequestPOSTBodyCacheDirectory = @"POSTBodyCache";

NSString *DQHTTPRequestFileInfoParameterNameKey = @"DQHTTPRequestFileInfoParameterNameKey";
NSString *DQHTTPRequestFileInfoFilenameKey = @"DQHTTPRequestFileInfoFilenameKey";
NSString *DQHTTPRequestFileInfoFileDataKey = @"DQHTTPRequestFileInfoFileDataKey";
NSString *DQHTTPRequestFileInfoFilePathKey = @"DQHTTPRequestFileInfoFilePathKey";
NSString *DQHTTPRequestFileInfoContentTypeKey = @"DQHTTPRequestFileInfoContentTypeKey";
NSString *DQHTTPRequestFileInfoUUIDKey = @"DQHTTPRequestFileInfoUUIDKey";

NSString *DQHTTPRequestErrorDomain = @"DQHTTPRequestErrorDomain";

const NSInteger DQHTTPRequestCancelledError = 1004;
const NSInteger DQHTTPRequestCouldNotCreateConnectionError = 1010;

const NSInteger DQHTTPRequestNoNetworkStatusCode = 0;
const NSInteger DQHTTPRequestNoCachedDataStatusCode = 1;
const NSInteger DQHTTPRequestLoadedCachedDataStatusCode = 2;
const NSInteger DQHTTPRequestSuccessStatusCode = 200;
const NSInteger DQHTTPRequestUnauthorizedStatusCode = 401;
const NSInteger DQHTTPRequestForbiddenStatusCode = 403;
const NSInteger DQHTTPRequestMinClientErrorStatusCode = 400;
const NSInteger DQHTTPRequestMaxClientErrorStatusCode = 499;
const NSInteger DQHTTPRequestMinServerErrorStatusCode = 500;
const NSInteger DQHTTPRequestMaxServerErrorStatusCode = 599;

const NSTimeInterval DQHTTPRequestDefaultTimeoutInterval = 35.0;
const NSInteger DQHTTPRequestDefaultMaximumRetryCount = 5;

const NSInteger DQHTTPRequestPOSTBodyStreamBufferSize = 1024;

// Class variables
static NSString *__preferredLanguages = nil;


@interface DQHTTPRequest ()

@property (nonatomic, strong) NSURL *URL;

@property (nonatomic, strong) NSDate *time;

@property (nonatomic, strong) NSMutableDictionary *userInfo;

@property (nonatomic, assign) DQHTTPRequestStatus loadStatus;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) NSInteger retryCount;

@property (nonatomic, strong) NSMutableDictionary *headers;
@property (nonatomic, strong) NSMutableDictionary *postBodyFiles;
@property (nonatomic, strong) NSMutableData *postBodyData;
@property (nonatomic, strong) NSFileHandle *postBodyFileHandle;

@property (nonatomic, strong) NSString *cachedPOSTBodyFilePath;

@property (nonatomic, assign, getter = isFinished) BOOL finished;
@property (nonatomic, assign, getter = isExecuting) BOOL executing;

@property (nonatomic, assign) float uploadPercentComplete;

@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, strong) NSString *responseMIMEType;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) id responseJSONObject;
@property (nonatomic, strong) NSString *responseString;
@property (nonatomic, strong) NSDictionary *responseURLEncodedDictionary;
@property (nonatomic, strong) NSNumber *responsePercentComplete;

+ (NSString *)cachePathForFilename:(NSString *)inFilename;

+ (NSThread *)networkThread;
+ (void)_runNetworkThread;

- (void)_addPostBodyFileWithData:(NSData *)inData forParameterName:(NSString *)inParameterName filename:(NSString *)inFilename contentType:(NSString *)inContentType fileUUID:(NSString *)inFileUUID;
- (void)_updateURL;
- (NSURLRequest *)_configuredURLRequest;
- (NSString *)_stringValueForParameterObject:(NSString *)inObject;
- (void)_handleResponseData;
- (BOOL)_statusCodeIsError:(NSInteger)statusCode;

- (void)_resetPOSTBody;
- (NSUInteger)_buildPOSTBody;
- (void)_buildMultipartPOSTBody;
- (void)_buildJSONPOSTBody;
- (void)_buildURLEncodedPOSTBody;

- (void)_appendPOSTBodyUTF8String:(NSString *)inString;
- (void)_appendPOSTBodyUTF8StringWithFormat:(NSString *)inString, ...;
- (void)_appendPOSTBodyData:(NSData *)inData;
- (void)_appendPOSTBodyFileDataAtPath:(NSString *)inPath;

@end


@implementation DQHTTPRequest

@synthesize URL;
@synthesize baseURL;
@synthesize command;
@synthesize tag;
@synthesize identifier;
@synthesize userInfo;
@synthesize time;
@synthesize userAgent;
@synthesize queryParameters;
@synthesize streamsPOSTBodyFromDisk;
@synthesize cachedPOSTBodyFilePath;
@synthesize persistsHeaders;
@synthesize nonPersistableHeaderList;
@synthesize requestMethod;
@synthesize loadStatus;
@synthesize timeoutInterval;
@synthesize error;
@synthesize retryMethod;
@synthesize retryCount;
@synthesize maximumRetryCount;
@synthesize headers;
@synthesize postBodyParameters;
@synthesize postBodyFiles;
@synthesize postBodyFormat;
@synthesize postBodyData;
@synthesize postBodyFileHandle;
@synthesize authenticationType;
@synthesize basicAuthUsername;
@synthesize basicAuthPassword;
@synthesize basicAuthKeychainServiceName;
@synthesize OAuthConsumerKey;
@synthesize OAuthSecretKey;
@synthesize OAuthToken;
@synthesize OAuthTokenSecret;
@synthesize additionalOAuthParameters;
@synthesize uploadPercentComplete;
@synthesize response;
@synthesize responseStatusCode;
@synthesize responseMIMEType;
@synthesize responseData;
@synthesize responseJSONObject;
@synthesize responseString;
@synthesize responseURLEncodedDictionary;
@synthesize responsePercentComplete;
@synthesize requestDidStartBlock;
@synthesize requestDidFinishBlock;
@synthesize requestDidFailBlock;
@synthesize requestDidUploadDataBlock;
@synthesize requestDidDownloadDataBlock;
@synthesize responseValidationBlock;
@synthesize finished = _finished;
@synthesize executing = _executing;

#if TARGET_OS_IPHONE
@synthesize spinsActivityIndicator;
#endif

#pragma mark Static Methods

+ (void)initialize
{
    if (self == [DQHTTPRequest class])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeUpdated:) name:NSCurrentLocaleDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeUpdated:) name:DQLocalizationSupportedLanguagesDidChangeNotification object:nil];
        [self localeUpdated:nil];
    }
}

+ (void)localeUpdated:(NSNotification *)notification
{
    NSMutableOrderedSet *languages = [[NSMutableOrderedSet alloc] initWithArray:[NSLocale preferredLanguages]];
    [languages intersectOrderedSet:[NSOrderedSet orderedSetWithArray:[DQLocalization supportedLanguages] ?: [DQLocalization allLanguages]]];
    NSMutableString *value = [NSMutableString new];
    NSUInteger q = 100;
    for (NSString *lang in languages)
    {
        if (q == 100)
        {
            [value appendString:lang];
        }
        else
        {
            [value appendString:[NSString stringWithFormat:@", %@;q=0.%lu", lang, (unsigned long)q]];
        }
        q = MAX(0, q-1);
    }
    __preferredLanguages = [value copy];
}

+ (id)requestWithBaseURL:(NSString *)inBaseURL;
{
    return [[self alloc] initWithBaseURL:inBaseURL command:nil userInfo:nil];
}

+ (id)requestWithBaseURL:(NSString *)inBaseURL command:(NSString *)inCommand;
{
    return [[self alloc] initWithBaseURL:inBaseURL command:inCommand userInfo:nil];
}

+ (NSThread *)networkThread;
{
    static NSThread *networkThread = nil;
    
	if (!networkThread) {
		networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(_runNetworkThread) object:nil];
        [networkThread setName:@"com.systemoftouch.DQHTTPRequest"];
		[networkThread start];
	}
    
	return networkThread;
}

+ (void)_runNetworkThread;
{
    BOOL done = NO;
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    } while (!done);
}

+ (NSString *)cachePathForFilename:(NSString *)inFilename;
{
    if (!inFilename.length) {
        return nil;
    }
    
    NSMutableArray *pathComponents = [[NSMutableArray alloc] init];
    
    // If we're on a Mac, include the app name in the
    // application support path.
    NSFileManager *fm = [NSFileManager new];
#if !TARGET_OS_IPHONE
    [pathComponents addObject:[fm cachePathIncludingAppName]];
#else
    [pathComponents addObject:[fm cachePath]];
#endif
    
    [pathComponents addObject:DQHTTPRequestCacheSubdirectory];
    [pathComponents addObject:inFilename];
         
    NSString *fullPath = [NSString pathWithComponents:pathComponents];
    
    
    return fullPath;
}

#pragma mark Initialization

- (id)initWithBaseURL:(NSString *)inBaseURL;
{
    return [self initWithBaseURL:inBaseURL command:nil userInfo:nil];
}

- (id)initWithBaseURL:(NSString *)inBaseURL command:(NSString *)inCommand;
{
    return [self initWithBaseURL:inBaseURL command:inCommand userInfo:nil];
}

- (id)initWithBaseURL:(NSString *)inBaseURL command:(NSString *)inCommand userInfo:(NSDictionary *)inUserInfo;
{    
    if (!(self = [super init])) {
        return nil;
    }
    
    self.requestMethod = DQHTTPRequestMethodGET;
    self.loadStatus = DQHTTPRequestStatusIdle;
    self.responseStatusCode = 0;

    self.retryMethod = DQHTTPRequestRetryMethodNone;
    self.maximumRetryCount = DQHTTPRequestDefaultMaximumRetryCount;
    self.retryCount = 0;
    
    self.authenticationType = DQHTTPRequestAuthenticationTypeNone;
    self.timeoutInterval = DQHTTPRequestDefaultTimeoutInterval;
    self.identifier = [NSString UUIDString];
    self.cachedPOSTBodyFilePath = nil;

    self.baseURL = inBaseURL;
    self.command = inCommand;
    
    userInfo = [inUserInfo mutableCopy];
    
    self.responsePercentComplete = @0.0f;
    self.uploadPercentComplete = 0.0f;
    
    self.postBodyFormat = DQHTTPRequestPOSTBodyFormatURLEncoded;
    self.streamsPOSTBodyFromDisk = NO;
    self.postBodyFileHandle = nil;
    self.postBodyData = nil;
    POSTBodyInputStream = nil;
    
#if TARGET_OS_IPHONE
    self.spinsActivityIndicator = YES;
#endif
    
    return self;    
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _delegate = nil;
    [self _resetPOSTBody];
}

#pragma mark Accessors

- (void)setBaseURL:(NSString *)inBaseURL;
{
    if (self.isLoading) {
        return;
    }
    
    baseURL = inBaseURL;
    
    [self _updateURL];
}

- (void)setCommand:(NSString *)inCommand;
{
    if (self.isLoading) {
        return;
    }
    
    command = inCommand;
    
    [self _updateURL];
}

- (void)setRequestMethod:(DQHTTPRequestMethod)inRequestMethod;
{
    if (self.isLoading) {
        return;
    }
    
    requestMethod = inRequestMethod;
    
    [self _updateURL];
}

- (void)setAuthenticationType:(DQHTTPRequestAuthenticationType)inAuthenticationType;
{
    if (self.isLoading) {
        return;
    }
    
    authenticationType = inAuthenticationType;    
}

- (void)setBasicAuthUsername:(NSString *)inBasicAuthUsername;
{
    if (self.isLoading) {
        return;
    }
    
    basicAuthUsername = inBasicAuthUsername;
}

- (void)setBasicAuthPassword:(NSString *)inBasicAuthPassword;
{
    if (self.isLoading) {
        return;
    }
    
    basicAuthPassword = inBasicAuthPassword;
}

- (void)setBasicAuthKeychainServiceName:(NSString *)inBasicAuthKeychainServiceName;
{
    if (self.isLoading) {
        return;
    }
    
    basicAuthKeychainServiceName = inBasicAuthKeychainServiceName;
}

- (BOOL)hasBasicAuthCredentials;
{
    return [[self basicAuthUsername] length] && [[self _basicAuthPassword] length];
}

- (NSString *)queryString;
{
    return [self.queryParameters URLEncodedStringValue];
}

- (void)setUserAgent:(NSString *)inUserAgent;
{
    if (self.isLoading) {
        return;
    }
    
    @synchronized (self) {
        userAgent = inUserAgent;
    }
}

- (void)setTime:(NSDate *)inTime;
{
    if (self.isLoading) {
        return;
    }
    
    @synchronized (self) {
        time = inTime;
    }
}

- (void)setResponse:(NSHTTPURLResponse *)inResponse;
{
    response = inResponse;
    
    if (inResponse) {
        self.responseStatusCode = inResponse.statusCode;
        self.responseMIMEType = inResponse.MIMEType;
    }
}

- (BOOL)isRetryable;
{
    return self.responseStatusCode == DQHTTPRequestNoNetworkStatusCode || self.responseStatusCode == DQHTTPRequestUnauthorizedStatusCode || (self.responseStatusCode < DQHTTPRequestMinServerErrorStatusCode && self.responseStatusCode > DQHTTPRequestMaxServerErrorStatusCode);
}

- (NSMutableDictionary *)headers;
{
    if (!headers) {
       headers = [[NSMutableDictionary alloc] init];
    }    
    
    return headers;
}

- (NSMutableDictionary *)queryParameters;
{
    if (!queryParameters) {
        queryParameters = [[NSMutableDictionary alloc] init];
    }
    
    return queryParameters;
}

- (NSMutableDictionary *)postBodyParameters;
{
    if (!postBodyParameters) {
        postBodyParameters = [[NSMutableDictionary alloc] init];
    }
    
    return postBodyParameters;
}

- (NSMutableDictionary *)postBodyFiles;
{
    if (!postBodyFiles) {
        postBodyFiles = [[NSMutableDictionary alloc] init];
    }

    return postBodyFiles;
}

- (BOOL)requiresOAuth;
{
    return (self.authenticationType == DQHTTPRequestAuthenticationTypeOAuth1 || self.authenticationType == DQHTTPRequestAuthenticationTypeOAuth2);
}

- (NSMutableDictionary *)additionalOAuthParameters;
{
    if (!additionalOAuthParameters) {
        additionalOAuthParameters = [[NSMutableDictionary alloc] init];
    }
    
    return additionalOAuthParameters;
}

- (NSInteger)responseStatusCode;
{
    if (!self.response) {
        return 0;
    }
    
    return [self.response statusCode];
}

- (NSMutableData *)responseData;
{
    if (!responseData) {
        responseData = [[NSMutableData alloc] init];
    }
    
    return responseData;
}

- (BOOL)isLoading;
{
    return (self.loadStatus == DQHTTPRequestStatusLoading);
}

- (NSMutableDictionary *)userInfo;
{
    if (!userInfo) {
        userInfo = [[NSMutableDictionary alloc] init];
    }
    
    return userInfo;
}

#pragma mark NSObject

- (BOOL)isEqual:(id)obj;
{
    // If they are literally the same object pointer-wise,
    // simply return YES.
    if ([super isEqual:obj]) return YES;
    
    BOOL equal = NO;
    
    if ([obj isKindOfClass:[DQHTTPRequest class]]) {
        equal = [((DQHTTPRequest *) obj).identifier isEqualToString:self.identifier];
    }
    
    return equal;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p (base URL: %@; command: %@; tag: %@; identifier: %@)>\nQuery Parameters%@\nPost Parameters: %@\nHeaders: %@\nUser Info: %@", NSStringFromClass([self class]), (void *)self, self.baseURL, self.command, self.tag, self.identifier, self.queryParameters, self.postBodyParameters, self.headers, self.userInfo];
}

#pragma mark Headers

- (void)addHeadersFromDictionary:(NSDictionary *)inDictionary;
{
    if (!inDictionary.count || self.isLoading) {
        return;
    }
    
    [self.headers addEntriesFromDictionary:inDictionary];
}

- (void)setHeaderString:(NSString *)inHeaderString forKey:(NSString *)inKey;
{
    if (!inHeaderString.length || !inKey.length) {
        return;
    }
        
    [self.headers setObject:inHeaderString forKey:inKey];
}

- (NSString *)headerStringForKey:(NSString *)inKey;
{
    return [self.headers stringForKey:inKey];
}

#pragma mark Query Parameters

- (void)addQueryParametersFromDictionary:(NSDictionary *)inDictionary;
{
    if (!inDictionary.count || self.isLoading) {
        return;
    }
    
    [self.queryParameters addEntriesFromDictionary:inDictionary];
    [self _updateURL];
}

- (void)setQueryParametersValue:(id)inQueryParameter forKey:(NSString *)inKey;
{
    if (!inQueryParameter || !inKey.length || self.isLoading) {
        return;
    }
    
    [self.queryParameters setObject:inQueryParameter forKey:inKey];
    [self _updateURL];
}

- (id)queryParameterValueForKey:(NSString *)inKey;
{
    return [self.queryParameters objectForKey:inKey];
}

#pragma mark POST Body Parameters

- (void)addPostBodyParametersFromDictionary:(NSDictionary *)inDictionary;
{
    if (!inDictionary.count || self.isLoading) {
        return;
    }
    
    [self.postBodyParameters addEntriesFromDictionary:inDictionary];
}

- (void)setPostBodyParameterValue:(id)inPostBodyParameter forKey:(NSString *)inKey;
{
    if (!inPostBodyParameter || !inKey.length || self.isLoading) {
        return;
    }
    
    [self.postBodyParameters setObject:inPostBodyParameter forKey:inKey];
}

- (id)postBodyParameterValueForKey:(NSString *)inKey;
{
    return [self.postBodyParameters objectForKey:inKey];
}

#pragma mark POST Body Files

- (void)setPostBodyFileData:(NSData *)inData forParameterName:(NSString *)inParameterName filename:(NSString *)inFilename contentType:(NSString *)inContentType;
{
    [self _addPostBodyFileWithData:inData forParameterName:inParameterName filename:inFilename contentType:inContentType fileUUID:nil];
}

- (void)addPostBodyFileWithPath:(NSString *)inFilePath fileInfo:(NSDictionary *)inDictionary;
{
    if (!inFilePath.length || !inDictionary.count || self.isLoading) {
        return;
    }
    
    NSString *parameterName = [inDictionary objectForKey:DQHTTPRequestFileInfoParameterNameKey];
    NSString *mimeType = [inDictionary objectForKey:DQHTTPRequestFileInfoContentTypeKey];
    NSData *fileData = [inDictionary objectForKey:DQHTTPRequestFileInfoFileDataKey];
    NSString *filePath = [inDictionary objectForKey:DQHTTPRequestFileInfoFilePathKey];
    
    // Make sure the dictionary contains the required attributes
    // before adding it to the file info
    if ( ! ([filePath length] || ![fileData length]) || ![mimeType length] || ![parameterName length])
    {
        return;
    }
    [self.postBodyFiles setObject:inDictionary forKey:parameterName];
}

- (void)_addPostBodyFileWithData:(NSData *)inData forParameterName:(NSString *)inParameterName filename:(NSString *)inFilename contentType:(NSString *)inContentType fileUUID:(NSString *)inFileUUID;
{
    BOOL hasData = inData && [inData length];
    BOOL hasContentType = inContentType && [inContentType length];
    BOOL hasParameterName = inParameterName && [inParameterName length];
    if (hasData && hasContentType && hasParameterName && !self.isLoading)
    {
        // If a file UUID is provided, use that, otherwise create one
        NSString *fileUUID = inFileUUID.length ? inFileUUID : [NSString UUIDString];

        NSString *filename = inFilename;
        if (![filename length])
        {
            filename = inParameterName;
        }
        NSMutableDictionary *fileInfoDictionary = [[NSMutableDictionary alloc] init];
        [fileInfoDictionary setObject:filename forKey:DQHTTPRequestFileInfoFilenameKey];
        [fileInfoDictionary setObject:inContentType forKey:DQHTTPRequestFileInfoContentTypeKey];
        [fileInfoDictionary setObject:fileUUID forKey:DQHTTPRequestFileInfoUUIDKey];
        [fileInfoDictionary setObject:inParameterName forKey:DQHTTPRequestFileInfoParameterNameKey];
        [fileInfoDictionary setObject:inData forKey:DQHTTPRequestFileInfoFileDataKey];
        [self.postBodyFiles setObject:fileInfoDictionary forKey:inParameterName];
    }
}

- (NSDictionary *)postBodyFileInfoForParameterName:(NSString *)inKey;
{
    return [self.postBodyFiles objectForKey:inKey];
}

#pragma mark OAuth Parameters

- (void)addOAuthParametersFromDictionary:(NSDictionary *)inDictionary;
{
    if (!inDictionary.count || self.isLoading) {
        return;
    }
    
    [self.additionalOAuthParameters addEntriesFromDictionary:inDictionary];
}

- (void)setOAuthParameter:(id)inOAuthParameter forKey:(NSString *)inKey;
{
    if (!inOAuthParameter || !inKey.length || self.isLoading) {
        return;
    }
    
    [self.additionalOAuthParameters setObject:inOAuthParameter forKey:inKey];
}

- (id)OAuthParameterForKey:(NSString *)inKey;
{
    return [self.additionalOAuthParameters objectForKey:inKey];
}

#pragma mark User Info

- (void)addUserInfoFromDictionary:(NSDictionary *)inDictionary;
{
    [self.userInfo addEntriesFromDictionary:inDictionary];
}

- (void)setUserInfoValue:(id)inValue forKey:(NSString *)inKey;
{
    [self.userInfo setObject:inValue forKey:inKey];
}

- (id)userInfoValueForKey:(NSString *)inKey;
{
    return [self.userInfo objectForKey:inKey];
}

#pragma mark NSOperation

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
	return YES;
}

// called on the queue's thread
- (void)start
{
    if ([self isCancelled])
    {
        self.finished = YES;
        NSError *cancelledError = [NSError errorWithDomain:DQHTTPRequestErrorDomain code:DQHTTPRequestCancelledError userInfo:nil];
        [self tellDelegateDidFailWithError:cancelledError];
    }
    else
    {
        self.executing = YES;
        NSDate *latestTime = [[NSDate alloc] init];
        self.time = latestTime;

        self.loadStatus = DQHTTPRequestStatusLoading;

        NSURLRequest *request = [self _configuredURLRequest];
        connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [connection start];

        if (connection)
        {
            id<DQHTTPRequestDelegate> delegate = self.delegate;
            BOOL tellDelegate = delegate != nil;
            DQHTTPRequestStatusBlock block = self.requestDidStartBlock;

            if (tellDelegate || block)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (tellDelegate)
                    {
                        [delegate httpRequestDidStart:self];
                    }
                    if (block)
                    {
                        block(self);
                    }
                });
            }

#if TARGET_OS_IPHONE
            if (self.spinsActivityIndicator)
            {
                [[STNetworkActivityIndicator sharedIndicator] increment];
            }
#endif
            CFRunLoopRun();
        }
        else
        {
            NSError *connectionFailedError = [NSError errorWithDomain:DQHTTPRequestErrorDomain code:DQHTTPRequestCouldNotCreateConnectionError userInfo:nil];
            [self tellDelegateDidFailWithError:connectionFailedError];
            self.executing = NO;
            self.finished = YES;
        }
    }
}

- (void)cancel
{
    if (self.finished) return;
    [super cancel];
    if (connection)
    {
#if TARGET_OS_IPHONE
        if (self.spinsActivityIndicator)
        {
            [[STNetworkActivityIndicator sharedIndicator] decrement];
        }
#endif
        [connection cancel];
        [self _resetPOSTBody];
        self.executing = NO;
        self.finished = YES;
    }
}

- (void)markAsComplete
{
#if TARGET_OS_IPHONE
    if (self.spinsActivityIndicator)
    {
        [[STNetworkActivityIndicator sharedIndicator] decrement];
    }
#endif
    [self _resetPOSTBody];
    self.executing = NO;
    self.finished = YES;
}

- (void)tellDelegateDidFinish
{
    self.loadStatus = DQHTTPRequestStatusComplete;
    self.error = nil;

    id<DQHTTPRequestDelegate> delegate = self.delegate;
    BOOL tellDelegate = delegate != nil;
    DQHTTPRequestStatusBlock block = self.requestDidFinishBlock;

    if (tellDelegate || block)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tellDelegate)
            {
                [delegate httpRequestDidFinish:self];
            }
            if (block)
            {
                block(self);
            }
        });
    }
}

- (void)tellDelegateDidFailWithError:(NSError *)inError
{
    self.loadStatus = DQHTTPRequestStatusFailed;
    self.error = inError;

    id<DQHTTPRequestDelegate> delegate = self.delegate;
    BOOL tellDelegate = delegate != nil;
    DQHTTPRequestStatusBlock failedBlock = self.requestDidFailBlock;

    if (tellDelegate || failedBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tellDelegate)
            {
                [delegate httpRequestDidFail:self];
            }
            if (failedBlock)
            {
                failedBlock(self);
            }
        });
    }
}

#pragma mark NSURLConnection

- (void)connection:(NSURLConnection *)inConnection didReceiveResponse:(NSURLResponse *)inResponse
{
    self.response = [inResponse isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)inResponse : nil;
}

- (void)connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)inData
{
    float percentComplete = (float) inData.length / [self.response expectedContentLength];
    self.responsePercentComplete = @(percentComplete);
    
    [self.responseData appendData:inData];
    
    if (self.requestDidDownloadDataBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.requestDidDownloadDataBlock(self);
        });
    }
}

- (void)connection:(NSURLConnection *)inConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)inChallenge;
{
    if (!self.hasBasicAuthCredentials) {
        return;
    }
    
    if (inChallenge.previousFailureCount > 0) {
        [[inChallenge sender] continueWithoutCredentialForAuthenticationChallenge:inChallenge];
    }
    
    NSURLCredential *credential = [NSURLCredential credentialWithUser:self.basicAuthUsername password:[self _basicAuthPassword] persistence:NSURLCredentialPersistenceNone];
	[[inChallenge sender] useCredential:credential forAuthenticationChallenge:inChallenge];
}

- (void)connection:(NSURLConnection *)inConnection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    self.uploadPercentComplete = (float)totalBytesWritten / totalBytesExpectedToWrite;

    if (self.requestDidUploadDataBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.requestDidUploadDataBlock(self);
        });
    }
}

- (void)connection:(NSURLConnection *)inConnection didFailWithError:(NSError *)inError
{
    CFRunLoopStop(CFRunLoopGetCurrent());
#if DEBUG
    [self printResponse:inError];
#endif
    [DQPapertrailLogger component:@"http-request" category:[@"failed-" stringByAppendingString:self.command ?: @"unknown"] error:inError httpURLResponse:self.response dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
        switch (inError.code)
        {
            case NSURLErrorCancelled:
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorResourceUnavailable:
            case NSURLErrorDNSLookupFailed:
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorUserCancelledAuthentication:
            case NSURLErrorInternationalRoamingOff:
            case NSURLErrorCallIsActive:
            case NSURLErrorDataNotAllowed:
                // don't log these codes regarding network or device conditions
                return (NSDictionary *)nil;
                break;

            default:
            {
                return @{@"args": self.papertrailLoggerDataBlock ? self.papertrailLoggerDataBlock() : [NSNull null]};
                break;
            }
        }
    }];
    [self tellDelegateDidFailWithError:inError];
    [self markAsComplete];
}

#if DEBUG
- (void)printResponse:(NSError *)inError
{
    NSMutableString *output = [NSMutableString new];
    [output appendFormat:@"\nrequest failed:\n%@\n\n", self];
    [output appendFormat:@"\nerror: %@\n\n", inError];
    NSArray *typesWeWillPrint = @[DQHTTPRequestTextHTMLContentType,
                                  DQHTTPRequestTextPlainContentType,
                                  DQHTTPRequestJSONContentType,
                                  DQHTTPRequestPropertyListContentType,
                                  DQHTTPRequestJavascriptContentType,
                                  DQHTTPRequestApplicationJavascriptContentType];
    [output appendFormat:@"\nresponse data Content-Type %@\nresponse data length: %@\n\n", self.responseMIMEType, @([self.responseData length])];
    if (self.responseMIMEType && [typesWeWillPrint containsObject:self.responseMIMEType])
    {
        [output appendFormat:@"response data as UTF8 string:\n%@\n\n", [self.responseData UTF8String]];
    }
    NSLog(@"%@", output);
}
#endif

- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{
    CFRunLoopStop(CFRunLoopGetCurrent());
    connection = nil;

    // TODO: consider only calling this after we've determined the status code is not an error
    [self _handleResponseData];

    if ([self _statusCodeIsError:self.responseStatusCode])
    {
        NSError *statusCodeError = [NSError errorWithDomain:DQHTTPRequestErrorDomain code:self.responseStatusCode userInfo:[NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:self.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
#if DEBUG
        [self printResponse:statusCodeError];
#endif
        [DQPapertrailLogger component:@"http-request" category:[@"error-" stringByAppendingString:self.command ?: @"unknown"] error:statusCodeError httpURLResponse:self.response dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"args": self.papertrailLoggerDataBlock ? self.papertrailLoggerDataBlock() : [NSNull null]};
        }];
        [self tellDelegateDidFailWithError:statusCodeError];
    }
    else
    {
        // TODO: consider calling _handleResponseData right here instead
        NSError *validationError = nil;
        if (self.responseValidationBlock) {
            validationError = self.responseValidationBlock(self);
        }

        if (validationError)
        {
#if DEBUG
            [self printResponse:validationError];
#endif
            [self tellDelegateDidFailWithError:validationError];
        }
        else
        {
            [self tellDelegateDidFinish];
        }
    }    
    [self markAsComplete];
}

#pragma mark Private Methods

- (void)_updateURL;
{
    if (!self.baseURL.length) {
        self.URL = nil;
        return;
    }
    
    NSMutableString *URLString = [[NSMutableString alloc] init];

    [URLString appendString:self.baseURL];
    
    [URLString appendPathComponent:self.command];
    
    NSString *queryString = self.queryString;
    if (queryString.length) {
        [URLString appendFormat:@"?%@", queryString];
    }
    
    self.URL = [NSURL URLWithString:URLString];
}

- (NSString *)_basicAuthPassword;
{
    if (self.basicAuthPassword.length) {
        return basicAuthPassword;
    }

    if (!self.basicAuthUsername.length || !self.basicAuthKeychainServiceName.length) {
        return nil;
    }
    
    NSError *keychainError = nil;
    NSString *keychainPassword = [STKeychain getPasswordForUsername:self.basicAuthUsername andServiceName:self.basicAuthKeychainServiceName error:&keychainError];
    
    if (keychainError)
    {
        [DQPapertrailLogger component:@"http-request" category:@"basic-auth-password-keychain-failed" error:keychainError httpURLResponse:self.response dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"username": self.basicAuthUsername ?: [NSNull null],
                     @"service-name": self.basicAuthKeychainServiceName ?: [NSNull null]};
        }];
        return nil;
    }
    
    return keychainPassword;
}

- (NSURLRequest *)_configuredURLRequest;
{
    if (!self.URL) {
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.timeoutInterval];
    
    NSString *requestMethodString = [self requestMethodStringForRequestMethod:self.requestMethod];
    
    [request setHTTPMethod:requestMethodString];
        
    // Process the user-specified headers
    NSArray *headerKeys = [self.headers allKeys];
    
    for (NSString *currentKey in headerKeys) {
        NSString *currentValue = [self.headers stringForKey:currentKey];
        [request addValue:currentValue forHTTPHeaderField:currentKey];
    }
    
    // Set the user agent header
    if (self.userAgent.length) {
        [request addValue:self.userAgent forHTTPHeaderField:DQHTTPRequestUserAgentHeaderKey];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [request addValue:@"iPad" forHTTPHeaderField:DQAPIIdiomHeaderKey];
    }
    else
    {
        [request setValue:@"iPhone" forHTTPHeaderField:DQAPIIdiomHeaderKey];
    }

    static NSString *ifv = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ifv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    });
    if ([ifv length])
    {
        [request addValue:ifv forHTTPHeaderField:DQAPIIdentifierForVendorHeaderKey];
    }

    // Set the language header
    if ([__preferredLanguages length])
    {
        [request addValue:__preferredLanguages forHTTPHeaderField:DQHTTPRequestAcceptLanguageHeaderKey];
    }

    // Set the time zone header
    if (self.time) {
        [request addValue:[self.time HTTPTimeZoneHeaderString] forHTTPHeaderField:DQHTTPRequestTimeZoneHeaderKey];
    }

    // Set the content type and body if it's
    // a POST request
    if (self.requestMethod == DQHTTPRequestMethodPOST && (self.postBodyParameters.count || self.postBodyFiles.count)) {
        NSString *contentType = nil;
        
        switch (self.postBodyFormat) {
            case DQHTTPRequestPOSTBodyFormatMultipart:
                contentType = [NSString stringWithFormat:DQHTTPRequestMultipartContentType, DQHTTPRequestMultipartBoundaryString];
                break;
            case DQHTTPRequestPOSTBodyFormatJSON:
                contentType = DQHTTPRequestJSONContentType;
                break;
            default:
                contentType = DQHTTPRequestURLEncodedContentType;
                break;
        }
        
        NSUInteger contentLength = [self _buildPOSTBody];
        
        if (self.streamsPOSTBodyFromDisk) {
            if (self.gzippedPOSTBody)
            {
                if (self.postBodyFileHandle)
                {
                    [self.postBodyFileHandle closeFile];
                    self.postBodyFileHandle = nil;
                }
                NSError *compressionError = nil;
                NSString *filename = [self.cachedPOSTBodyFilePath lastPathComponent];
                NSString *compressedPath = [[self.cachedPOSTBodyFilePath stringByRemovingLastPathComponent] stringByAppendingPathComponent:[filename stringByAppendingPathExtension:@"gz"]];
                BOOL compressionSuccess = [ASIDataCompressor compressDataFromFile:self.cachedPOSTBodyFilePath toFile:compressedPath error:&compressionError];
                if (compressionSuccess)
                {
                    NSFileManager *fm = [NSFileManager new];
                    [fm removeItemAtPath:self.cachedPOSTBodyFilePath error:NULL];
                    [request setValue:@"gzip" forHTTPHeaderField:DQHTTPRequestContentEncodingHeaderKey];
                    contentLength = (NSUInteger)[fm fileSizeAtPath:compressedPath];
                    self.cachedPOSTBodyFilePath = compressedPath;
                }
            }
            POSTBodyInputStream = [[NSInputStream alloc] initWithFileAtPath:self.cachedPOSTBodyFilePath];
            [request setHTTPBodyStream:POSTBodyInputStream];
        } else {
            if (self.gzippedPOSTBody)
            {
                NSError *compressionError = nil;
                NSMutableData *compressedData = [ASIDataCompressor compressData:self.postBodyData error:&compressionError];
                if (compressedData)
                {
                    [request setValue:@"gzip" forHTTPHeaderField:DQHTTPRequestContentEncodingHeaderKey];
                    contentLength = [compressedData length];
                    self.postBodyData = compressedData;
                }
            }
            [request setHTTPBody:self.postBodyData];
        }
        
        [request addValue:contentType forHTTPHeaderField:DQHTTPRequestContentTypeHeaderKey];
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)contentLength] forHTTPHeaderField:DQHTTPRequestContentLengthHeaderKey];
    }
    
    request.HTTPShouldHandleCookies = NO;
    
    return request;
}

- (void)_resetPOSTBody;
{
    if (POSTBodyInputStream) {
        POSTBodyInputStream.delegate = nil;
        POSTBodyInputStream = nil;
    }
    
    self.postBodyData = nil;
    
    [self.postBodyFileHandle closeFile];
    self.postBodyFileHandle = nil;
    
    if (self.cachedPOSTBodyFilePath.length) {
        NSFileManager *fm = [NSFileManager new];
        [fm removeItemAtPath:self.cachedPOSTBodyFilePath error:NULL];
        self.cachedPOSTBodyFilePath = nil;
    }
}

- (NSUInteger)_buildPOSTBody;
{
    
    if (self.streamsPOSTBodyFromDisk) {
        NSFileManager *fm = [NSFileManager new];
        self.cachedPOSTBodyFilePath = [DQHTTPRequest cachePathForFilename:self.identifier];
        if (![fm recursivelyCreatePath:self.cachedPOSTBodyFilePath lastComponentIsFile:YES]) {
            NSLog(@"Unable to recursively create path: %@", self.cachedPOSTBodyFilePath);
        }

        self.postBodyFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.cachedPOSTBodyFilePath];
        if (!self.postBodyFileHandle) {
            NSLog(@"Unable to open file handle to write POST body at path: %@.", self.cachedPOSTBodyFilePath);
        }
    } else {
        self.postBodyData = [NSMutableData new];
    }
    
    switch (self.postBodyFormat) {
        case DQHTTPRequestPOSTBodyFormatJSON:
            [self _buildJSONPOSTBody];
            break;
        case DQHTTPRequestPOSTBodyFormatMultipart:
            [self _buildMultipartPOSTBody];
            break;
        default:
            [self _buildURLEncodedPOSTBody];
            break;
    }
    
    NSUInteger contentLength = 0;
    if (self.postBodyFileHandle) {
        contentLength = (NSUInteger)[self.postBodyFileHandle seekToEndOfFile];
        [self.postBodyFileHandle closeFile];
        self.postBodyFileHandle = nil;
    } else {
        contentLength = [self.postBodyData length];
    }
    
    return contentLength;
}

- (void)_buildMultipartPOSTBody;
{
    if (!self.postBodyParameters.count && !self.postBodyFiles.count) {
        return;
    }
    
    NSString *startItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n", DQHTTPRequestMultipartBoundaryString];
    
    // Handle all the basic POST form parameters
    NSUInteger parameterIndex = 0;
    NSArray *postKeys = [self.postBodyParameters allKeys];
    for (id currentKey in postKeys) {
        id currentObject = [self.postBodyParameters objectForKey:currentKey];
        NSString *parameterValue = [self _stringValueForParameterObject:currentObject];
        
        if (!parameterValue.length) {
            continue;
        }
        
        // Append the start item boundary
        [self _appendPOSTBodyUTF8String:startItemBoundary];
        
        // Append the content disposition
        [self _appendPOSTBodyUTF8StringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", currentKey];
        
        // Append the parameter string
        [self _appendPOSTBodyUTF8String:parameterValue];
        
        // Append the end item boundary, but only if this
        // isn't the last item.
        parameterIndex++;
        if (parameterIndex > self.postBodyParameters.count || self.postBodyFiles.count) {
            [self _appendPOSTBodyUTF8String:startItemBoundary];
        }
    }
    
    // Handle all the file parameters
    NSUInteger fileIndex = 0;
    for (NSString *currentFileKey in self.postBodyFiles) {
        NSDictionary *currentFileInfo = [self postBodyFileInfoForParameterName:currentFileKey];
        NSString *filename = [currentFileInfo objectForKey:DQHTTPRequestFileInfoFilenameKey];
        NSData *fileData = [currentFileInfo objectForKey:DQHTTPRequestFileInfoFileDataKey];
        NSString *filePath = [currentFileInfo objectForKey:DQHTTPRequestFileInfoFilePathKey];
        NSString *contentType = [currentFileInfo objectForKey:DQHTTPRequestFileInfoContentTypeKey];

        // have to have either file data or a path that exists
        NSFileManager *fm = [NSFileManager new];
        if (!(fileData.length || (filePath.length && [fm fileExistsAtPath:filePath]))) {
            continue;
        }
        
        [self _appendPOSTBodyUTF8StringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", currentFileKey, filename];
        [self _appendPOSTBodyUTF8StringWithFormat:@"Content-Type: %@\r\n\r\n", contentType];
        
        // Write the file data
        if (fileData.length) {
            [self _appendPOSTBodyData:fileData];
        } else {
            [self _appendPOSTBodyFileDataAtPath:filePath];
        }
                
        // Append the end item boundary, but only if this 
        // isn't the last item.
        fileIndex++;
        if (fileIndex < self.postBodyFiles.count) {
            [self _appendPOSTBodyUTF8String:startItemBoundary];
        }
    }
    
    // Append the end boundary
    [self _appendPOSTBodyUTF8StringWithFormat:@"\r\n--%@--\r\n", DQHTTPRequestMultipartBoundaryString];
}

- (void)_buildJSONPOSTBody;
{
    if (!self.postBodyParameters.count) {
        return;
    }
    
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:self.postBodyParameters options:0 error:nil];
    [self _appendPOSTBodyData:JSONData];
}

- (void)_buildURLEncodedPOSTBody;
{
    if (!self.postBodyParameters.count) {
        return;
    }
    
    NSData *URLEncodedData = [[self.postBodyParameters URLEncodedStringValue] dataUsingEncoding:NSUTF8StringEncoding];
    [self _appendPOSTBodyData:URLEncodedData];
}

- (void)_appendPOSTBodyUTF8StringWithFormat:(NSString *)inString, ...;
{
    va_list args;
    va_start(args, inString);
    
    if (self.streamsPOSTBodyFromDisk) {
        [self.postBodyFileHandle writeUTF8StringWithFormat:inString arguments:args];
    } else {
        [inString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        [self.postBodyData appendUTF8StringWithFormat:inString arguments:args];
    }
    
    va_end(args);
}

- (void)_appendPOSTBodyUTF8String:(NSString *)inString;
{
    if (self.streamsPOSTBodyFromDisk) {
        [self.postBodyFileHandle writeUTF8String:inString];
    } else {
        [inString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        [self.postBodyData appendUTF8String:inString];
    }
}

- (void)_appendPOSTBodyData:(NSData *)inData;
{
    if (self.streamsPOSTBodyFromDisk) {
        [inData length];
        [self.postBodyFileHandle writeData:inData];
    } else {
        [inData length];
        [self.postBodyData appendData:inData];
    }
}

- (void)_appendPOSTBodyFileDataAtPath:(NSString *)inPath;
{
    NSFileManager *fm = [NSFileManager new];
    if (!inPath.length || ![fm fileExistsAtPath:inPath])
    {
        return;
    }

    if (self.streamsPOSTBodyFromDisk)
    {
        NSInputStream *fileInputStream = [NSInputStream inputStreamWithFileAtPath:inPath];
        if (fileInputStream)
        {
            [fileInputStream open];
            uint8_t *buffer = malloc(32768);
            while ([fileInputStream hasBytesAvailable])
            {
                @autoreleasepool
                {
                    NSInteger bytesRead = [fileInputStream read:buffer maxLength:32768];
                    if (bytesRead)
                    {
                        NSData *d = [NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO];
                        [self.postBodyFileHandle writeData:d];
                    }
                }
            }
            free(buffer);
            [fileInputStream close];
        }
    }
    else
    {
        NSError *error_ = nil;
        NSData *fileData = [NSData dataWithContentsOfFile:inPath options:NSDataReadingMappedIfSafe error:&error_];
        if (fileData)
        {
            [self.postBodyData appendData:fileData];
        }
    }
}

- (NSString *)requestMethodStringForRequestMethod:(DQHTTPRequestMethod)inRequestMethod;
{
    //Set the request method
    NSString *requestMethodString = @"GET";
    
    switch (inRequestMethod) {
        case DQHTTPRequestMethodPOST:
            requestMethodString = @"POST";
            break;
        case DQHTTPRequestMethodPUT:
            requestMethodString = @"PUT";
            break;
        case DQHTTPRequestMethodDELETE:
            requestMethodString = @"DELETE";
            break;
        case DQHTTPRequestMethodHEAD:
            requestMethodString = @"HEAD";
            break;
        default:
            break;
    }
    
    return requestMethodString;
}

- (NSString *)_stringValueForParameterObject:(NSString *)inObject;
{
    NSString *stringValue = nil;
    
	if ([inObject isKindOfClass:[NSString class]]) {
		stringValue = (NSString *)inObject;
	} else if ([inObject isKindOfClass:[NSNumber class]]) {		
		stringValue = [(NSNumber *)inObject stringValue];
	} else if ([self isKindOfClass:[NSDate class]]) {
		stringValue = [(NSDate *)inObject HTTPTimeZoneHeaderString];
	} else if ([self isKindOfClass:[NSData class]]) {
        stringValue = [(NSData *)inObject st_base64EncodedString];
    }
	
	return stringValue;
}

- (void)_handleResponseData;
{
    if (!self.response || !self.responseData.length) {
        // TO DO: Error if no response
        return;
    }
    
    // Uncomment to see raw body
    //NSLog(@"Response body string for %@: %@", self.command, [NSString stringWithUTF8String:[[self.responseData UTF8String] UTF8String]]);
    
    if ([self.responseMIMEType isEqualToString:DQHTTPRequestJSONContentType] || [self.responseMIMEType isEqualToString:DQHTTPRequestJavascriptContentType] || [self.responseMIMEType isEqualToString:DQHTTPRequestApplicationJavascriptContentType]) {
        id responseObject = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:nil];
        if (responseObject) {
            self.responseJSONObject = responseObject;
        } else {
            self.responseString = [self.responseData UTF8String];
        }
    } else if ([self.responseMIMEType isEqualToString:DQHTTPRequestTextHTMLContentType] || [self.responseMIMEType isEqualToString:DQHTTPRequestTextPlainContentType]) {
        self.responseString = [self.responseData UTF8String];
    } else if ([self.responseMIMEType isEqualToString:DQHTTPRequestURLEncodedContentType]) {
        self.responseURLEncodedDictionary = [NSDictionary dictionaryWithURLEncodedString:[self.responseData UTF8String]];
    }
}

- (BOOL)_statusCodeIsError:(NSInteger)statusCode;
{
    return statusCode == DQHTTPRequestNoNetworkStatusCode || (statusCode >= DQHTTPRequestMinClientErrorStatusCode && statusCode <= DQHTTPRequestMaxClientErrorStatusCode) || (statusCode >= DQHTTPRequestMinServerErrorStatusCode && statusCode <= DQHTTPRequestMaxServerErrorStatusCode);
}

@end
