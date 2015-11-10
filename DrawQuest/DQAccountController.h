//
//  DQAccountController.h
//  DrawQuest
//
//  Created by Buzz Andersen on 9/11/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQController.h"
#import "DQAccount.h"

@class DQHTTPRequest;

typedef void (^DQAccountServiceStatusBlock)(DQHTTPRequest *request);

@class DQDataStoreController;

extern NSString *DQPushPayloadTypeNoop;
extern NSString *DQPushPayloadTypeQuestOfTheDay;
extern NSString *DQPushPayloadTypeNewColors;
extern NSString *DQPushPayloadTypeStarred;
extern NSString *DQPushPayloadTypeFacebookFriendJoined;
extern NSString *DQPushPayloadTypeTwitterFriendJoined;
extern NSString *DQPushPayloadTypeFeaturedInExplore;
extern NSString *DQPushPayloadTypeFollowedByUser;
extern NSString *DQPushPayloadTypeNewColors;

extern NSString *DQUserInfoKeyAccount;

@class DQAccountController;

@protocol DQAccountControllerDelegate <DQControllerDelegate>

- (void)accountControllerDidReset:(DQAccountController *)c;
- (void)accountControllerDidChangeLoggedInAccount:(DQAccountController *)c;

@end

@interface DQAccountController : DQController

@property (nonatomic, weak) id<DQAccountControllerDelegate> delegate;

@property (nonatomic, readwrite, strong) DQAccount *loggedInAccount;

@property (nonatomic, assign) BOOL hasNewQuestOfTheDay;
@property (nonatomic, assign) BOOL questOfTheDayPushEnabled;
@property (nonatomic, assign) BOOL starAlertsPushEnabled;

@property (nonatomic, assign) BOOL hasUserEverLoggedIn;

- (id)initWithDelegate:(id<DQAccountControllerDelegate>)delegate;

// Shop related
- (void)updateCoinBalanceForLoggedInUser:(NSNumber *)inCoinBalance;
- (void)updateColorsForLoggedInUser:(NSArray *)colors;

// Life Cycle
- (void)requestLogout:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock;

// Push
/*
- (void)startUAWithLaunch;
- (void)registerUAPushWithDeviceToken:(NSData *)inDeviceToken;
- (void)unregisterUAPush;
- (void)updateUAPushSettings;
*/

// Local Notification
- (void)configureLocalQOTDNotification;

- (void)takeHeavyStateSync:(NSDictionary *)responseDictionary;
- (void)handleSuccessfulAuthForRequest:(DQHTTPRequest *)inRequest withResponseDictionary:(NSDictionary *)inDictionary;

// Sharing settings
- (void)setShareToFacebookOn:(BOOL)inShareToFacebookOn completionBlock:(dispatch_block_t)inCompletionBlock failureBlock:(void (^)(NSError *error))inFailureBlock;
- (void)setShareToTwitterOn:(BOOL)inShareToTwitterOn completionBlock:(dispatch_block_t)inCompletionBlock failureBlock:(void (^)(NSError *error))inFailureBlock;

// Privacy Settings
- (void)setShareFacebookProfileOn:(BOOL)inShareFacebookProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock;
- (void)setShareTwitterProfileOn:(BOOL)inShareTwitterProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock;
- (void)setShareFacebookProfileIfNotExplicitlySet:(BOOL)inShareFacebookProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock;
- (void)setShareTwitterProfileIfNotExplicitlySet:(BOOL)inShareTwitterProfile completionBlock:(DQAccountServiceStatusBlock)inCompletionBlock failureBlock:(DQAccountServiceStatusBlock)inFailureBlock;

@end
