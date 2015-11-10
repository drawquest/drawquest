//
//  DQController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-21.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import <objc/runtime.h>
#import "DQDataStoreController.h"
#import "UIFont+DQAdditions.h"

@implementation DQController

@dynamic dataStoreController;
@dynamic publicServiceController;
@dynamic privateServiceController;

- (void)dealloc
{
    _delegate = nil;
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

- (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

+ (id)settingForKey:(NSString *)key fallbackKey:(NSString *)fallbackKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:fallbackKey];
}

- (void)tellUserAboutFailureWithTitle:(NSString *)title forError:(NSError *)error
{
    NSString *message = error.dq_displayDescription;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [alertView show];
}

- (void)tellUserAboutFailureWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [alertView show];
}

- (UIBarButtonItem *)newBarButtonItemWithTitle:(NSString *)title action:(SEL)action isPrimaryAction:(BOOL)isPrimaryAction
{
    return [self newBarButtonItemWithTitle:title target:self action:action isPrimaryAction:isPrimaryAction];
}

- (UIBarButtonItem *)newPadBarButtonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action isPrimaryAction:(BOOL)isPrimaryAction
{
    DQButton *button = [DQButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont dq_modalBarButtonItemTitleFont];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.shadowColor = [UIColor clearColor];
    button.titleLabel.shadowOffset = CGSizeZero;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    button.frameHeight = button.frameHeight + 2.0f;

    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *result = [[UIBarButtonItem alloc] initWithCustomView:button];
    return result;
}

- (UIBarButtonItem *)newPhoneBarButtonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action isPrimaryAction:(BOOL)isPrimaryAction
{
    UIBarButtonItem *result = [[UIBarButtonItem alloc] initWithTitle:title
                                                               style:(isPrimaryAction ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain)
                                                              target:target
                                                              action:action];
    [result setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [UIFont fontWithName:@"ArialRoundedMTBold" size:18.0f]} forState:UIControlStateNormal];
    return result;
}

- (UIBarButtonItem *)newPhoneBarButtonItemWithImageNamed:(NSString *)imageName buttonBlock:(DQButtonBlock)buttonBlock
{
    DQButton *button = [DQButton buttonWithImage:[UIImage imageNamed:imageName]];
    button.tappedBlock = buttonBlock;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    return item;
}

- (UIBarButtonItem *)newBarButtonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action isPrimaryAction:(BOOL)isPrimaryAction
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return [self newPadBarButtonItemWithTitle:title target:target action:action isPrimaryAction:isPrimaryAction];
    }
    else
    {
        return [self newPhoneBarButtonItemWithTitle:title target:target action:action isPrimaryAction:isPrimaryAction];
    }
}

