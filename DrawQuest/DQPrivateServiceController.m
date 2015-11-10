//
//  DQPrivateServiceController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-07-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPrivateServiceController.h"
#import "NSDictionary+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQCommentUpload.h"
#import "DQQuestUpload.h"
#import "DQPapertrailLogger.h"

NSString *DQAvatarChangedNotification = @"DQAvatarChangedNotification";
NSString *DQProfileUpdatedNotification = @"DQProfileUpdatedNotification";
NSString *DQFacebookProfileURLUpdatedNotification = @"DQFacebookProfileURLUpdatedNotification";
NSString *DQTwitterProfileURLUpdatedNotification = @"DQTwitterProfileURLUpdatedNotification";

// API Method Constants
NSString *DQAPIMethodAssociateFacebookAccount = @"auth/associate_facebook_account";
NSString *DQAPIMethodAssociateTwitterAccount = @"auth/associate_twitter_account";
NSString *DQAPIMethodFlagComment = @"quest_comments/flag";
NSString *DQAPIMethodFlagQuest = @"quests/flag";
NSString *DQAPIMethodDeleteComment = @"quest_comments/delete";
NSString *DQAPIMethodStarComment = @"stars/star";
NSString *DQAPIMethodUnstarComment = @"stars/unstar";
NSString *DQAPIMethodActivity = @"activity/activities";
NSString *DQAPIMethodPhoneActivity = @"activity/iphone_activities";
NSString *DQAPIMethodFeedFollowees = @"feed/followee_comments";
NSString *DQAPIMethodUpload = @"upload";
NSString *DQAPIMethodPostComment = @"quest_comments/post";
NSString *DQAPIMethodPostQuest = @"ugq/create_quest";
NSString *DQAPIMethodSetPlaybackData = @"playback/set_playback_data";
NSString *DQAPIMethodChangeProfileInfo = @"user/change_profile";
NSString *DQAPIMethodChangeAvatar = @"user/change_avatar";
NSString *DQAPIMethodChangeWebProfilePrivacy = @"user/set_web_profile_privacy";
NSString *DQAPIMethodChangeFacebookPrivacy = @"user/set_facebook_privacy";
NSString *DQAPIMethodChangeTwitterPrivacy = @"user/set_twitter_privacy";
NSString *DQAPIMethodFollowUser = @"following/follow_user";
NSString *DQAPIMethodUnfollowUser = @"following/unfollow_user";
NSString *DQAPIMethodFacebookFriendsOnDrawQuest = @"invites/facebook_friends_on_drawquest";
NSString *DQAPIMethodTwitterFollowersOnDrawQuest = @"invites/twitter_followers_on_drawquest";
NSString *DQAPIMethodTwitterFriendsInvited = @"invites/invited_twitter_friends";
NSString *DQAPIMethodShopGetItems = @"shop/all_items";
NSString *DQAPIMethodShopPurchaseColor = @"palettes/purchase_color";
NSString *DQAPIMethodShopPurchaseColorPack = @"palettes/purchase_color_pack";
NSString *DQAPIMethodShopPurchaseBrush = @"brushes/purchase_brush";
NSString *DQAPIMethodGetCoinProducts = @"iap/coin_products";
NSString *DQAPIMethodProcessPurchaseReceipt = @"iap/process_receipt";
NSString *DQAPIMethodPushSubscribe = @"push_notifications/resubscribe";
NSString *DQAPIMethodPushUnsubscribe = @"push_notifications/unsubscribe";
NSString *DQAPIMethodPostSocialNetworkMessage = @"profiles/share_web_profile";
NSString *DQAPIMethodGetQuestHistory = @"quests/history";
NSString *DQAPIMethodGetQuestInbox = @"quests/inbox";
NSString *DQAPIMethodDismissQuest = @"quests/dismiss_quest";
NSString *DQAPIMethodKeyValueSet = @"kv/set";
NSString *DQAPIMethodGetInviteMessage = @"share/create_for_channel";

@interface DQCommentUpload (DQAPIConveniences)

- (DQHTTPRequest *)configuredCommentPostRequestForServiceQueue:(DQHTTPRequestQueue *)inQueue;

@end

@interface DQQuestUpload (DQAPIConveniences)

- (DQHTTPRequest *)configuredQuestPostRequestForServiceQueue:(DQHTTPRequestQueue *)inQueue;

@end

@implementation DQPrivateServiceController

- (NSString *)serviceQueueName
{
    return @"as.canv.DrawQuest.PrivateAPIRequestQueue";
}

#pragma mark -
#pragma mark Template Methods

- (NSString *)papertrailLoggerComponentPrefix
{
    return @"private";
}

#pragma mark -
#pragma mark Associating Social Access Tokens

- (void)postNotification:(NSString *)notificationName withProfileURLForKey:(NSString *)profileURLKey inRequest:(DQHTTPRequest *)request
{
    dispatch_async(dispatch_get_main_queue(), ^{
        id JSONObject = request.responseJSONObject;
        if ([JSONObject isKindOfClass:[NSDictionary class]])
        {
            NSString *profileURLString = [(NSDictionary *)JSONObject objectForKey:profileURLKey];
            if ([profileURLString isKindOfClass:[NSString class]] && [profileURLString length])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:profileURLString];
            }
        }
    });
}

- (DQHTTPRequest *)requestAssociateFacebookToken:(NSString *)inFacebookToken completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self.serviceQueue requestWithCommand:DQAPIMethodAssociateFacebookAccount];
    request.requestMethod = DQHTTPRequestMethodPOST;
    request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    request.timeoutInterval = 60.0;  // DQ-374

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:inFacebookToken forKey:DQAPIKeyStringFacebookToken];
    [request addPostBodyParametersFromDictionary:args];
    request.papertrailLoggerDataBlock = ^{
        return args;
    };

    __weak typeof(self) weakSelf = self;
    request.requestDidFinishBlock = ^(DQHTTPRequest *request) {
        [weakSelf postNotification:DQFacebookProfileURLUpdatedNotification withProfileURLForKey:@"facebook_url" inRequest:request];
        if (weakSelf.associatedFacebookTokenBlock)
        {
            weakSelf.associatedFacebookTokenBlock(^(DQHTTPRequest *inRequest) {
                // Success Block
                if (inCompletionBlock)
                {
                    inCompletionBlock(request, request.dq_responseDictionary);
                }
            }, ^(DQHTTPRequest *inRequest) {
                // Failure Block
                if (inFailureBlock)
                {
                    inFailureBlock(inRequest);
                }
            });
        }
        else if (inCompletionBlock)
        {
            inCompletionBlock(request, request.dq_responseDictionary);
        }
    };

    if (inFailureBlock)
    {
        request.requestDidFailBlock = inFailureBlock;
    }

    [self startHTTPRequest:request];
    return request;
}

