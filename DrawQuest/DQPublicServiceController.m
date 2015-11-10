//
//  DQPublicServiceController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPublicServiceController.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQFollowConstants.h"
#import "DQPapertrailLogger.h"

// API Method Constants
NSString *DQAPIMethodLogout = @"auth/logout";
NSString *DQApiMethodExploreComments = @"explore/comments";
NSString *DQApiMethodExploreUserSearch = @"search/users";
NSString *DQAPIMethodGetCurrentQuest = @"quests/current";
NSString *DQAPIMethodGetQuestArchive = @"quests/archive/v2";
NSString *DQAPIMethodGetQuestGallery = @"quests/gallery";
NSString *DQAPIMethodGetQuestGalleryTop = @"quests/top_gallery";
NSString *DQAPIMethodGetQuestGalleryForComment = @"quests/gallery_for_comment";
NSString *DQAPIMethodGetTopQuests = @"quests/top";
NSString *DQAPIMethodGetUserComments = @"quest_comments/user_comments/v2";
NSString *DQAPIMethodGetUserCommentsWithUGQ = @"quest_comments/user_comments/v3";
NSString *DQAPIMethodGetQuest = @"quests/quest";
NSString *DQAPIMethodGetComment = @"quest_comments/comment";
NSString *DQAPIMethodGetUserQuests = @"ugq/quests_created_by_user";
NSString *DQAPIMethodProfileInfo = @"user/profile";
NSString *DQAPIMethodGetEmailInviteURL = @"create_email_invite_url";
NSString *DQAPIMethodGetShareURL = @"share/create_for_channel";
NSString *DQAPIMethodGetFollowers = @"following/followers";
NSString *DQAPIMethodGetFollowing = @"following/following";
NSString *DQAPIMethodIsFollowing = @"following/is_following";
NSString *DQAPIMethodGetRewardsForPosting = @"quest_comments/rewards_for_posting";
NSString *DQAPIMethodLogPlayback = @"playback/playback";
NSString *DQAPIMethodDownloadPlaybackData = @"playback/playback_data";
NSString *DQAPIMethodStateSync = @"heavy_state_sync";
NSString *DQAPIMethodMetricRecord = @"metric/record";
NSString *DQAPIMethodTrackViewedComments = @"quest_comments/viewed";
NSString *DQAPIMethodGetUsersByEmail = @"existing_users_by_email";

@implementation DQPublicServiceController

- (NSString *)serviceQueueName
{
    return @"as.canv.DrawQuest.PublicAPIRequestQueue";
}

#pragma mark -
#pragma mark Template Methods

- (NSString *)papertrailLoggerComponentPrefix
{
    return @"public";
}

#pragma mark -
#pragma mark Logout

- (void)requestLogout:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodLogout resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *logoutRequest = [weakSelf requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodLogout completionBlock:inCompletionBlock failureBlock:inFailureBlock];
            logoutRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            [weakSelf startHTTPRequest:logoutRequest];
        }
        else if (inFailureBlock)
        {
            inFailureBlock(nil);
        }
    }];
}

#pragma mark -
#pragma mark Explore

- (DQHTTPRequest *)requestExploreCommentsWithCompletionBlock:(DQServiceStatusBlock)completionBlock
{
    return [self requestExploreCommentsWithCompletionBlock:completionBlock failureBlock:completionBlock];
}

- (DQHTTPRequest *)requestExploreCommentsWithCompletionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock
{
    DQHTTPRequest *commentsRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQApiMethodExploreComments completionBlock:completionBlock failureBlock:failureBlock];
    commentsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    commentsRequest.timeoutInterval = 90.0f;  //Special time out value for this endpoint
    [self startHTTPRequest:commentsRequest];
    return commentsRequest;
}

- (void)requestExploreUserSearchWithQuery:(NSString *)query completionBlock:(DQServiceStatusBlock)completionBlock
{
    DQHTTPRequest *userSearchRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQApiMethodExploreUserSearch completionBlock:completionBlock failureBlock:completionBlock];
    userSearchRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    userSearchRequest.baseURL = [self settingForKey:DQRouterSpecifiedSearchURL fallbackKey:DQServiceControllerDefaultSearchEndpointInfoDictKey];
    [userSearchRequest setPostBodyParameterValue:query forKey:@"query"];
    [self startHTTPRequest:userSearchRequest];
}

#pragma mark -
#pragma mark Quests

