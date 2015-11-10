//
//  DQDataStoreController.h
//  DrawQuest
//
//  Created by Buzz Andersen on 9/11/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DQAbstractServiceController.h"
#import "DQCommentUpload.h"
#import "DQQuestUpload.h"
#import "DQFollowConstants.h"
#import "DQStarConstants.h"

@class DQAccount;
@class DQUser;
@class DQQuest;
@class DQComment;

typedef void(^DQDataObjectsBlock)(NSArray *objects);

// Notifications
extern NSString *DQCommentUploadCompletedNotification;
extern NSString *DQCommentUploadProgressChangedNotification;
extern NSString *DQCommentUploadFailedNotification;
extern NSString *DQCommentUploadFailedInvalidFacebookTokenNotification;
extern NSString *DQCommentUploadFailedInvalidTwitterTokenNotification;
extern NSString *DQQuestUploadCompletedNotification;
extern NSString *DQQuestUploadProgressChangedNotification;
extern NSString *DQQuestUploadFailedNotification;
extern NSString *DQQuestUploadFailedInvalidFacebookTokenNotification;
extern NSString *DQQuestUploadFailedInvalidTwitterTokenNotification;
extern NSString *DQCommentPlayedNotification;
extern NSString *DQCommentFlaggedNotification;
extern NSString *DQQuestFlaggedNotification;
extern NSString *DQCommentDeletedNotification;

// Notification Keys
extern NSString *DQCommentObjectNotificationKey;
extern NSString *DQCommentUploadObjectNotificationKey;
extern NSString *DQQuestObjectNotificationKey;
extern NSString *DQQuestUploadObjectNotificationKey;

@interface DQDataStoreController : NSObject

@property (nonatomic, readonly, copy) NSString *preloadedQuestID;

// designated initializer
- (id)init;

//- (void)beginLongLivedReadTransaction;

- (void)deletePersistentStore;

- (void)addObserver:(id)inObserver action:(SEL)inAction forEntityName:(NSString *)inEntityName;
- (void)removeObserver:(id)inObserver forEntityName:(NSString *)inEntityName;
- (void)removeObserver:(id)inObserver;

// Quest CRUD
- (void)createOrUpdateQuestsFromJSONList:(NSArray *)inJSONList inBackground:(BOOL)inBackground resultsBlock:(void (^)(NSArray *objects))resultsBlock;
- (DQQuest *)createOrUpdateQuestWithJSONInfo:(NSDictionary *)inJSONInfo;

- (void)markQuestIDCompleted:(NSString *)inQuestID;
- (void)markQuestsIDsFromJSONListCompleted:(NSArray *)inQuestIDList inBackground:(BOOL)inBackground;

// Comment CRUD
- (void)createOrUpdateCommentsForQuestID:(NSString *)inQuestID fromJSONList:(NSArray *)inJSONList questJSONDictionary:(NSDictionary *)questJSONDictionary inBackground:(BOOL)inBackground resultsBlock:(void (^)(NSArray *objects))resultsBlock;
- (void)createOrUpdateCommentsFromJSONList:(NSArray *)inJSONList inBackground:(BOOL)inBackground resultsBlock:(void (^)(NSArray *objects))resultsBlock;
- (DQComment *)createOrUpdateCommentWithJSONInfo:(NSDictionary *)inJSONInfo;

- (void)flagCommentWithServerID:(NSString *)inServerID;
- (void)flagQuestWithServerID:(NSString *)inServerID;
- (void)deleteCommentWithServerID:(NSString *)inServerID;

// Quest Upload CRUD

- (DQQuestUpload *)createQuestUpload;

- (void)markAllUploadingQuestUploadsFailed;

- (void)deleteQuestUpload:(DQQuestUpload *)questUpload;
- (void)takeProgress:(NSNumber *)percentComplete forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveFacebookToken:(NSString *)facebookToken forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveFacebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveContentID:(NSString *)contentID forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveStatus:(DQQuestUploadStatus)status forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveStatus:(DQQuestUploadStatus)status withError:(NSError *)error forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveTitle:(NSString *)title forQuestUpload:(DQQuestUpload *)questUpload;

// Comment Upload CRUD
- (DQCommentUpload *)createCommentUploadForQuestWithServerID:(NSString *)inQuestID
                                                  shareFlags:(NSArray *)inShareFlags
                                               facebookToken:(NSString *)facebookToken
                                                twitterToken:(NSString *)twitterToken
                                          twitterTokenSecret:(NSString *)twitterTokenSecret
                                                   emailList:(NSArray *)emailList;

- (void)markAllUploadingCommentUploadsFailed;

- (void)deleteCommentUpload:(DQCommentUpload *)commentUpload;
- (void)takeProgress:(NSNumber *)percentComplete forCommentUpload:(DQCommentUpload *)commentUpload;
- (void)saveFacebookToken:(NSString *)facebookToken forCommentUpload:(DQCommentUpload *)commentUpload;
- (void)saveTwitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret forCommentUpload:(DQCommentUpload *)commentUpload;
- (void)saveContentID:(NSString *)contentID forCommentUpload:(DQCommentUpload *)commentUpload;
- (void)saveStatus:(DQCommentUploadStatus)status forCommentUpload:(DQCommentUpload *)commentUpload;
- (void)saveShareToFacebook:(BOOL)shouldShareToFacebook forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveShareToTwitter:(BOOL)shouldShareToTwitter forQuestUpload:(DQQuestUpload *)questUpload;
- (void)saveEmailList:(NSArray *)emailList forQuestUpload:(DQQuestUpload *)questUpload;

// User CRUD
- (void)createOrUpdateUsersFromJSONList:(NSArray *)inJSONList inBackground:(BOOL)inBackground withCompletionBlock:(void (^)(NSArray *objects))completionBlock;
- (void)updateCoinBalanceForUserWithUserName:(NSString *)inUserID withCount:(NSNumber *)inCount;
- (void)saveIsFollowing:(BOOL)isFollowing forUser:(DQUser *)user;

// Quest Queries
- (DQQuest *)questForServerID:(NSString *)inServerID;
- (NSArray *)quests;

// Comment Queries
- (DQComment *)commentForServerID:(NSString *)inServerID;

// Comment Upload Queries
- (NSArray *)sortedCommentUploadsForQuest:(DQQuest *)quest;
- (DQCommentUpload *)commentUploadForIdentifier:(NSString *)inIdentifier;

// Quest Upload Queries
- (NSArray *)questUploads;

// User Queries
- (DQUser *)userForUserName:(NSString *)inUserName;

// Follow States
- (void)populateFollowStateMap:(NSMutableDictionary *)map;
- (DQFollowState)followStateForUsername:(NSString *)username;
- (void)setFollowState:(DQFollowState)state forUsername:(NSString *)username withTimestamp:(NSDate *)timestamp;
- (void)setManyFollowStates:(NSDictionary *)updates withTimestamp:(NSDate *)timestamp;

// Star States
- (void)populateStarStateMap:(NSMutableDictionary *)map;
- (DQStarState)starStateForCommentWithServerID:(NSString *)commentID;
- (void)setStarState:(DQStarState)state forCommentWithServerID:(NSString *)commentID withTimestamp:(NSDate *)timestamp;

@end
