//
//  DQMigrate2xxTo300.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQMigrate2xxTo300.h"
#import <CoreData/CoreData.h>
#import "DQCoreDataQuest.h"
#import "DQCoreDataCommentUpload.h"

#import "YapCollectionsDatabase.h"
#import "YapCollectionsDatabaseConnection.h"
#import "DQQuest+DataStore.h"
#import "DQCommentUpload+DataStore.h"
#import "STKeychain.h"

@interface NSString (DQMigrate2xxTo300Additions)

- (NSString *)dq_migrate2xxTo300_stringByRemovingLastPathComponent;

@end

@interface NSMutableString (DQMigrate2xxTo300Additions)

- (void)dq_migrate2xxTo300_appendPathComponent:(NSString *)inPathComponent;

@end

@interface NSFileManager (DQMigrate2xxTo300Additions)

- (NSString *)dq_migrate2xxTo300_applicationSupportPath;
- (BOOL)dq_migrate2xxTo300_recursivelyCreatePath:(NSString *)inPath;

@end

@implementation DQMigrate2xxTo300

- (BOOL)run
{
    [self removePlaybackDatabase];

    return [self migrateQuestsAndCommentUploads];
}

- (void)removePlaybackDatabase
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *appSupportPath = [fm dq_migrate2xxTo300_applicationSupportPath];
    NSString *playbackPath = [[appSupportPath stringByAppendingPathComponent:@"STDataStoreController"] stringByAppendingPathComponent:@"as.canv.drawquest.playback.sqlite"];
    if ([fm fileExistsAtPath:playbackPath])
    {
        [fm removeItemAtPath:playbackPath error:NULL]; // if removing it fails, just let it be
    }
}

