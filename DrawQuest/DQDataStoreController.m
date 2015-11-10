//
//  DQDataStoreController.m
//  DrawQuest
//
//  Created by Buzz Andersen on 9/11/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQDataStoreController.h"
#import "DQAnalyticsConstants.h"
#import "DQModelObject+DataStore.h"
#import "DQQuest+DataStore.h"
#import "DQQuestUpload+DataStore.h"
#import "DQComment+DataStore.h"
#import "DQCommentUpload+DataStore.h"
#import "DQUser+DataStore.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"
#import "DQPrivateServiceController.h"
#import "YapCollectionsDatabase.h"
#import "YapCollectionsDatabaseConnection.h"
#import "DQViewController.h"

NSString *DQApplicationPreloadedQuestID = @"DQApplicationPreloadedQuestID";

// Notifications
NSString *DQCommentUploadCompletedNotification = @"DQCommentUploadCompletedNotification";
NSString *DQCommentUploadProgressChangedNotification = @"DQCommentUploadProgressChangedNotification";
NSString *DQCommentUploadFailedNotification = @"DQCommentUploadFailedNotification";
NSString *DQCommentUploadFailedInvalidFacebookTokenNotification = @"DQCommentUploadFailedInvalidFacebookTokenNotification";
NSString *DQCommentUploadFailedInvalidTwitterTokenNotification = @"DQCommentUploadFailedInvalidTwitterTokenNotification";
NSString *DQQuestUploadCompletedNotification = @"DQQuestUploadCompletedNotification";
NSString *DQQuestUploadProgressChangedNotification = @"DQQuestUploadProgressChangedNotification";
NSString *DQQuestUploadFailedNotification = @"DQQuestUploadFailedNotification";
NSString *DQQuestUploadFailedInvalidFacebookTokenNotification = @"DQQuestUploadFailedInvalidFacebookTokenNotification";
NSString *DQQuestUploadFailedInvalidTwitterTokenNotification = @"DQQuestUploadFailedInvalidTwitterTokenNotification";
NSString *DQCommentPlayedNotification = @"DQCommentPlayedNotification";
NSString *DQCommentFlaggedNotification = @"DQCommentFlaggedNotification";
NSString *DQQuestFlaggedNotification = @"DQQuestFlaggedNotification";
NSString *DQCommentDeletedNotification = @"DQCommentDeletedNotification";

// Notification Keys
NSString *DQCommentUploadObjectNotificationKey = @"CommentUpload";
NSString *DQCommentObjectNotificationKey = @"Comment";
NSString *DQQuestUploadObjectNotificationKey = @"QuestUpload";
NSString *DQQuestObjectNotificationKey = @"Quest";

@interface DQDataStoreController ()

@property (nonatomic, strong) YapCollectionsDatabase *database;
@property (nonatomic, strong) YapCollectionsDatabaseConnection *mainConnection;
@property (nonatomic, strong) YapCollectionsDatabaseConnection *backgroundConnection;

@end

@implementation DQDataStoreController

+ (NSString *)databasePath
{
    NSFileManager *fm = [NSFileManager new];
    return [[fm applicationSupportPath] stringByAppendingPathComponent:@"DQDataStoreController-collections.sqlite"];
}

#pragma mark Initialization

- (void)dealloc
{
    if (_database)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:_database];
    }
}

- (id)init
{
    // FIXME: root directory isn't set up anymore
    // This should result in a data store at
    // ~/Library/Application Support/DQDataStoreController.sqlite
    self = [super init];
    if (self)
    {
        [self ensureStackExists];
        [self installPreloadedQuest];
    }
    return self;
}

- (void)ensureStackExists
{
    if (!_database)
    {
        _database = [[YapCollectionsDatabase alloc] initWithPath:[[self class] databasePath]];

        _mainConnection = [_database newConnection];
        // [_mainConnection beginLongLivedReadTransaction];

        _backgroundConnection = [_database newConnection];
        // [_backgroundConnection beginLongLivedReadTransaction];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:_database];
    }
}

- (YapCollectionsDatabase *)database
{
    [self ensureStackExists];
    return _database;
}

- (YapCollectionsDatabaseConnection *)mainConnection
{
    [self ensureStackExists];
    return _mainConnection;
}