- (DQHTTPRequest *)requestAssociateTwitterToken:(NSString *)inTwitterToken twitterSecret:(NSString *)inTwitterSecret completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *request = [self.serviceQueue requestWithCommand:DQAPIMethodAssociateTwitterAccount];
    request.requestMethod = DQHTTPRequestMethodPOST;
    request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:inTwitterToken forKey:DQAPIKeyStringTwitterToken];
    [args ifNotNilSetObject:inTwitterSecret forKey:DQAPIKeyStringTwitterSecret];
    [request addPostBodyParametersFromDictionary:args];
    request.papertrailLoggerDataBlock = ^{
        return args;
    };

    __weak typeof(self) weakSelf = self;
    request.requestDidFinishBlock = ^(DQHTTPRequest *request){
        [weakSelf postNotification:DQTwitterProfileURLUpdatedNotification withProfileURLForKey:@"twitter_url" inRequest:request];
        if (weakSelf.associatedTwitterTokenBlock)
        {
            weakSelf.associatedTwitterTokenBlock(^(DQHTTPRequest *inRequest) {
                // Success Block
                if (inCompletionBlock)
                {
                    inCompletionBlock(request, request.dq_responseDictionary);
                }
            }, ^(DQHTTPRequest *inRequest) {
                // Failure Block
                if (inFailureBlock)
                {
                    inFailureBlock(inRequest);
                }
            });
        }
        else if (inCompletionBlock)
        {
            inCompletionBlock(request, request.dq_responseDictionary);
        }
    };

    if (inFailureBlock)
    {
        request.requestDidFailBlock = inFailureBlock;
    }

    [self startHTTPRequest:request];
    return request;
}

#pragma mark -
#pragma mark Flagging and Deleting

- (void)requestFlagForCommentWithServerID:(NSString *)inServerID
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodFlagComment tag:inServerID resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *flagRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodFlagComment];
            flagRequest.requestMethod = DQHTTPRequestMethodPOST;
            flagRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            [flagRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringCommentID];

            flagRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

                NSLog(@"Flag Comment Completed: %@", responseDictionary);
            };

            [weakSelf startHTTPRequest:flagRequest];
        }
    }];
}

- (void)requestFlagForQuestWithServerID:(NSString *)inServerID
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodFlagQuest tag:inServerID resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *flagRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodFlagQuest];
            flagRequest.requestMethod = DQHTTPRequestMethodPOST;
            flagRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            [flagRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringQuestID];

            flagRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

                NSLog(@"Flag Quest Completed: %@", responseDictionary);
            };

            [weakSelf startHTTPRequest:flagRequest];
        }
    }];
}

- (void)requestDeleteCommentWithServerID:(NSString *)inServerID
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodDeleteComment tag:inServerID resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *deleteRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodDeleteComment];
            deleteRequest.requestMethod = DQHTTPRequestMethodPOST;
            deleteRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            [deleteRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringCommentID];

            deleteRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

                NSLog(@"Delete Comment Completed: %@", responseDictionary);
            };

            // FIXME: service controller should not be presenting an alert view.
            deleteRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                // Simply alert the user it failed for now
                UIAlertView *deleteFailedAlert = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Drawing delete failed", @"Delete drawing request error alert title") message:DQLocalizedString(@"Something went wrong and we couldn't delete your drawing. Please try again.", @"Delete drawing request error alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil, nil];
                [deleteFailedAlert show];
            };

            [weakSelf startHTTPRequest:deleteRequest];
        }
    }];
}

#pragma mark -
#pragma mark Starring and Unstarring

- (void)requestStarOfCommentWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodStarComment tag:inServerID resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *starCommentRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodStarComment];
            starCommentRequest.requestMethod = DQHTTPRequestMethodPOST;
            starCommentRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            starCommentRequest.tag = inServerID;

            [starCommentRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringCommentID];

            starCommentRequest.requestDidFinishBlock = completionBlock;
            starCommentRequest.requestDidFailBlock = failureBlock;

            [weakSelf startHTTPRequest:starCommentRequest];
        }
    }];
}

- (void)requestUnstarOfCommentWithServerID:(NSString *)inServerID completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodUnstarComment tag:inServerID resultBlock:^(BOOL found) {
        if (!found)
        {
            DQHTTPRequest *unstarCommentRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodUnstarComment];
            unstarCommentRequest.requestMethod = DQHTTPRequestMethodPOST;
            unstarCommentRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            unstarCommentRequest.tag = inServerID;

            [unstarCommentRequest setPostBodyParameterValue:inServerID forKey:DQAPIKeyStringCommentID];

            unstarCommentRequest.requestDidFinishBlock = completionBlock;
            unstarCommentRequest.requestDidFailBlock = failureBlock;

            // FIXME: Nees a fail block

            [weakSelf startHTTPRequest:unstarCommentRequest];
        }
    }];
}

#pragma mark -
#pragma mark Home Feed

- (DQHTTPRequest *)requestCommentsForFolloweeFeedWithCompletionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    return [self requestCommentsForFolloweeFeedWithOffset:nil direction:nil completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (DQHTTPRequest *)requestCommentsForFolloweeFeedWithOffset:(NSString *)offset direction:(DQOffsetDirection)direction completionBlock:(DQServiceStatusBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *feedRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodFeedFollowees completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    feedRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [feedRequest setPostBodyParameterValue:offset ?: @"top" forKey:@"offset"];

    switch (direction)
    {
        case DQOffsetDirectionNext:
            [feedRequest setPostBodyParameterValue:@"next" forKey:@"direction"];
            break;
        case DQOffsetDirectionPrevious:
            [feedRequest setPostBodyParameterValue:@"previous" forKey:@"direction"];
            break;
        default:
            break;
    }

    [self startHTTPRequest:feedRequest];
    return feedRequest;
}

#pragma mark -
#pragma mark Activities

- (DQHTTPRequest *)requestActivityWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    return [self requestActivityNewerThan:nil olderThan:nil withCompletionBlock:inCompletionBlock];
}

