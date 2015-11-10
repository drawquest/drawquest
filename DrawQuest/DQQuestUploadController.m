//
//  DQQuestUploadController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestUploadController.h"
#import "DQAnalyticsConstants.h"
#import "DQDataStoreController.h"
#import "DQQuestUpload.h"
#import "DQQuest.h"
#import "CVSDrawing.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQPrivateServiceController.h"

@interface DQQuestUploadController ()

@property (nonatomic, weak) DQAccountController *accountController;

@end

@implementation DQQuestUploadController
{
    NSString *_draftsPath;
}

- (id)initWithDraftsPath:(NSString *)draftsPath accountController:(DQAccountController *)accountController delegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _draftsPath = [draftsPath copy];
        _accountController = accountController;
        // taking this out of the background, I'd rather have this done synchronously and not worry about race conditions
        [self.dataStoreController markAllUploadingQuestUploadsFailed];
    }
    return self;
}

#pragma mark -
#pragma mark Public API

- (void)retryQuestUpload:(DQQuestUpload *)questUpload
{
    [self _processQuestUpload:questUpload];
}

- (BOOL)uploadQuestUpload:(DQQuestUpload *)questUpload
{
    if (questUpload)
    {
        NSError *error = nil;
        NSFileManager *fm = [NSFileManager new];
        NSString *draftPath = [questUpload pathToDraftFiles];
        BOOL hasDraft = [fm fileExistsAtPath:draftPath];
        if (!hasDraft)
        {
            hasDraft = [fm createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (hasDraft)
        {
            // Analytics
            NSString *publishEvent = self.loggedInAccount.hasPublishedAQuest ? DQAnalyticsEventPublishQuest : DQAnalyticsEventViewFTEPublishQuest;
            [self logEvent:publishEvent withParameters:nil];

            if (questUpload.shareToFacebook)
            {
                [self logEvent:DQAnalyticsEventShareQuestToFacebook withParameters:nil];
            }
            if (questUpload.shareToTwitter)
            {
                [self logEvent:DQAnalyticsEventShareQuestToTwitter withParameters:nil];
            }
            [self _processQuestUpload:questUpload];
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

- (NSNumber *)_percentCompleteForQuestUpload:(DQQuestUpload *)cu requestPercentComplete:(CGFloat)requestPercentComplete
{
    CGFloat imageSize = [cu.imageSize floatValue];
    // not supporting quest playback for now :(
    // CGFloat playbackDataSize = [cu.playbackDataSize floatValue];
    // not supporting quest playback for now :(
    CGFloat totalSize = imageSize; // + playbackDataSize;
    if (totalSize == 0.0) // shouldn't happen but hey
    {
        return @(0.0); // avoid divide by zero
    }
    else
    {
        if (cu.status == DQQuestUploadStatusUploadingImage)
        {
            CGFloat result = (imageSize * requestPercentComplete) / totalSize;
            return @(result * 100);
        }
        // not supporting quest playback for now :(
        /* else if (cu.status == DQQuestUploadStatusUploadingPlaybackData)
        {
            CGFloat result = (imageSize + (playbackDataSize * requestPercentComplete)) / totalSize;
            return @(result * 100);
        }*/
        return cu.uploadProgress;
    }
}

- (void)_processQuestUpload:(DQQuestUpload *)inQuestUpload
{
    DQPrivateServiceController *privateServiceController = self.privateServiceController;

    if (inQuestUpload.status == DQQuestUploadStatusNew)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusUploadingImage forQuestUpload:inQuestUpload];
    } // purposely not using else if here so New (which is processed synchronously) can cascade into UploadingImage without recursing

    NSData *imageData = inQuestUpload.imageData;
    if (inQuestUpload.status == DQQuestUploadStatusUploadingImage)
    {
        if (!imageData)
        {
            [self.dataStoreController saveStatus:DQQuestUploadStatusPostingQuest forQuestUpload:inQuestUpload];
        }
    } // purposely not using else if here so it can cascade into PostingQuest without recursing

    if (inQuestUpload.status == DQQuestUploadStatusUploadingImage)
    {
        if (imageData)
        {
            __weak typeof(self) weakSelf = self;
            [privateServiceController requestUploadOfImageData:imageData withTag:inQuestUpload.identifier progressBlock:^(DQHTTPRequest *request) {
                // Update the progress as the upload continues
                // Send progress changed notification
                NSNumber *percentComplete = [weakSelf _percentCompleteForQuestUpload:inQuestUpload requestPercentComplete:request.uploadPercentComplete];
                [weakSelf.dataStoreController takeProgress:percentComplete forQuestUpload:inQuestUpload];
                [weakSelf _handleProgressChangeForQuestUpload:inQuestUpload];
            } completionBlock:^(DQHTTPRequest *imageRequest, NSDictionary *contentDictionary, NSString *contentID) {
                if (imageRequest)
                {
                    if (imageRequest.error)
                    {
                        [weakSelf _handleFailureForQuestUpload:inQuestUpload
                                                    withStatus:DQQuestUploadStatusFailedUploadingImage
                                                         error:imageRequest.error];
                    }
                    else
                    {
                        [weakSelf.dataStoreController saveContentID:contentID forQuestUpload:inQuestUpload];
                        [weakSelf _processQuestUpload:inQuestUpload];
                    }
                }
                else
                {
                    [weakSelf _handleFailureForQuestUpload:inQuestUpload
                                                withStatus:DQQuestUploadStatusFailedUploadingImage
                                                     error:nil];
                }
            }];
        }
        else
        {
            [self _handleFailureForQuestUpload:inQuestUpload
                                    withStatus:DQQuestUploadStatusFailedUploadingImage
                                         error:nil];
        }
    }
    else if (inQuestUpload.status == DQQuestUploadStatusPostingQuest)
    {
        __weak typeof(self) weakSelf = self;
        [privateServiceController requestPostQuestUpload:inQuestUpload completionBlock:^(NSDictionary *questInfo) {
            // there's nowhere to save the questInfo in the DQQuestUpload so save it to disk
            NSData *questInfoJSONData = [NSJSONSerialization dataWithJSONObject:questInfo options:0 error:nil];
            NSError *error = nil;
            NSString *questInfoPath = [[inQuestUpload pathToDraftFiles] stringByAppendingPathComponent:@"quest.json"];
            if ([questInfoJSONData writeToFile:questInfoPath options:NSDataWritingAtomic error:&error])
            {
                NSURL *url = [NSURL fileURLWithPath:questInfoPath];
                [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
                // not supporting quest playback for now :(
                /* [weakSelf.dataStoreController saveStatus:DQQuestUploadStatusUploadingPlaybackData forCommentUpload:inQuestUpload];
                [self _processQuestUpload:inQuestUpload];*/
                [weakSelf _handleQuestUploadSucceeded:inQuestUpload questInfo:questInfo];
            }
            else
            {
                [weakSelf _handleFailureForQuestUpload:inQuestUpload
                                            withStatus:DQQuestUploadStatusFailedPostingQuest
                                                 error:error];
            }
        } failureBlock:^(NSString *errorType) {
            if ([errorType isEqualToString:DQAPIErrorTypeInvalidFacebookToken])
            {
                [weakSelf _handleInvalidFacebookToken:inQuestUpload];
            }
            else if ([errorType isEqualToString:DQAPIErrorTypeInvalidTwitterToken])
            {
                [weakSelf _handleInvalidTwitterToken:inQuestUpload];
            }
            else
            {
                [weakSelf _handleFailureForQuestUpload:inQuestUpload
                                            withStatus:DQQuestUploadStatusFailedPostingQuest
                                                 error:nil];
            }
        }];
    }
    // not supporting quest playback for now :(
    /*else if (inQuestUpload.status == DQQuestUploadStatusUploadingPlaybackData)
    {
        NSString *questInfoPath = [[inQuestUpload pathToDraftFiles] stringByAppendingPathComponent:@"quest.json"];
        NSData *questInfoJSONData = [NSData dataWithContentsOfFile:questInfoPath];
        NSDictionary *questInfo = [questInfoJSONData objectFromJSONData];

        // Send the playback data
        NSString *playbackDataPath = [inQuestUpload playbackDataPath];

        __weak typeof(self) weakSelf = self;
        [privateServiceController requestSetPlaybackDataFromFileAtPath:playbackDataPath forQuestWithServerID:questInfo.dq_serverID progressBlock:^(DQHTTPRequest *request) {
            NSNumber *percentComplete = [self _percentCompleteForQuestUpload:inQuestUpload requestPercentComplete:request.uploadPercentComplete];
            [weakSelf.dataStoreController takeProgress:percentComplete forQuestUpload:inQuestUpload];
            [self _handleProgressChangeForQuestUpload:inQuestUpload];
        } completionBlock:^(DQHTTPRequest *request) {
            [self _handleQuestUploadSucceeded:inQuestUpload questInfo:questInfo];
        } failureBlock:^(DQHTTPRequest *request) {
            [self _handleFailureForQuestUpload:inQuestUpload
                                      withStatus:DQQuestUploadStatusFailedUploadingPlaybackData];
        }];
    }*/
    else if (inQuestUpload.status == DQQuestUploadStatusFailedNew)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusNew forQuestUpload:inQuestUpload];
        [self _processQuestUpload:inQuestUpload];
    }
    else if (inQuestUpload.status == DQQuestUploadStatusFailedWithInvalidFacebookToken)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusPostingQuest forQuestUpload:inQuestUpload];
        [self _processQuestUpload:inQuestUpload];
    }
    else if (inQuestUpload.status == DQQuestUploadStatusFailedWithInvalidTwitterToken)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusPostingQuest forQuestUpload:inQuestUpload];
        [self _processQuestUpload:inQuestUpload];
    }
    else if (inQuestUpload.status == DQQuestUploadStatusFailedUploadingImage)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusUploadingImage forQuestUpload:inQuestUpload];
        [self _processQuestUpload:inQuestUpload];
    }
    else if (inQuestUpload.status == DQQuestUploadStatusFailedPostingQuest)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusPostingQuest forQuestUpload:inQuestUpload];
        [self _processQuestUpload:inQuestUpload];
    }
    // not supporting quest playback for now :(
    /*else if (inQuestUpload.status == DQQuestUploadStatusFailedUploadingPlaybackData)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusUploadingPlaybackData forQuestUpload:inQuestUpload];
        [self _processQuestUpload:inQuestUpload];
    }*/
}

