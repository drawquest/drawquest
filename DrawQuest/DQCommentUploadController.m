//
//  DQCommentUploadController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentUploadController.h"
#import "DQAnalyticsConstants.h"
#import "DQDataStoreController.h"
#import "DQCommentUpload.h"
#import "DQComment.h"
#import "DQQuest.h"
#import "CVSDrawing.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQPrivateServiceController.h"

@interface DQCommentUploadController ()

@property (nonatomic, weak) DQAccountController *accountController;

@end

@implementation DQCommentUploadController
{
    NSString *_uploadsPath;
}

- (id)initWithUploadsPath:(NSString *)uploadsPath accountController:(DQAccountController *)accountController delegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _uploadsPath = [uploadsPath copy];
        _accountController = accountController;
        // taking this out of the background, I'd rather have this done synchronously and not worry about race conditions
        [self.dataStoreController markAllUploadingCommentUploadsFailed];
    }
    return self;
}

#pragma mark -
#pragma mark Public API

- (void)retryCommentUpload:(DQCommentUpload *)commentUpload
{
    [self _processCommentUpload:commentUpload];
}

- (BOOL)uploadDraftAtPath:(NSString *)draftPath forQuestWithServerID:(NSString *)questID title:(NSString *)questTitle shareFlags:(NSArray *)shareFlags facebookAccessToken:(NSString *)facebookAccessToken twitterAccessToken:(NSString *)twitterAccessToken twitterAccessTokenSecret:(NSString *)twitterAccessTokenSecret emailList:(NSArray *)emailList
{
    // Create a comment upload object in the data store
    DQDataStoreController *dataStoreController = self.dataStoreController;
    DQCommentUpload *commentUpload = [dataStoreController createCommentUploadForQuestWithServerID:questID shareFlags:shareFlags facebookToken:facebookAccessToken twitterToken:twitterAccessToken twitterTokenSecret:twitterAccessTokenSecret emailList:emailList];
    if (commentUpload)
    {
        // Move the draft into the uploading area
        NSString *uploadPath = [self _pathForCommentUpload:commentUpload];
        NSError *error = nil;
        NSFileManager *fm = [[NSFileManager alloc] init];
        if ([fm moveItemAtPath:draftPath toPath:uploadPath error:&error])
        {
            // Analytics
            NSString *publishEvent = self.loggedInAccount.hasPublishedAComment ? DQAnalyticsEventPublishComment : DQAnalyticsEventViewFTEPublish;
            [self logEvent:publishEvent withParameters:nil];

            if ([shareFlags containsObject:DQAPIValueShareChannelTypeFacebook])
            {
                [self logEvent:DQAnalyticsEventShareCommentToFacebook withParameters:nil];
            }
            if ([shareFlags containsObject:DQAPIValueShareChannelTypeTwitter])
            {
                [self logEvent:DQAnalyticsEventShareCommentToTwitter withParameters:nil];
            }
            [self _processCommentUpload:commentUpload];
            return YES;
        }
        else
        {
            [self _showPostingErrorWithText:nil error:error];
            return NO;
        }
    }
    else
    {
        [self _showPostingErrorWithText:nil error:nil];
        return NO;
    }
}

#pragma mark -
#pragma mark Private API

- (NSNumber *)_percentCompleteForCommentUpload:(DQCommentUpload *)cu requestPercentComplete:(CGFloat)requestPercentComplete
{
    CGFloat imageSize = [cu.imageSize floatValue];
    CGFloat playbackDataSize = [cu.playbackDataSize floatValue];
    CGFloat totalSize = imageSize + playbackDataSize;
    if (totalSize == 0.0) // shouldn't happen but hey
    {
        return @(0.0); // avoid divide by zero
    }
    else
    {
        if (cu.status == DQCommentUploadStatusUploadingImage)
        {
            CGFloat result = (imageSize * requestPercentComplete) / totalSize;
            return @(result * 100);
        }
        else if (cu.status == DQCommentUploadStatusUploadingPlaybackData)
        {
            CGFloat result = (imageSize + (playbackDataSize * requestPercentComplete)) / totalSize;
            return @(result * 100);
        }
        return cu.uploadProgress;
    }
}

- (NSString *)_pathForCommentUpload:(DQCommentUpload *)cu
{
    return [_uploadsPath stringByAppendingPathComponent:cu.identifier];
}