- (DQHTTPRequest *)requestActivityNewerThan:(NSDate *)inNewerThanDate withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    return [self requestActivityNewerThan:inNewerThanDate olderThan:nil withCompletionBlock:inCompletionBlock];
}

- (DQHTTPRequest *)requestActivityOlderThan:(NSDate *)inOlderThanDate withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    return [self requestActivityNewerThan:nil olderThan:inOlderThanDate withCompletionBlock:inCompletionBlock];
}

- (DQHTTPRequest *)requestActivityNewerThan:(NSDate *)inNewerThanDate olderThan:(NSDate *)inOlderThanDate withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    NSString *command = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? DQAPIMethodActivity : DQAPIMethodPhoneActivity;
    DQHTTPRequest *activityRequest = [self.serviceQueue requestWithCommand:command];
    activityRequest.requestMethod = DQHTTPRequestMethodPOST;
    activityRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    if (inNewerThanDate)
    {
        NSString *value = [@([inNewerThanDate timeIntervalSince1970]) stringValue];
        [activityRequest setPostBodyParameterValue:value forKey:DQAPIKeyStringNewerThanDate];
    }
    else if (inOlderThanDate)
    {
        NSString *value = [@([inOlderThanDate timeIntervalSince1970]) stringValue];
        [activityRequest setPostBodyParameterValue:value forKey:DQAPIKeyStringOlderThanDate];
    }

    activityRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
        if (inCompletionBlock)
        {
            inCompletionBlock(inRequest, responseDictionary);
        }
    };

    if (inCompletionBlock)
    {
        activityRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest, nil);
        };
    }

    [self startHTTPRequest:activityRequest];
    return activityRequest;
}

#pragma mark -
#pragma mark Uploading Content

- (void)requestUploadOfImageData:(NSData *)inImageData withTag:(NSString *)inTag progressBlock:(DQServiceStatusBlock)inProgressBlock completionBlock:(DQServiceImageUploadCompletionBlock)inCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForTag:inTag resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *uploadRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodUpload];
            uploadRequest.requestMethod = DQHTTPRequestMethodPOST;
            uploadRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatMultipart;
            uploadRequest.tag = inTag;

            [uploadRequest setPostBodyFileData:inImageData forParameterName:@"file" filename:@"file.png" contentType:@"image/png"];

            uploadRequest.requestDidUploadDataBlock = inProgressBlock;

            uploadRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

                NSString *contentID = responseDictionary.dq_content.dq_serverID;

                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, responseDictionary.dq_content, contentID);
                }
            };

            if (inCompletionBlock) {
                uploadRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                    inCompletionBlock(inRequest, nil, nil);
                };
            }

            [weakSelf startHTTPRequest:uploadRequest];
        }
    }];
}

- (void)requestPostCommentUpload:(DQCommentUpload *)inCommentUpload completionBlock:(void (^)(NSDictionary *commentInfo))completionBlock failureBlock:(void (^)(NSString *errorType))failureBlock
{
    // If the image upload was successful, do the post
    DQHTTPRequest *postCommentRequest = [inCommentUpload configuredCommentPostRequestForServiceQueue:self.serviceQueue];
    if (postCommentRequest)
    {
        postCommentRequest.timeoutInterval = 30.0;  // DQ-374
        NSLog(@"Post comment request finished");
        if (completionBlock)
        {
            postCommentRequest.requestDidFinishBlock = ^(DQHTTPRequest *request) {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSDictionary *commentInfo = [responseDictionary.dq_comments firstObject];
                completionBlock(commentInfo);
            };
        }

        if (failureBlock)
        {
            postCommentRequest.requestDidFailBlock = ^(DQHTTPRequest *request) {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                failureBlock(responseDictionary.dq_errorType);
            };
        }

        [self startHTTPRequest:postCommentRequest];
    }
    else if (failureBlock)
    {
        failureBlock(nil);
    }
}

- (void)requestSetPlaybackDataFromFileAtPath:(NSString *)inPlaybackDataPath forCommentWithServerID:(NSString *)inCommentID progressBlock:(DQServiceStatusBlock)progressBlock completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock
{
    if (![inPlaybackDataPath length])
    {
        if (failureBlock)
        {
            failureBlock(nil);
        }
        return;
    }

    DQHTTPRequest *playbackDataRequest = [self.serviceQueue requestWithCommand:DQAPIMethodSetPlaybackData];
    playbackDataRequest.requestMethod = DQHTTPRequestMethodPOST;
    playbackDataRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatMultipart;
    playbackDataRequest.tag = inCommentID;
    playbackDataRequest.streamsPOSTBodyFromDisk = YES;
    playbackDataRequest.gzippedPOSTBody = YES;
    playbackDataRequest.timeoutInterval = 300.0;

    NSString *parameterName = DQAPIKeyStringJSONPlaybackData;
    NSString *contentType = DQHTTPRequestJSONContentType;
    if ([@"plist" isEqualToString:[inPlaybackDataPath pathExtension]]) // support uploading pre-2.0 plist upload data
    {
        parameterName = DQAPIKeyStringPropertyListPlaybackData;
        contentType = DQHTTPRequestPropertyListContentType;
    }

    NSDictionary *fileInfo = @{
                               DQHTTPRequestFileInfoParameterNameKey : parameterName,
                               DQHTTPRequestFileInfoFilenameKey : [inPlaybackDataPath lastPathComponent],
                               DQHTTPRequestFileInfoFilePathKey : inPlaybackDataPath,
                               DQHTTPRequestFileInfoContentTypeKey : contentType
                               };
    [playbackDataRequest setPostBodyParameterValue:inCommentID forKey:DQAPIKeyStringCommentID];
    [playbackDataRequest addPostBodyFileWithPath:inPlaybackDataPath fileInfo:fileInfo];
    playbackDataRequest.papertrailLoggerDataBlock = ^{
        return @{DQAPIKeyStringCommentID: inCommentID ?: [NSNull null],
                 @"path":inPlaybackDataPath ?: [NSNull null]};
    };
    if (progressBlock)
    {
        playbackDataRequest.requestDidUploadDataBlock = progressBlock;
    }
    if (completionBlock)
    {
        playbackDataRequest.requestDidFinishBlock = completionBlock;
    }
    if (failureBlock)
    {
        playbackDataRequest.requestDidFailBlock = failureBlock;
    }
    [self startHTTPRequest:playbackDataRequest];
}

