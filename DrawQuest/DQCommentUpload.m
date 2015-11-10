//
//  DQCommentUpload.m
//  DrawQuest
//
//  Created by Buzz Andersen on 11/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCommentUpload.h"

#import <objc/runtime.h>

#import "DQQuest.h"
#import "STUtils.h"

NSString *DQCommentUploadStatusChangedNotification = @"DQCommentUploadStatusChangedNotification";

void * const kDQCommentUploadUploadsPathKey = (void *)&kDQCommentUploadUploadsPathKey;

static void *DQCommentUploadCachedPropertyKeysKey = &DQCommentUploadCachedPropertyKeysKey;

@interface DQCommentUpload ()

@property (nonatomic, readwrite, copy) NSString *identifier;
@property (nonatomic, readwrite, copy) NSString *questID;
@property (nonatomic, readwrite, copy) NSArray *shareFlags;
@property (nonatomic, readwrite, assign) DQCommentUploadStatus status;
@property (nonatomic, readwrite, copy) NSString *facebookToken;
@property (nonatomic, readwrite, copy) NSString *twitterToken;
@property (nonatomic, readwrite, copy) NSString *twitterTokenSecret;
@property (nonatomic, readwrite, copy) NSNumber *uploadProgress;
@property (nonatomic, readwrite, copy) NSString *contentID;
@property (nonatomic, readwrite, strong) NSArray *emailList;

@end

@implementation DQCommentUpload
{
    NSString *_playbackDataPath;
}

@synthesize imageSize = _imageSize;
@synthesize playbackDataSize = _playbackDataSize;

+ (NSSet *)propertyKeys
{
	NSSet *cachedKeys = objc_getAssociatedObject(self, DQCommentUploadCachedPropertyKeysKey);
	if (cachedKeys != nil) return cachedKeys;

    NSSet *superResult = [super propertyKeys];
    NSMutableSet *result = [NSMutableSet setWithSet:superResult];
    [result removeObject:@"uploadProgress"];
    [result removeObject:@"imageSize"];
    [result removeObject:@"playbackDataSize"];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, DQCommentUploadCachedPropertyKeysKey, result, OBJC_ASSOCIATION_COPY);

    return result;
}

- (NSUInteger)hash
{
	NSUInteger value = [self.identifier hash];
    return value;
}

- (BOOL)isEqual:(DQCommentUpload *)model
{
    return self == model || ([model isMemberOfClass:[self class]] && (self.identifier ? [self.identifier isEqualToString:model.identifier] : !model.identifier));

}

#pragma mark File System Data Management

+ (NSString *)imageFilename
{
    return @"image.png";
}

+ (NSString *)pathToUploads
{
    return objc_getAssociatedObject(self, kDQCommentUploadUploadsPathKey);
}

- (NSString *)pathToUploadFiles
{
    return [[[self class] pathToUploads] stringByAppendingPathComponent:self.identifier];
}

- (NSString *)imagePath
{
    return [[self pathToUploadFiles] stringByAppendingPathComponent:[[self class] imageFilename]];
}

- (NSData *)imageData
{
    NSString *path = [self imagePath];
    return [NSData dataWithContentsOfFile:path];
}

- (UIImage *)image
{
    NSString *path = [self imagePath];
    return [UIImage imageWithContentsOfFile:path];
}

+ (NSString *)playbackDataFilename
{
    return @"playback.json";
}

+ (NSString *)propertyListPlaybackDataFilename // to support migration of pre-2.0 plist playback data
{
    return @"playback.plist";
}

- (NSString *)playbackDataPath
{
    if (!_playbackDataPath)
    {
        NSString *path = [[self pathToUploadFiles] stringByAppendingPathComponent:[[self class] playbackDataFilename]];
        NSFileManager *fm = [[NSFileManager alloc] init];
        if (![fm fileExistsAtPath:path])
        {
            path = [[self pathToUploadFiles] stringByAppendingPathComponent:[[self class] propertyListPlaybackDataFilename]];
        }
        _playbackDataPath = [path copy];
    }
    return _playbackDataPath;
}

#pragma mark -
#pragma mark Transient properties for upload progress

- (NSNumber *)imageSize
{
    if (!_imageSize)
    {
        NSFileManager *fm = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSDictionary *atts = [fm attributesOfItemAtPath:[self imagePath] error:&error];
        if (atts)
        {
            _imageSize = @([atts fileSize]);
        }
        else
        {
            _imageSize = @0.0;
        }
    }
    return _imageSize;
}

- (NSNumber *)playbackDataSize
{
    if (!_playbackDataSize)
    {
        NSFileManager *fm = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSDictionary *atts = [fm attributesOfItemAtPath:[self playbackDataPath] error:&error];
        if (atts)
        {
            _playbackDataSize = @([atts fileSize]);
        }
        else
        {
            _playbackDataSize = @0.0;
        }
    }
    return _playbackDataSize;
}

@end
