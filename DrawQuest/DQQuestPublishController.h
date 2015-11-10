//
//  DQQuestPublishController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import "RCSStatechart.h"
#import "DQQuestUploadController.h"
#import "DQSimilarQuestsViewController.h"
#import "DQQuestPublishViewController.h"
#import "DQAuthenticationConstants.h"

extern NSString *DQQuestPublishErrorDomain;
extern const NSInteger DQQuestPublishMissingFacebookTokenErrorCode;
extern const NSInteger DQQuestPublishMissingTwitterTokenErrorCode;
extern const NSInteger DQQuestPublishFailedCode;

@interface DQQuestPublishControllerStatechart : RCSBaseStatechart

+ (DQQuestPublishControllerStatechart *)statechart;

@end

@class DQQuest;
@class DQQuestPublishController;
@class DQGalleryViewController;
@class DQAccountController;

typedef void(^DQQuestPublishControllerBlock)(DQQuestPublishController *c);
typedef void(^DQQuestPublishControllerFailureBlock)(DQQuestPublishController *c, NSError *error);

@interface DQQuestPublishController : DQController <DQQuestPublishViewControllerDelegate>

@property (nonatomic, weak) DQQuestPublishControllerStatechart *statechart;
@property (nonatomic, copy) void (^pushSimilarQuestsViewControllerBlock)(DQQuestPublishController *c, void (^willPresentBlock)(DQSimilarQuestsViewController *vc), void (^didPopBlock)(DQSimilarQuestsViewController *vc));
@property (nonatomic, copy) void (^pushShareQuestViewControllerBlock)(DQQuestPublishController *c, void (^willPresentBlock)(DQQuestPublishViewController *vc), void (^didPopBlock)(DQQuestPublishViewController *vc));
@property (nonatomic, copy) void (^showGalleryBlock)(DQQuestPublishController *c, void (^beforePresentingBlock)(DQGalleryViewController *galleryViewController));
@property (nonatomic, readonly, weak) DQAccountController *accountController;
@property (nonatomic, readonly, strong) DQQuestUpload *questUpload;
@property (nonatomic, readonly, weak) DQQuestUploadController *questUploadController;
@property (nonatomic, readonly, strong) DQQuest *quest;

// designated initializer
- (id)initWithDelegate:(id<DQControllerDelegate>)delegate accountController:(DQAccountController *)accountController questUpload:(DQQuestUpload *)questUpload questUploadController:(DQQuestUploadController *)questUploadController;

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:accountController:questUpload:questUploadController:);

- (void)presentFromViewController:(UIViewController *)presentingViewController
                cancellationBlock:(dispatch_block_t)cancellationBlock
                  completionBlock:(dispatch_block_t)completionBlock
                     failureBlock:(void (^)(NSError *error))failureBlock;

- (void)takeTemplateImage:(UIImage *)templateImage;

#pragma mark -
#pragma mark For subclasses only

@property (nonatomic, weak) UIViewController *presentingViewController;

- (void)complete;

@end

@interface DQQuestPublishControllerStatechart (Transitions)

- (void)auth:(DQQuestPublishController *)c;

- (void)share:(DQQuestPublishController *)c;
- (void)post:(DQQuestPublishController *)c;

- (void)signedIn:(DQQuestPublishController *)c;

- (void)gallery:(DQQuestPublishController *)c;

- (void)backTask:(DQQuestPublishController *)c;

- (void)dqCancelTask:(DQQuestPublishController *)c;
- (void)complete:(DQQuestPublishController *)c;
- (void)failed:(DQQuestPublishController *)c message:(NSString *)message;
- (void)failed:(DQQuestPublishController *)c error:(NSError *)error;

@end
