//
//  DQFollowConstants.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DQFollowState) {
    DQFollowStateIndeterminate = NSNotFound,
    DQFollowStateNotFollowing = 0,
    DQFollowStateFollowing = 1
};

typedef void(^DQFollowStateResponseBlock)(NSString *username, DQFollowState state);

extern NSString *const DQFollowStateNotificationStateUserInfoKey;

extern NSString *const DQFollowStateRequestNotification;
extern NSString *const DQFollowStateRequestNotificationResponseBlockUserInfoKey;

extern NSString *const DQUpdateFollowStateRequestNotification;
extern NSString *const DQSetFollowStateRequestNotification;
extern NSString *const DQFollowStateChangedNotification;

extern NSString *const DQUpdateManyFollowStatesRequestNotification;
extern NSString *const DQFollowStateNotificationManyStatesUserInfoKey;

// if called on the main thread, response block will be called synchronously, otherwise asynchronously using dispatch_async on the main queue
void DQRequestFollowState(NSString *username, DQFollowStateResponseBlock responseBlock);

// returns YES if the process began, NO otherwise
// observe DQFollowStateChangedNotification for the result
BOOL DQRequestSetFollowState(NSString *username, DQFollowState state);

// updates the local state with this new state from the server
void DQRequestUpdateFollowState(NSString *username, DQFollowState state);

// updates the local state with many usernames/states
void DQRequestUpdateFollowStatesFromDictionary(NSDictionary *updates);