- (void)_processCommentUpload:(DQCommentUpload *)inCommentUpload
{
    DQPrivateServiceController *privateServiceController = self.privateServiceController;

    if (inCommentUpload.status == DQCommentUploadStatusNew)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusUploadingImage forCommentUpload:inCommentUpload];
    } // purposely not using else if here so New (which is processed synchronously) can cascade into UploadingImage without recursing

    if (inCommentUpload.status == DQCommentUploadStatusUploadingImage)
    {
        NSData *imageData = inCommentUpload.imageData;
        if (imageData)
        {
            __weak typeof(self) weakSelf = self;
            [privateServiceController requestUploadOfImageData:imageData withTag:inCommentUpload.identifier progressBlock:^(DQHTTPRequest *request) {
                // Update the progress as the upload continues
                // Send progress changed notification
                NSNumber *percentComplete = [weakSelf _percentCompleteForCommentUpload:inCommentUpload requestPercentComplete:request.uploadPercentComplete];
                [weakSelf.dataStoreController takeProgress:percentComplete forCommentUpload:inCommentUpload];
                [weakSelf _handleProgressChangeForCommentUpload:inCommentUpload];
            } completionBlock:^(DQHTTPRequest *imageRequest, NSDictionary *contentDictionary, NSString *contentID) {
                if (imageRequest)
                {
                    if (imageRequest.error)
                    {
                        [self _handleFailureForCommentUpload:inCommentUpload
                                                  withStatus:DQCommentUploadStatusFailedUploadingImage];
                    }
                    else
                    {
                        [weakSelf.dataStoreController saveContentID:contentID forCommentUpload:inCommentUpload];
                        [self _processCommentUpload:inCommentUpload];
                    }
                }
                else
                {
                    [self _handleFailureForCommentUpload:inCommentUpload
                                              withStatus:DQCommentUploadStatusFailedUploadingImage];
                }
            }];
        }
        else
        {
            [self _handleFailureForCommentUpload:inCommentUpload
                                     withStatus:DQCommentUploadStatusFailedUploadingImage];
        }
    }
    else if (inCommentUpload.status == DQCommentUploadStatusPostingComment)
    {
        __weak typeof(self) weakSelf = self;
        [privateServiceController requestPostCommentUpload:inCommentUpload completionBlock:^(NSDictionary *commentInfo) {
            // there's nowhere to save the commentInfo in the DQCommentUpload so save it to disk
            NSData *commentInfoJSONData = [NSJSONSerialization dataWithJSONObject:commentInfo options:0 error:nil];
            NSError *error = nil;
            NSString *commentInfoPath = [[weakSelf _pathForCommentUpload:inCommentUpload] stringByAppendingPathComponent:@"comment.json"];
            if ([commentInfoJSONData writeToFile:commentInfoPath options:NSDataWritingAtomic error:&error])
            {
                NSURL *url = [NSURL fileURLWithPath:commentInfoPath];
                [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
                [weakSelf.dataStoreController saveStatus:DQCommentUploadStatusUploadingPlaybackData forCommentUpload:inCommentUpload];
                [self _processCommentUpload:inCommentUpload];
            }
            else
            {
                [self _handleFailureForCommentUpload:inCommentUpload
                                         withStatus:DQCommentUploadStatusFailedPostingComment];
            }
        } failureBlock:^(NSString *errorType) {
            if ([errorType isEqualToString:DQAPIErrorTypeInvalidFacebookToken])
            {
                [self _handleInvalidFacebookToken:inCommentUpload];
            }
            else if ([errorType isEqualToString:DQAPIErrorTypeInvalidTwitterToken])
            {
                [self _handleInvalidTwitterToken:inCommentUpload];
            }
            else
            {
                [self _handleFailureForCommentUpload:inCommentUpload
                                         withStatus:DQCommentUploadStatusFailedPostingComment];
            }
        }];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusUploadingPlaybackData)
    {
        NSString *commentInfoPath = [[self _pathForCommentUpload:inCommentUpload] stringByAppendingPathComponent:@"comment.json"];
        NSData *commentInfoJSONData = [NSData dataWithContentsOfFile:commentInfoPath];
        NSDictionary *commentInfo = [NSJSONSerialization JSONObjectWithData:commentInfoJSONData options:0 error:nil];

        // Send the playback data
        NSString *playbackDataPath = [inCommentUpload playbackDataPath];

        __weak typeof(self) weakSelf = self;
        [privateServiceController requestSetPlaybackDataFromFileAtPath:playbackDataPath forCommentWithServerID:commentInfo.dq_serverID progressBlock:^(DQHTTPRequest *request) {
            NSNumber *percentComplete = [self _percentCompleteForCommentUpload:inCommentUpload requestPercentComplete:request.uploadPercentComplete];
            [weakSelf.dataStoreController takeProgress:percentComplete forCommentUpload:inCommentUpload];
            [self _handleProgressChangeForCommentUpload:inCommentUpload];
        } completionBlock:^(DQHTTPRequest *request) {
            [self _handleCommentUploadSucceeded:inCommentUpload commentInfo:commentInfo];
        } failureBlock:^(DQHTTPRequest *request) {
            [self _handleFailureForCommentUpload:inCommentUpload
                                     withStatus:DQCommentUploadStatusFailedUploadingPlaybackData];
        }];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusFailedNew)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusNew forCommentUpload:inCommentUpload];
        [self _processCommentUpload:inCommentUpload];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusFailedWithInvalidFacebookToken)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusPostingComment forCommentUpload:inCommentUpload];
        [self _processCommentUpload:inCommentUpload];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusFailedWithInvalidTwitterToken)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusPostingComment forCommentUpload:inCommentUpload];
        [self _processCommentUpload:inCommentUpload];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusFailedUploadingImage)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusUploadingImage forCommentUpload:inCommentUpload];
        [self _processCommentUpload:inCommentUpload];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusFailedPostingComment)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusPostingComment forCommentUpload:inCommentUpload];
        [self _processCommentUpload:inCommentUpload];
    }
    else if (inCommentUpload.status == DQCommentUploadStatusFailedUploadingPlaybackData)
    {
        [self.dataStoreController saveStatus:DQCommentUploadStatusUploadingPlaybackData forCommentUpload:inCommentUpload];
        [self _processCommentUpload:inCommentUpload];
    }
}

