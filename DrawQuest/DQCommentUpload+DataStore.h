//
//  DQCommentUpload+DataStore.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentUpload.h"
#import "DQModelObject+DataStore.h"

@interface DQCommentUpload (DataStore)

- (instancetype)initWithQuestID:(NSString *)questID
                     shareFlags:(NSArray *)shareFlags
                  facebookToken:(NSString *)facebookToken
                   twitterToken:(NSString *)twitterToken
             twitterTokenSecret:(NSString *)twitterTokenSecret
                      emailList:(NSArray *)emailList;

- (void)takeProgress:(NSNumber *)percentComplete;
- (void)takeIdentifier:(NSString *)identifier;
- (void)takeContentID:(NSString *)contentID status:(DQCommentUploadStatus)status;

- (void)saveFacebookToken:(NSString *)facebookToken inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveTwitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveContentID:(NSString *)contentID inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveStatus:(DQCommentUploadStatus)status inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;

+ (NSArray *)sortedCommentUploadsForQuestWithServerID:(NSString *)questID inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction;

@end
