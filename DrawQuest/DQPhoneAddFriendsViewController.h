//
//  DQPhoneAddFriendsViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@class DQAddFriendsViewController;
@class DQFacebookController;
@class DQTwitterController;

@interface DQPhoneAddFriendsViewController : DQViewController

@property (nonatomic, copy) void (^presentActionSheetBlock)(UIActionSheet *sheet);

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController featureInviteFromFacebook:(BOOL)featureInviteFromFacebook featureInviteFromTwitter:(BOOL)featureInviteFromTwitter questID:(NSString *)questID;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:facebookController:twitterController:featureInviteFromFacebook:featureInviteFromTwitter:questID:);

- (void)attemptCancel:(void (^)(BOOL cancelled))completionBlock;
- (NSUInteger)numberOfInvitesSentOrPending;

- (void)submitWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end
