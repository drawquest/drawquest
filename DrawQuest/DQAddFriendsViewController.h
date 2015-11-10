//
//  DQAddFriendsViewController.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-05-31.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import <MessageUI/MFMailComposeViewController.h>

@class DQAddFriendsViewController;
@class DQFacebookController;
@class DQTwitterController;

typedef void(^DQAddFriendsViewControllerBlock)(DQAddFriendsViewController *c);

@interface DQAddFriendsViewController : DQViewController

@property (nonatomic, copy) void (^inviteEmailBlock)(UIViewController <MFMailComposeViewControllerDelegate> *presentingViewController);

// designated initializer
- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController signupService:(DQAuthenticationSignupService)signupService featureInviteFromFacebook:(BOOL)featureInviteFromFacebook featureInviteFromTwitter:(BOOL)featureInviteFromTwitter;
- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:facebookController:twitterController:signupService:featureInviteFromFacebook:featureInviteFromTwitter:);
- (id)init MSDesignatedInitializer(initWithDelegate:facebookController:twitterController:signupService:featureInviteFromFacebook:featureInviteFromTwitter:);

- (NSUInteger)numberOfInvitesSentOrPending;

- (void)attemptCancel:(void (^)(BOOL cancelled))completionBlock;
- (void)submitWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end
