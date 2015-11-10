//
//  DQHTTPRequestQueue.m
//
//  Created by Buzz Andersen on 3/8/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "DQHTTPRequestQueue.h"
#import "DQHTTPRequest.h"
#import "STUtils.h"

NSString *DQHTTPRequestOAuthConsumerKeyKey = @"oauth_consumer_key";
NSString *DQHTTPRequestOAuthVersionKey = @"oauth_version";
NSString *DQHTTPRequestOAuthTimestampKey = @"oauth_timestamp";
NSString *DQHTTPRequestOauthNonceKey = @"oauth_nonce";
NSString *DQHTTPRequestOAuthSignatureMethodKey = @"oauth_signature_method";
NSString *DQHTTPRequestOAuthSignatureKey = @"oauth_signature";
NSString *DQHTTPRequestXAuthUsernameParameterKey = @"x_auth_username";
NSString *DQHTTPRequestXAuthPasswordParameterKey = @"x_auth_password";
NSString *DQHTTPRequestXauthAuthModeKey = @"x_auth_mode";
NSString *DQHTTPRequestOAuthTokenKey = @"oauth_token";
NSString *DQHTTPRequestOAuthTokenSecretKey = @"oauth_token_secret";

@interface DQHTTPRequest (AuthExtensions)

- (NSString *)_basicAuthAuthorizationHeaderString;
- (NSString *)_OAuthAuthorizationHeaderString;
- (NSString *)_OAuth2AuthorizationHeaderString;

@end

@interface DQHTTPRequestQueue ()

@property (nonatomic, readonly, strong) dispatch_queue_t workerQueue;

@end

@implementation DQHTTPRequestQueue
{
    NSOperationQueue *_operationQueue;
}

@synthesize queueName;
@synthesize baseURL;
@synthesize userAgent;

@synthesize basicAuthUsername;
@synthesize basicAuthPassword;
@synthesize basicAuthKeychainServiceName;

@synthesize OAuthConsumerKey;
@synthesize OAuthSecretKey;
@synthesize OAuthToken;
@synthesize OAuthTokenSecret;

#pragma mark Initialization

- (id)initWithQueueName:(NSString *)inQueueName;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    queueName = [inQueueName copy];
    _operationQueue = [[NSOperationQueue alloc] init];
    [_operationQueue setName:queueName];

    NSString *workerName = [NSString stringWithFormat:@"com.systemoftouch.%@Worker", NSStringFromClass([self class])];
    _workerQueue = dispatch_queue_create([workerName UTF8String], DISPATCH_QUEUE_SERIAL);

    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_operationQueue cancelAllOperations];
    [_operationQueue waitUntilAllOperationsAreFinished];

    dispatch_sync(_workerQueue, ^{ });
}

- (void)workerAsync:(dispatch_block_t)block
{
    if (block)
    {
        dispatch_async(self.workerQueue, ^{
            block();
        });
    }
}

#pragma mark NSOperationQueue

