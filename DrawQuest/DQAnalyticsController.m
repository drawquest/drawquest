//
//  DQAnalyticsController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/19/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQAnalyticsController.h"

#import "DQPublicServiceController.h"
//#import "Flurry.h"

//static NSString * const kDQFlurryAPIKey = @"nope";

@implementation DQAnalyticsController

- (void)startSession
{
//    [Flurry setSecureTransportEnabled:YES];
//    [Flurry startSession:kDQFlurryAPIKey];
}

- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)inParameters
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:inParameters ?: @{}];
    parameters[@"idiom"] = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
//    [Flurry logEvent:event withParameters:parameters];
    [self.publicServiceController requestRecordingForMetricNamed:event info:parameters];
}

@end