- (BOOL)migrateQuestsAndCommentUploads
{
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *appSupportPath = [fm dq_migrate2xxTo300_applicationSupportPath];
    NSString *databasePath2 = [[appSupportPath stringByAppendingPathComponent:@"DQDataStoreController"] stringByAppendingPathComponent:@"DQDataStoreController.sqlite"];
    if (![fm fileExistsAtPath:databasePath2])
    {
        return YES;
    }
    else
    {
        NSURL *storeURL2 = [NSURL fileURLWithPath:databasePath2];
        NSError *error = nil;

        // Build the old stack
        NSManagedObjectModel *model2 = [[self class] managedObjectModelForModel2];
        if (model2)
        {
            NSPersistentStoreCoordinator *psc2  = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model2];
            if (psc2)
            {
                NSDictionary *optionsDictionary = @{NSReadOnlyPersistentStoreOption : @(YES), NSSQLitePragmasOption : @{ @"journal_mode" : @"DELETE" }};
                if ([psc2 addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL2 options:optionsDictionary error:&error])
                {
                    NSManagedObjectContext *ctx2 = [[NSManagedObjectContext alloc] init];
                    [ctx2 setPersistentStoreCoordinator:psc2];

                    NSEntityDescription *qEntity2 = [NSEntityDescription entityForName:@"Quest" inManagedObjectContext:ctx2];
                    NSFetchRequest *qRequest = [[NSFetchRequest alloc] init];
                    [qRequest setEntity:qEntity2];
                    [qRequest setResultType:NSDictionaryResultType];
                    error = nil;
                    NSArray *quests = [ctx2 executeFetchRequest:qRequest error:&error];
                    if (quests)
                    {
                        NSEntityDescription *cuEntity2 = [NSEntityDescription entityForName:@"CommentUpload" inManagedObjectContext:ctx2];
                        NSFetchRequest *cuRequest = [[NSFetchRequest alloc] init];
                        [cuRequest setEntity:cuEntity2];
                        [cuRequest setResultType:NSDictionaryResultType];
                        error = nil;
                        NSArray *commentUploads = [ctx2 executeFetchRequest:cuRequest error:&error];
                        if (commentUploads)
                        {
                            // get rid of references to the old stack so that we can safely delete it later
                            cuRequest = nil;
                            cuEntity2 = nil;
                            qRequest = nil;
                            qEntity2 = nil;
                            ctx2 = nil;
                            psc2 = nil;
                            model2 = nil;

                            // Start building the new stack
                            NSString *yapDatabaseFinalPath = [[fm dq_migrate2xxTo300_applicationSupportPath] stringByAppendingPathComponent:@"DQDataStoreController-collections.sqlite"];
                            NSString *yapDatabaseMigrationPath = [[fm dq_migrate2xxTo300_applicationSupportPath] stringByAppendingPathComponent:@"DQDataStoreController-collections-migration.sqlite"];
                            if ([fm fileExistsAtPath:yapDatabaseMigrationPath])
                            {
                                [fm removeItemAtPath:yapDatabaseMigrationPath error:NULL];
                            }

                            YapCollectionsDatabase *_database = [[YapCollectionsDatabase alloc] initWithPath:yapDatabaseMigrationPath];
                            YapCollectionsDatabaseConnection *_mainConnection = [_database newConnection];


                            NSMutableDictionary *quest2Map = [NSMutableDictionary new];
                            [_mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
                                for (NSDictionary *quest in quests)
                                {
                                    if ([quest[@"serverID"] length])
                                    {
                                        DQQuest *quest2 = [[DQQuest alloc] initWithServerID:quest[@"serverID"] title:quest[@"title"]];
                                        NSMutableDictionary *JSONDictionary = [NSMutableDictionary new];
                                        void (^safeSet)(NSMutableDictionary *, NSString *, NSString *) = ^(NSMutableDictionary *target, NSString *questKey, NSString *JSONKey) {
                                            id o = quest[questKey];
                                            if (o)
                                            {
                                                target[JSONKey] = o;
                                            }
                                        };
                                        safeSet(JSONDictionary, @"serverID", @"id");
                                        safeSet(JSONDictionary, @"timestamp", @"migration_timestamp");
                                        safeSet(JSONDictionary, @"content", @"content");
                                        safeSet(JSONDictionary, @"title", @"title");
                                        safeSet(JSONDictionary, @"drawingCount", @"drawing_count");
                                        safeSet(JSONDictionary, @"authorCount", @"author_count");
                                        safeSet(JSONDictionary, @"commentsURL", @"comments_url");
                                        safeSet(JSONDictionary, @"attributionCopy", @"attribution_copy");
                                        safeSet(JSONDictionary, @"attributionUsername", @"attribution_username");
                                        safeSet(JSONDictionary, @"attributionAvatarUrl", @"migration_avatar_url");

                                        NSMutableDictionary *user = [NSMutableDictionary new];
                                        safeSet(user, @"authorUsername", @"username");
                                        safeSet(user, @"authorAvatarUrl", @"migration_avatar_url");
                                        JSONDictionary[@"user"] = user;
                                        (void)[quest2 initializeWithJSONDictionary:JSONDictionary]; // (void) to suppress warning about not using result
                                        if ([quest[@"completedByUser"] boolValue])
                                        {
                                            [quest2 markCompletedByUser];
                                        }
                                        quest2Map[quest2.serverID] = quest2;
                                        [transaction setObject:quest2 forKey:quest2.yapCollectionKey inCollection:[[quest2 class] yapCollectionName]];
                                    }
                                }
                            }];
                            [_mainConnection readWriteWithBlock:^(YapCollectionsDatabaseReadWriteTransaction *transaction) {
                                for (NSDictionary *cu in commentUploads)
                                {
                                    if ([cu[@"questID"] length])
                                    {
                                        DQQuest *cuQuest = quest2Map[cu[@"questID"]];
                                        if (cuQuest && ((DQCommentUploadStatus)[cu[@"status"] intValue] != DQCommentUploadStatusPublished))
                                        {
                                            DQCommentUpload *cu2 = [[DQCommentUpload alloc] initWithQuestID:cu[@"questID"]
                                                                                                 shareFlags:cu[@"shareFlags"]
                                                                                              facebookToken:cu[@"facebookToken"]
                                                                                               twitterToken:cu[@"twitterToken"]
                                                                                         twitterTokenSecret:cu[@"twitterTokenSecret"]
                                                                    // email wasn't in 1.x
                                                                                                  emailList:nil];
                                            // DQModelObject properties
                                            NSMutableDictionary *JSONDictionary = [NSMutableDictionary new];
                                            void (^safeSet)(NSMutableDictionary *, NSString *, NSString *) = ^(NSMutableDictionary *target, NSString *questKey, NSString *JSONKey) {
                                                id o = cu[questKey];
                                                if (o)
                                                {
                                                    target[JSONKey] = o;
                                                }
                                            };
                                            safeSet(JSONDictionary, @"serverID", @"id");
                                            safeSet(JSONDictionary, @"timestamp", @"migration_timestamp");
                                            safeSet(JSONDictionary, @"content", @"content");
                                            (void)[cu2 initializeWithJSONDictionary:JSONDictionary]; // void to suppress warning about ignoring the result
                                            [cu2 takeIdentifier:cu[@"identifier"]];
                                            [cu2 takeContentID:cu[@"contentID"] status:(DQCommentUploadStatus)[cu[@"status"] intValue]];
                                            // DQCommentUpload properties
                                            [transaction setObject:cu2 forKey:cu2.yapCollectionKey inCollection:[[cu2 class] yapCollectionName]];
                                        }
                                    }
                                }
                            }];
                            // Get rid of the new stack so we can move the database
                            _mainConnection = nil;
                            _database = nil;

                            NSString *movedDatabasePath2 = [databasePath2 stringByAppendingPathExtension:@"backup"];
                            if ([fm fileExistsAtPath:movedDatabasePath2])
                            {
                                [fm removeItemAtPath:movedDatabasePath2 error:NULL];
                            }

                            error = nil;
                            BOOL deleted = [fm removeItemAtURL:storeURL2 error:&error];
                            if (deleted)
                            {
                                error = nil;
                                BOOL moved = [fm moveItemAtPath:yapDatabaseMigrationPath toPath:yapDatabaseFinalPath error:NULL];
                                if (moved)
                                {
                                    return YES;
                                }
                                else
                                {
                                    // what now??? I guess DQDataStoreController will make a new database
                                    // the chances of this happening are slim to none
                                    [self logout];
                                }
                            }
                            else
                            {
                                // what now???
                                // the old database is still there, it should be lightweight migrated
                                // again, this is very unlikely to happen.
                            }
                        }
                        else
                        {
                            // failed to fetch comment uploads. Delete the database
                            // a new one should be created at launch
                            psc2 = nil;
                            model2 = nil;
                            [fm removeItemAtPath:databasePath2 error:NULL];
                            [self logout];
                        }
                    }
                    else
                    {
                        // failed to fetch quests. Delete the database
                        // a new one should be created at launch
                        psc2 = nil;
                        model2 = nil;
                        [fm removeItemAtPath:databasePath2 error:NULL];
                        [self logout];
                    }
                }
                else // the database is buggered. Delete it. a new one should be created at launch
                {
                    psc2 = nil;
                    model2 = nil;
                    [fm removeItemAtPath:databasePath2 error:NULL];
                    [self logout];
                }
            }
            else // the old model is buggered. Delete the database. a new one should be created at launch
            {
                NSLog(@"failed to create a persistent store coordinator for the old model");
                model2 = nil;
                [fm removeItemAtPath:databasePath2 error:NULL];
                [self logout];
            }
        }
        else // the old model is buggered. Delete the database. a new one should be created at launch
        {
            NSLog(@"failed to create a managed model for the old model");
            [fm removeItemAtPath:databasePath2 error:NULL];
            [self logout];
        }
        return NO;
    }
}

