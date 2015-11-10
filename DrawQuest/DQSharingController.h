//
//  DQSharingController.h
//  DrawQuest
//
//  Created by David Mauro on 10/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"

// Models
#import "DQComment.h"
#import "DQQuest.h"

// Controllers
#import "DQController.h"
#import "DQNavigationController.h"
#import "STHTTPResourceController.h"

@interface DQSharingController : DQController

@property (nonatomic, weak) STHTTPResourceController *imageController;

@property (nonatomic, strong) NSString *tumblrSuccessRegexPattern;
@property (nonatomic, copy) DQNavigationController *(^makeNavigationControllerBlock)(DQSharingController *c, UIViewController *rootViewController);
@property (nonatomic, copy) DQController *(^makeControllerBlock)(DQSharingController *c);

- (void)showSharingSheetForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;
- (void)showSharingSheetForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;

- (void)showFacebookShareForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;
- (void)showTwitterShareForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;
- (void)showTumblrShareForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;

// change
- (void)showFacebookShareForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;
- (void)showTwitterShareForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;
- (void)showTumblrShareForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source;

@end

@interface DQShareMessageProvider : UIActivityItemProvider

@property (nonatomic, copy) NSString *commentID;
@property (nonatomic, copy) NSString *questID;
@property (nonatomic, copy) NSString *questTitle;
@property (nonatomic, copy) NSString *shareSubject;

- (id)initWithPublicServiceController:(DQPublicServiceController *)publicServiceController;
- (id)initWithPlaceholderItem:(id)placeholderItem MSDesignatedInitializer(initWithMessage:publicServiceController:);

@end

@interface DQShareImageProvider : UIActivityItemProvider

@property (nonatomic, copy) NSString *shareSubject;
@property (nonatomic, weak) STHTTPResourceController *imageController;

- (id)initWithImageURL:(NSString *)imageURL imageController:(STHTTPResourceController *)imageController;
- (id)initWithPlaceholderItem:(id)placeholderItem MSDesignatedInitializer(initWithImageURL:imageController:);

@end
