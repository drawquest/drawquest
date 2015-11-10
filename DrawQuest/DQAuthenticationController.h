//
//  DQAuthenticationController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-24.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "RCSStatechart.h"

@class CVSEditorViewController;
@class DQSignInViewController;
@class DQSignUpViewController;
@class DQAlmostThereViewController;
@class DQAddFriendsViewController;
@class DQAuthServiceController;
@class DQNavigationController;

extern NSString *DQHTTPRequestErrorDomain;
extern const NSInteger DQAuthenticationDuplicateRequestIgnoredErrorCode;
extern const NSInteger DQAuthenticationMustBeLoggedInErrorCode;
extern const NSInteger DQAuthenticationInvalidSignUpCredentialsErrorCode;
extern const NSInteger DQAuthenticationInvalidSignInCredentialsErrorCode;
extern const NSInteger DQAuthenticationMissingBlocksErrorCode;

@interface DQAuthenticationControllerStatechart : RCSBaseStatechart

+ (DQAuthenticationControllerStatechart *)statechart;

@end

@class DQAuthenticationController;
@class DQHTTPRequest;

typedef void(^DQAuthenticationControllerBlock)(DQAuthenticationController *c, DQNavigationController *modalNavigationController);
typedef void(^DQAuthenticationControllerCompletionBlock)(DQAuthenticationController *c, DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController);
typedef void(^DQAuthenticationControllerFailureBlock)(DQAuthenticationController *c, NSError *error, DQNavigationController *modalNavigationController);

@class DQFacebookController;
@class DQTwitterController;

@interface DQAuthenticationController : DQController

@property (nonatomic, weak) DQAuthenticationControllerStatechart *statechart;

@property (nonatomic, readonly, assign, getter = isPublishing) BOOL publishing;

@property (nonatomic, copy) DQNavigationController *(^makeModalNavigationControllerBlock)(DQAuthenticationController *c);
@property (nonatomic, copy) DQSignInViewController *(^makeSignInViewControllerBlock)(DQAuthenticationController *c, BOOL publishing);
@property (nonatomic, copy) DQSignUpViewController *(^makeSignUpViewControllerBlock)(DQAuthenticationController *c, BOOL publishing);
@property (nonatomic, copy) NSString *(^titleForSignUpRightBarButtonItem)(DQAuthenticationController *c, BOOL publishing);
@property (nonatomic, copy) NSString *(^titleForSignInRightBarButtonItem)(DQAuthenticationController *c, BOOL publishing);
@property (nonatomic, copy) DQAlmostThereViewController *(^makeAlmostThereViewControllerBlock)(DQAuthenticationController *c, BOOL publishing);
@property (nonatomic, copy) DQAddFriendsViewController *(^makeAddFriendsViewControllerBlock)(DQAuthenticationController *c, DQAuthenticationSignupService signupService);
@property (nonatomic, copy) void (^signedUpBlock)(DQAuthenticationSignupService signupService);

// designated initializer
- (id)initWithDelegate:(id<DQControllerDelegate>)delegate authServiceController:(DQAuthServiceController*)authServiceController;

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:);
- (id)init MSDesignatedInitializer(initWithDelegate:facebookController:twitterController:);

- (void)startSignInFromView:(UIView *)sender
         fromViewController:(UIViewController *)presentingViewController
  modalNavigationController:(DQNavigationController *)modalNavigationController
                 publishing:(BOOL)isPublishing
 twitterSheetDismissedBlock:(DQAuthenticationControllerBlock)twitterSheetDismissedBlock
          cancellationBlock:(DQAuthenticationControllerBlock)cancellationBlock
            completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock
               failureBlock:(DQAuthenticationControllerFailureBlock)failureBlock;

- (void)startSignUpFromView:(UIView *)sender
         fromViewController:(UIViewController *)presentingViewController
  modalNavigationController:(DQNavigationController *)modalNavigationController
                 withOption:(DQAuthenticationOption)option
                 publishing:(BOOL)isPublishing
 twitterSheetDismissedBlock:(DQAuthenticationControllerBlock)twitterSheetDismissedBlock
          cancellationBlock:(DQAuthenticationControllerBlock)cancellationBlock
            completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock
               failureBlock:(DQAuthenticationControllerFailureBlock)failureBlock;

@end
