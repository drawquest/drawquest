//
//  DQAuthServiceController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAuthServiceController.h"
#import "NSDictionary+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQPapertrailLogger.h"

NSString *DQAPIMethodUsernameAvailable = @"auth/username_available";
NSString *DQAPIMethodEmailIsUnused = @"auth/email_is_unused";
NSString *DQAPIMethodLogin = @"auth/login";
NSString *DQAPIMethodLoginWithFacebook = @"auth/login_with_facebook";
NSString *DQAPIMethodLoginWithTwitter = @"auth/login_with_twitter";
NSString *DQAPIMethodSignup = @"auth/signup";

@interface DQAuthCredentials : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *emailAddress;
@property (nonatomic, strong) NSString *facebookToken;
@property (nonatomic, strong) NSString *twitterToken;
@property (nonatomic, strong) NSString *twitterSecret;

@property (nonatomic, readonly) BOOL validForLogin;
@property (nonatomic, readonly) BOOL validForSignup;

+ (DQAuthCredentials *)authCredentialsWithUsername:(NSString *)inUsername password:(NSString *)inPassword emailAddress:(NSString *)inEmailAddress;

@end

@implementation DQAuthServiceController

- (id)initWithDelegate:(id<DQAuthServiceControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
    }
    return self;
}

- (id<DQAuthServiceControllerDelegate>)delegate
{
    return (id<DQAuthServiceControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQAuthServiceControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

- (NSString *)serviceQueueName
{
    return @"as.canv.DrawQuest.AuthAPIRequestQueue";
}

#pragma mark -
#pragma mark Template Methods

- (NSString *)papertrailLoggerComponentPrefix
{
    return @"auth";
}

- (BOOL)shouldAddSessionIDHeader
{
    return NO;
}

- (BOOL)shouldLogError:(NSError *)error
{
    return error.code != DQAPIErrorCodeValidationFailure;
}

#pragma mark Account Request Methods

/*- (void)requestAvailabilityForUsername:(NSString *)inUsername
 {
 if (!inUsername.length || [self.serviceQueue hasRequestsForCommand:DQAPIMethodUsernameAvailable tag:inUsername]) {
 return;
 }

 DQHTTPRequest *availabilityRequest = [self.serviceQueue requestWithCommand:DQAPIMethodUsernameAvailable];
 availabilityRequest.requestMethod = DQHTTPRequestMethodPOST;
 availabilityRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
 availabilityRequest.tag = inUsername;

 [availabilityRequest setPostBodyParameterValue:inUsername forKey:DQAPIKeyStringUsername];

 [self startHTTPRequest:availabilityRequest];
 }

 - (void)requestUnusedStatusForEmail:(NSString *)inEmail
 {
 if (!inEmail.length || [self.serviceQueue hasRequestsForCommand:DQAPIMethodEmailIsUnused tag:inEmail]) {
 return;
 }

 DQHTTPRequest *emailStatusRequest = [self.serviceQueue requestWithCommand:DQAPIMethodEmailIsUnused];
 emailStatusRequest.requestMethod = DQHTTPRequestMethodPOST;
 emailStatusRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
 emailStatusRequest.tag = inEmail;

 [emailStatusRequest setPostBodyParameterValue:inEmail forKey:DQAPIKeyStringEmail];

 [self startHTTPRequest:emailStatusRequest];
 }*/

- (void)requestSignupWithUsername:(NSString *)inUsername password:(NSString *)inPassword email:(NSString *)inEmail facebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterSecret:(NSString *)twitterSecret completionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    DQAuthCredentials *credentials = [DQAuthCredentials authCredentialsWithUsername:inUsername password:inPassword emailAddress:inEmail];
    credentials.facebookToken = facebookToken;
    credentials.twitterToken = twitterToken;
    credentials.twitterSecret = twitterSecret;

    [self requestAuthWithSignup:YES credentials:credentials completionBlock:inCompletionBlock];
}

- (void)requestLoginWithUsername:(NSString *)inUsername password:(NSString *)inPassword completionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    [self requestAuthWithSignup:NO credentials:[DQAuthCredentials authCredentialsWithUsername:inUsername password:inPassword emailAddress:nil] completionBlock:inCompletionBlock];
}

