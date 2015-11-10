//
//    TWSignedRequest.m
//    TWiOSReverseAuthExample
//
//    Copyright (c) 2013 Sean Cook
//
//    Permission is hereby granted, free of charge, to any person obtaining a
//    copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to permit
//    persons to whom the Software is furnished to do so, subject to the
//    following conditions:
//
//    The above copyright notice and this permission notice shall be included
//    in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
//    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
//    USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OAuthCore.h"
#import "TWSignedRequest.h"
#import "STKeychain.h"
#import "TWKeyDeobfuscator.h"

#define TW_HTTP_METHOD_GET @"GET"
#define TW_HTTP_METHOD_POST @"POST"
#define TW_HTTP_METHOD_DELETE @"DELETE"
#define TW_HTTP_HEADER_AUTHORIZATION @"Authorization"

#define REQUEST_TIMEOUT_INTERVAL 30

static NSString *gTWConsumerKey;
static NSString *gTWConsumerSecret;

NSString *TWConsumerKeyKeychainServiceName = @"TWConsumerKeyKeychainServiceName";
NSString *TWConsumerSecretKeychainServiceName = @"TWConsumerSecretKeychainServiceName";

@interface TWSignedRequest()
{
    NSURL *_url;
    NSDictionary *_parameters;
    TWSignedRequestMethod _signedRequestMethod;
}

- (NSURLRequest *)_buildRequest;

@end

@implementation TWSignedRequest
@synthesize authToken = _authToken;
@synthesize authTokenSecret = _authTokenSecret;

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(TWSignedRequestMethod)requestMethod
{
    self = [super init];
    if (self) {
        _url = url;
        _parameters = parameters;
        _signedRequestMethod = requestMethod;
    }
    return self;
}

- (NSURLRequest *)_buildRequest
{
    NSString *method;

    switch (_signedRequestMethod) {
        case TWSignedRequestMethodPOST:
            method = TW_HTTP_METHOD_POST;
            break;
        case TWSignedRequestMethodDELETE:
            method = TW_HTTP_METHOD_DELETE;
            break;
        case TWSignedRequestMethodGET:
        default:
            method = TW_HTTP_METHOD_GET;
    }

    //  Build our parameter string
    NSMutableString *paramsAsString = [[NSMutableString alloc] init];
    [_parameters enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [paramsAsString appendFormat:@"%@=%@&", key, obj];
     }];

    //  Create the authorization header and attach to our request
    NSData *bodyData = [paramsAsString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authorizationHeader = OAuthorizationHeader(_url, method, bodyData, [TWSignedRequest consumerKey], [TWSignedRequest consumerSecret], _authToken, _authTokenSecret);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    [request setTimeoutInterval:REQUEST_TIMEOUT_INTERVAL];
    [request setHTTPMethod:method];
    [request setValue:authorizationHeader forHTTPHeaderField:TW_HTTP_HEADER_AUTHORIZATION];
    [request setHTTPBody:bodyData];

    return request;
}

- (void)performRequestWithHandler:(TWSignedRequestHandler)handler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLResponse *response;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:[self _buildRequest] returningResponse:&response error:&error];
        handler(data, response, error);
    });
}

// OBFUSCATE YOUR KEYS!
+ (NSString *)consumerKey
{
    if (!gTWConsumerKey) {
        NSError *error = nil;
        NSString* result = [STKeychain getPasswordForUsername:TWConsumerKeyKeychainServiceName andServiceName:TWConsumerKeyKeychainServiceName error:&error];
        if (result == nil)
        {
            NSLog(@"Unable to store access token due to error: %@", error);
        }

        gTWConsumerKey = result;
    }

    return gTWConsumerKey;
}

// OBFUSCATE YOUR KEYS!
+ (NSString *)consumerSecret
{
    if (!gTWConsumerSecret) {
        NSError *error = nil;
        NSString* result = [STKeychain getPasswordForUsername:TWConsumerSecretKeychainServiceName andServiceName:TWConsumerSecretKeychainServiceName error:&error];
        if (result == nil)
        {
            NSLog(@"Unable to store access token due to error: %@", error);
        }
        
        gTWConsumerSecret = result;
    }

    return gTWConsumerSecret;
}

+ (BOOL)storeTwitterSyncString:(NSString *)obfuscatedString
{
    NSDictionary *credentials = [TWKeyDeobfuscator keysForPairString:obfuscatedString];
    if (credentials == nil || credentials[TWKeyDeobfuscatorTypeKey] == nil || credentials[TWKeyDeobfuscatorTypeSecret] == nil)
        return NO;
    
    NSError *error = nil;
    BOOL result = [STKeychain storeUsername:TWConsumerKeyKeychainServiceName andPassword:credentials[TWKeyDeobfuscatorTypeKey] forServiceName:TWConsumerKeyKeychainServiceName updateExisting:YES error:&error];
    if (!result && error != nil)
        TWDLog(@"Unable to save twitter consumer key due to error: %@", error);
    else
    {
        error = nil;
        result = [STKeychain storeUsername:TWConsumerSecretKeychainServiceName andPassword:credentials[TWKeyDeobfuscatorTypeSecret] forServiceName:TWConsumerSecretKeychainServiceName updateExisting:YES error:&error];
        if (error != nil)
            TWDLog(@"Unable to save twitter consumer secret due to error: %@", error);
    }
    
    return result;
}

@end