- (void)requestPostQuestUpload:(DQQuestUpload *)inQuestUpload completionBlock:(void (^)(NSDictionary *questInfo))completionBlock failureBlock:(void (^)(NSString *errorType))failureBlock
{
    // FIXME: the request/input/output have not been defined yet

    // If the image upload was successful, do the post
    DQHTTPRequest *postQuestRequest = [inQuestUpload configuredQuestPostRequestForServiceQueue:self.serviceQueue];
    if (postQuestRequest)
    {
        postQuestRequest.timeoutInterval = 30.0;  // DQ-374
        NSLog(@"Post comment request finished");
        if (completionBlock)
        {
            postQuestRequest.requestDidFinishBlock = ^(DQHTTPRequest *request) {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSDictionary *questInfo = responseDictionary.dq_quest;
                completionBlock(questInfo);
            };
        }

        if (failureBlock)
        {
            postQuestRequest.requestDidFailBlock = ^(DQHTTPRequest *request) {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                failureBlock(responseDictionary.dq_errorType);
            };
        }

        [self startHTTPRequest:postQuestRequest];
    }
    else if (failureBlock)
    {
        failureBlock(nil);
    }
}

- (void)requestSetPlaybackDataFromFileAtPath:(NSString *)inPlaybackDataPath forQuestWithServerID:(NSString *)inQuestID progressBlock:(DQServiceStatusBlock)progressBlock completionBlock:(DQServiceStatusBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock
{
    if (![inPlaybackDataPath length])
    {
        if (failureBlock)
        {
            failureBlock(nil);
        }
        return;
    }

    DQHTTPRequest *playbackDataRequest = [self.serviceQueue requestWithCommand:DQAPIMethodSetPlaybackData];
    playbackDataRequest.requestMethod = DQHTTPRequestMethodPOST;
    playbackDataRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatMultipart;
    playbackDataRequest.tag = inQuestID;
    playbackDataRequest.streamsPOSTBodyFromDisk = YES;
    playbackDataRequest.gzippedPOSTBody = YES;
    playbackDataRequest.timeoutInterval = 300.0;

    NSString *parameterName = DQAPIKeyStringJSONPlaybackData;
    NSString *contentType = DQHTTPRequestJSONContentType;

    NSDictionary *fileInfo = @{
                               DQHTTPRequestFileInfoParameterNameKey : parameterName,
                               DQHTTPRequestFileInfoFilenameKey : [inPlaybackDataPath lastPathComponent],
                               DQHTTPRequestFileInfoFilePathKey : inPlaybackDataPath,
                               DQHTTPRequestFileInfoContentTypeKey : contentType
                               };
    [playbackDataRequest setPostBodyParameterValue:inQuestID forKey:DQAPIKeyStringQuestID];
    [playbackDataRequest addPostBodyFileWithPath:inPlaybackDataPath fileInfo:fileInfo];

    if (progressBlock)
    {
        playbackDataRequest.requestDidUploadDataBlock = progressBlock;
    }
    if (completionBlock)
    {
        playbackDataRequest.requestDidFinishBlock = completionBlock;
    }
    if (failureBlock)
    {
        playbackDataRequest.requestDidFailBlock = failureBlock;
    }
    [self startHTTPRequest:playbackDataRequest];
}

#pragma mark -
#pragma mark Account Settings

- (void)requestChangeProfileInfoWithEmail:(NSString *)inEmail oldPassword:(NSString *)inOldPassword newPassword:(NSString *)inNewPassword bioText:(NSString *)inBioText completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestForIdentifier:DQAPIMethodChangeProfileInfo resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *changeProfileRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodChangeProfileInfo];
            changeProfileRequest.requestMethod = DQHTTPRequestMethodPOST;
            changeProfileRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            if ([inEmail length]) {
                [changeProfileRequest setPostBodyParameterValue:inEmail forKey:@"new_email"];
            }

            if ([inOldPassword length] && [inNewPassword length]) {
                [changeProfileRequest setPostBodyParameterValue:inOldPassword forKey:@"old_password"];
                [changeProfileRequest setPostBodyParameterValue:inNewPassword forKey:@"new_password"];
            }

            if (inBioText) {
                [changeProfileRequest setPostBodyParameterValue:inBioText forKey:@"bio"];
            }

            changeProfileRequest.requestDidFinishBlock = ^(DQHTTPRequest *completedAvatarChangeRequest) {
                [[NSNotificationCenter defaultCenter] postNotificationName:DQProfileUpdatedNotification object:nil userInfo:nil];
                if (inCompletionBlock) {
                    inCompletionBlock(completedAvatarChangeRequest, completedAvatarChangeRequest.dq_responseDictionary);
                }
            };

            if (inCompletionBlock) {
                changeProfileRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                    inCompletionBlock(inRequest, nil);
                };
            }

            [weakSelf startHTTPRequest:changeProfileRequest];
        }
    }];
}

- (void)requestAvatarChangeWithImageData:(NSData *)inImageData completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    if (!inImageData.length) {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil, nil);
        }
        return;
    }

    [self requestUploadOfImageData:inImageData withTag:nil progressBlock:NULL completionBlock:^(DQHTTPRequest *imageRequest, NSDictionary *contentDictionary, NSString *contentID) {
        if (imageRequest)
        {
            [self requestSetAvatarWithContentID:contentID completionBlock:inCompletionBlock];
        }
        else
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
    }];
}

- (void)requestSetAvatarWithContentID:(NSString *)inContentID completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    if (!inContentID)
    {
        if (inCompletionBlock)
        {
            inCompletionBlock(nil, nil);
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodChangeAvatar tag:inContentID resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *changeAvatarRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodChangeAvatar];
            changeAvatarRequest.requestMethod = DQHTTPRequestMethodPOST;
            changeAvatarRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            changeAvatarRequest.tag = inContentID;

            [changeAvatarRequest setPostBodyParameterValue:inContentID forKey:DQAPIKeyStringContentID];

            changeAvatarRequest.requestDidFinishBlock = ^(DQHTTPRequest *completedAvatarChangeRequest) {
                [[NSNotificationCenter defaultCenter] postNotificationName:DQAvatarChangedNotification object:nil userInfo:nil];

                if (inCompletionBlock) {
                    inCompletionBlock(completedAvatarChangeRequest, completedAvatarChangeRequest.dq_responseDictionary);
                }
            };

            if (inCompletionBlock) {
                changeAvatarRequest.requestDidFailBlock = ^(DQHTTPRequest *failedAvatarChangeRequest) {
                    inCompletionBlock(failedAvatarChangeRequest, nil);
                };
            }

            [weakSelf startHTTPRequest:changeAvatarRequest];
        }
    }];
}

