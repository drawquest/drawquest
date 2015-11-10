//
//  DQPrivateServiceController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractServiceController.h"

extern NSString *DQAvatarChangedNotification;
extern NSString *DQProfileUpdatedNotification;
extern NSString *DQFacebookProfileURLUpdatedNotification;
extern NSString *DQTwitterProfileURLUpdatedNotification;

@class DQCommentUpload; // FIXME: remove this dependency
@class DQQuestUpload; // FIXME: remove this dependency

@interface DQPrivateServiceController : DQAbstractServiceController

#pragma mark - Associating Social Access Tokens

@property (nonatomic, copy) void (^associatedFacebookTokenBlock)(DQHTTPRequestStatusBlock completionBlock, DQHTTPRequestStatusBlock failureBlock);
@property (nonatomic, copy) void (^associatedTwitterTokenBlock)(DQHTTPRequestStatusBlock completionBlock, DQHTTPRequestStatusBlock failureBlock);

- (DQHTTPRequest *)requestAssociateFacebookToken:(NSString *)inFacebookToken completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestAssociateTwitterToken:(NSString *)inTwitterToken twitterSecret:(NSString *)inTwitterSecret completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Flagging and Deleting

- (void)requestFlagForCommentWithServerID:(NSString *)inServerID;
- (void)requestFlagForQuestWithServerID:(NSString *)inServerID;
- (void)requestDeleteCommentWithServerID:(NSString *)inServerID;

#pragma mark - Starring and Unstarring

- (void)requestStarOfCommentWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock;
- (void)requestUnstarOfCommentWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock;

#pragma mark - Home Feed

- (DQHTTPRequest *)requestCommentsForFolloweeFeedWithCompletionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestCommentsForFolloweeFeedWithOffset:(NSString *)offset direction:(DQOffsetDirection)direction completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Activities

- (DQHTTPRequest *)requestActivityWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (DQHTTPRequest *)requestActivityNewerThan:(NSDate *)inNewerThanDate withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (DQHTTPRequest *)requestActivityOlderThan:(NSDate *)inOlderThanDate withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Uploading Content

- (void)requestUploadOfImageData:(NSData *)inImageData withTag:(NSString *)inTag progressBlock:(DQServiceStatusBlock)inProgressBlock completionBlock:(DQServiceImageUploadCompletionBlock)inCompletionBlock;
- (void)requestPostCommentUpload:(DQCommentUpload *)inCommentUpload completionBlock:(void (^)(NSDictionary *commentInfo))completionBlock failureBlock:(void (^)(NSString *errorType))failureBlock;
- (void)requestSetPlaybackDataFromFileAtPath:(NSString *)inPlaybackDataPath forCommentWithServerID:(NSString *)inCommentID progressBlock:(DQServiceStatusBlock)progressBlock completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock;

- (void)requestPostQuestUpload:(DQQuestUpload *)inQuestUpload completionBlock:(void (^)(NSDictionary *questInfo))completionBlock failureBlock:(void (^)(NSString *errorType))failureBlock;
- (void)requestSetPlaybackDataFromFileAtPath:(NSString *)inPlaybackDataPath forQuestWithServerID:(NSString *)inQuestID progressBlock:(DQServiceStatusBlock)progressBlock completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock;

#pragma mark - Account Settings

- (void)requestChangeProfileInfoWithEmail:(NSString *)inEmail oldPassword:(NSString *)inOldPassword newPassword:(NSString *)inNewPassword bioText:(NSString *)inBioText completionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (void)requestAvatarChangeWithImageData:(NSData *)inImageData completionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (void)requestWebProfilePrivacyChange:(BOOL)inBool completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestFacebookProfilePrivacyChange:(BOOL)inBool completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestTwitterProfilePrivacyChange:(BOOL)inBool completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestPushSubscribeForNotificationType:(DQAccountPushNotificationType)inNotificationType withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (void)requestPushUnsubscribeForNotificationType:(DQAccountPushNotificationType)inNotificationType withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (void)requestSetLastSeenModalUpgradeVersion:(NSString *)version failureBlock:(DQServiceStatusBlock)failureBlock;
- (void)requestSetSawWebProfileModalWithFailureBlock:(DQServiceStatusBlock)failureBlock;
- (void)requestSetPublishToFacebookUserKV:(BOOL)isOn completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestSetPublishToTwitterUserKV:(BOOL)isOn completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Following

- (void)requestFollow:(BOOL)inFollow forUserWithName:(NSString *)inUserName completionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (DQHTTPRequest *)requestFollowForUsersWithNames:(NSArray *)inUserNameArray completionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Invites

- (DQHTTPRequest *)requestFacebookFriendsOnDrawQuestWithFacebookToken:(NSString *)facebookToken completionBlock:(DQServiceCompletionBlockWithObjects)inCompletionBlock;
- (DQHTTPRequest *)requestTwitterFollowersOnDrawQuestWithTwitterToken:(NSString *)twitterToken twitterSecret:(NSString *)twitterSecret completionBlock:(DQServiceCompletionBlockWithObjects)inCompletionBlock;
- (DQHTTPRequest *)requestAddInvitedTwitterFriends:(NSArray *)twitterIDList completionBlock:(DQServiceStatusBlock)inCompletionBlock;
- (DQHTTPRequest *)requestInviteMessageForChannel:(NSString *)inChannel withQuestID:(NSString *)questID completionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Shop

- (DQHTTPRequest *)requestShopItemsWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestPurchaseColorID:(NSString *)inColorID completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestPurchaseColorPackID:(NSString *)inColorPackID completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestPurchaseBrushID:(NSString *)inBrushCanonicalName completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Economy

- (void)requestCoinProductsWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;
- (void)requestProcessPurchaseReceiptWithData:(NSData *)inData completionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Sharing

- (void)requestSendMessage:(NSString *)message facebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterSecret:(NSString *)twitterSecret;

#pragma mark - Quests

- (DQHTTPRequest *)requestQuestInboxWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestQuestHistoryWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestDismissQuestWithID:(NSString *)questID completionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock;

@end