- (DQHTTPRequest *)requestQuestWithServerID:(NSString *)inQuestID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = nil;
    if ([inQuestID length])
    {
        request = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetQuest completionBlock:inCompletionBlock failureBlock:inFailureBlock];
        request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

        [request setPostBodyParameterValue:inQuestID forKey:DQAPIKeyStringQuestID];
        [self startHTTPRequest:request];
    }
    return request;
}

- (void)requestCurrentQuestWithCompletionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetCurrentQuest completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    [self startHTTPRequest:request];
}

- (DQHTTPRequest *)requestQuestArchiveWithPage:(NSNumber *)page completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetQuestArchive completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    if (page)
    {
        [request setPostBodyParameterValue:page forKey:@"offset"];
    }
    [request setPostBodyParameterValue:@"next" forKey:@"direction"];

    [self startHTTPRequest:request];
    return request;
}

- (DQHTTPRequest *)requestCommentsForQuestWithServerID:(NSString *)inServerID forcedCommentID:(NSString *)inForcedCommentID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    return [self requestCommentsForQuestWithServerID:inServerID forcedCommentID:inForcedCommentID offset:nil direction:nil completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (DQHTTPRequest *)requestCommentsForQuestWithServerID:(NSString *)inServerID forcedCommentID:(NSString *)inForcedCommentID offset:(NSNumber *)offset direction:(DQOffsetDirection)direction completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    if (!inServerID)
    {
        if (inFailureBlock)
        {
            inFailureBlock(nil); // FIXME: create an error for this, or should this raise an exception?
        }
        return nil;
    }

    NSString *command = [inForcedCommentID length] ? DQAPIMethodGetQuestGalleryForComment : DQAPIMethodGetQuestGallery;
    DQHTTPRequest *questCommentsRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:command completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    questCommentsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    questCommentsRequest.tag = inServerID;

    [questCommentsRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringQuestID];

    if ([inForcedCommentID length])
    {
        [questCommentsRequest setPostBodyParameterValue:inForcedCommentID forKey:@"comment_id"];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [questCommentsRequest setPostBodyParameterValue:@(NO) forKey:@"include_reactions"];
    }

    [questCommentsRequest setPostBodyParameterValue:offset ?: @"top" forKey:@"offset"];

    switch (direction)
    {
        case DQOffsetDirectionNext:
            [questCommentsRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
            break;
        case DQOffsetDirectionPrevious:
            [questCommentsRequest setPostBodyParameterValue:@"previous" forKey:@"direction"];
            break;
        default:
            break;
    }

    [self startHTTPRequest:questCommentsRequest];
    return questCommentsRequest;
}

- (DQHTTPRequest *)requestTopCommentsForQuestWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    return [self requestTopCommentsForQuestWithServerID:inServerID offset:nil direction:nil completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (DQHTTPRequest *)requestTopCommentsForQuestWithServerID:(NSString *)inServerID offset:(NSNumber *)offset direction:(DQOffsetDirection)direction completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    if (!inServerID)
    {
        if (inFailureBlock)
        {
            inFailureBlock(nil); // FIXME: create an error for this, or should this raise an exception?
        }
        return nil;
    }

    DQHTTPRequest *questCommentsRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetQuestGalleryTop completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    questCommentsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    questCommentsRequest.tag = inServerID;

    [questCommentsRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringQuestID];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [questCommentsRequest setPostBodyParameterValue:@(NO) forKey:@"include_reactions"];
    }

    // No pagination for now
    //[questCommentsRequest setPostBodyParameterValue:offset ?: @"top" forKey:@"offset"];

    switch (direction)
    {
        case DQOffsetDirectionNext:
            //[questCommentsRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
            break;
        case DQOffsetDirectionPrevious:
            //[questCommentsRequest setPostBodyParameterValue:@"previous" forKey:@"direction"];
            break;
        default:
            break;
    }

    [self startHTTPRequest:questCommentsRequest];
    return questCommentsRequest;
}

- (DQHTTPRequest *)requestTopQuestsWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock
{
    DQHTTPRequest *questsRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetTopQuests completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    [self startHTTPRequest:questsRequest];
    return questsRequest;
}

#pragma mark -
#pragma mark Comments

- (DQHTTPRequest *)requestCommentWithServerID:(NSString *)inCommentID completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = nil;
    if ([inCommentID length])
    {
        request = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetComment completionBlock:inCompletionBlock failureBlock:inFailureBlock];
        request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

        [request setPostBodyParameterValue:inCommentID forKey:DQAPIKeyStringCommentID];
        [self startHTTPRequest:request];
    }
    return request;
}

#pragma mark -
#pragma mark Profile