- (YapCollectionsDatabaseConnection *)backgroundConnection
{
    [self ensureStackExists];
    return _backgroundConnection;
}

- (void)beginLongLivedReadTransaction
{
//    [self.mainConnection beginLongLivedReadTransaction];
//    [self.backgroundConnection beginLongLivedReadTransaction];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    [self beginLongLivedReadTransaction];
}

- (void)readWriteInBackground:(BOOL)inBackground block:(void (^)(YapCollectionsDatabaseReadWriteTransaction *transaction))block
{
    if (inBackground)
    {
        [self.backgroundConnection asyncReadWriteWithBlock:block];
    }
    else
    {
        [self.mainConnection readWriteWithBlock:block];
    }
}

#pragma mark Preloaded Quest

- (void)installPreloadedQuest
{
    DQQuest *preloadedQuest = [self createOrUpdatePreloadedQuest];
    [self setPreloadedQuestID:preloadedQuest.serverID];
}

- (void)setPreloadedQuestID:(NSString *)inPreloadedQuestID
{
    [[NSUserDefaults standardUserDefaults] setObject:inPreloadedQuestID forKey:DQApplicationPreloadedQuestID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)preloadedQuestID
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DQApplicationPreloadedQuestID];
}

- (DQQuest *)createOrUpdatePreloadedQuest
{
    NSString *JSONPath = [[NSBundle mainBundle] pathForResource:@"preloaded_quest" ofType:@"json"];
    if (!JSONPath) {
        NSLog(@"Error opening preloaded quest: Can't find file.");
        return nil;
    }
    
    NSError *error = nil;
    NSString *JSONString = [NSString stringWithContentsOfFile:JSONPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error opening preloaded quest: %@", error);
    }
    
    return [self createOrUpdateQuestFromJSONString:JSONString];
}

#pragma mark Quest CRUD

- (DQQuest *)createOrUpdateQuestFromJSONString:(NSString *)inQuestJSONString
{
    NSError *error = nil;
    NSDictionary *questDictionary = [NSJSONSerialization JSONObjectWithData:[inQuestJSONString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (questDictionary)
    {
        __block DQQuest *quest = nil;
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            quest = [self createOrUpdateQuestWithJSONInfo:questDictionary inTransaction:transaction];
            [quest saveInTransaction:transaction];
        }];
        return quest;
    }
    else
    {
        NSLog(@"Unable to create quest from JSON string due to error: %@", error);
        return nil;
    }
}

- (void)createOrUpdateQuestsFromJSONList:(NSArray *)inJSONList inBackground:(BOOL)inBackground resultsBlock:(void (^)(NSArray *objects))resultsBlock
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        NSMutableArray *quests = [[NSMutableArray alloc] init];
        for (NSDictionary *questInfo in inJSONList)
        {
            DQQuest *quest = [self createOrUpdateQuestWithJSONInfo:questInfo inTransaction:transaction];
            if (quest)
            {
                [quests addObject:quest];
            }
        }
        if (resultsBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultsBlock(quests);
            });
        }
    }];
}

- (DQQuest *)createOrUpdateQuestWithJSONInfo:(NSDictionary *)inJSONInfo
{
    __block DQQuest *quest = nil;
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        quest = [self createOrUpdateQuestWithJSONInfo:inJSONInfo inTransaction:transaction];
    }];
    return quest;
}

- (DQQuest *)createOrUpdateQuestWithJSONInfo:(NSDictionary *)inJSONInfo inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    DQQuest *quest = nil;
    if ([inJSONInfo.dq_serverID length])
    {
        quest = [self createOrUpdateQuestWithServerID:inJSONInfo.dq_serverID title:inJSONInfo.dq_questTitle inTransaction:transaction];
        if (quest.flagged)
        {
            quest = nil;
        }
        if ([quest initializeWithJSONDictionary:inJSONInfo])
        {
            [quest saveInTransaction:transaction];
        }
    }
    return quest;
}

- (DQQuest *)createOrUpdateQuestWithServerID:(NSString *)inQuestServerID title:(NSString *)inTitle inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    DQQuest *quest = nil;
    if ([inQuestServerID length])
    {
        quest = [self questForServerID:inQuestServerID inTransaction:transaction];
        if (!quest)
        {
            quest = [[DQQuest alloc] initWithServerID:inQuestServerID title:inTitle];
            [quest saveInTransaction:transaction];
        }
    }
    return quest;
}