- (void)_handleProgressChangeForCommentUpload:(DQCommentUpload *)inCommentUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{DQCommentUploadObjectNotificationKey : inCommentUpload};
        NSNotification *progressChangedNotification = [NSNotification notificationWithName:DQCommentUploadProgressChangedNotification object:nil userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:progressChangedNotification];
    });
}

- (void)_handleInvalidFacebookToken:(DQCommentUpload *)inCommentUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStoreController saveStatus:DQCommentUploadStatusFailedWithInvalidFacebookToken forCommentUpload:inCommentUpload];
    });
}

- (void)_handleInvalidTwitterToken:(DQCommentUpload *)inCommentUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStoreController saveStatus:DQCommentUploadStatusFailedWithInvalidTwitterToken forCommentUpload:inCommentUpload];
    });
}

- (void)_handleFailureForCommentUpload:(DQCommentUpload *)inCommentUpload withStatus:(DQCommentUploadStatus)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStoreController saveStatus:status forCommentUpload:inCommentUpload];
    });
}

- (void)_handleCommentUploadSucceeded:(DQCommentUpload *)inCommentUpload commentInfo:(NSDictionary *)commentInfo
{
    NSLog(@"Comment upload succeeded");
    dispatch_async(dispatch_get_main_queue(), ^{
        DQComment *comment = [self.dataStoreController createOrUpdateCommentWithJSONInfo:commentInfo];
        // Save the quest ID so we have it after we delete the comment upload
        NSString *questID = [inCommentUpload.questID copy];
        DQRequestUpdateStarState(comment.serverID, DQStarStateNotStarred);

        NSDictionary *userInfo = @{DQCommentUploadObjectNotificationKey : inCommentUpload,
                                   DQCommentObjectNotificationKey : comment };
        NSNotification *completeNotification = [NSNotification notificationWithName:DQCommentUploadCompletedNotification object:nil userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:completeNotification];

        NSFileManager *fm = [[NSFileManager alloc] init];
        NSError *error = nil;
        if (![fm removeItemAtPath:[self _pathForCommentUpload:inCommentUpload] error:&error])
        {
            NSLog(@"Failed to remove the upload directory for %@", inCommentUpload.identifier);
        }
        [self.dataStoreController deleteCommentUpload:inCommentUpload];
        [self.dataStoreController markQuestIDCompleted:questID];
    });
}

- (void)_showPostingErrorWithText:(NSString *)inText error:(NSError *)error
{
    NSString *messageText = inText;
    if (!messageText) {
        messageText = DQLocalizedString(@"There was an unexpected problem and DrawQuest is unable to post.", @"Unknown DrawQuest upload error message");
    }

    if (error)
    {
        NSString *reason = [error localizedFailureReason] ?: [error localizedDescription];
        messageText = [messageText stringByAppendingFormat:@"\n\n%@", reason];
    }
    UIAlertView *noImageAlert = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Posting Error", @"Upload error alert title") message:messageText delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [noImageAlert show];
}

@end