- (DQHTTPRequest *)requestCommentsForUsername:(NSString *)inUserName page:(NSNumber *)page completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    if (!inUserName.length)
    {
        if (inFailureBlock)
        {
            inFailureBlock(nil);
        }
        return nil;
    }

    // Only show UGQ for iPhone
    NSString *command = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? DQAPIMethodGetUserComments : DQAPIMethodGetUserCommentsWithUGQ;
    DQHTTPRequest *userCommentsRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:command completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    userCommentsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [userCommentsRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [userCommentsRequest setPostBodyParameterValue:@(NO) forKey:@"include_reactions"];
    }

    if (page)
    {
        [userCommentsRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
        [userCommentsRequest setPostBodyParameterValue:page forKey:@"offset"];
    }

    [self startHTTPRequest:userCommentsRequest];
    return userCommentsRequest;
}

- (DQHTTPRequest *)requestQuestsForUsername:(NSString *)inUserName page:(NSNumber *)page completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    if (!inUserName.length)
    {
        if (inFailureBlock)
        {
            inFailureBlock(nil);
        }
        return nil;
    }

    DQHTTPRequest *userQuestsRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetUserQuests completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    userQuestsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [userQuestsRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];

    if (page)
    {
        [userQuestsRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
        [userQuestsRequest setPostBodyParameterValue:page forKey:@"offset"];
    }

    [self startHTTPRequest:userQuestsRequest];
    return userQuestsRequest;
}

- (void)requestProfileInfoForUsername:(NSString *)inUserName completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    if (!inUserName.length)
    {
        if (inFailureBlock)
        {
            inFailureBlock(nil);
        }
        return;
    }

    DQHTTPRequest *profileRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodProfileInfo completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    profileRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    [profileRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];
    [self startHTTPRequest:profileRequest];
}

#pragma mark -
#pragma mark Sharing

- (void)requestCreateEmailInviteURLWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlockBlock
{
    DQHTTPRequest *emailInviteRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetEmailInviteURL];
    emailInviteRequest.requestMethod = DQHTTPRequestMethodPOST;
    emailInviteRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    emailInviteRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlockBlock) {
            inCompletionBlockBlock(inRequest, responseDictionary);
        }
    };

    // FIXME: Needs a fail block

    [self startHTTPRequest:emailInviteRequest];
}

- (void)requestShareURLForCommentID:(NSString *)inCommentID channel:(NSString *)inChannel withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *shareURLRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetShareURL];
    shareURLRequest.requestMethod = DQHTTPRequestMethodPOST;
    shareURLRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [shareURLRequest setPostBodyParameterValue:inCommentID forKey:DQAPIKeyStringCommentID];
    [shareURLRequest setPostBodyParameterValue:inChannel forKey:DQAPIKeyStringShareChannel];

    shareURLRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock) {
            inCompletionBlock(inRequest, responseDictionary);
        }
    };

    if (inCompletionBlock) {
        shareURLRequest.requestDidFailBlock =  ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest, nil);
        };
    }

    [self startHTTPRequest:shareURLRequest];
}

- (void)requestShareURLForQuestID:(NSString *)inQuestID channel:(NSString *)inChannel withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *shareURLRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetShareURL];
    shareURLRequest.requestMethod = DQHTTPRequestMethodPOST;
    shareURLRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [shareURLRequest setPostBodyParameterValue:inQuestID forKey:DQAPIKeyStringQuestID];
    [shareURLRequest setPostBodyParameterValue:inChannel forKey:DQAPIKeyStringShareChannel];

    shareURLRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock) {
            inCompletionBlock(inRequest, responseDictionary);
        }
    };

    if (inCompletionBlock) {
        shareURLRequest.requestDidFailBlock =  ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest, nil);
        };
    }

    [self startHTTPRequest:shareURLRequest];
}

#pragma mark -
#pragma mark Inviting

- (DQHTTPRequest *)requestUsernamesFromEmailHashList:(NSArray *)emailHashList withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *usernamesRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetUsersByEmail];
    usernamesRequest.requestMethod = DQHTTPRequestMethodPOST;
    usernamesRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [usernamesRequest setPostBodyParameterValue:emailHashList forKey:DQAPIKeyStringEmailHashList];

    usernamesRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock) {
            inCompletionBlock(inRequest, responseDictionary);
        }
    };

    if (inCompletionBlock) {
        usernamesRequest.requestDidFailBlock =  ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest, nil);
        };
    }

    [self startHTTPRequest:usernamesRequest];
    return usernamesRequest;
}

#pragma mark -
#pragma mark Following

