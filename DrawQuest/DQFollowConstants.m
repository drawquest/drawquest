//
//  DQFollowConstants.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFollowConstants.h"

NSString *const DQFollowStateRequestNotification = @"DQFollowStateRequestNotification";
NSString *const DQFollowStateRequestNotificationResponseBlockUserInfoKey = @"DQFollowStateRequestNotificationResponseBlockUserInfoKey";

NSString *const DQSetFollowStateRequestNotification = @"DQSetFollowStateRequestNotification";

NSString *const DQUpdateFollowStateRequestNotification = @"DQUpdateFollowStateRequestNotification";
NSString *const DQFollowStateChangedNotification = @"DQFollowStateChangedNotification";
NSString *const DQFollowStateNotificationStateUserInfoKey = @"DQFollowStateNotificationStateUserInfoKey";

NSString *const DQUpdateManyFollowStatesRequestNotification = @"DQUpdateManyFollowStatesRequestNotification";
NSString *const DQFollowStateNotificationManyStatesUserInfoKey = @"DQFollowStateNotificationManyStatesUserInfoKey";

void DQRequestFollowState(NSString *username, DQFollowStateResponseBlock responseBlock)
{
    NSDictionary *userInfo = responseBlock ? @{DQFollowStateRequestNotificationResponseBlockUserInfoKey: [responseBlock copy]} : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:DQFollowStateRequestNotification
                                                        object:username
                                                      userInfo:userInfo];
}

BOOL DQRequestSetFollowState(NSString *username, DQFollowState state)
{
    if ([username length])
    {
        NSDictionary *userInfo = @{DQFollowStateNotificationStateUserInfoKey: @(state)};
        [[NSNotificationCenter defaultCenter] postNotificationName:DQSetFollowStateRequestNotification
                                                            object:username
                                                          userInfo:userInfo];
        return YES;
    }
    return NO;
}

void DQRequestUpdateFollowState(NSString *username, DQFollowState state)
{
    if ([username length])
    {
        NSDictionary *userInfo = @{DQFollowStateNotificationStateUserInfoKey: @(state)};
        [[NSNotificationCenter defaultCenter] postNotificationName:DQUpdateFollowStateRequestNotification
                                                            object:username
                                                          userInfo:userInfo];
    }
}

void DQRequestUpdateFollowStatesFromDictionary(NSDictionary *updates)
{
    if ([updates count])
    {
        NSDictionary *userInfo = @{DQFollowStateNotificationManyStatesUserInfoKey: updates};
        [[NSNotificationCenter defaultCenter] postNotificationName:DQUpdateManyFollowStatesRequestNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
}