- (void)markQuestIDCompleted:(NSString *)inQuestID
{
    if ([inQuestID length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            DQQuest *quest = [self questForServerID:inQuestID inTransaction:transaction];
            [quest markCompletedByUser];
            [quest saveInTransaction:transaction];
        }];
    }
}

- (void)markQuestsIDsFromJSONListCompleted:(NSArray *)inQuestIDList inBackground:(BOOL)inBackground
{
    if ([inQuestIDList count])
    {
        [self readWriteInBackground:inBackground block:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            for (NSNumber *currentID in inQuestIDList) {
                DQQuest *quest = [self questForServerID:[currentID stringValue] inTransaction:transaction];
                [quest markCompletedByUser];
                [quest saveInTransaction:transaction];
            }
        }];
    }
}

#pragma mark Comment CRUD

// called by DQGalleryViewController
- (void)createOrUpdateCommentsForQuestID:(NSString *)inQuestID fromJSONList:(NSArray *)inJSONList questJSONDictionary:(NSDictionary *)questJSONDictionary inBackground:(BOOL)inBackground resultsBlock:(void (^)(NSArray *objects))resultsBlock
{
    if ([inQuestID length])
    {
        if ([inJSONList count])
        {
            [self readWriteInBackground:inBackground block:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
                DQQuest *quest = [self createOrUpdateQuestWithJSONInfo:questJSONDictionary inTransaction:transaction];
                if (quest)
                {
                    NSMutableArray *comments = [[NSMutableArray alloc] init];
                    for (NSDictionary *currentCommentInfo in inJSONList)
                    {
                        @autoreleasepool
                        {
                            DQComment *comment = [self createOrUpdateCommentWithJSONInfo:currentCommentInfo inTransaction:transaction];
                            if (comment)
                            {
                                [comments addObject:comment];
                            }
                        }
                    }
                    if (resultsBlock)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            resultsBlock(comments);
                        });
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        resultsBlock(nil);
                    });
                }
            }];
        }
        else if (resultsBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultsBlock(@[]);
            });
        }
    }
    else if (resultsBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            resultsBlock(nil);
        });
    }
}

// called by DQGalleryViewController (starring)
// called by DQPadApp (playback)
// called by DQPadProfile (loadNextPage/viewDidLoad)
// called by DQPhoneHomeViewController
- (void)createOrUpdateCommentsFromJSONList:(NSArray *)inJSONList inBackground:(BOOL)inBackground resultsBlock:(void (^)(NSArray *objects))resultsBlock
{
    [self readWriteInBackground:inBackground block:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        NSMutableArray *comments = [[NSMutableArray alloc] init];
        for (NSDictionary *currentCommentInfo in inJSONList)
        {
            @autoreleasepool
            {
                DQComment *comment = [self createOrUpdateCommentWithJSONInfo:currentCommentInfo inTransaction:transaction];
                if (comment)
                {
                    [comments addObject:comment];
                }
            }
        }
        if (resultsBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultsBlock(comments);
            });
        }
    }];
}

// called by DQCommentUploadController
- (DQComment *)createOrUpdateCommentWithJSONInfo:(NSDictionary *)inJSONInfo
{
    __block DQComment *comment = nil;
    if ([inJSONInfo.dq_serverID length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            comment = [self createOrUpdateCommentWithJSONInfo:inJSONInfo inTransaction:transaction];
        }];
    }
    return comment;
}

- (DQComment *)createOrUpdateCommentWithJSONInfo:(NSDictionary *)inJSONInfo inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    DQComment *comment = nil;
    if ([inJSONInfo.dq_serverID length])
    {
        comment = [self commentForServerID:inJSONInfo.dq_serverID inTransaction:transaction];
        if (!comment)
        {
            comment = [[DQComment alloc] initWithServerID:inJSONInfo.dq_serverID];
            [self createOrUpdateQuestWithServerID:inJSONInfo.dq_commentQuestID title:inJSONInfo.dq_commentQuestTitle inTransaction:transaction];
        }
        else if (comment.flagged)
        {
            comment = nil;
        }
        if ([comment initializeWithJSONDictionary:inJSONInfo])
        {
            [comment saveInTransaction:transaction];
        }
    }
    return comment;
}

