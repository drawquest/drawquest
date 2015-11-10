//
//  DQFacebookController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-11.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"

@class DQAccount;

extern NSString *DQFacebookErrorDomain;
extern NSInteger DQFacebookErrorCodeCancelled;

@interface DQFacebookController : DQController

- (void)reset;

- (BOOL)hasOpenFacebookSession;
- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions;
- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
- (NSString *)openFacebookSessionAccessToken;

- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock;
- (void)requestFacebookPublishAccessForFeature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *))failureBlock;

@end