// Dirty way to get the managed object model for a particular version. This is needed because nobody thought
// it a wise idea to give the core data model version identifiers since the original version. Now we can't use
// them without obsoleting the DrawQuest model and creating another one. Even in that case, we still have to do
// this below to get a specific version of the DrawQuest model.
+ (NSManagedObjectModel *)managedObjectModelForModel2
{
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"DrawQuest.momd/DrawQuest 2" ofType:@"mom"]];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (void)logout
{
    NSString *accountID = [[NSUserDefaults standardUserDefaults] objectForKey:@"LoggedInAccountID"];
    [STKeychain deleteItemForUsername:accountID andServiceName:@"DrawQuest" error:nil];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LoggedInAccountID"];
	NSMutableDictionary *accountsInfo = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"UserDefaultAccountsInfo"] mutableCopy] ?: [NSMutableDictionary new];
    if (accountID)
    {
        [accountsInfo removeObjectForKey:[accountID lowercaseString]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:accountsInfo forKey:@"UserDefaultAccountsInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

@implementation NSString (DQMigrate2xxTo300Additions)

- (NSString *)dq_migrate2xxTo300_stringByRemovingLastPathComponent
{
    NSArray *pathComponents = [self pathComponents];
    NSMutableString *returnString = [[NSMutableString alloc] init];

    NSString *lastComponent = [pathComponents lastObject];
    for (NSString *currentComponent in pathComponents) {
        if (currentComponent == lastComponent) {
            break;
        }

        [returnString dq_migrate2xxTo300_appendPathComponent:currentComponent];
    }

    return returnString;
}

@end

@implementation NSMutableString (DQMigrate2xxTo300Additions)

- (void)dq_migrate2xxTo300_appendPathComponent:(NSString *)inPathComponent
{
    [self dq_migrate2xxTo300_appendPathComponent:inPathComponent queryString:nil];
}

- (void)dq_migrate2xxTo300_appendPathComponent:(NSString *)inPathComponent queryString:(NSString *)inQueryString
{
    if (!inPathComponent.length) {
        return;
    }

    if ([inPathComponent isEqualToString:@"/"]) {
        [self appendString:inPathComponent];
        return;
    }

    // See if there is already a query string
    NSRange queryRange = [self rangeOfString:@"\?.*" options:NSRegularExpressionSearch];
    if (queryRange.location != NSNotFound) {
        // Remove the existing query string, but cache it
        NSString *foundQueryString = [self substringWithRange:queryRange];
        [self deleteCharactersInRange:queryRange];

        // If the user passed in a new query string, or we
        // have a query string with only a ?, simply lose
        // the existing query string. Otherwise, append it
        // after the
        if (foundQueryString.length > 1 && !inQueryString.length) {
            [self dq_migrate2xxTo300_appendPathComponent:inPathComponent queryString:foundQueryString];
            return;
        }
    }

    if (!self.length || [self hasSuffix:@"/"]) {
        [self appendString:inPathComponent];
    } else {
        [self appendFormat:@"/%@", inPathComponent];
    }

    if (inQueryString.length) {
        [self appendString:inQueryString];
    }
}

@end

@implementation NSFileManager (DQMigrate2xxTo300Additions)

- (NSString *)dq_migrate2xxTo300_applicationSupportPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *rootDirectory = [paths count] ? [paths objectAtIndex:0] : nil;

    if ([rootDirectory length])
    {
        return rootDirectory;
    }
    return nil;
}

- (BOOL)dq_migrate2xxTo300_recursivelyCreatePath:(NSString *)inPath;
{
    return [self dq_migrate2xxTo300_recursivelyCreatePath:inPath lastComponentIsFile:NO];
}

- (BOOL)dq_migrate2xxTo300_recursivelyCreatePath:(NSString *)inPath lastComponentIsFile:(BOOL)isFile;
{
    if ([self fileExistsAtPath:inPath isDirectory:NULL]) {
        return NO;
    }

    NSArray *pathComponents = [inPath pathComponents];
    if (!pathComponents.count || (isFile && pathComponents.count < 2)) {
        return NO;
    }

    NSString *actualPath = isFile ? [inPath dq_migrate2xxTo300_stringByRemovingLastPathComponent] : inPath;
    NSError *error = nil;
    BOOL directoryCreated = [self createDirectoryAtPath:actualPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"Unable to recursively create path due to error: %@", error);
    }
    
    if (!isFile || !directoryCreated) {
        return directoryCreated;
    }
    
    NSFileManager *fm = [NSFileManager new];
    BOOL success = [fm createFileAtPath:inPath contents:nil attributes:nil];
    if (success)
    {
        NSURL *dataURL = [NSURL fileURLWithPath:inPath];
        [dataURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    return success;
}

@end
