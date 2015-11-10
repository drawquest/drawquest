//
//  DQQuestUpload+DataStore.h
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestUpload.h"
#import "DQModelObject+DataStore.h"

@interface DQQuestUpload (DataStore)

- (instancetype)init;

- (void)takeProgress:(NSNumber *)percentComplete;
- (void)saveFacebookToken:(NSString *)facebookToken inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveFacebookToken:(NSString *)facebookToken twitterToken:(NSString *)twitterToken twitterTokenSecret:(NSString *)twitterTokenSecret inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveContentID:(NSString *)contentID inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveStatus:(DQQuestUploadStatus)status withError:(NSError *)error inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveShareToFacebook:(BOOL)shareToFacebook inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveShareToTwitter:(BOOL)shareToTwitter inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveEmailList:(NSArray *)emailList inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)saveTitle:(NSString *)title inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;

+ (NSArray *)sortedQuestUploadsInTransaction:(YapCollectionsDatabaseReadTransaction *)transaction;

@end