- (void)requestProfilePrivacyChange:(BOOL)inBool forPrivacyCommand:(NSString *)privacyCommand completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:privacyCommand resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *changeWebProfilePrivacyRequest = [weakSelf.serviceQueue requestWithCommand:privacyCommand];
            changeWebProfilePrivacyRequest.requestMethod = DQHTTPRequestMethodPOST;
            changeWebProfilePrivacyRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

            [changeWebProfilePrivacyRequest setPostBodyParameterValue:@(inBool) forKey:@"privacy"];

            changeWebProfilePrivacyRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                if (inCompletionBlock)
                {
                    inCompletionBlock(inRequest, inRequest.dq_responseDictionary);
                }
            };
            changeWebProfilePrivacyRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                if (inFailureBlock)
                {
                    inFailureBlock(inRequest);
                }
            };

            [self startHTTPRequest:changeWebProfilePrivacyRequest];
        }
    }];
}

- (void)requestWebProfilePrivacyChange:(BOOL)inBool completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    [self requestProfilePrivacyChange:inBool forPrivacyCommand:DQAPIMethodChangeWebProfilePrivacy completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (void)requestFacebookProfilePrivacyChange:(BOOL)inBool completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    [self requestProfilePrivacyChange:inBool forPrivacyCommand:DQAPIMethodChangeFacebookPrivacy completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (void)requestTwitterProfilePrivacyChange:(BOOL)inBool completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    [self requestProfilePrivacyChange:inBool forPrivacyCommand:DQAPIMethodChangeTwitterPrivacy completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (NSString *)stringForPushNotificationType:(DQAccountPushNotificationType)inNotificationType
{
    switch (inNotificationType) {
        case DQAccountPushNotificationTypeQuestOfTheDay:
            return DQAPIValuePushNotificationTypeQuestOfTheDay;
            break;
        case DQAccountPushNotificationTypeStarred:
            return DQAPIValuePushNotificationTypeStarred;
            break;
        case DQAccountPushNotificationTypeFacebookFriendJoined:
            return DQAPIValuePushNotificationTypeFacebookFriendJoined;
            break;
        case DQAccountPushNotificationTypeTwitterFriendJoined:
            return DQAPIValuePushNotificationTypeTwitterFriendJoined;
            break;
        default:
            break;
    }

    return nil;
}

- (void)requestPushSubscribeForNotificationType:(DQAccountPushNotificationType)inNotificationType withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    NSString *notificationTypeString = [self stringForPushNotificationType:inNotificationType];

    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodPushSubscribe tag:notificationTypeString resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *pushSubscribeRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodPushSubscribe];
            pushSubscribeRequest.requestMethod = DQHTTPRequestMethodPOST;
            pushSubscribeRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            pushSubscribeRequest.tag = notificationTypeString;

            [pushSubscribeRequest setPostBodyParameterValue:notificationTypeString forKey:DQAPIKeyStringNotificationType];

            pushSubscribeRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, inRequest.dq_responseDictionary);
                }
            };

            if (inCompletionBlock) {
                pushSubscribeRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                    inCompletionBlock(inRequest, nil);
                };
            }

            [weakSelf startHTTPRequest:pushSubscribeRequest];
        }
    }];
}

- (void)requestPushUnsubscribeForNotificationType:(DQAccountPushNotificationType)inNotificationType withCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    NSString *notificationTypeString = [self stringForPushNotificationType:inNotificationType];

    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodPushUnsubscribe tag:notificationTypeString resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *pushUnsubscribeRequest = [weakSelf.serviceQueue requestWithCommand:DQAPIMethodPushUnsubscribe];
            pushUnsubscribeRequest.requestMethod = DQHTTPRequestMethodPOST;
            pushUnsubscribeRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            pushUnsubscribeRequest.tag = notificationTypeString;

            [pushUnsubscribeRequest setPostBodyParameterValue:notificationTypeString forKey:DQAPIKeyStringNotificationType];

            pushUnsubscribeRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, inRequest.dq_responseDictionary);
                }
            };

            if (inCompletionBlock) {
                pushUnsubscribeRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                    inCompletionBlock(inRequest, nil);
                };
            }

            [weakSelf startHTTPRequest:pushUnsubscribeRequest];
        }
    }];
}

- (void)requestSetLastSeenModalUpgradeVersion:(NSString *)version failureBlock:(DQServiceStatusBlock)failureBlock
{
    if ([version length])
    {
        NSDictionary *options = @{ DQAPIKeyStringUpgradeModalSetLastSeenVersion: version };
        [self saveObjectsAndKeysInDictionary:options completionBlock:nil failureBlock:failureBlock];
    }
}

- (void)requestSetSawWebProfileModalWithFailureBlock:(DQServiceStatusBlock)failureBlock
{
    NSDictionary* options = @{ DQAPIKeyStringSawShareWebProfileModal: @YES };
    [self saveObjectsAndKeysInDictionary:options completionBlock:nil failureBlock:failureBlock];
}

- (void)requestSetPublishToFacebookUserKV:(BOOL)isOn completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    NSDictionary *kv = @{DQAPIKeyStringPublishToFacebook: @(isOn)};
    [self saveObjectsAndKeysInDictionary:kv completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

- (void)requestSetPublishToTwitterUserKV:(BOOL)isOn completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    NSDictionary *kv = @{DQAPIKeyStringPublishToTwitter: @(isOn)};
    [self saveObjectsAndKeysInDictionary:kv completionBlock:inCompletionBlock failureBlock:inFailureBlock];
}

#pragma mark -
#pragma mark Following

- (void)requestFollow:(BOOL)inFollow forUserWithName:(NSString *)inUserName completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    NSString *methodName = inFollow ? DQAPIMethodFollowUser : DQAPIMethodUnfollowUser;

    __weak typeof(self) weakSelf = self;
    [self.serviceQueue hasRequestsForCommand:methodName tag:inUserName resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            DQHTTPRequest *followUnfollowRequest = [weakSelf.serviceQueue requestWithCommand:methodName];
            followUnfollowRequest.requestMethod = DQHTTPRequestMethodPOST;
            followUnfollowRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            followUnfollowRequest.tag = inUserName;

            [followUnfollowRequest setPostBodyParameterValue:inUserName forKey:DQAPIKeyStringUsername];

            followUnfollowRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, responseDictionary);
                }
            };

            if (inCompletionBlock) {
                followUnfollowRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                    inCompletionBlock(inRequest, nil);
                };
            }

            [weakSelf startHTTPRequest:followUnfollowRequest];
        }
    }];
}

