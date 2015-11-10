//
//  DQController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-21.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Social/SLRequest.h>
#import "DQAuthenticationConstants.h"
#import "DQBlockActionTarget.h"
#import "DQButton.h"

@class DQDataStoreController;
@class DQPublicServiceController;
@class DQPrivateServiceController;
@class DQFacebookController;
@class DQTwitterController;
@class DQAccount;

@protocol DQControllerDelegate;

@interface DQController : NSObject

@property (nonatomic, weak) id<DQControllerDelegate> delegate;
@property (nonatomic, readonly, strong) DQDataStoreController *dataStoreController;
@property (nonatomic, readonly, strong) DQPublicServiceController *publicServiceController;
@property (nonatomic, readonly, strong) DQPrivateServiceController *privateServiceController;
@property (nonatomic, readonly, strong) DQFacebookController *facebookController;
@property (nonatomic, readonly, strong) DQTwitterController *twitterController;
@property (nonatomic, readonly, assign, getter = isLoggedIn) BOOL loggedIn;
@property (nonatomic, readonly, assign) BOOL hasUserEverLoggedIn;
@property (nonatomic, readonly, strong) DQAccount *loggedInAccount;

// designated initializer
- (id)initWithDelegate:(id<DQControllerDelegate>)delegate;
- (id)init MSDesignatedInitializer(initWithDelegate:);

+ (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey;
- (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey;

- (void)tellUserAboutFailureWithTitle:(NSString *)title forError:(NSError *)error;
- (void)tellUserAboutFailureWithTitle:(NSString *)title message:(NSString *)message;

- (UIBarButtonItem *)newBarButtonItemWithTitle:(NSString *)title action:(SEL)action isPrimaryAction:(BOOL)isPrimaryAction;
- (UIBarButtonItem *)newBarButtonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action isPrimaryAction:(BOOL)isPrimaryAction;
- (UIBarButtonItem *)newBarButtonItemWithTitle:(NSString *)title isPrimaryAction:(BOOL)isPrimaryAction block:(DQBlockActionTargetSenderBlock)block;

- (UIBarButtonItem *)newCancelBarButtonItemWithAction:(SEL)action;
- (UIBarButtonItem *)newCancelBarButtonItemWithTarget:(id)target action:(SEL)action;
- (UIBarButtonItem *)newCancelBarButtonItemWithBlock:(DQBlockActionTargetSenderBlock)block;

- (UIBarButtonItem *)newDoneBarButtonItemWithAction:(SEL)action;
- (UIBarButtonItem *)newDoneBarButtonItemWithTarget:(id)target action:(SEL)action;
- (UIBarButtonItem *)newDoneBarButtonItemWithBlock:(DQBlockActionTargetSenderBlock)block;

- (UIBarButtonItem *)newNextBarButtonItemWithAction:(SEL)action;
- (UIBarButtonItem *)newNextBarButtonItemWithTarget:(id)target action:(SEL)action;
- (UIBarButtonItem *)newNextBarButtonItemWithBlock:(DQBlockActionTargetSenderBlock)block;

- (UIBarButtonItem *)newPhoneBarButtonItemWithImageNamed:(NSString *)imageName buttonBlock:(DQButtonBlock)buttonBlock;

- (void)requestAuthenticationFromViewController:(UIViewController *)vc withCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestFacebookPublishAccessFromViewController:(UIViewController *)vc feature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestTwitterAccessInView:(UIView *)view fromViewController:(UIViewController *)vc withCancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;

- (BOOL)hasOpenFacebookSession;
- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions;
- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
- (NSString *)openFacebookSessionAccessToken;

- (void)hasTwitterAccess:(void (^)(BOOL result))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)requestDataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end

@protocol DQControllerDelegate <NSObject>

- (DQDataStoreController *)dataStoreControllerForController:(DQController *)c;
- (DQPublicServiceController *)publicServiceControllerForController:(DQController *)c;
- (DQPrivateServiceController *)privateServiceControllerForController:(DQController *)c;
- (DQFacebookController *)facebookControllerForController:(DQController *)c;
- (DQTwitterController *)twitterControllerForController:(DQController *)c;
- (BOOL)isLoggedInForController:(DQController *)c;
- (BOOL)hasUserEverLoggedInForController:(DQController *)c;
- (DQAccount *)loggedInAccountForController:(DQController *)c;
- (void)authenticatedForController:(DQController *)c fromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)facebookAccessGrantedForController:(DQController *)c feature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)facebookPublishAccessGrantedForController:(DQController *)c feature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)twitterAccessGrantedForController:(DQController *)c inView:(UIView *)view fromViewController:(UIViewController *)vc cancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)controller:(DQController *)c logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;
- (BOOL)hasOpenFacebookSessionForController:(DQController *)c;
- (BOOL)controller:(DQController *)c hasOpenFacebookSessionWithPermissions:(NSArray *)permissions;
- (NSArray *)controller:(DQController *)c openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
- (NSString *)openFacebookSessionAccessTokenForController:(DQController *)c;
- (void)hasTwitterAccessForController:(DQController *)c resultBlock:(void (^)(BOOL result))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;
- (void)dataForTwitterAccountForController:(DQController *)c withURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end
