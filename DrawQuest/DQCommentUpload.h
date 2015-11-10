//
//  DQCommentUpload.h
//  DrawQuest
//
//  Created by Buzz Andersen on 11/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQModelObject.h"

extern void * const kDQCommentUploadUploadsPathKey;

typedef enum {
    DQCommentUploadStatusNew = 0,
    DQCommentUploadStatusDraft = 1, // this isn't even used
    DQCommentUploadStatusUploading_DEPRECATED = 2,
    DQCommentUploadStatusPublished = 3,
    DQCommentUploadStatusFailed_DEPRECATED = 4,
    DQCommentUploadStatusFailedWithInvalidFacebookToken = 5,
    DQCommentUploadStatusUploadingImage = DQCommentUploadStatusUploading_DEPRECATED,
    DQCommentUploadStatusPostingComment = 6,
    DQCommentUploadStatusUploadingPlaybackData = 7,
    DQCommentUploadStatusFailedNew = DQCommentUploadStatusFailed_DEPRECATED,
    DQCommentUploadStatusFailedUploadingImage = 8,
    DQCommentUploadStatusFailedPostingComment = 9,
    DQCommentUploadStatusFailedUploadingPlaybackData = 10,
    DQCommentUploadStatusFailedWithInvalidTwitterToken = 11
} DQCommentUploadStatus;

extern NSString *DQCommentUploadStatusChangedNotification;

@interface DQCommentUpload : DQModelObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *questID;
@property (nonatomic, readonly, copy) NSArray *shareFlags;
@property (nonatomic, readonly, assign) DQCommentUploadStatus status;
@property (nonatomic, readonly, copy) NSString *facebookToken;
@property (nonatomic, readonly, copy) NSString *twitterToken;
@property (nonatomic, readonly, copy) NSString *twitterTokenSecret;
@property (nonatomic, readonly, copy) NSNumber *uploadProgress;
@property (nonatomic, readonly, copy) NSString *contentID;
@property (nonatomic, readonly, strong) NSArray *emailList;

// these are used by DQCommentUploadController to help calculate percentage progress
@property (nonatomic, readonly, copy) NSNumber *imageSize;
@property (nonatomic, readonly, copy) NSNumber *playbackDataSize;

- (NSString *)imagePath;
- (NSData *)imageData;
- (UIImage *)image;

- (NSString *)playbackDataPath;

+ (NSString *)imageFilename;
+ (NSString *)playbackDataFilename;
+ (NSString *)propertyListPlaybackDataFilename; // to support migration of pre-2.0 plist playback data

@end