- (void)flagCommentWithServerID:(NSString *)inServerID
{
    if ([inServerID length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            DQComment *comment = [self commentForServerID:inServerID inTransaction:transaction];
            if (comment)
            {
                [comment markFlaggedByUser];
                [comment saveInTransaction:transaction];

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = @{DQCommentObjectNotificationKey: comment};
                    NSNotification *notification = [NSNotification notificationWithName:DQCommentFlaggedNotification object:nil userInfo:userInfo];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                });
            }
        }];
    }
}

- (void)flagQuestWithServerID:(NSString *)inServerID
{
    if ([inServerID length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            DQQuest *quest = [self questForServerID:inServerID inTransaction:transaction];
            if (quest)
            {
                [quest markFlaggedByUser];
                [quest saveInTransaction:transaction];

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = @{DQQuestObjectNotificationKey: quest};
                    NSNotification *notification = [NSNotification notificationWithName:DQQuestFlaggedNotification object:nil userInfo:userInfo];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                });
            }
        }];
    }
}

- (void)deleteCommentWithServerID:(NSString *)inServerID
{
    if ([inServerID length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            DQComment *comment = [self commentForServerID:inServerID inTransaction:transaction];
            if (comment)
            {
                [comment deleteInTransaction:transaction];

                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = @{DQCommentObjectNotificationKey: comment};
                    NSNotification *notification = [NSNotification notificationWithName:DQCommentDeletedNotification object:nil userInfo:userInfo];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                });
            }
        }];
    }
}

#pragma mark Quest Upload CRUD

- (DQQuestUpload *)createQuestUpload
{
    __block DQQuestUpload *questUpload = nil;
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        questUpload = [[DQQuestUpload alloc] init];
        [questUpload saveInTransaction:transaction];
    }];
    return questUpload;
}

- (void)deleteQuestUpload:(DQQuestUpload *)questUpload
{
    if (questUpload)
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            [questUpload deleteInTransaction:transaction];
        }];
    }
}

- (void)takeProgress:(NSNumber *)percentComplete forQuestUpload:(DQQuestUpload *)questUpload
{
    [questUpload takeProgress:percentComplete];
}

- (void)saveFacebookToken:(NSString *)facebookToken forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveFacebookToken:facebookToken inTransaction:transaction];
    }];
}

- (void)saveFacebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveFacebookToken:facebookToken twitterToken:twitterToken twitterTokenSecret:twitterTokenSecret inTransaction:transaction];
    }];
}

- (void)saveContentID:(NSString *)contentID forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveContentID:contentID inTransaction:transaction];
    }];
}

- (void)saveTitle:(NSString *)title forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveTitle:title inTransaction:transaction];
    }];
}

- (void)saveStatus:(DQQuestUploadStatus)status withError:(NSError *)error forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveStatus:status withError:error inTransaction:transaction];
    }];
}

- (void)saveStatus:(DQQuestUploadStatus)status forQuestUpload:(DQQuestUpload *)questUpload
{
    [self saveStatus:status withError:nil forQuestUpload:questUpload];
}

- (void)saveShareToFacebook:(BOOL)shouldShareToFacebook forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveShareToFacebook:shouldShareToFacebook inTransaction:transaction];
    }];
}

- (void)saveShareToTwitter:(BOOL)shouldShareToTwitter forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveShareToTwitter:shouldShareToTwitter inTransaction:transaction];
    }];
}

- (void)saveEmailList:(NSArray *)emailList forQuestUpload:(DQQuestUpload *)questUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [questUpload saveEmailList:emailList inTransaction:transaction];
    }];
}

- (void)markAllUploadingQuestUploadsFailed
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        NSMutableArray *uploads = [NSMutableArray new];
        [transaction enumerateKeysAndObjectsInCollection:[DQQuestUpload yapCollectionName] usingBlock:^(NSString *key, DQQuestUpload *object, BOOL *stop) {
            [uploads addObject:object];
        }];
        for (DQQuestUpload *currentUpload in uploads)
        {
            switch (currentUpload.status)
            {
                case DQQuestUploadStatusNew:
                    [currentUpload saveStatus:DQQuestUploadStatusFailedNew withError:nil inTransaction:transaction];
                    break;
                case DQQuestUploadStatusUploadingImage:
                    [currentUpload saveStatus:DQQuestUploadStatusFailedUploadingImage withError:nil inTransaction:transaction];
                    break;
                case DQQuestUploadStatusPostingQuest:
                    [currentUpload saveStatus:DQQuestUploadStatusFailedPostingQuest withError:nil inTransaction:transaction];
                    break;
                // not supporting quest playback for now :(
                /*case DQQuestUploadStatusUploadingPlaybackData:
                    [currentUpload saveStatus:DQQuestUploadStatusFailedUploadingPlaybackData withError:nil inTransaction:transaction];
                    break;*/
                default:
                    break;
            }
        }
    }];
}

