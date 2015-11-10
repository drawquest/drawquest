//
//  DQUser+DataStore.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQUser.h"
#import "YapCollectionsDatabaseTransaction.h"

@interface DQUser (DataStore)

- (instancetype)initWithUserName:(NSString *)userName;

- (void)saveCoinCount:(NSNumber *)coinCount inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;

- (void)setIsFollowing:(BOOL)isFollowing inTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;

@end