- (void)updateViewerIsFollowingForList:(NSArray *)list
{
    NSMutableDictionary *updates = [NSMutableDictionary new];
    for (NSDictionary *dict in list)
    {
        NSString *username = dict.dq_userName;
        NSNumber *vif = dict.dq_viewerIsFollowing;
        if (vif && [username length])
        {
            updates[username] = @([vif boolValue] ? DQFollowStateFollowing : DQFollowStateNotFollowing);
        }
    }
    if ([updates count])
    {
        DQRequestUpdateFollowStatesFromDictionary(updates);
    }
}

- (DQHTTPRequest *)requestFollowersForUserName:(NSString *)inUserName withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    return [self requestFollowersForUserName:inUserName offset:nil withCompletionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (DQHTTPRequest *)requestFollowersForUserName:(NSString *)inUserName offset:(NSString *)next withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *followersRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetFollowers];
    followersRequest.requestMethod = DQHTTPRequestMethodPOST;
    followersRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    followersRequest.tag = inUserName;

    [followersRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];

    [followersRequest setPostBodyParameterValue:next ?: @"top" forKey:@"offset"];
    if (next)
    {
        [followersRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
    }

    __weak typeof(self) weakSelf = self;
    followersRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        if (inCompletionBlock) {
            NSArray *result = inRequest.dq_responseDictionary.dq_followingFollowersList;
            [weakSelf updateViewerIsFollowingForList:result];
            inCompletionBlock(inRequest, result);
        }
    };

    if (inFailureBlock)
    {
        followersRequest.requestDidFailBlock = ^(DQHTTPRequest *request) {
            inFailureBlock(request);
        };
    }

    [self startHTTPRequest:followersRequest];
    return followersRequest;
}

- (DQHTTPRequest *)requestFollowingForUserName:(NSString *)inUserName withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    return [self requestFollowingForUserName:inUserName offset:nil withCompletionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (DQHTTPRequest *)requestFollowingForUserName:(NSString *)inUserName offset:(NSString *)next withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *followingRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetFollowing];
    followingRequest.requestMethod = DQHTTPRequestMethodPOST;
    followingRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    followingRequest.tag = inUserName;

    [followingRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];

    [followingRequest setPostBodyParameterValue:next ?: @"top" forKey:@"offset"];
    if (next)
    {
        [followingRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
    }

    __weak typeof(self) weakSelf = self;
    followingRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        if (inCompletionBlock) {
            NSArray *result = inRequest.dq_responseDictionary.dq_followingFollowersList;
            [weakSelf updateViewerIsFollowingForList:result];
            inCompletionBlock(inRequest, result);
        }
    };

    if (inFailureBlock)
    {
        followingRequest.requestDidFailBlock = ^(DQHTTPRequest *request) {
            inFailureBlock(request);
        };
    }

    [self startHTTPRequest:followingRequest];
    return followingRequest;
}

- (void)requestFollowStatusForUserName:(NSString *)inUserName withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *isFollowingRequest = [self.serviceQueue requestWithCommand:DQAPIMethodIsFollowing];
    isFollowingRequest.requestMethod = DQHTTPRequestMethodPOST;
    isFollowingRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    isFollowingRequest.tag = inUserName;

    [isFollowingRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];

    isFollowingRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        if (inCompletionBlock) {
            inCompletionBlock(inRequest, inRequest.dq_responseDictionary);
        }
    };

    // FIXME: Needs a fail block

    [self startHTTPRequest:isFollowingRequest];
}

#pragma mark -
#pragma mark Economy

- (void)requestPostingRewardsForQuestID:(NSString *)inQuestID shareFlags:(NSArray *)inShareFlags withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceFailureBlock)inFailureBlock
{
    if (!inQuestID)
    {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil, nil);
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodGetRewardsForPosting tag:inQuestID resultBlock:^(BOOL found) {
        DQHTTPRequest *rewardsInfoRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodGetRewardsForPosting];
        rewardsInfoRequest.requestMethod = DQHTTPRequestMethodPOST;
        rewardsInfoRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
        rewardsInfoRequest.tag = inQuestID;

        [rewardsInfoRequest setPostBodyParameterValue:inQuestID forKey:DQAPIKeyStringQuestID];

        if ([inShareFlags containsObject:DQAPIValueShareChannelTypeFacebook]) {
            [rewardsInfoRequest setPostBodyParameterValue:@YES forKey:DQAPIValueShareChannelTypeFacebook];
        }

        if ([inShareFlags containsObject:DQAPIValueShareChannelTypeTwitter]) {
            [rewardsInfoRequest setPostBodyParameterValue:@YES forKey:DQAPIValueShareChannelTypeTwitter];
        }

        rewardsInfoRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
            NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

            if (inCompletionBlock) {
                inCompletionBlock(inRequest, responseDictionary.dq_rewardsInfo);
            }
        };

        rewardsInfoRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
            if (inFailureBlock)
            {
                inFailureBlock(inRequest, inRequest.error);
            }
        };

        [weakSelf startHTTPRequest:rewardsInfoRequest];
    }];
}