#pragma mark Comment Upload CRUD

- (DQCommentUpload *)createCommentUploadForQuestWithServerID:(NSString *)inQuestID
                                                  shareFlags:(NSArray *)inShareFlags
                                               facebookToken:(NSString *)inFacebookToken
                                                twitterToken:(NSString *)inTwitterToken
                                          twitterTokenSecret:(NSString *)inTwitterTokenSecret
                                                   emailList:(NSArray *)emailList
{
    __block DQCommentUpload *commentUpload = nil;
    if ([inQuestID length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            commentUpload = [[DQCommentUpload alloc] initWithQuestID:inQuestID shareFlags:inShareFlags facebookToken:inFacebookToken twitterToken:inTwitterToken twitterTokenSecret:inTwitterTokenSecret emailList:emailList];
            [commentUpload saveInTransaction:transaction];
        }];
    }
    return commentUpload;
}

- (void)deleteCommentUpload:(DQCommentUpload *)commentUpload
{
    if (commentUpload)
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            [commentUpload deleteInTransaction:transaction];
        }];
    }
}

- (void)takeProgress:(NSNumber *)percentComplete forCommentUpload:(DQCommentUpload *)commentUpload
{
    [commentUpload takeProgress:percentComplete];
}

- (void)saveFacebookToken:(NSString *)facebookToken forCommentUpload:(DQCommentUpload *)commentUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [commentUpload saveFacebookToken:facebookToken inTransaction:transaction];
    }];
}

- (void)saveTwitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret forCommentUpload:(DQCommentUpload *)commentUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [commentUpload saveTwitterToken:twitterToken twitterTokenSecret:twitterTokenSecret inTransaction:transaction];
    }];
}

- (void)saveContentID:(NSString *)contentID forCommentUpload:(DQCommentUpload *)commentUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [commentUpload saveContentID:contentID inTransaction:transaction];
    }];
}

- (void)saveStatus:(DQCommentUploadStatus)status forCommentUpload:(DQCommentUpload *)commentUpload
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [commentUpload saveStatus:status inTransaction:transaction];
    }];
}

- (void)markAllUploadingCommentUploadsFailed
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        NSMutableArray *uploads = [NSMutableArray new];
        [transaction enumerateKeysAndObjectsInCollection:[DQCommentUpload yapCollectionName] usingBlock:^(NSString *key, DQCommentUpload *object, BOOL *stop) {
            [uploads addObject:object];
        }];
        for (DQCommentUpload *currentUpload in uploads)
        {
            switch (currentUpload.status)
            {
                case DQCommentUploadStatusNew:
                    [currentUpload saveStatus:DQCommentUploadStatusFailedNew inTransaction:transaction];
                    break;
                case DQCommentUploadStatusUploadingImage:
                    [currentUpload saveStatus:DQCommentUploadStatusFailedUploadingImage inTransaction:transaction];
                    break;
                case DQCommentUploadStatusPostingComment:
                    [currentUpload saveStatus:DQCommentUploadStatusFailedPostingComment inTransaction:transaction];
                    break;
                case DQCommentUploadStatusUploadingPlaybackData:
                    [currentUpload saveStatus:DQCommentUploadStatusFailedUploadingPlaybackData inTransaction:transaction];
                    break;
                default:
                    break;
            }
        }
    }];
}

#pragma mark User CRUD

// called by Explore, Profile and Settings
- (void)createOrUpdateUsersFromJSONList:(NSArray *)inJSONList inBackground:(BOOL)inBackground withCompletionBlock:(void (^)(NSArray *objects))completionBlock
{
    if ([inJSONList count])
    {
        [self readWriteInBackground:inBackground block:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *users = [NSMutableArray new];
            for (NSDictionary *currentUserInfo in inJSONList)
            {
                @autoreleasepool
                {
                    DQUser *user = [self createOrUpdateUserWithJSONInfo:currentUserInfo inTransaction:transaction];
                    if (user)
                    {
                        [users addObject:user];
                    }
                }
            }
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(users);
                });
            }
        }];
    }
    else if (completionBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(nil);
        });
    }
}