- (void)_handleProgressChangeForQuestUpload:(DQQuestUpload *)inQuestUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{DQQuestUploadObjectNotificationKey : inQuestUpload};
        NSNotification *progressChangedNotification = [NSNotification notificationWithName:DQQuestUploadProgressChangedNotification object:nil userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:progressChangedNotification];
    });
}

- (void)_handleInvalidFacebookToken:(DQQuestUpload *)inQuestUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStoreController saveStatus:DQQuestUploadStatusFailedWithInvalidFacebookToken forQuestUpload:inQuestUpload];
    });
}

- (void)_handleInvalidTwitterToken:(DQQuestUpload *)inQuestUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStoreController saveStatus:DQQuestUploadStatusFailedWithInvalidTwitterToken forQuestUpload:inQuestUpload];
    });
}

- (void)_handleFailureForQuestUpload:(DQQuestUpload *)inQuestUpload withStatus:(DQQuestUploadStatus)status error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStoreController saveStatus:status withError:error forQuestUpload:inQuestUpload];
    });
}

- (void)_handleQuestUploadSucceeded:(DQQuestUpload *)inQuestUpload questInfo:(NSDictionary *)questInfo
{
    NSLog(@"Quest upload succeeded");
    dispatch_async(dispatch_get_main_queue(), ^{
        DQQuest *quest = [self.dataStoreController createOrUpdateQuestWithJSONInfo:questInfo];

        NSDictionary *userInfo = @{DQQuestUploadObjectNotificationKey : inQuestUpload,
                                   DQQuestObjectNotificationKey : quest };
        NSNotification *completeNotification = [NSNotification notificationWithName:DQQuestUploadCompletedNotification object:nil userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:completeNotification];

        NSFileManager *fm = [[NSFileManager alloc] init];
        NSError *error = nil;
        if (![fm removeItemAtPath:[inQuestUpload pathToDraftFiles] error:&error])
        {
            NSLog(@"Failed to remove the upload directory for %@", inQuestUpload.identifier);
        }
        [self.dataStoreController deleteQuestUpload:inQuestUpload];
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
