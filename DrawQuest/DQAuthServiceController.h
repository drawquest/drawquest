//
//  DQAuthServiceController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractServiceController.h"

@class DQAuthServiceController;

@protocol DQAuthServiceControllerDelegate <DQControllerDelegate>

- (void)authServiceController:(DQAuthServiceController *)authServiceController handleSuccessfulAuthForRequest:(DQHTTPRequest *)inRequest withResponseDictionary:(NSDictionary *)inDictionary completionBlock:(DQServiceStatusBlock)inCompletionBlock;

@end

@interface DQAuthServiceController : DQAbstractServiceController

@property (nonatomic, weak) id<DQAuthServiceControllerDelegate> delegate;

// designated initializer
- (id)initWithDelegate:(id<DQAuthServiceControllerDelegate>)delegate;

- (void)requestSignupWithUsername:(NSString *)inUsername password:(NSString *)inPassword email:(NSString *)inEmail facebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterSecret:(NSString *)twitterSecret completionBlock:(DQServiceStatusBlock)inCompletionBlock;
- (void)requestLoginWithUsername:(NSString *)inUsername password:(NSString *)inPassword completionBlock:(DQServiceStatusBlock)inCompletionBlock;
- (void)requestLoginWithFacebookToken:(NSString *)inFacebookToken completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestLoginWithTwitterToken:(NSString *)inTwitterToken twitterSecret:(NSString *)inTwitterSecret completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

@end
