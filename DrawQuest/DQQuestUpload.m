//
//  DQQuestUpload.m
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestUpload.h"

#import <objc/runtime.h>

#import "STUtils.h"

NSString *DQQuestUploadStatusChangedNotification = @"DQQuestUploadStatusChangedNotification";

void * const kDQQuestUploadUploadsPathKey = (void *)&kDQQuestUploadUploadsPathKey;

static void *DQQuestUploadCachedPropertyKeysKey = &DQQuestUploadCachedPropertyKeysKey;

@interface DQQuestUpload ()

@property (nonatomic, readwrite, copy) NSString *identifier;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, assign) BOOL shareToFacebook;
@property (nonatomic, readwrite, assign) BOOL shareToTwitter;
@property (nonatomic, readwrite, assign) DQQuestUploadStatus status;
@property (nonatomic, readwrite, copy) NSString *facebookToken;
@property (nonatomic, readwrite, copy) NSString *twitterToken;
@property (nonatomic, readwrite, copy) NSString *twitterTokenSecret;
@property (nonatomic, readwrite, copy) NSNumber *uploadProgress;
@property (nonatomic, readwrite, copy) NSString *contentID;
@property (nonatomic, readwrite, strong) NSArray *emailList;

@end

@implementation DQQuestUpload
{
    // not supporting quest playback for now :(
    // NSString *_playbackDataPath;
}

@synthesize imageSize = _imageSize;
// not supporting quest playback for now :(
// @synthesize playbackDataSize = _playbackDataSize;

+ (NSSet *)propertyKeys
{
	NSSet *cachedKeys = objc_getAssociatedObject(self, DQQuestUploadCachedPropertyKeysKey);
	if (cachedKeys != nil) return cachedKeys;

    NSSet *superResult = [super propertyKeys];
    NSMutableSet *result = [NSMutableSet setWithSet:superResult];
    [result removeObject:@"uploadProgress"];
    [result removeObject:@"imageSize"];
    // not supporting quest playback for now :(
    // [result removeObject:@"playbackDataSize"];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, DQQuestUploadCachedPropertyKeysKey, result, OBJC_ASSOCIATION_COPY);

    return result;
}

- (NSUInteger)hash
{
	NSUInteger value = [self.identifier hash];
    return value;
}

- (BOOL)isEqual:(DQQuestUpload *)model
{
    return self == model || ([model isMemberOfClass:self.class] && (self.identifier ? [self.identifier isEqualToString:model.identifier] : !model.identifier));

}

#pragma mark File System Data Management

+ (NSString *)imageFilename
{
    return @"image.png";
}

+ (NSString *)pathToDrafts
{
    return objc_getAssociatedObject(self, kDQQuestUploadUploadsPathKey);
}

- (NSString *)pathToDraftFiles
{
    return [[[[self class] pathToDrafts] stringByAppendingPathComponent:[@"Quest-" stringByAppendingString:self.identifier]] stringByAppendingPathComponent:@"Draft"];
}

- (NSString *)imagePath
{
    return [[self pathToDraftFiles] stringByAppendingPathComponent:[[self class] imageFilename]];
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

// not supporting quest playback for now :(
/* + (NSString *)playbackDataFilename
{
    return @"playback.json";
}*/

// not supporting quest playback for now :(
/* - (NSString *)playbackDataPath
{
    if (!_playbackDataPath)
    {
        NSString *path = [[self pathToDraftFiles] stringByAppendingPathComponent:[[self class] playbackDataFilename]];
        _playbackDataPath = [path copy];
    }
    return _playbackDataPath;
}*/

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

// not supporting quest playback for now :(
/* - (NSNumber *)playbackDataSize
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
}*/

@end