- (void)requestAuthWithSignup:(BOOL)inSignupFlag credentials:(DQAuthCredentials *)inCredentials completionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    // If the credentials aren't valid for login, or it's
    // a signup request and we didn't get an email, abort
    if (!inCredentials.validForLogin || (inSignupFlag && !inCredentials.validForSignup)) {
        NSLog(@"Attempted auth with invalid credentials.");
        if (inCompletionBlock)
        {
            inCompletionBlock(nil);
        }
        return;
    }

    // If we already have a running login or signup request
    // don't run another
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodSignup resultBlock:^(BOOL found) {
        if (found)
        {
            NSLog(@"Attempted auth with an already in-flight signup request.");
            if (inCompletionBlock)
            {
                inCompletionBlock(nil);
            }
        }
        else
        {
            [weakSelf.serviceQueue hasRequestsForCommand:DQAPIMethodLogin resultBlock:^(BOOL found) {
                if (found)
                {
                    NSLog(@"Attempted auth with an already in-flight login request.");
                    if (inCompletionBlock)
                    {
                        inCompletionBlock(nil);
                    }
                }
                else
                {
                    DQHTTPRequest *authRequest = [weakSelf.serviceQueue requestWithCommand:inSignupFlag ? DQAPIMethodSignup : DQAPIMethodLogin];
                    authRequest.requestMethod = DQHTTPRequestMethodPOST;
                    authRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
                    authRequest.tag = inCredentials.username;
                    if (inSignupFlag)
                    {
                        authRequest.timeoutInterval = 60.0;  // DQ-374
                    }

                    NSMutableDictionary *args = [NSMutableDictionary new];
                    [args ifNotNilSetObject:inCredentials.username forKey:DQAPIKeyStringUsername];
                    [args ifNotNilSetObject:inCredentials.password forKey:DQAPIKeyStringPassword];
                    if (inSignupFlag)
                    {
                        [args ifNotNilSetObject:inCredentials.emailAddress forKey:DQAPIKeyStringEmail];
                    }

                    if ([inCredentials.facebookToken length])
                    {
                        [args ifNotNilSetObject:inCredentials.facebookToken forKey:DQAPIKeyStringFacebookToken];
                    }

                    if ([inCredentials.twitterToken length])
                    {
                        [args ifNotNilSetObject:inCredentials.twitterToken forKey:DQAPIKeyStringTwitterToken];
                    }

                    if ([inCredentials.twitterSecret length])
                    {
                        [args ifNotNilSetObject:inCredentials.twitterSecret forKey:DQAPIKeyStringTwitterSecret];
                    }

                    [authRequest addPostBodyParametersFromDictionary:args];
                    authRequest.papertrailLoggerDataBlock = ^{
                        return args;
                    };
                    authRequest.requestDidFinishBlock = ^(DQHTTPRequest *request) {
                        NSDictionary *responseDictionary = request.dq_responseDictionary;
                        [weakSelf.delegate authServiceController:weakSelf
                                  handleSuccessfulAuthForRequest:request
                                          withResponseDictionary:responseDictionary
                                                 completionBlock:inCompletionBlock];
                    };

                    if (inCompletionBlock)
                    {
                        authRequest.requestDidFailBlock = inCompletionBlock;
                    }

                    [weakSelf startHTTPRequest:authRequest];
                }
            }];
        }
    }];
}

- (void)requestLoginWithTwitterToken:(NSString *)inTwitterToken twitterSecret:(NSString *)inTwitterSecret completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodLoginWithTwitter resultBlock:^(BOOL found) {
        if (found)
        {
            if (inFailureBlock)
            {
                inFailureBlock(nil);
            }
        }
        else
        {
            DQHTTPRequest *twitterAuthRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodLoginWithTwitter];
            twitterAuthRequest.requestMethod = DQHTTPRequestMethodPOST;
            twitterAuthRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            NSMutableDictionary *args = [NSMutableDictionary new];
            [args ifNotNilSetObject:inTwitterToken forKey:DQAPIKeyStringTwitterToken];
            [args ifNotNilSetObject:inTwitterSecret forKey:DQAPIKeyStringTwitterSecret];
            [twitterAuthRequest addPostBodyParametersFromDictionary:args];
            twitterAuthRequest.papertrailLoggerDataBlock = ^{
                return args;
            };
            twitterAuthRequest.requestDidFinishBlock = ^(DQHTTPRequest *request) {
                NSDictionary *responseDictionary = request.dq_responseDictionary;

                NSLog(@"Twitter auth request finished with response: %@", responseDictionary);
                [weakSelf.delegate authServiceController:weakSelf handleSuccessfulAuthForRequest:request withResponseDictionary:responseDictionary completionBlock:inCompletionBlock];

            };

            if (inFailureBlock)
            {
                twitterAuthRequest.requestDidFailBlock = inFailureBlock;
            }

            [weakSelf startHTTPRequest:twitterAuthRequest];
        }
    }];
}

- (void)requestLoginWithFacebookToken:(NSString *)inFacebookToken completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodLoginWithFacebook resultBlock:^(BOOL found) {
        if (found)
        {
            if (inFailureBlock)
            {
                inFailureBlock(nil);
            }
        }
        else
        {
            DQHTTPRequest *facebookAuthRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodLoginWithFacebook];
            facebookAuthRequest.requestMethod = DQHTTPRequestMethodPOST;
            facebookAuthRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            facebookAuthRequest.timeoutInterval = 60.0;  // DQ-374

            NSMutableDictionary *args = [NSMutableDictionary new];
            [args ifNotNilSetObject:inFacebookToken forKey:DQAPIKeyStringFacebookToken];
            [facebookAuthRequest addPostBodyParametersFromDictionary:args];
            facebookAuthRequest.papertrailLoggerDataBlock = ^{
                return args;
            };

            facebookAuthRequest.requestDidFinishBlock = ^(DQHTTPRequest *request) {
                NSDictionary *responseDictionary = request.dq_responseDictionary;

                NSLog(@"Facebook auth request finished with response: %@", responseDictionary);
                [weakSelf.delegate authServiceController:weakSelf handleSuccessfulAuthForRequest:request withResponseDictionary:responseDictionary completionBlock:inCompletionBlock];

            };

            if (inFailureBlock)
            {
                facebookAuthRequest.requestDidFailBlock = inFailureBlock;
            }
            
            [weakSelf startHTTPRequest:facebookAuthRequest];
        }
    }];
}

@end

@implementation DQAuthCredentials

+ (DQAuthCredentials *)authCredentialsWithUsername:(NSString *)inUsername password:(NSString *)inPassword emailAddress:(NSString *)inEmailAddress
{
    DQAuthCredentials *credentials = [[DQAuthCredentials alloc] init];

    credentials.username = inUsername;
    credentials.password = inPassword;
    credentials.emailAddress = inEmailAddress;

    return credentials;
}

- (BOOL)validForLogin
{
    return (self.username.length && self.password.length);
}

- (BOOL)validForSignup
{
    return (self.username.length && self.password.length && self.emailAddress.length);
}

@end