- (UIBarButtonItem *)newBarButtonItemWithTitle:(NSString *)title isPrimaryAction:(BOOL)isPrimaryAction block:(DQBlockActionTargetSenderBlock)block
{
    DQBlockActionTarget *target = [[DQBlockActionTarget alloc] initWithSenderBlock:block];
    UIBarButtonItem *result = [self newBarButtonItemWithTitle:title target:target action:target.actionSelector isPrimaryAction:isPrimaryAction];
    objc_setAssociatedObject(result, kDQBlockActionTargetTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}

- (UIBarButtonItem *)newCancelBarButtonItemWithAction:(SEL)action
{
    return [self newBarButtonItemWithTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") action:action isPrimaryAction:NO];
}

- (UIBarButtonItem *)newCancelBarButtonItemWithTarget:(id)target action:(SEL)action
{
    return [self newBarButtonItemWithTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") target:target action:action isPrimaryAction:NO];
}

- (UIBarButtonItem *)newCancelBarButtonItemWithBlock:(DQBlockActionTargetSenderBlock)block
{
    return [self newBarButtonItemWithTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") isPrimaryAction:NO block:block];
}

- (UIBarButtonItem *)newDoneBarButtonItemWithAction:(SEL)action
{
    return [self newBarButtonItemWithTitle:DQLocalizedString(@"Done", @"User is done with this action button title") action:action isPrimaryAction:YES];
}

- (UIBarButtonItem *)newDoneBarButtonItemWithTarget:(id)target action:(SEL)action
{
    return [self newBarButtonItemWithTitle:DQLocalizedString(@"Done", @"User is done with this action button title") target:target action:action isPrimaryAction:YES];
}

- (UIBarButtonItem *)newDoneBarButtonItemWithBlock:(DQBlockActionTargetSenderBlock)block
{
    return [self newBarButtonItemWithTitle:DQLocalizedString(@"Done", @"User is done with this action button title") isPrimaryAction:YES block:block];
}

- (UIBarButtonItem *)newNextBarButtonItemWithAction:(SEL)action
{
    return [self newBarButtonItemWithTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") action:action isPrimaryAction:YES];
}

- (UIBarButtonItem *)newNextBarButtonItemWithTarget:(id)target action:(SEL)action
{
    return [self newBarButtonItemWithTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") target:target action:action isPrimaryAction:YES];
}

- (UIBarButtonItem *)newNextBarButtonItemWithBlock:(DQBlockActionTargetSenderBlock)block
{
    return [self newBarButtonItemWithTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") isPrimaryAction:YES block:block];
}

- (DQDataStoreController *)dataStoreController
{
    return [self.delegate dataStoreControllerForController:self];
}

- (DQPublicServiceController *)publicServiceController
{
    return [self.delegate publicServiceControllerForController:self];
}

- (DQPrivateServiceController *)privateServiceController
{
    return [self.delegate privateServiceControllerForController:self];
}

- (DQFacebookController *)facebookController
{
    return [self.delegate facebookControllerForController:self];
}

- (DQTwitterController *)twitterController
{
    return [self.delegate twitterControllerForController:self];
}

- (BOOL)isLoggedIn
{
    return [self.delegate isLoggedInForController:self];
}

- (BOOL)hasUserEverLoggedIn
{
    return [self.delegate hasUserEverLoggedInForController:self];
}

- (DQAccount *)loggedInAccount
{
    return [self.delegate loggedInAccountForController:self];
}

- (void)requestAuthenticationFromViewController:(UIViewController *)vc withCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(DQAuthenticationCompletionBlock)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate authenticatedForController:self fromViewController:vc cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookAccessForFeature:(NSString *)feature readPermissions:(NSArray *)readPermissions publishPermissions:(NSArray *)publishPermissions cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate facebookAccessGrantedForController:self feature:feature readPermissions:readPermissions publishPermissions:publishPermissions cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestFacebookPublishAccessFromViewController:(UIViewController *)vc feature:(NSString *)feature cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(void (^)(NSString *facebookToken))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate facebookPublishAccessGrantedForController:self feature:feature cancellationBlock:cancellationBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)requestTwitterAccessInView:(UIView *)view fromViewController:(UIViewController *)vc withCancellationBlock:(dispatch_block_t)cancellationBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate twitterAccessGrantedForController:self inView:view fromViewController:vc cancellationBlock:cancellationBlock accountSelectedBlock:accountSelectedBlock completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters
{
    [self.delegate controller:self logEvent:event withParameters:parameters];
}

- (BOOL)hasOpenFacebookSession
{
    return [self.delegate hasOpenFacebookSessionForController:self];
}

- (BOOL)hasOpenFacebookSessionWithPermissions:(NSArray *)permissions
{
    return [self.delegate controller:self hasOpenFacebookSessionWithPermissions:permissions];
}

- (NSArray *)openFacebookSessionPermissionsMissingFromPermissions:(NSArray *)permissions;
{
    return [self.delegate controller:self openFacebookSessionPermissionsMissingFromPermissions:permissions];
}

- (NSString *)openFacebookSessionAccessToken
{
    return [self.delegate openFacebookSessionAccessTokenForController:self];
}

- (void)hasTwitterAccess:(void (^)(BOOL result))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate hasTwitterAccessForController:self resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)requestDataForTwitterAccountWithURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(SLRequestMethod)method resultBlock:(void (^)(NSData *responseData, NSHTTPURLResponse *urlResponse))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    [self.delegate dataForTwitterAccountForController:self withURL:url parameters:parameters method:method resultBlock:resultBlock failureBlock:failureBlock];
}

@end
