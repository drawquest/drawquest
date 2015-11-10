//
//  DQCommentPublishController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-08.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "RCSStatechart.h"
#import "DQCommentUploadController.h"
#import "DQCommentPublishViewController.h"
#import "DQAuthenticationConstants.h"

extern NSString *DQCommentPublishErrorDomain;
extern const NSInteger DQCommentPublishMissingFacebookTokenErrorCode;
extern const NSInteger DQCommentPublishMissingTwitterTokenErrorCode;
extern const NSInteger DQCommentPublishFailedCode;

@interface DQCommentPublishControllerStatechart : RCSBaseStatechart

+ (DQCommentPublishControllerStatechart *)statechart;

@end

@class DQPublishAuthViewController;
@class DQAddFriendsViewController;
@class DQCommentPublishController;
@class DQGalleryViewController;
@class DQPhoneDrawViewController;
@class CVSEditorViewController;
@class DQAccountController;
@class DQHTTPRequest;

typedef void(^DQCommentPublishControllerBlock)(DQCommentPublishController *c);
typedef void(^DQCommentPublishControllerFailureBlock)(DQCommentPublishController *c, NSError *error);

@protocol DQCommentPublishControllerDelegate <DQControllerDelegate>

- (void)commentPublishController:(DQCommentPublishController *)publishController
          authenticateFromEditor:(CVSEditorViewController *)editorViewController
       modalNavigationController:(DQNavigationController *)modalNavigationController
                      withOption:(DQAuthenticationOption)option
                        fromView:(UIView *)view
      twitterSheetDismissedBlock:(dispatch_block_t)twitterSheetDismissedBlock
               cancellationBlock:(dispatch_block_t)cancellationBlock
                 completionBlock:(DQAuthenticationCompletionBlock)completionBlock
                    failureBlock:(void (^)(NSError *error))failureBlock;

@end

@interface DQCommentPublishController : DQController <DQCommentPublishViewControllerDataSource, DQCommentPublishViewControllerDelegate>

@property (nonatomic, weak) id<DQCommentPublishControllerDelegate> delegate;
@property (nonatomic, weak) DQCommentPublishControllerStatechart *statechart;
@property (nonatomic, readonly, assign) DQAuthenticationSignupService signupService;
@property (nonatomic, copy) DQNavigationController *(^makeModalNavigationControllerBlock)(DQCommentPublishController *c);
@property (nonatomic, copy) DQPublishAuthViewController *(^makePublishAuthViewControllerBlock)(DQCommentPublishController *c);
@property (nonatomic, copy) DQCommentPublishViewController *(^makePublishViewControllerBlock)(DQCommentPublishController *c);
@property (nonatomic, copy) DQAddFriendsViewController *(^makeAddFriendsViewControllerBlock)(DQCommentPublishController *c);
@property (nonatomic, copy) UIViewController *(^makeNiceJobViewControllerBlock)(DQCommentPublishController *c);
@property (nonatomic, copy) void (^showHomeBlock)(DQCommentPublishController *c, CVSEditorViewController *editorViewController);
@property (nonatomic, copy) void (^showGalleryBlock)(DQCommentPublishController *c, CVSEditorViewController *editorViewController, void (^beforePresentingBlock)(DQGalleryViewController *galleryViewController));
@property (nonatomic, copy) void (^showDrawBlock)(DQCommentPublishController *c, CVSEditorViewController *editorViewController);
@property (nonatomic, readonly, weak) DQAccountController *accountController;
@property (nonatomic, readonly, weak) DQCommentUploadController *commentUploadController;
@property (nonatomic, readonly, assign, getter = isOnboarding) BOOL onboarding;
@property (nonatomic, strong, readonly) NSArray *emailList;

// designated initializer
- (id)initWithDelegate:(id<DQCommentPublishControllerDelegate>)delegate accountController:(DQAccountController *)accountController commentUploadController:(DQCommentUploadController *)commentUploadController;

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:accountController:commentUploadController:);

- (void)presentInModalNavigationController:(DQNavigationController *)modalNavigationController
                   forEditorViewController:(CVSEditorViewController *)editorViewController
                         cancellationBlock:(dispatch_block_t)cancellationBlock
                           completionBlock:(dispatch_block_t)completionBlock
                              failureBlock:(void (^)(NSError *error))failureBlock;

- (NSString *)publishingTitle;

#pragma mark -
#pragma mark For subclasses only

@property (nonatomic, weak) CVSEditorViewController *editorViewController;
@property (nonatomic, strong) DQNavigationController *modalNavigationController;

@property (nonatomic, strong) NSMutableArray *shareFlags;
@property (nonatomic, copy) NSString *facebookAccessToken;
@property (nonatomic, copy) NSString *twitterAccessToken;
@property (nonatomic, copy) NSString *twitterAccessTokenSecret;

- (void)complete;

@end

@interface DQCommentPublishControllerStatechart (Transitions)

- (void)auth:(DQCommentPublishController *)c;
- (void)auth:(DQCommentPublishController *)c withOption:(NSNumber *)option;
- (void)authTwitter:(DQCommentPublishController *)c fromView:(UIView *)sender;

- (void)post:(DQCommentPublishController *)c;

- (void)signedUp:(DQCommentPublishController *)c;
- (void)signedIn:(DQCommentPublishController *)c;

- (void)firstPost:(DQCommentPublishController *)c;

- (void)gallery:(DQCommentPublishController *)c;

- (void)twitterSheetDismissed:(DQCommentPublishController *)c;
- (void)dqCancelTask:(DQCommentPublishController *)c;
- (void)complete:(DQCommentPublishController *)c;
- (void)failed:(DQCommentPublishController *)c error:(NSError *)error;

@end
