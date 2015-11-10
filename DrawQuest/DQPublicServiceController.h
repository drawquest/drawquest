//
//  DQPublicServiceController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractServiceController.h"

@interface DQPublicServiceController : DQAbstractServiceController

#pragma mark - Logout

- (void)requestLogout:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Explore

- (DQHTTPRequest *)requestExploreCommentsWithCompletionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock;
- (void)requestExploreUserSearchWithQuery:(NSString *)query completionBlock:(DQServiceStatusBlock)completionBlock;

// deprecated: use the version with the failure block
- (DQHTTPRequest *)requestExploreCommentsWithCompletionBlock:(DQServiceStatusBlock)completionBlock;

#pragma mark - Quests

- (DQHTTPRequest *)requestQuestWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestCurrentQuestWithCompletionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;;
- (DQHTTPRequest *)requestQuestArchiveWithPage:(NSNumber *)page completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestCommentsForQuestWithServerID:(NSString *)inServerID forcedCommentID:(NSString *)inForcedCommentID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestCommentsForQuestWithServerID:(NSString *)inServerID forcedCommentID:(NSString *)inForcedCommentID offset:(NSNumber *)offset direction:(DQOffsetDirection)direction completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestTopCommentsForQuestWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestTopCommentsForQuestWithServerID:(NSString *)inServerID offset:(NSNumber *)offset direction:(DQOffsetDirection)direction completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestTopQuestsWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock;

#pragma mark - Comments

- (DQHTTPRequest *)requestCommentWithServerID:(NSString *)inCommentID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Profile

- (DQHTTPRequest *)requestCommentsForUsername:(NSString *)inUserName page:(NSNumber *)page completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestQuestsForUsername:(NSString *)inUserName page:(NSNumber *)page completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (void)requestProfileInfoForUsername:(NSString *)inUserName completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark - Sharing

- (void)requestCreateEmailInviteURLWithCompletionBlock:(DQServiceCompletionBlock)inBlock;
- (void)requestShareURLForCommentID:(NSString *)inCommentID channel:(NSString *)inChannel withCompletionBlock:(DQServiceCompletionBlock)inBlock;
- (void)requestShareURLForQuestID:(NSString *)inQuestID channel:(NSString *)inChannel withCompletionBlock:(DQServiceCompletionBlock)inBlock;

#pragma mark - Inviting

- (DQHTTPRequest *)requestUsernamesFromEmailHashList:(NSArray *)emailHashList withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Following

- (DQHTTPRequest *)requestFollowersForUserName:(NSString *)inUserName withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestFollowersForUserName:(NSString *)inUserName offset:(NSString *)next withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

- (DQHTTPRequest *)requestFollowingForUserName:(NSString *)inUserName withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;
- (DQHTTPRequest *)requestFollowingForUserName:(NSString *)inUserName offset:(NSString *)next withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

- (void)requestFollowStatusForUserName:(NSString *)inUserName withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Economy

- (void)requestPostingRewardsForQuestID:(NSString *)inQuestID shareFlags:(NSArray *)inShareFlags withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceFailureBlock)inFailureBlock;

#pragma mark - Playback

- (void)requestLogPlaybackForCommentID:(NSString *)inCommentID withCompletionBlock:(DQServiceStatusBlock)inCompletionBlock;
- (void)requestPlaybackDataForCommentID:(NSString *)inCommentID withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;

#pragma mark - Realtime Sync

- (void)requestStateSyncWithHomeTimestamp:(NSNumber *)homeTimestamp drawTimestamp:(NSNumber *)drawTimestamp activityTimestamp:(NSNumber *)activityTimestamp completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

#pragma mark Metrics

- (void)requestRecordingForMetricNamed:(NSString *)eventName info:(NSDictionary *)info;
- (DQHTTPRequest *)requestTrackViewedCommentsWithServerIDs:(NSArray *)serverIDs completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock;

@end
