//
//  DQQuestUpload.h
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQModelObject.h"

extern void * const kDQQuestUploadUploadsPathKey;

typedef enum {
    DQQuestUploadStatusNew = 0,
    DQQuestUploadStatusDraft = 1, // this isn't even used
    DQQuestUploadStatusUploadingImage = 2,
    DQQuestUploadStatusPublished = 3,
    DQQuestUploadStatusFailedNew = 4,
    DQQuestUploadStatusFailedWithInvalidFacebookToken = 5,
    DQQuestUploadStatusPostingQuest = 6,
    // not supporting quest playback for now :(
    // DQQuestUploadStatusUploadingPlaybackData = 7,
    DQQuestUploadStatusFailedUploadingImage = 8,
    DQQuestUploadStatusFailedPostingQuest = 9,
    // not supporting quest playback for now :(
    // DQQuestUploadStatusFailedUploadingPlaybackData = 10,
    DQQuestUploadStatusFailedWithInvalidTwitterToken = 11
} DQQuestUploadStatus;

extern NSString *DQQuestUploadStatusChangedNotification;

@interface DQQuestUpload : DQModelObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, assign) BOOL shareToFacebook;
@property (nonatomic, readonly, assign) BOOL shareToTwitter;
@property (nonatomic, readonly, assign) DQQuestUploadStatus status;
@property (nonatomic, readonly, copy) NSString *facebookToken;
@property (nonatomic, readonly, copy) NSString *twitterToken;
@property (nonatomic, readonly, copy) NSString *twitterTokenSecret;
@property (nonatomic, readonly, copy) NSNumber *uploadProgress;
@property (nonatomic, readonly, copy) NSString *contentID;
@property (nonatomic, readonly, strong) NSArray *emailList;

// these are used by DQQuestUploadController to help calculate percentage progress
@property (nonatomic, readonly, copy) NSNumber *imageSize;
// not supporting quest playback for now :(
// @property (nonatomic, readonly, copy) NSNumber *playbackDataSize;

- (NSString *)pathToDraftFiles;
- (NSString *)imagePath;
- (NSData *)imageData;
- (UIImage *)image;

// not supporting quest playback for now :(
// - (NSString *)playbackDataPath;

+ (NSString *)imageFilename;
// not supporting quest playback for now :(
// + (NSString *)playbackDataFilename;

@end