- (DQHTTPRequest *)requestFollowForUsersWithNames:(NSArray *)inUserNameArray completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *followRequest = [self.serviceQueue requestWithCommand:DQAPIMethodFollowUser];
    __weak typeof(self) weakSelf = self;
    NSString *tag = [inUserNameArray componentsJoinedByString:@""];
    [self.serviceQueue hasRequestsForCommand:DQAPIMethodFollowUser tag:tag resultBlock:^(BOOL found) {
        if (found)
        {
            if (inCompletionBlock)
            {
                inCompletionBlock(nil, nil);
            }
        }
        else
        {
            followRequest.requestMethod = DQHTTPRequestMethodPOST;
            followRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
            followRequest.tag = tag;

            [followRequest setPostBodyParameterValue:inUserNameArray forKey:DQAPIKeyStringUsername];
            followRequest.papertrailLoggerDataBlock = ^{
                return @{DQAPIKeyStringUsername: inUserNameArray ?: [NSNull null]};
            };
            followRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
                NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

                if (inCompletionBlock) {
                    inCompletionBlock(inRequest, responseDictionary);
                }
            };

            if (inCompletionBlock) {
                followRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
                    inCompletionBlock(inRequest, nil);
                };
            }

            [weakSelf startHTTPRequest:followRequest];
        }
    }];
    return followRequest;
}

#pragma mark -
#pragma mark Invites

- (DQHTTPRequest *)requestFacebookFriendsOnDrawQuestWithFacebookToken:(NSString *)facebookToken completionBlock:(DQServiceCompletionBlockWithObjects)inCompletionBlock
{
    DQHTTPRequest *friendsRequest = [self.serviceQueue requestWithCommand:DQAPIMethodFacebookFriendsOnDrawQuest];
    friendsRequest.requestMethod = DQHTTPRequestMethodPOST;
    friendsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:facebookToken forKey:DQAPIKeyStringFacebookToken];
    [friendsRequest addPostBodyParametersFromDictionary:args];
    friendsRequest.papertrailLoggerDataBlock = ^{
        return args;
    };
    friendsRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        if (inCompletionBlock) {
            inCompletionBlock(inRequest, inRequest.dq_responseDictionary, inRequest.dq_responseDictionary.dq_users);
        }
    };

    if (inCompletionBlock)
    {
        friendsRequest.requestDidFailBlock = ^(DQHTTPRequest *request) {
            inCompletionBlock(request, nil, nil);
        };
    }
    [self startHTTPRequest:friendsRequest];

    return friendsRequest;
}

- (DQHTTPRequest *)requestTwitterFollowersOnDrawQuestWithTwitterToken:(NSString *)twitterToken twitterSecret:(NSString *)twitterSecret completionBlock:(DQServiceCompletionBlockWithObjects)inCompletionBlock
{
    DQHTTPRequest *friendsRequest = [self.serviceQueue requestWithCommand:DQAPIMethodTwitterFollowersOnDrawQuest];
    friendsRequest.requestMethod = DQHTTPRequestMethodPOST;
    friendsRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:twitterToken forKey:DQAPIKeyStringTwitterToken];
    [args ifNotNilSetObject:twitterSecret forKey:DQAPIKeyStringTwitterSecret];
    [friendsRequest addPostBodyParametersFromDictionary:args];
    friendsRequest.papertrailLoggerDataBlock = ^{
        return args;
    };
    friendsRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        if (inCompletionBlock) {
            inCompletionBlock(inRequest, inRequest.dq_responseDictionary, inRequest.dq_responseDictionary.dq_users);
        }
    };

    if (inCompletionBlock)
    {
        friendsRequest.requestDidFailBlock = ^(DQHTTPRequest *request) {
            inCompletionBlock(request, nil, nil);
        };
    }

    [self startHTTPRequest:friendsRequest];
    
    return friendsRequest;
}

- (DQHTTPRequest *)requestAddInvitedTwitterFriends:(NSArray *)twitterIDList completionBlock:(DQServiceStatusBlock)inCompletionBlock
{
    DQHTTPRequest *request = [self.serviceQueue requestWithCommand:DQAPIMethodTwitterFriendsInvited];
    request.requestMethod = DQHTTPRequestMethodPOST;
    request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:twitterIDList forKey:DQAPIKeyStringTwitterIDs];
    [request addPostBodyParametersFromDictionary:args];
    request.papertrailLoggerDataBlock = ^{
        return args;
    };
    request.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        if (inCompletionBlock) {
            inCompletionBlock(inRequest);
        }
    };

    if (inCompletionBlock)
    {
        request.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest);
        };
    }

    [self startHTTPRequest:request];

    return request;
}

- (DQHTTPRequest *)requestInviteMessageForChannel:(NSString *)inChannel withQuestID:(NSString *)questID completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *inviteMessageRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetInviteMessage];
    inviteMessageRequest.requestMethod = DQHTTPRequestMethodPOST;
    inviteMessageRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    [inviteMessageRequest setPostBodyParameterValue:@(YES) forKey:@"is_invite"]; // We're just using the shareURL API to do per channel invites
    [inviteMessageRequest setPostBodyParameterValue:questID forKey:DQAPIKeyStringQuestID];
    [inviteMessageRequest setPostBodyParameterValue:inChannel forKey:DQAPIKeyStringShareChannel];

    inviteMessageRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock) {
            inCompletionBlock(inRequest, responseDictionary);
        }
    };

    if (inCompletionBlock) {
        inviteMessageRequest.requestDidFailBlock =  ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest, nil);
        };
    }

    [self startHTTPRequest:inviteMessageRequest];
    return inviteMessageRequest;
}

#pragma mark -
#pragma mark Shop