- (DQUser *)createOrUpdateUserWithJSONInfo:(NSDictionary *)inJSONInfo inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    DQUser *user = nil;
    if ([inJSONInfo.dq_userInfo.dq_serverID length] && [inJSONInfo.dq_userInfo.dq_userName length])
    {
        user = [self createOrUpdateUserWithUserName:inJSONInfo.dq_userInfo.dq_userName inTransaction:transaction];
        if ([user initializeWithJSONDictionary:inJSONInfo])
        {
            [user saveInTransaction:transaction];
        }
    }
    return user;
}

- (DQUser *)createOrUpdateUserWithUserName:(NSString *)inUserName inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    DQUser *user = nil;
    if ([inUserName length])
    {
        user = [self userForUserName:inUserName inTransaction:transaction];
        if (!user)
        {
            user = [[DQUser alloc] initWithUserName:inUserName];
            [user saveInTransaction:transaction];
        }
    }
    return user;
}

- (void)updateCoinBalanceForUserWithUserName:(NSString *)inUserName withCount:(NSNumber *)inCount
{
    if (inCount && [inUserName length])
    {
        [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            DQUser *user = [self createOrUpdateUserWithUserName:inUserName inTransaction:transaction];
            if (user)
            {
                [user saveCoinCount:inCount inTransaction:transaction];
            }
        }];
    }
}

- (void)saveIsFollowing:(BOOL)isFollowing forUser:(DQUser *)user
{
    [self.mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
        [user setIsFollowing:isFollowing inTransaction:transaction];
    }];
}

#pragma mark Quest Queries

- (DQQuest *)questForServerID:(NSString *)inServerID
{
    __block DQQuest *quest = nil;
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        quest = [self questForServerID:inServerID inTransaction:transaction];
    }];
    return quest;
}

- (DQQuest *)questForServerID:(NSString *)inServerID inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction
{
    DQQuest *quest = [DQQuest objectForKey:inServerID inTransaction:transaction];
    // FIXME: the old version prefetched comment uploads
    return quest;
}

// FIXME: this method should not be used, as quests are paginated
- (NSArray *)quests
{
    __block NSMutableArray *quests = [NSMutableArray new];
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[DQQuest yapCollectionName] usingBlock:^(NSString *key, id object, BOOL *stop) {
            [quests addObject:object];
            // FIXME: the old version prefetched comment uploads
        }];
    }];
    // Note: quests should probably be a view so they can be automatically sorted.
    [quests sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    return quests;
}

#pragma mark Comment Queries

- (DQComment *)commentForServerID:(NSString *)inServerID
{
    __block DQComment *result = nil;
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        result = [self commentForServerID:inServerID inTransaction:transaction];
    }];
    return result;
}

- (DQComment *)commentForServerID:(NSString *)inServerID inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction
{
    DQComment *comment = [DQComment objectForKey:inServerID inTransaction:transaction];
    return comment;
}

#pragma mark Comment Upload Queries

- (NSArray *)sortedCommentUploadsForQuest:(DQQuest *)quest
{
    __block NSArray *result = nil;
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        result = [DQCommentUpload sortedCommentUploadsForQuestWithServerID:quest.serverID inTransaction:transaction];
    }];
    return result;
}

- (DQCommentUpload *)commentUploadForIdentifier:(NSString *)inIdentifier
{
    __block DQCommentUpload *commentUpload = nil;
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        commentUpload = [DQCommentUpload objectForKey:inIdentifier inTransaction:transaction];
    }];
    // FIXME: the old version prefetched the quest
    return commentUpload;
}

#pragma mark Quest Upload Queries

- (NSArray *)questUploads
{
    __block NSMutableArray *uploads = [NSMutableArray new];
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[DQQuestUpload yapCollectionName] usingBlock:^(NSString *key, DQQuestUpload *object, BOOL *stop) {
            [uploads addObject:object];
        }];
    }];
    return uploads;
}

#pragma mark User Queries