- (void)hasOperations:(void (^)(BOOL hasOperations))resultBlock
{
    if (resultBlock)
    {
        [self workerAsync:^{
            NSInteger result = [_operationQueue operationCount] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

- (void)maxConcurrentOperationCount:(void (^)(NSInteger result))resultBlock
{
    if (resultBlock)
    {
        [self workerAsync:^{
            NSInteger result = [_operationQueue maxConcurrentOperationCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

- (void)setMaxConcurrentOperationCount:(NSInteger)cnt completionBlock:(dispatch_block_t)completionBlock
{
    [self workerAsync:^{
        [_operationQueue setMaxConcurrentOperationCount:cnt];
        if (completionBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    }];
}

- (void)enqueueRequest:(DQHTTPRequest *)request resultBlock:(void (^)(BOOL enqueued))resultBlock
{
    [self workerAsync:^{
        if ([self _findRequestForIdentifier:request.identifier])
        {
            NSLog(@"ERROR: throwing out duplicate request: %@", [request.URL absoluteString]);
            if (resultBlock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(NO);
                });
            }
        }
        else
        {
            // NSLog(@"INFO: enqueuing request: %@", [request.URL absoluteString]);

            NSURL *requestURL = request.URL;
            BOOL mayAddRequest = YES;
            if (requestURL)
            {
                if (request.requiresOAuth)
                {
                    NSString *OAuthSignature = nil;
                    switch(request.authenticationType)
                    {
                        case DQHTTPRequestAuthenticationTypeOAuth2:
                            OAuthSignature = [request _OAuth2AuthorizationHeaderString];
                            break;
                        default:
                            OAuthSignature = [request _OAuthAuthorizationHeaderString];
                            break;
                    }

                    if (OAuthSignature.length)
                    {
                        [request setHeaderString:OAuthSignature forKey:DQHTTPRequestAuthorizationHeaderKey];
                    }
                    else
                    {
                        NSLog(@"ERROR: empty OAuth signature for request: %@", request);
                        mayAddRequest = NO;
                    }
                }
                else if (request.authenticationType == DQHTTPRequestAuthenticationTypeBasic)
                {
                    NSString *headerString = [request _basicAuthAuthorizationHeaderString];
                    [request setHeaderString:headerString forKey:DQHTTPRequestAuthorizationHeaderKey];
                }

                if (mayAddRequest)
                {
                    [_operationQueue addOperation:request];
                }
                if (resultBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        resultBlock(mayAddRequest);
                    });
                }
            }
            else
            {
                NSLog(@"ERROR: trying to enqueue request that doesn't have an URL: %@", request);
                if (resultBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        resultBlock(NO);
                    });
                }
            }
        }
    }];
}

- (void)cancelRequestsForURL:(NSString *)inURL completionBlock:(dispatch_block_t)completionBlock
{
    if ([inURL length])
    {
        [self workerAsync:^{
            for (DQHTTPRequest *currentRequest in _operationQueue.operations) {
                if ([[currentRequest.URL absoluteString] isEqualToString:inURL]) {
                    // NSLog(@"cancelling request: %@", inURL);
                    [currentRequest cancel];
                }
            }
            if (completionBlock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock();
                });
            }
        }];
    }
    else
    {
        if (completionBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    }
}

#pragma mark Request Creation

- (DQHTTPRequest *)requestWithURL:(NSString *)inURL;
{
    if (!inURL.length) {
        return nil;
    }
    
    DQHTTPRequest *request = [[DQHTTPRequest alloc] initWithBaseURL:inURL];
    [self _configureAuthParametersForRequest:request];
    
    return request;
}


- (DQHTTPRequest *)requestWithCommand:(NSString *)inCommand;
{
    return [self requestWithCommand:inCommand tag:nil userInfo:nil];
}

- (DQHTTPRequest *)requestWithCommand:(NSString *)inCommand tag:(NSString *)inTag userInfo:(NSDictionary *)inUserInfo;
{
    if (!self.baseURL || !inCommand.length) {
        return nil;
    }
    
    DQHTTPRequest *request = [[DQHTTPRequest alloc] initWithBaseURL:self.baseURL command:inCommand userInfo:inUserInfo];
    request.tag = inTag;
    request.userAgent = self.userAgent;
    [self _configureAuthParametersForRequest:request];
    
    return request;
}

#pragma mark Request Lookup

- (void)hasRequestForIdentifier:(NSString *)inIdentifier resultBlock:(void (^)(BOOL found))resultBlock;
{
    if (resultBlock)
    {
        [self workerAsync:^{
            BOOL result = [self _findRequestForIdentifier:inIdentifier] != nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

- (void)hasRequestsForURL:(NSString *)inURL resultBlock:(void (^)(BOOL found))resultBlock;
{
    if (resultBlock)
    {
        [self workerAsync:^{
            BOOL result = [[self _findRequestsForURL:inURL] count] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

- (void)hasRequestsForCommand:(NSString *)inCommand resultBlock:(void (^)(BOOL found))resultBlock;
{
    if (resultBlock)
    {
        [self workerAsync:^{
            BOOL result = [[self _findRequestsForCommand:inCommand] count] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

- (void)hasRequestsForTag:(NSString *)inTag resultBlock:(void (^)(BOOL found))resultBlock;
{
    if (resultBlock)
    {
        [self workerAsync:^{
            BOOL result = [[self _findRequestsForTag:inTag] count] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

- (void)hasRequestsForCommand:(NSString *)inCommand tag:(NSString *)inTag resultBlock:(void (^)(BOOL found))resultBlock;
{
    if (resultBlock)
    {
        [self workerAsync:^{
            BOOL result = [[self _findRequestsForCommand:inCommand tag:inTag] count] > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(result);
            });
        }];
    }
}

#pragma mark - Private API that assumes it's run on the workerQueue

- (DQHTTPRequest *)_findRequestForIdentifier:(NSString *)inIdentifier
{
    for (DQHTTPRequest *currentRequest in _operationQueue.operations) {
        if ([currentRequest.identifier isEqualToString:inIdentifier])
        {
            return currentRequest;
        }
    }
    return nil;
}

- (NSArray *)_findRequestsForURL:(NSString *)inURL
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (DQHTTPRequest *currentRequest in _operationQueue.operations) {
        if ([[currentRequest.URL absoluteString] isEqualToString:inURL]) {
            [resultArray addObject:currentRequest];
        }
    }
    return resultArray;
}

- (NSArray *)_findRequestsForCommand:(NSString *)inCommand
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (DQHTTPRequest *currentRequest in _operationQueue.operations) {
        if ([currentRequest.command isEqualToString:inCommand]) {
            [resultArray addObject:currentRequest];
        }
    }
    return resultArray;
}

- (NSArray *)_findRequestsForTag:(NSString *)inTag
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (DQHTTPRequest *currentRequest in _operationQueue.operations) {
        if ([currentRequest.tag isEqualToString:inTag]) {
            [resultArray addObject:currentRequest];
        }
    }
    return resultArray;
}

- (NSArray *)_findRequestsForCommand:(NSString *)inCommand tag:(NSString *)inTag
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    for (DQHTTPRequest *currentRequest in _operationQueue.operations) {
        if ([currentRequest.command isEqualToString:inCommand] && [currentRequest.tag isEqualToString:inTag]) {
            [resultArray addObject:currentRequest];
        }
    }
    return resultArray;
}

#pragma mark Accessors

- (BOOL)hasOAuthCredentials;
{
    return (self.OAuthConsumerKey != nil && self.OAuthSecretKey != nil && self.OAuthToken != nil && self.OAuthTokenSecret != nil);
}

- (BOOL)hasBasicAuthCredentials;
{
    return (self.basicAuthUsername != nil && (self.basicAuthKeychainServiceName != nil || self.basicAuthPassword != nil));
}

#pragma mark Private Methods

- (void)_configureAuthParametersForRequest:(DQHTTPRequest *)inRequest;
{
    if (!inRequest.basicAuthUsername) {
        inRequest.basicAuthUsername = self.basicAuthUsername;
    }
    
    if (!inRequest.basicAuthPassword && !inRequest.basicAuthKeychainServiceName) {
        if (self.basicAuthKeychainServiceName) {
            inRequest.basicAuthKeychainServiceName = self.basicAuthKeychainServiceName;
        } else if (self.basicAuthPassword) {
            inRequest.basicAuthPassword = self.basicAuthPassword;
        }
    }
    
    inRequest.OAuthConsumerKey = self.OAuthConsumerKey;
    inRequest.OAuthSecretKey = self.OAuthSecretKey;
    inRequest.OAuthToken = self.OAuthToken;
    inRequest.OAuthTokenSecret = self.OAuthTokenSecret;
}

@end

@implementation DQHTTPRequest (AuthExtensions)

- (NSString *)_basicAuthAuthorizationHeaderString;
{
    if (!self.hasBasicAuthCredentials) {
        return nil;
    }

    NSString *combinedUsernamePassword = [[NSString alloc] initWithFormat:@"%@:%@", self.basicAuthUsername, [self _basicAuthPassword]];
    NSString *base64String = [combinedUsernamePassword base64String];

    return base64String;
}

- (NSString *)_OAuthAuthorizationHeaderString;
{
    if (!self.OAuthSecretKey.length || !self.OAuthConsumerKey.length) {
        return nil;
    }

    NSMutableDictionary *signatureParameterDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *headerParameterDictionary = [[NSMutableDictionary alloc] init];

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    // Add the standard boilerplate parameters common to all OAuth requests to the header parameters
    [headerParameterDictionary setObject:[NSString stringWithFormat:@"%d", (int)now] forKey:DQHTTPRequestOAuthTimestampKey];
    [headerParameterDictionary setObject:self.identifier forKey:DQHTTPRequestOauthNonceKey];
    [headerParameterDictionary setObject:@"1.0" forKey:DQHTTPRequestOAuthVersionKey];
    [headerParameterDictionary setObject:@"HMAC-SHA1" forKey:DQHTTPRequestOAuthSignatureMethodKey];
    [headerParameterDictionary setObject:self.OAuthConsumerKey forKey:DQHTTPRequestOAuthConsumerKeyKey];
    if (self.OAuthToken) {
        [headerParameterDictionary setObject:self.OAuthToken forKey:DQHTTPRequestOAuthTokenKey];
    }

    // Add in any additionally specified OAuth parameters to the header parameters
    if (self.additionalOAuthParameters.count) {
        [headerParameterDictionary addEntriesFromDictionary:self.additionalOAuthParameters];
    }

    // Mix the header parameters into the signature parameter dictionary
    [signatureParameterDictionary addEntriesFromDictionary:headerParameterDictionary];

    if (self.queryParameters.count) {
        [signatureParameterDictionary addEntriesFromDictionary:self.queryParameters];
    }

    // Add any POST body parameters to the signature dictionary, but only as long as the
    // post body format is URL encoded.
    if (self.postBodyParameters.count && self.postBodyFormat == DQHTTPRequestPOSTBodyFormatURLEncoded) {
        // The post parameter values need to be double percent encodeded
        for (NSString *currentPostBodyKey in [self.postBodyParameters allKeys]) {
            NSString *currentPostBodyValue = [self.postBodyParameters objectForKey:currentPostBodyKey];
            [signatureParameterDictionary setObject:[currentPostBodyValue stringByEscapingQueryParameters] forKey:currentPostBodyKey];
        }
    }

    // Start the raw signature string
    NSMutableString *rawSignatureString = [[NSMutableString alloc] init];

    [rawSignatureString appendFormat:@"%@&%@&", [self requestMethodStringForRequestMethod:self.requestMethod], [[self.URL absoluteStringMinusQueryString] stringByEscapingQueryParameters]];

    NSArray *parameterKeys = [[signatureParameterDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    id lastElement = [parameterKeys lastObject];
    for (NSString *currentKey in parameterKeys) {
        id currentValue = [signatureParameterDictionary objectForKey:currentKey];
        NSMutableString *parameterString = [[NSMutableString alloc] init];
        [parameterString appendFormat:@"%@=%@", currentKey, currentValue];

        if (currentKey != lastElement) {
            [parameterString appendString:@"&"];
        }

        [rawSignatureString appendString:[parameterString stringByEscapingQueryParameters]];

    }


    // Hash the raw signature string into an encrypted signature
    NSString *keyString = [NSString stringWithFormat:@"%@&", self.OAuthSecretKey];
    if (self.OAuthTokenSecret) {
        keyString = [keyString stringByAppendingString:self.OAuthTokenSecret];
    }
    NSString *encryptedSignatureString = [[[rawSignatureString dataUsingEncoding:NSUTF8StringEncoding] hmacSHA1DataValueWithKey:[keyString dataUsingEncoding:NSUTF8StringEncoding]] st_base64EncodedString];

    // Add the encrypted signature to the header parameter dictionary
    [headerParameterDictionary setObject:encryptedSignatureString forKey:DQHTTPRequestOAuthSignatureKey];

    // Turn the header parameter dictionary into a string
    NSString *authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", [headerParameterDictionary URLEncodedQuotedKeyValueListValue]];

    return authorizationHeaderString;
}

- (NSString *)_OAuth2AuthorizationHeaderString
{
    if (!self.OAuthSecretKey.length || !self.OAuthConsumerKey.length) {
        return nil;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSString *OAuthNonce = self.identifier;
    NSString *OAuthTimeStamp = [NSString stringWithFormat:@"%d", (int)now];

    NSMutableString *rawSignatureString = [[NSMutableString alloc] init];

    [rawSignatureString appendFormat:@"%@\n", self.OAuthToken];
    [rawSignatureString appendFormat:@"%@\n", OAuthTimeStamp];
    [rawSignatureString appendFormat:@"%@\n", OAuthNonce];
    [rawSignatureString appendFormat:@"%@\n", [self requestMethodStringForRequestMethod:self.requestMethod]];
    [rawSignatureString appendFormat:@"%@\n", [[self URL] host]];
    [rawSignatureString appendFormat:@"%d\n", 80];
    [rawSignatureString appendFormat:@"%@\n", [[self URL] path]];


    NSString *encryptedSignatureString = [[[rawSignatureString dataUsingEncoding:NSUTF8StringEncoding] hmacSHA1DataValueWithKey:[self.OAuthTokenSecret dataUsingEncoding:NSUTF8StringEncoding]] st_base64EncodedString];

    NSString *authorizationString = [NSString stringWithFormat:@"MAC token=\"%@\", timestamp=\"%@\", nonce=\"%@\", signature=\"%@\"", self.OAuthToken, OAuthTimeStamp, OAuthNonce, encryptedSignatureString];
    
    return authorizationString;
}

@end
