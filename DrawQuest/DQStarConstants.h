//
//  DQStarConstants.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DQStarState) {
    DQStarStateIndeterminate = NSNotFound,
    DQStarStateNotStarred = 0,
    DQStarStateStarred = 1
};

typedef void(^DQStarStateResponseBlock)(NSString *commentID, DQStarState state);

extern NSString *const DQStarStateNotificationStateUserInfoKey;

extern NSString *const DQStarStateRequestNotification;
extern NSString *const DQStarStateRequestNotificationResponseBlockUserInfoKey;

extern NSString *const DQUpdateStarStateRequestNotification;
extern NSString *const DQSetStarStateRequestNotification;
extern NSString *const DQStarStateChangedNotification;
extern NSString *const DQStarStateNotificationEventLoggingParametersUserInfoKey;

// if called on the main thread, response block will be called synchronously, otherwise asynchronously using dispatch_async on the main queue
void DQRequestStarState(NSString *commentID, DQStarStateResponseBlock responseBlock);

// returns YES if the process began, NO otherwise
// observe DQStarStateChangedNotification for the result
BOOL DQRequestSetStarState(NSString *commentID, DQStarState state, NSDictionary *eventLoggingParameters);

// updates the local state with this new state from the server
void DQRequestUpdateStarState(NSString *commentID, DQStarState state);