- (DQUser *)userForUserName:(NSString *)inUserName
{
    __block DQUser *user = nil;
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        user = [self userForUserName:inUserName inTransaction:transaction];
    }];
    return user;
}

- (DQUser *)userForUserName:(NSString *)inUserName inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction
{
    DQUser *user = [DQUser objectForKey:inUserName inTransaction:transaction];
    return user;
}

- (void)addObserver:(id)inObserver action:(SEL)inAction forEntityName:(NSString *)inEntityName
{
    // FIXME: implement
}

- (void)removeObserver:(id)inObserver forEntityName:(NSString *)inEntityName
{
    // FIXME: implement
}

- (void)removeObserver:(id)inObserver
{
    // FIXME: implement
}

- (void)reset
{
    if (self.database)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:self.database];
    }
    self.mainConnection = nil;
    self.backgroundConnection = nil;
    self.database = nil;
}

- (void)deletePersistentStore
{
    NSString *path = self.database.databasePath;

    // Clear out Core Data stack
    [self reset];

    if ([path length])
    {
        NSFileManager *fm = [NSFileManager new];
        [fm removeItemAtPath:path error:NULL];
    }
}

#pragma mark -
#pragma mark Follow States

- (void)populateFollowStateMap:(NSMutableDictionary *)map
{
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:@"follow" usingBlock:^(NSString *username, NSNumber *stateNumber, BOOL *stop) {
            map[username] = stateNumber;
        }];
    }];
}

- (DQFollowState)followStateForUsername:(NSString *)username
{
    __block DQFollowState result = DQFollowStateIndeterminate;
    if ([username length])
    {
        [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
            NSNumber *value = [transaction objectForKey:username inCollection:@"follow"];
            if (value)
            {
                result = [value integerValue];
            }
        }];
    }
    return result;
}

- (void)setFollowState:(DQFollowState)state forUsername:(NSString *)username withTimestamp:(NSDate *)timestamp
{
    if (!timestamp)
    {
        timestamp = [NSDate date];
    }
    if ([username length])
    {
        id obj = @(state);
        [self.backgroundConnection asyncReadWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:obj forKey:username inCollection:@"follow" withMetadata:timestamp];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{DQFollowStateNotificationStateUserInfoKey: obj};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQFollowStateChangedNotification object:username userInfo:userInfo];
        });
    }
}

- (void)setManyFollowStates:(NSDictionary *)updates withTimestamp:(NSDate *)timestamp
{
    if (!timestamp)
    {
        timestamp = [NSDate date];
    }
    if ([updates count])
    {
        [self.backgroundConnection asyncReadWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            [updates enumerateKeysAndObjectsUsingBlock:^(NSString *username, id obj, BOOL *stop) {
                [transaction setObject:obj forKey:username inCollection:@"follow" withMetadata:timestamp];
            }];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{DQFollowStateNotificationManyStatesUserInfoKey: updates};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQFollowStateChangedNotification object:nil userInfo:userInfo];
        });
    }
}

#pragma mark -
#pragma mark Star States

- (void)populateStarStateMap:(NSMutableDictionary *)map
{
    [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:@"star" usingBlock:^(NSString *commentID, NSNumber *stateNumber, BOOL *stop) {
            map[commentID] = stateNumber;
        }];
    }];
}

- (DQStarState)starStateForCommentWithServerID:(NSString *)commentID
{
    __block DQStarState result = DQStarStateIndeterminate;
    if ([commentID length])
    {
        [self.mainConnection readWithBlock:^(YapCollectionsDatabaseReadTransaction *transaction) {
            NSNumber *value = [transaction objectForKey:commentID inCollection:@"star"];
            if (value)
            {
                result = [value integerValue];
            }
        }];
    }
    return result;
}

- (void)setStarState:(DQStarState)state forCommentWithServerID:(NSString *)commentID withTimestamp:(NSDate *)timestamp
{
    if (!timestamp)
    {
        timestamp = [NSDate date];
    }
    if ([commentID length])
    {
        id obj = @(state);
        [self.backgroundConnection asyncReadWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:obj forKey:commentID inCollection:@"star" withMetadata:timestamp];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{DQStarStateNotificationStateUserInfoKey: obj};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQStarStateChangedNotification object:commentID userInfo:userInfo];
        });
    }
}

@end
