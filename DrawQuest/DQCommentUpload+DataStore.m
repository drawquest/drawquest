//
//  DQCommentUpload+DataStore.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentUpload+DataStore.h"
#import "DQModelObject+DataStore.h"
#import "STUtils.h"

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

static NSArray *__sortDescriptors;

@implementation DQCommentUpload (DataStore)

+ (void)load
{
    __sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
}

+ (NSString *)yapCollectionName
{
    return @"comment-uploads";
}

- (NSString *)equalityIdentifier
{
    return [self.questID stringByAppendingFormat:@"/%@", self.identifier];
}

- (instancetype)initWithQuestID:(NSString *)questID
                     shareFlags:(NSArray *)shareFlags
                  facebookToken:(NSString *)facebookToken
                   twitterToken:(NSString *)twitterToken
             twitterTokenSecret:(NSString *)twitterTokenSecret
                      emailList:(NSArray *)emailList
{
    self = [super init];
    if (self)
    {
        self.questID = questID;
        self.shareFlags = shareFlags;
        self.identifier = [[NSString UUIDString] copy];
        self.facebookToken = facebookToken;
        self.twitterToken = twitterToken;
        self.twitterTokenSecret = twitterTokenSecret;
        self.status = DQCommentUploadStatusNew;
        self.emailList = emailList;
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
    BOOL changed = NO;
    DQModelObjectSetProperty(facebookToken, facebookToken, changed);
    if (changed)
    {
        [self saveInTransaction:transaction];
    }
}

- (void)saveTwitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    BOOL changed = NO;
    DQModelObjectSetProperty(twitterToken, twitterToken, changed);
    DQModelObjectSetProperty(twitterTokenSecret, twitterTokenSecret, changed);
    if (changed)
    {
        [self saveInTransaction:transaction];
    }
}

- (void)takeIdentifier:(NSString *)identifier
{
    self.identifier = identifier;
}

- (void)takeContentID:(NSString *)contentID status:(DQCommentUploadStatus)status
{
    self.contentID = contentID;
    self.status = status;
}

- (void)saveContentID:(NSString *)contentID inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    [self takeContentID:contentID status:DQCommentUploadStatusPostingComment];
    [self saveInTransaction:transaction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DQCommentUploadStatusChangedNotification object:self userInfo:nil];
    });
}

- (void)saveStatus:(DQCommentUploadStatus)status inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    if (status != self.status)
    {
        self.status = status;
        [self saveInTransaction:transaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:DQCommentUploadStatusChangedNotification object:self userInfo:nil];
        });
    }
}

+ (NSArray *)sortedCommentUploadsForQuestWithServerID:(NSString *)questID inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction
{
    __block NSMutableArray *result = nil;
    if ([questID length])
    {
        result = [NSMutableArray new];
        NSString *prefix = [questID stringByAppendingString:@"/"];
        [transaction enumerateKeysAndObjectsInCollection:[DQCommentUpload yapCollectionName] usingBlock:^(NSString *key, DQCommentUpload *object, BOOL *stop) {
            [result addObject:object];
        } withFilter:^BOOL(NSString *key) {
            return [key hasPrefix:prefix];
        }];
    }
    [result sortUsingDescriptors:__sortDescriptors];
    return result;
}

@end
