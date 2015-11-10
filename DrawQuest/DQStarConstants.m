//
//  DQStarConstants.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQStarConstants.h"

NSString *const DQStarStateRequestNotification = @"DQStarStateRequestNotification";
NSString *const DQStarStateRequestNotificationResponseBlockUserInfoKey = @"DQStarStateRequestNotificationResponseBlockUserInfoKey";

NSString *const DQSetStarStateRequestNotification = @"DQSetStarStateRequestNotification";

NSString *const DQUpdateStarStateRequestNotification = @"DQUpdateStarStateRequestNotification";
NSString *const DQStarStateChangedNotification = @"DQStarStateChangedNotification";
NSString *const DQStarStateNotificationStateUserInfoKey = @"DQStarStateNotificationStateUserInfoKey";
NSString *const DQStarStateNotificationEventLoggingParametersUserInfoKey = @"DQStarStateNotificationEventLoggingParametersUserInfoKey";

void DQRequestStarState(NSString *commentID, DQStarStateResponseBlock responseBlock)
{
    NSDictionary *userInfo = responseBlock ? @{DQStarStateRequestNotificationResponseBlockUserInfoKey: [responseBlock copy]} : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:DQStarStateRequestNotification
                                                        object:commentID
                                                      userInfo:userInfo];
}

BOOL DQRequestSetStarState(NSString *commentID, DQStarState state, NSDictionary *eventLoggingParameters)
{
    if ([commentID length])
    {
        NSDictionary *userInfo = (eventLoggingParameters ?
                                  @{DQStarStateNotificationStateUserInfoKey: @(state), DQStarStateNotificationEventLoggingParametersUserInfoKey: eventLoggingParameters} :
                                  @{DQStarStateNotificationStateUserInfoKey: @(state)});
        [[NSNotificationCenter defaultCenter] postNotificationName:DQSetStarStateRequestNotification
                                                            object:commentID
                                                          userInfo:userInfo];
        return YES;
    }
    return NO;
}

void DQRequestUpdateStarState(NSString *commentID, DQStarState state)
{
    if ([commentID length])
    {
        NSDictionary *userInfo = @{DQStarStateNotificationStateUserInfoKey: @(state)};
        [[NSNotificationCenter defaultCenter] postNotificationName:DQUpdateStarStateRequestNotification
                                                            object:commentID
                                                          userInfo:userInfo];
    }
}