#pragma mark -
#pragma mark Playback

- (void)requestLogPlaybackForCommentID:(NSString *)inCommentID withCompletionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodLogPlayback tag:inCommentID resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *logPlaybackRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodLogPlayback];
            logPlaybackRequest.requestMethod = DQHTTPRequestMethodPOST;
            logPlaybackRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            logPlaybackRequest.tag = inCommentID;

            [logPlaybackRequest setPostBodyParameterValue:inCommentID forKey:DQAPIKeyStringCommentID];

            logPlaybackRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                if (inCompletionBlock)
                {
                    inCompletionBlock(inRequest);
                }
            };

            [weakSelf startHTTPRequest:logPlaybackRequest];
        }
    }];
}

- (void)requestPlaybackDataForCommentID:(NSString *)inCommentID withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodDownloadPlaybackData tag:inCommentID resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *playbackDataRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodDownloadPlaybackData];
            playbackDataRequest.requestMethod = DQHTTPRequestMethodPOST;
            playbackDataRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            playbackDataRequest.tag = inCommentID;

            [playbackDataRequest setPostBodyParameterValue:inCommentID forKey:DQAPIKeyStringCommentID];

            playbackDataRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
                NSString *playbackJSONString = responseDictionary.dq_playbackDataJSONString;
                NSDictionary *playbackData = nil;
                if (playbackJSONString)
                {
                    // FIXME: this uses a huge amount of memory - instead the download should
                    // be streamed into a file and then the file should be read incrementally
                    playbackData = [NSJSONSerialization JSONObjectWithData:[playbackJSONString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                }

                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, playbackData);
                }
            };

            playbackDataRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, nil);
                }
            };

            [weakSelf startHTTPRequest:playbackDataRequest];
        }
    }];
}

#pragma mark -
#pragma mark Realtime Sync

- (void)requestStateSyncWithHomeTimestamp:(NSNumber *)homeTimestamp drawTimestamp:(NSNumber *)drawTimestamp activityTimestamp:(NSNumber *)activityTimestamp completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodStateSync resultBlock:^(BOOL stateSyncFound) {
        if (stateSyncFound)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil);
            }
        }
        else
        {
            DQHTTPRequest *syncRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodStateSync];
            syncRequest.requestMethod = DQHTTPRequestMethodPOST;
            syncRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            NSMutableDictionary *timestamps = [NSMutableDictionary new];
            if (homeTimestamp)
            {
                timestamps[@"home"] = homeTimestamp;
            }
            if (drawTimestamp)
            {
                timestamps[@"draw"] = drawTimestamp;
            }
            if (activityTimestamp)
            {
                timestamps[@"activity"] = activityTimestamp;
            }
            if ([timestamps count])
            {
                [syncRequest setPostBodyParameterValue:timestamps forKey:@"tab_last_seen_timestamps"];
            }

            syncRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                if (inCompletionBlock)
                {
                    inCompletionBlock(inRequest);
                }
            };

            syncRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                if (inFailureBlock)
                {
                    inFailureBlock(inRequest);
                }
            };

            [weakSelf startHTTPRequest:syncRequest];
        }
    }];
}

#pragma mark -
#pragma mark Metrics

- (void)requestRecordingForMetricNamed:(NSString *)eventName info:(NSDictionary *)info
{
    DQHTTPRequest *recordRequest = [self.serviceQueue requestWithCommand:DQAPIMethodMetricRecord];
    recordRequest.requestMethod = DQHTTPRequestMethodPOST;
    recordRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [recordRequest setPostBodyParameterValue:eventName forKey:DQAPIKeyStringMetricName];

    // ignore completion and errors
    recordRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {};
    recordRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {};

    [self startHTTPRequest:recordRequest];
}

- (DQHTTPRequest *)requestTrackViewedCommentsWithServerIDs:(NSArray *)serverIDs completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodTrackViewedComments completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    [request setPostBodyParameterValue:serverIDs forKey:DQAPIKeyCommentIDs];
    [self startHTTPRequest:request];
    return request;
}

@end
