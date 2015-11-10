//
//  DQTwitterController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-05-15.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import <Social/SLRequest.h>

@class DQAccount;
@class ACAccount;

extern NSString *DQTwitterErrorDomain;
extern NSInteger DQTwitterErrorCodeNoKeys;
extern NSInteger DQTwitterErrorCodeNoAccounts;
extern NSInteger DQTwitterErrorCodeNoAccess;
extern NSInteger DQTwitterErrorCodeUnexpectedReverseAuthResponse;

@class DQTwitterController;
@protocol DQTwitterControllerDelegate <DQControllerDelegate>

- (void)twitterControllerDidForgetCredentials:(DQTwitterController *)c;

@end

@interface DQTwitterController : DQController

@property (nonatomic, weak) id<DQTwitterControllerDelegate> delegate;

@property (nonatomic, readonly, strong) ACAccount *twitterAccount;
@property (nonatomic, readonly, copy) NSString *twitterUsername;
@property (nonatomic, readonly, copy) NSString *twitterAccessToken;
@property (nonatomic, readonly, copy) NSString *twitterAccessTokenSecret;
@property (nonatomic, readonly, assign) BOOL hasUnverifiedTwitterAuthCredentials;

- (id)initWithDelegate:(id<DQTwitterControllerDelegate>)delegate;

- (void)reset;

- (void)requestDataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void)hasTwitterAccess:(void (^)(BOOL))resultBlock failureBlock:(void (^)(NSError *))failureBlock;
- (void)requestTwitterAccessInView:(UIView *)view cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;


- (void)requestFriendsListForTwitterAccount:(void (^)(NSArray *friendsArray))resultBlock cancellationBlock:(dispatch_block_t)cancellationBlock failureBlock:(void (^)(NSError *error))failureBlock;

- (void)sendDirectMessageForTwitterAccount:(NSString *)messageBody toUserID:(NSString *)userID cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end
