//
//  DQQuestUpload+DataStore.m
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestUpload+DataStore.h"
#import "DQModelObject+DataStore.h"
#import "STUtils.h"

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

static NSArray *__sortDescriptors;

@implementation DQQuestUpload (DataStore)

+ (void)load
{
    __sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
}

+ (NSString *)yapCollectionName
{
    return @"quest-uploads";
}

- (NSString *)equalityIdentifier
{
    return self.identifier;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.identifier = [[NSString UUIDString] copy];
        self.status = DQQuestUploadStatusNew;
        self.emailList = @[];
    }
    return self;
}

- (void)takeProgress:(NSNumber *)percentComplete
{
    // uploadProgress is transient, so we're not saving it
    self.uploadProgress = percentComplete;
}

- (void)saveFacebookToken:(NSString *)facebookToken inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.facebookToken = facebookToken;
    [self saveInTransaction:transaction];
}

- (void)saveFacebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.facebookToken = facebookToken;
    self.twitterToken = twitterToken;
    self.twitterTokenSecret = twitterTokenSecret;
    [self saveInTransaction:transaction];
}

- (void)saveContentID:(NSString *)contentID inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.contentID = contentID;
    self.status = DQQuestUploadStatusPostingQuest;
    [self saveInTransaction:transaction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DQQuestUploadStatusChangedNotification object:self userInfo:nil];
    });
}

- (void)saveShareToFacebook:(BOOL)shareToFacebook inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    if (shareToFacebook != self.shareToFacebook)
    {
        self.shareToFacebook = shareToFacebook;
        [self saveInTransaction:transaction];
    }
}

- (void)saveShareToTwitter:(BOOL)shareToTwitter inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    if (shareToTwitter != self.shareToTwitter)
    {
        self.shareToTwitter = shareToTwitter;
        [self saveInTransaction:transaction];
    }
}

- (void)saveEmailList:(NSArray *)emailList inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    if (emailList != self.emailList)
    {
        self.emailList = emailList;
        [self saveInTransaction:transaction];
    }
}

- (void)saveStatus:(DQQuestUploadStatus)status withError:(NSError *)error inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.status = status;
    [self saveInTransaction:transaction];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = error ? @{NSUnderlyingErrorKey: error} : nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:DQQuestUploadStatusChangedNotification object:self userInfo:userInfo];
    });
}

- (void)saveTitle:(NSString *)title inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    self.title = title;
    [self saveInTransaction:transaction];
}

+ (NSArray *)sortedQuestUploadsInTransaction:(YapCollectionsDatabaseReadTransaction *)transaction
{
    __block NSMutableArray *result = [NSMutableArray new];
    [transaction enumerateKeysAndObjectsInCollection:[DQQuestUpload yapCollectionName] usingBlock:^(NSString *key, DQQuestUpload *object, BOOL *stop) {
        [result addObject:object];
    }];
    [result sortUsingDescriptors:__sortDescriptors];
    return result;
}

@end