- (DQHTTPRequest *)requestShopItemsWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *shopRequest = [self.serviceQueue requestWithCommand:DQAPIMethodShopGetItems];
    shopRequest.requestMethod = DQHTTPRequestMethodPOST;

    shopRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock)
        {
            inCompletionBlock(inRequest, responseDictionary.dq_shopColors);
        }
    };

    if (inFailureBlock)
    {
        shopRequest.requestDidFailBlock = inFailureBlock;
    }

    [self startHTTPRequest:shopRequest];
    return shopRequest;
}

- (DQHTTPRequest *)requestPurchaseColorID:(NSString *)inColorID completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *purchaseRequest = [self.serviceQueue requestWithCommand:DQAPIMethodShopPurchaseColor];
    purchaseRequest.requestMethod = DQHTTPRequestMethodPOST;
    purchaseRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:inColorID forKey:DQAPIKeyStringShopColorID];
    [purchaseRequest addPostBodyParametersFromDictionary:args];
    purchaseRequest.papertrailLoggerDataBlock = ^{
        return args;
    };

    purchaseRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
        if (inCompletionBlock)
        {
            inCompletionBlock(inRequest, responseDictionary.dq_shopColors);
        }
    };

    if (inFailureBlock)
    {
        purchaseRequest.requestDidFailBlock = inFailureBlock;
    }

    [self startHTTPRequest:purchaseRequest];
    return purchaseRequest;
}

- (DQHTTPRequest *)requestPurchaseColorPackID:(NSString *)inColorPackID completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *purchaseRequest = [self.serviceQueue requestWithCommand:DQAPIMethodShopPurchaseColorPack];
    purchaseRequest.requestMethod = DQHTTPRequestMethodPOST;
    purchaseRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:inColorPackID forKey:DQAPIKeyStringShopColorPackID];
    [purchaseRequest addPostBodyParametersFromDictionary:args];
    purchaseRequest.papertrailLoggerDataBlock = ^{
        return args;
    };

    purchaseRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
        if (inCompletionBlock)
        {
            inCompletionBlock(inRequest, responseDictionary.dq_shopColorPacks);
        }
    };

    if (inFailureBlock)
    {
        purchaseRequest.requestDidFailBlock = inFailureBlock;
    }

    [self startHTTPRequest:purchaseRequest];
    return purchaseRequest;
}

- (DQHTTPRequest *)requestPurchaseBrushID:(NSString *)inBrushCanonicalName completionBlock:(DQServiceCompletionBlock)inCompletionBlock failureBlock:(DQServiceStatusBlock)inFailureBlock
{
    DQHTTPRequest *purchaseRequest = [self.serviceQueue requestWithCommand:DQAPIMethodShopPurchaseBrush];
    purchaseRequest.requestMethod = DQHTTPRequestMethodPOST;
    purchaseRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    
    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:inBrushCanonicalName forKey:DQAPIKeyStringShopBrushCanonicalName];
    [purchaseRequest addPostBodyParametersFromDictionary:args];
    purchaseRequest.papertrailLoggerDataBlock = ^{
        return args;
    };

    purchaseRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;
        if (inCompletionBlock)
        {
            inCompletionBlock(inRequest, responseDictionary.dq_shopBrushes);
        }
    };
    
    if (inFailureBlock)
    {
        purchaseRequest.requestDidFailBlock = inFailureBlock;
    }
    
    [self startHTTPRequest:purchaseRequest];
    return purchaseRequest;
}

#pragma mark -
#pragma mark Economy

- (void)requestCoinProductsWithCompletionBlock:(DQServiceCompletionBlock)inCompletionBlock;
{
    DQHTTPRequest *coinProductsRequest = [self.serviceQueue requestWithCommand:DQAPIMethodGetCoinProducts];
    coinProductsRequest.requestMethod = DQHTTPRequestMethodPOST;

    coinProductsRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock) {
            inCompletionBlock(inRequest, responseDictionary.dq_coinProductsInfo);
        }
    };

    // FIXME: Needs a fail block

    [self startHTTPRequest:coinProductsRequest];
}

- (void)requestProcessPurchaseReceiptWithData:(NSData *)inData completionBlock:(DQServiceCompletionBlock)inCompletionBlock
{
    DQHTTPRequest *purchaseRequest = [self.serviceQueue requestWithCommand:DQAPIMethodProcessPurchaseReceipt];
    purchaseRequest.requestMethod = DQHTTPRequestMethodPOST;
    purchaseRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    purchaseRequest.timeoutInterval = 60.0; // give our server more time to get a response from Apple

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:[inData st_base64EncodedString] forKey:DQAPIKeyStringReceiptData];
    [purchaseRequest addPostBodyParametersFromDictionary:args];
    purchaseRequest.papertrailLoggerDataBlock = ^{
        return args;
    };

    purchaseRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSDictionary *responseDictionary = inRequest.dq_responseDictionary;

        if (inCompletionBlock) {
            inCompletionBlock(inRequest, responseDictionary);
        }
    };

    if (inCompletionBlock) {
        purchaseRequest.requestDidFailBlock =  ^(DQHTTPRequest *inRequest) {
            inCompletionBlock(inRequest, nil);
        };
    }
    
    [self startHTTPRequest:purchaseRequest];
}

#pragma mark -
#pragma mark Sharing

// TODO: add a completionBlock and failureBlock
// This method may send to only one or the other or both.
- (void)requestSendMessage:(NSString *)message facebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterSecret:(NSString *)twitterSecret
{
    if (facebookToken || (twitterToken && twitterSecret))
    {
        DQHTTPRequest *sendMessageRequest = [self.serviceQueue requestWithCommand:DQAPIMethodPostSocialNetworkMessage];
        sendMessageRequest.requestMethod = DQHTTPRequestMethodPOST;
        sendMessageRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
        sendMessageRequest.timeoutInterval = 60.0;  // DQ-374

        NSMutableDictionary *args = [NSMutableDictionary new];
        [args ifNotNilSetObject:message forKey:DQAPIKeyStringSocialMessage];

        if (facebookToken)
        {
            [args ifNotNilSetObject:facebookToken forKey:DQAPIKeyStringFacebookToken];
        }

        if (twitterToken && twitterSecret)
        {
            [args ifNotNilSetObject:twitterToken forKey:DQAPIKeyStringTwitterToken];
            [args ifNotNilSetObject:twitterSecret forKey:DQAPIKeyStringTwitterSecret];
        }
        [sendMessageRequest addPostBodyParametersFromDictionary:args];
        sendMessageRequest.papertrailLoggerDataBlock = ^{
            return args;
        };

        [self startHTTPRequest:sendMessageRequest];
    }
}

#pragma mark -
#pragma mark - Quests

- (DQHTTPRequest *)requestQuestInboxWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock
{
    DQHTTPRequest *questInboxRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetQuestInbox completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    [self startHTTPRequest:questInboxRequest];
    return questInboxRequest;
}

- (DQHTTPRequest *)requestQuestHistoryWithCompletionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock
{
    DQHTTPRequest *questHistoryRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodGetQuestHistory completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    [self startHTTPRequest:questHistoryRequest];
    return questHistoryRequest;
}

- (DQHTTPRequest *)requestDismissQuestWithID:(NSString *)questID completionBlock:(DQHTTPRequestStatusBlock)inCompletionBlock failureBlock:(DQHTTPRequestStatusBlock)inFailureBlock
{
    DQHTTPRequest *questDismissRequest = [self requestWithMethod:DQHTTPRequestMethodPOST forCommand:DQAPIMethodDismissQuest completionBlock:inCompletionBlock failureBlock:inFailureBlock];
    questDismissRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;
    [questDismissRequest setPostBodyParameterValue:questID forKey:DQAPIKeyStringQuestID];
    [self startHTTPRequest:questDismissRequest];
    return questDismissRequest;
}

#pragma mark -
#pragma mark Key-Value Store

- (void)saveObjectsAndKeysInDictionary:(NSDictionary *)dict completionBlock:(DQServiceCompletionBlock)completionBlock failureBlock:(DQServiceStatusBlock)failureBlock
{
    if (dict == nil)
    {
        if (failureBlock)
        {
            failureBlock(nil);
        }
    }
    else
    {
        DQHTTPRequest *request = [self.serviceQueue requestWithCommand:DQAPIMethodKeyValueSet];
        request.requestMethod = DQHTTPRequestMethodPOST;
        request.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

        [request setPostBodyParameterValue:dict forKey:@"items"];

        request.requestDidFinishBlock = ^(DQHTTPRequest *req) {
            NSDictionary *responseDictionary = req.dq_responseDictionary;

            if (completionBlock) {
                completionBlock(req, responseDictionary);
            }
        };

        request.requestDidFailBlock = ^(DQHTTPRequest *req) {
            if (failureBlock) {
                failureBlock(req);
            }
        };
        [self startHTTPRequest:request];
    }
}

@end

@implementation DQCommentUpload (DQAPIConveniences)

- (DQHTTPRequest *)configuredCommentPostRequestForServiceQueue:(DQHTTPRequestQueue *)inQueue
{
    if (!inQueue || !self.contentID || !self.questID) {
        return nil;
    }

    DQHTTPRequest *postCommentRequest = [inQueue requestWithCommand:DQAPIMethodPostComment];
    postCommentRequest.requestMethod = DQHTTPRequestMethodPOST;
    postCommentRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    postCommentRequest.tag = self.identifier;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:self.questID forKey:DQAPIKeyStringQuestID];
    [args ifNotNilSetObject:self.contentID forKey:DQAPIKeyStringContentID];

    if ([self.shareFlags containsObject:DQAPIValueShareChannelTypeFacebook] && [self.facebookToken length])
    {
        [args ifNotNilSetObject:@YES forKey:DQAPIKeyStringFacebookShare];
        [args ifNotNilSetObject:self.facebookToken forKey:DQAPIKeyStringFacebookToken];
    }

    if ([self.shareFlags containsObject:DQAPIValueShareChannelTypeTwitter] && [self.twitterToken length] && [self.twitterTokenSecret length])
    {
        [args ifNotNilSetObject:@YES forKey:DQAPIKeyStringTwitterShare];
        [args ifNotNilSetObject:self.twitterToken forKey:DQAPIKeyStringTwitterToken];
        [args ifNotNilSetObject:self.twitterTokenSecret forKey:DQAPIKeyStringTwitterSecret];
    }

    if ([self.emailList count])
    {
        [args ifNotNilSetObject:@YES forKey:DQAPIKeyStringEmailShare];
        [args ifNotNilSetObject:self.emailList forKey:DQAPIKeyStringEmailShareList];
    }

    [postCommentRequest addPostBodyParametersFromDictionary:args];
    postCommentRequest.papertrailLoggerDataBlock = ^{
        return args;
    };
    return postCommentRequest;
}

@end

@implementation DQQuestUpload (DQAPIConveniences)

- (DQHTTPRequest *)configuredQuestPostRequestForServiceQueue:(DQHTTPRequestQueue *)inQueue
{
    if (!inQueue || !self.title) {
        return nil;
    }

    DQHTTPRequest *postQuestRequest = [inQueue requestWithCommand:DQAPIMethodPostQuest];
    postQuestRequest.requestMethod = DQHTTPRequestMethodPOST;
    postQuestRequest.postBodyFormat = DQHTTPRequestPOSTBodyFormatJSON;

    postQuestRequest.tag = self.identifier;

    NSMutableDictionary *args = [NSMutableDictionary new];
    [args ifNotNilSetObject:@YES forKey:@"invite_followees"];
    [args ifNotNilSetObject:self.title forKey:DQAPIKeyStringTitle];

    if (self.contentID)
    {
        [args ifNotNilSetObject:self.contentID forKey:DQAPIKeyStringContentID];
    }

    if (self.shareToFacebook && [self.facebookToken length])
    {
        [args ifNotNilSetObject:@YES forKey:DQAPIKeyStringFacebookShare];
        [args ifNotNilSetObject:self.facebookToken forKey:DQAPIKeyStringFacebookToken];
    }

    if (self.shareToTwitter && [self.twitterToken length] && [self.twitterTokenSecret length])
    {
        [args ifNotNilSetObject:@YES forKey:DQAPIKeyStringTwitterShare];
        [args ifNotNilSetObject:self.twitterToken forKey:DQAPIKeyStringTwitterToken];
        [args ifNotNilSetObject:self.twitterTokenSecret forKey:DQAPIKeyStringTwitterSecret];
    }

    if ([self.emailList count])
    {
        [args ifNotNilSetObject:@YES forKey:DQAPIKeyStringEmailShare];
        [args ifNotNilSetObject:self.emailList forKey:DQAPIKeyStringEmailShareList];
    }

    [postQuestRequest addPostBodyParametersFromDictionary:args];
    postQuestRequest.papertrailLoggerDataBlock = ^{
        return args;
    };
    return postQuestRequest;
}

@end
