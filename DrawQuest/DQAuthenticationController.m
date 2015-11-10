//
//  DQAuthenticationController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-24.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAuthenticationController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "DQAnalyticsConstants.h"
#import "DQAuthServiceController.h"
#import "DQDataStoreController.h"
#import "DQFacebookController.h"
#import "DQTwitterController.h"
#import "DQSignInViewController.h"
#import "DQSignUpViewController.h"
#import "DQAlmostThereViewController.h"
#import "DQAddFriendsViewController.h"
#import "DQNavigationController.h"
#import "DQHUDView.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAbstractAuthViewController+TemplateMethods.h"
#import "DQPapertrailLogger.h"

NSString *DQAuthenticationErrorDomain = @"DQAuthenticationErrorDomain";
const NSInteger DQAuthenticationDuplicateRequestIgnoredErrorCode = 1000;
const NSInteger DQAuthenticationMustBeLoggedInErrorCode = 1001;
const NSInteger DQAuthenticationInvalidSignUpCredentialsErrorCode = 1002;
const NSInteger DQAuthenticationInvalidSignInCredentialsErrorCode = 1003;
const NSInteger DQAuthenticationMissingBlocksErrorCode = 1004;

@interface DQAuthenticationControllerStatechart (Transitions)

- (void)presentSignIn:(DQAuthenticationController *)c;
- (void)presentSignUp:(DQAuthenticationController *)c;
- (void)presentPublish:(DQAuthenticationController *)c;

- (void)auth:(DQAuthenticationController *)c fromViewController:(UIViewController *)vc;
- (void)facebook:(DQAuthenticationController *)c;
- (void)facebook:(DQAuthenticationController *)c permissions:(NSDictionary *)permissions;
- (void)twitter:(DQAuthenticationController *)c inView:(UIView *)view;
- (void)userNotFound:(DQAuthenticationController *)c;
- (void)addFriends:(DQAuthenticationController *)c fromService:(NSNumber *)signupService;
- (void)cancelAddFriends:(DQAuthenticationController *)c fromService:(NSNumber *)signupService;

- (void)twitterSheetDismissed:(DQAuthenticationController *)c;
- (void)dqCancelTask:(DQAuthenticationController *)c;
- (void)complete:(DQAuthenticationController *)c fromService:(NSNumber *)signupService;
- (void)failed:(DQAuthenticationController *)c error:(NSError *)error;

@end

@interface DQAuthenticationController () <RCSStatechartContext>

@property (nonatomic, strong) NSMutableArray *statechartStack;
@property (nonatomic, strong) DQAuthServiceController *authServiceController;
@property (nonatomic, weak) DQFacebookController *facebookController;
@property (nonatomic, weak) DQTwitterController *twitterController;

@property (nonatomic, strong) UIViewController *presentingViewController;
@property (nonatomic, copy) DQAuthenticationControllerBlock twitterSheetDismissedBlock;
@property (nonatomic, copy) DQAuthenticationControllerBlock cancellationBlock;
@property (nonatomic, copy) DQAuthenticationControllerCompletionBlock completionBlock;
@property (nonatomic, copy) DQAuthenticationControllerFailureBlock failureBlock;
@property (nonatomic, strong) DQNavigationController *modalNavigationController;
@property (nonatomic, assign) BOOL modalNavigationControllerWasProvided;

@property (nonatomic, assign, getter = isPublishing) BOOL publishing; // ugh
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *email;

@end

@implementation DQAuthenticationController

@dynamic delegate;

+ (void)initialize
{
    if (self == [DQAuthenticationController class])
    {
        id<RCSStatechart> Base                              = [DQAuthenticationControllerStatechart statechart];
        id<RCSStatechart> Error                             = [Base statechartNamed:@"Error"];
        id<RCSStatechart> Start                             = [Base statechartNamed:@"Start"];

        id<RCSStatechart> PresentingSignIn                  = [Base statechartNamed:@"PresentingSignIn"];
        id<RCSStatechart> PresentingSignUp                  = [Base statechartNamed:@"PresentingSignUp"];
        id<RCSStatechart> SigningInWithDrawQuest            = [Base statechartNamed:@"SigningInWithDrawQuest"];
        id<RCSStatechart> SigningUpWithDrawQuest            = [Base statechartNamed:@"SigningUpWithDrawQuest"];
        id<RCSStatechart> SigningUpWithFacebook             = [Base statechartNamed:@"SigningUpWithFacebook"];
        id<RCSStatechart> SigningUpWithTwitter              = [Base statechartNamed:@"SigningUpWithTwitter"];
        id<RCSStatechart> SignUpFailed                      = [Base statechartNamed:@"SignUpFailed"];
        id<RCSStatechart> AttemptingSignInWithFacebook      = [Base statechartNamed:@"AttemptingSignInWithFacebook"];
        id<RCSStatechart> AttemptingSignInWithTwitter       = [Base statechartNamed:@"AttemptingSignInWithTwitter"];
        id<RCSStatechart> PresentingAlmostThereFacebook     = [Base statechartNamed:@"PresentingAlmostThereFacebook"];
        id<RCSStatechart> PresentingAlmostThereTwitter      = [Base statechartNamed:@"PresentingAlmostThereTwitter"];
        id<RCSStatechart> SigningUpWithDrawQuestAndFacebook = [Base statechartNamed:@"SigningUpWithDrawQuestAndFacebook"];
        id<RCSStatechart> SigningUpWithDrawQuestAndTwitter  = [Base statechartNamed:@"SigningUpWithDrawQuestAndTwitter"];

        id<RCSStatechart> PresentingAddFriends              = [Base statechartNamed:@"PresentingAddFriends"];

        id<RCSStatechart> Cancelled                         = [Base statechartNamed:@"Cancelled"];
        id<RCSStatechart> Complete                          = [Base statechartNamed:@"Complete"];

        SEL presentSignIn            = [Base transitionToErrorStatechartWhen:@selector(presentSignIn:)];
        SEL presentSignUp            = [Base transitionToErrorStatechartWhen:@selector(presentSignUp:)];
        SEL authFromViewController   = [Base transitionToErrorStatechartWhen:@selector(auth:fromViewController:)];
        SEL facebook                 = [Base transitionToErrorStatechartWhen:@selector(facebook:)];
        SEL twitterInView            = [Base transitionToErrorStatechartWhen:@selector(twitter:inView:)];
        SEL userNotFound             = [Base transitionToErrorStatechartWhen:@selector(userNotFound:)];
        SEL twitterSheetDismissed    = [Base transitionToErrorStatechartWhen:@selector(twitterSheetDismissed:)];
        SEL cancel                   = [Base transitionToErrorStatechartWhen:@selector(dqCancelTask:)];
        SEL addFriends               = [Base transitionToErrorStatechartWhen:@selector(addFriends:fromService:)];
        SEL cancelAddFriends         = [Base transitionToErrorStatechartWhen:@selector(cancelAddFriends:fromService:)];
        SEL complete                 = [Base transitionToErrorStatechartWhen:@selector(complete:fromService:)];
        SEL failedError              = [Base transitionToErrorStatechartWhen:@selector(failed:error:)];

        [Base declareErrorStatechart:Error];
        [Base declareStartStatechart:Start];

        [Start when:failedError transitionTo:Cancelled after:@selector(_startFailedWithError:)];
        [Start when:presentSignIn transitionTo:PresentingSignIn before:@selector(_presentSignIn)];
        [Start when:presentSignUp transitionTo:PresentingSignUp before:@selector(_presentSignUp)];
        [Start when:facebook transitionTo:SigningUpWithFacebook before:@selector(_signUpWithFacebook)];
        [Start when:twitterInView transitionTo:SigningUpWithTwitter before:@selector(_signUpWithTwitterInView:)];
        [Start when:complete transitionTo:Complete before:@selector(_complete:)];

        [PresentingSignIn when:cancel transitionTo:Cancelled before:@selector(_cancel)];
        [PresentingSignIn when:facebook push:AttemptingSignInWithFacebook before:@selector(_attemptSignInWithFacebook)];
        [PresentingSignIn when:twitterInView push:AttemptingSignInWithTwitter before:@selector(_attemptSignInWithTwitterInView:)];
        [PresentingSignIn when:authFromViewController push:SigningInWithDrawQuest before:@selector(_signInFromViewController:)];
        [PresentingSignIn when:presentSignUp transitionTo:PresentingSignUp before:@selector(_presentSignUp)];

        [PresentingSignUp when:cancel transitionTo:Cancelled before:@selector(_cancel)];
        [PresentingSignUp when:facebook push:AttemptingSignInWithFacebook before:@selector(_attemptSignInWithFacebook)];
        [PresentingSignUp when:twitterInView push:AttemptingSignInWithTwitter before:@selector(_attemptSignInWithTwitterInView:)];
        [PresentingSignUp when:presentSignIn transitionTo:PresentingSignIn before:@selector(_presentSignIn)];
        [PresentingSignUp when:authFromViewController push:SigningUpWithDrawQuest before:@selector(_signUpWithDrawQuestFromViewController:)];

        [SigningInWithDrawQuest popWhen:failedError after:@selector(_signInFailedWithError:)];
        [SigningInWithDrawQuest when:complete transitionTo:Complete before:@selector(_complete:)];

        [SigningUpWithDrawQuest popWhen:failedError after:@selector(_signUpWithDrawQuestFailedWithError:)];
        [SigningUpWithDrawQuest when:complete transitionTo:Complete before:@selector(_complete:)];
        [SigningUpWithDrawQuest when:addFriends transitionTo:PresentingAddFriends before:@selector(_presentAddFriends:)];

        [SigningUpWithFacebook when:cancel transitionTo:Cancelled before:@selector(_cancel)];
        [SigningUpWithFacebook when:failedError transitionTo:SignUpFailed before:@selector(_signUpWithFacebookFailedWithError:)];
        [SigningUpWithFacebook when:complete transitionTo:Complete before:@selector(_complete:)];
        [SigningUpWithFacebook when:userNotFound transitionTo:PresentingAlmostThereFacebook before:@selector(_presentAlmostThere)];

        [SigningUpWithTwitter when:twitterSheetDismissed transitionTo:Cancelled before:@selector(_twitterSheetDismissed)];
        [SigningUpWithTwitter when:failedError transitionTo:SignUpFailed before:@selector(_signUpWithTwitterFailedWithError:)];
        [SigningUpWithTwitter when:complete transitionTo:Complete before:@selector(_complete:)];
        [SigningUpWithTwitter when:userNotFound transitionTo:PresentingAlmostThereTwitter before:@selector(_presentAlmostThere)];

        [AttemptingSignInWithFacebook popWhen:cancel];
        [AttemptingSignInWithFacebook popWhen:failedError before:@selector(_attemptSignInWithFacebookFailedWithError:)];
        [AttemptingSignInWithFacebook when:complete transitionTo:Complete before:@selector(_complete:)];
        [AttemptingSignInWithFacebook when:userNotFound transitionTo:PresentingAlmostThereFacebook before:@selector(_presentAlmostThere)];

        [AttemptingSignInWithTwitter popWhen:twitterSheetDismissed];
        [AttemptingSignInWithTwitter popWhen:failedError before:@selector(_attemptSignInWithTwitterFailedWithError:)];
        [AttemptingSignInWithTwitter when:complete transitionTo:Complete before:@selector(_complete:)];
        [AttemptingSignInWithTwitter when:userNotFound transitionTo:PresentingAlmostThereTwitter before:@selector(_presentAlmostThere)];

        [PresentingAlmostThereFacebook when:cancel transitionTo:Cancelled before:@selector(_cancel)];
        [PresentingAlmostThereFacebook when:authFromViewController push:SigningUpWithDrawQuestAndFacebook before:@selector(_signUpWithFacebookFromViewController:)];

        [PresentingAlmostThereTwitter when:cancel transitionTo:Cancelled before:@selector(_cancel)];
        [PresentingAlmostThereTwitter when:authFromViewController push:SigningUpWithDrawQuestAndTwitter before:@selector(_signUpWithTwitterFromViewController:)];

        [SigningUpWithDrawQuestAndFacebook popWhen:failedError after:@selector(_signUpWithDrawQuestAndFacebookFailedWithError:)];
        [SigningUpWithDrawQuestAndFacebook when:complete transitionTo:Complete before:@selector(_complete:)];
        [SigningUpWithDrawQuestAndFacebook when:addFriends transitionTo:PresentingAddFriends before:@selector(_presentAddFriends:)];

        [SigningUpWithDrawQuestAndTwitter popWhen:failedError after:@selector(_signUpWithDrawQuestAndTwitterFailedWithError:)];
        [SigningUpWithDrawQuestAndTwitter when:complete transitionTo:Complete before:@selector(_complete:)];
        [SigningUpWithDrawQuestAndTwitter when:addFriends transitionTo:PresentingAddFriends before:@selector(_presentAddFriends:)];

        [PresentingAddFriends when:cancelAddFriends transitionTo:Complete before:@selector(_complete:)];
        [PresentingAddFriends when:complete transitionTo:Complete before:@selector(_complete:)];
    }
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate authServiceController:(DQAuthServiceController *)authServiceController
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _statechartStack = [NSMutableArray new];
        _statechart = [[DQAuthenticationControllerStatechart statechart] startStatechart];
        _authServiceController = authServiceController;
    }
    return self;
}

- (NSString *)strippedUsername:(NSString *)inUserName
{
    NSCharacterSet *illegalCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_"] invertedSet];
    NSString *strippedUsername = [[inUserName componentsSeparatedByCharactersInSet:illegalCharacters] componentsJoinedByString:@""];
    return strippedUsername;
}

#pragma mark -
#pragma mark Public API

- (void)startSignInFromView:(UIView *)sender
         fromViewController:(UIViewController *)presentingViewController
  modalNavigationController:(DQNavigationController *)modalNavigationController
                 publishing:(BOOL)isPublishing
 twitterSheetDismissedBlock:(DQAuthenticationControllerBlock)twitterSheetDismissedBlock
          cancellationBlock:(DQAuthenticationControllerBlock)cancellationBlock
            completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock
               failureBlock:(DQAuthenticationControllerFailureBlock)failureBlock
{
    self.presentingViewController = presentingViewController;
    self.modalNavigationController = modalNavigationController;
    self.modalNavigationControllerWasProvided = modalNavigationController != nil;
    self.publishing = isPublishing;
    self.twitterSheetDismissedBlock = twitterSheetDismissedBlock;
    self.cancellationBlock = cancellationBlock;
    self.completionBlock = completionBlock;
    self.failureBlock = failureBlock;
    if (self.loggedIn)
    {
        [self.statechart complete:self fromService:@(DQAuthenticationSignupServiceNone)];
    }
    else
    {
        [self.statechart presentSignIn:self];
    }
}

- (void)startSignUpFromView:(UIView *)sender
         fromViewController:(UIViewController *)presentingViewController
  modalNavigationController:(DQNavigationController *)modalNavigationController
                 withOption:(DQAuthenticationOption)option
                 publishing:(BOOL)isPublishing
 twitterSheetDismissedBlock:(DQAuthenticationControllerBlock)twitterSheetDismissedBlock
          cancellationBlock:(DQAuthenticationControllerBlock)cancellationBlock
            completionBlock:(DQAuthenticationControllerCompletionBlock)completionBlock
               failureBlock:(DQAuthenticationControllerFailureBlock)failureBlock
{
    self.presentingViewController = presentingViewController;
    self.modalNavigationController = modalNavigationController;
    self.modalNavigationControllerWasProvided = modalNavigationController != nil;
    self.publishing = isPublishing;
    self.twitterSheetDismissedBlock = twitterSheetDismissedBlock;
    self.cancellationBlock = cancellationBlock;
    self.completionBlock = completionBlock;
    self.failureBlock = failureBlock;
    if (self.loggedIn)
    {
        [self.statechart complete:self fromService:@(DQAuthenticationSignupServiceNone)];
    }
    else if ((option == DQAuthenticationOptionDefault) || (option == DQAuthenticationOptionEmailSignUp))
    {
        [self.statechart presentSignUp:self];
    }
    else if (option == DQAuthenticationOptionFacebookSignUp)
    {
        [self.statechart facebook:self];
    }
    else if (option == DQAuthenticationOptionTwitterSignUp)
    {
        [self.statechart twitter:self inView:sender];
    }
}

- (UIBarButtonItem *)newCancelBarButtonItem
{
    __weak typeof(self) weakSelf = self;
    return [self newCancelBarButtonItemWithBlock:^(id sender) {
        [weakSelf.statechart dqCancelTask:weakSelf];
    }];
}

#pragma mark -
#pragma mark RCSStateChart methods

// this will be called when any unexpected transition occurs
- (void)_statechartContextDidEnterErrorStatechart
{
    [self failedWithError:nil]; // FIXME: create an error for this
}

- (id<RCSStatechart>)pushStatechart
{
    id<RCSStatechart> result = self.statechart;
    if (result) [self.statechartStack addObject:result];
    return result;
}

- (id<RCSStatechart>)popStatechart
{
    id<RCSStatechart> result = [_statechartStack lastObject];
    if (result) [self.statechartStack removeLastObject];
    return result;
}

#pragma mark -
#pragma mark Methods that trigger the completion blocks

- (void)failedWithError:(NSError *)error
{
    if (self.failureBlock)
    {
        self.failureBlock(self, error, self.modalNavigationController);
    }
    self.presentingViewController = nil;
    self.twitterSheetDismissedBlock = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)twitterSheetDismissed
{
    if (self.twitterSheetDismissedBlock)
    {
        self.twitterSheetDismissedBlock(self, self.modalNavigationController);
    }
    [self.twitterController reset];
    [self.facebookController reset];
    self.presentingViewController = nil;
    self.twitterSheetDismissedBlock = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)cancel
{
    if (self.cancellationBlock)
    {
        self.cancellationBlock(self, self.modalNavigationController);
    }
    [self.twitterController reset];
    [self.facebookController reset];
    self.presentingViewController = nil;
    self.twitterSheetDismissedBlock = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)complete:(DQAuthenticationSignupService)service
{
    if (self.completionBlock)
    {
        self.completionBlock(self, service, self.modalNavigationController);
    }
    self.presentingViewController = nil;
    self.twitterSheetDismissedBlock = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

@end

@implementation DQAuthenticationController (DQAuthenticationControllerPrivateMethods)

- (void)_startFailedWithError:(NSError *)error
{
    [self failedWithError:error];
}

- (DQNavigationController *)_modalNavigationController
{
    if (!self.modalNavigationController)
    {
        if (self.makeModalNavigationControllerBlock)
        {
            self.modalNavigationController = self.makeModalNavigationControllerBlock(self);
        }
    }
    return self.modalNavigationController;
}

- (void)_presentSignIn
{
    if (self.makeSignInViewControllerBlock)
    {
        __weak typeof(self) weakSelf = self;
        DQSignInViewController *vc = nil;
        vc = self.makeSignInViewControllerBlock(self, self.publishing);
        vc.username = self.username;
        vc.password = self.password;
        vc.email = nil;
        vc.facebookBlock = ^(DQSignInViewController *c) {
            [weakSelf.statechart facebook:weakSelf];
        };
        vc.twitterBlock = ^(DQSignInViewController *c, UIView *sender) {
            [weakSelf.statechart twitter:weakSelf inView:sender];
        };
        vc.switchBlock = ^(DQSignInViewController *c) {
            weakSelf.username = c.username;
            weakSelf.password = c.password;
            weakSelf.email = nil;
            [weakSelf.statechart presentSignUp:weakSelf];
        };
        vc.finishBlock = ^(DQSignInViewController *c, NSString *username, NSString *password, NSString *email) {
            // this will be called by vc's submit: method
            weakSelf.username = c.username;
            weakSelf.password = c.password;
            weakSelf.email = nil;
            [weakSelf.statechart auth:weakSelf fromViewController:c];
        };
        vc.navigationItem.leftBarButtonItem = [self newCancelBarButtonItem];
        NSString *localizedButtonTitle = nil;
        if (self.titleForSignInRightBarButtonItem)
        {
            localizedButtonTitle = self.titleForSignInRightBarButtonItem(self, self.isPublishing);
        }
        vc.navigationItem.rightBarButtonItem = [self newBarButtonItemWithTitle:localizedButtonTitle target:vc action:@selector(submit:) isPrimaryAction:YES];
        DQNavigationController *mnc = [self _modalNavigationController];
        [mnc setViewControllers:@[vc]];
        if (!mnc.presentingViewController)
        {
            [self.presentingViewController presentViewController:mnc animated:YES completion:nil];
        }
    }
    else
    {
        [self.statechart failed:self error:[NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationMissingBlocksErrorCode userInfo:@{NSLocalizedDescriptionKey: NSStringFromSelector(_cmd)}]];
    }
}

- (void)_presentSignUp
{
    if (self.makeSignUpViewControllerBlock)
    {
        __weak typeof(self) weakSelf = self;
        DQSignUpViewController *vc = self.makeSignUpViewControllerBlock(self, self.publishing);
        vc.username = self.username;
        vc.password = self.password;
        vc.email = self.email;
        vc.facebookBlock = ^(DQSignUpViewController *c) {
            [weakSelf.statechart facebook:weakSelf];
        };
        vc.twitterBlock = ^(DQSignUpViewController *c, UIView *sender) {
            [weakSelf.statechart twitter:weakSelf inView:sender];
        };
        vc.switchBlock = ^(DQSignUpViewController *c) {
            weakSelf.username = c.username;
            weakSelf.password = c.password;
            weakSelf.email = nil;
            [weakSelf.statechart presentSignIn:weakSelf];
        };
        vc.finishBlock = ^(DQSignUpViewController *c, NSString *username, NSString *password, NSString *email) {
            weakSelf.username = c.username;
            weakSelf.password = c.password;
            weakSelf.email = c.email;
            [weakSelf.statechart auth:weakSelf fromViewController:c];
        };
        vc.navigationItem.leftBarButtonItem = [self newCancelBarButtonItem];
        NSString *title = nil;
        if (self.titleForSignUpRightBarButtonItem)
        {
            title = self.titleForSignUpRightBarButtonItem(self, self.isPublishing);
        }
        vc.navigationItem.rightBarButtonItem = [self newBarButtonItemWithTitle:title target:vc action:@selector(submit:) isPrimaryAction:YES];

        DQNavigationController *mnc = [self _modalNavigationController];
        [mnc setViewControllers:@[vc]];
        if (!mnc.presentingViewController)
        {
            [self.presentingViewController presentViewController:mnc animated:YES completion:nil];
        }
    }
    else
    {
        [self.statechart failed:self error:[NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationMissingBlocksErrorCode userInfo:@{NSLocalizedDescriptionKey: NSStringFromSelector(_cmd)}]];
    }
}

- (void)_presentAlmostThere
{
    if (self.makeAlmostThereViewControllerBlock)
    {
        __weak typeof(self) weakSelf = self;
        DQAlmostThereViewController *vc = self.makeAlmostThereViewControllerBlock(self, self.publishing);
        vc.username = self.username;
        vc.password = self.password;
        vc.email = self.email;
        vc.finishBlock = ^(DQAlmostThereViewController *c, NSString *username, NSString *password, NSString *email) {
            weakSelf.username = c.username;
            weakSelf.password = c.password;
            weakSelf.email = c.email;
            [weakSelf.statechart auth:weakSelf fromViewController:c];
        };
        vc.title = [vc textForTopLabel];
        vc.navigationItem.leftBarButtonItem = [self newCancelBarButtonItem];
        NSString *title = nil;
        if (self.titleForSignUpRightBarButtonItem)
        {
            title = self.titleForSignUpRightBarButtonItem(self, self.isPublishing);
        }
        vc.navigationItem.rightBarButtonItem = [self newBarButtonItemWithTitle:title target:vc action:@selector(submit:) isPrimaryAction:YES];
        DQNavigationController *mnc = [self _modalNavigationController];
        if (mnc.presentingViewController)
        {
            [mnc pushViewController:vc animated:NO];
        }
        else
        {
            [mnc setViewControllers:@[vc]];
            [self.presentingViewController presentViewController:mnc animated:YES completion:nil];
        }
    }
    else
    {
        [self.statechart failed:self error:[NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationMissingBlocksErrorCode userInfo:@{NSLocalizedDescriptionKey: NSStringFromSelector(_cmd)}]];
    }
}

- (void)_signInFromViewController:(UIViewController *)vc
{
    __weak typeof(self) weakSelf = self;

    // display HUD
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:vc.view.bounds];
    hud.text = DQLocalizedString(@"Authorizing", @"User is being authorized message");
    [hud showInView:vc.view animated:YES];
    // do the service method
    [self.authServiceController requestLoginWithUsername:self.username password:self.password completionBlock:^(DQHTTPRequest *request) {
        [hud hideAnimated:YES];
        if (request)
        {
            if (request.error)
            {
                [weakSelf.statechart failed:weakSelf error:request.error];
            }
            else
            {
                [weakSelf.statechart complete:weakSelf fromService:@(DQAuthenticationSignupServiceNone)];
            }
        }
        else
        {
            // nil request means it failed validation inside the serviceController, ie: something was nil/empty
            // This should never happen unless there's a bug in the app, as the form shouldn't allow you to continue before the fields are filled in
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Invalid sign-in credentials."};
            NSError *error = [NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationInvalidSignInCredentialsErrorCode userInfo:userInfo];
            [weakSelf.statechart failed:weakSelf error:error];
        }
    }];
}

- (void)_signUpFromViewController:(UIViewController *)vc usingFacebook:(BOOL)usingFacebook usingTwitter:(BOOL)usingTwitter
{
    __weak typeof(self) weakSelf = self;

    // display HUD
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:vc.view.bounds];
    hud.text = DQLocalizedString(@"Authorizing", @"User is being authorized message");
    [hud showInView:vc.view animated:YES];
    // do the service method
    NSString *facebookToken = usingFacebook ? self.facebookController.openFacebookSessionAccessToken : nil;
    NSString *twitterToken = usingTwitter ? self.twitterController.twitterAccessToken : nil;
    NSString *twitterSecret = usingTwitter ? self.twitterController.twitterAccessTokenSecret : nil;
    [self.authServiceController requestSignupWithUsername:self.username password:self.password email:self.email facebookToken:facebookToken twitterToken:twitterToken twitterSecret:twitterSecret completionBlock:^(DQHTTPRequest *request) {
        [hud hideAnimated:YES];
        if (request)
        {
            if (request.error)
            {
                [weakSelf.statechart failed:weakSelf error:request.error];
            }
            else
            {
                // Log signup analytics only if they are actually signups and not logins
                BOOL wasActuallyLogin = request.dq_responseDictionary.dq_wasLoginRequest;
                if ( ! wasActuallyLogin)
                {
                    if (usingFacebook)
                    {
                        [weakSelf logEvent:DQAnalyticsEventSignupWithFacebook withParameters:nil];
                    }
                    else if (usingTwitter)
                    {
                        [weakSelf logEvent:DQAnalyticsEventSignupWithTwitter withParameters:nil];
                    }
                    else
                    {
                        [weakSelf logEvent:DQAnalyticsEventSignup withParameters:nil];
                    }
                }
                DQAuthenticationSignupService service = DQAuthenticationSignupServiceEmail;
                if (usingFacebook)
                {
                    service = DQAuthenticationSignupServiceFacebook;
                }
                else if (usingTwitter)
                {
                    service = DQAuthenticationSignupServiceTwitter;
                }
                else if (wasActuallyLogin)
                {
                    service = DQAuthenticationSignupServiceNone;
                }

                if (weakSelf.publishing)
                {
                    [weakSelf.statechart complete:weakSelf fromService:@(service)];
                }
                else
                {
                    [weakSelf.statechart addFriends:weakSelf fromService:@(service)];
                }
            
                if ( ! wasActuallyLogin && weakSelf.signedUpBlock)
                {
                    weakSelf.signedUpBlock(service);
                }
            }
        }
        else
        {
            // nil request means it failed validation inside the serviceController, ie: something was nil/empty
            // This should never happen unless there's a bug in the app, as the form shouldn't allow you to continue before the fields are filled in
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Invalid sign-up credentials."};
            NSError *error = [NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationInvalidSignUpCredentialsErrorCode userInfo:userInfo];
            [weakSelf.statechart failed:weakSelf error:error];
        }
    }];
}

- (void)_signUpWithDrawQuestFromViewController:(UIViewController *)vc
{
    [self _signUpFromViewController:vc usingFacebook:NO usingTwitter:NO];
}

- (void)_signUpWithFacebookFromViewController:(UIViewController *)vc
{
    [self _signUpFromViewController:vc usingFacebook:YES usingTwitter:NO];
}

- (void)_signUpWithTwitterFromViewController:(UIViewController *)vc
{
    [self _signUpFromViewController:vc usingFacebook:NO usingTwitter:YES];
}

// for the purpose of signing in / signing up (when publishing or not), this gets Facebook access with email permission
// outbound transitions:
// - cancel
// - userNotFound
// - complete
// - failedError
- (void)_attemptSignInWithFacebook
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:self.modalNavigationController.view.bounds];
    hud.text = DQLocalizedString(@"Authorizing", @"User is being authorized message");
    [hud showInView:self.modalNavigationController.view animated:YES];

    __weak typeof(self) weakSelf = self;
    [self.facebookController requestFacebookAccessForFeature:@"auth" readPermissions:@[@"email"] publishPermissions:nil cancellationBlock:^{
        [weakSelf.statechart dqCancelTask:weakSelf];
        [hud hideAnimated:YES];
    } completionBlock:^(NSString *facebookToken) {
        [weakSelf.authServiceController requestLoginWithFacebookToken:facebookToken completionBlock:^(DQHTTPRequest *request) {
            [hud hideAnimated:YES];
            [weakSelf.statechart complete:weakSelf fromService:@(DQAuthenticationSignupServiceNone)];
        } failureBlock:^(DQHTTPRequest *request) {
            [hud hideAnimated:YES];
            if (request)
            {
                if (request.responseStatusCode == DQHTTPRequestForbiddenStatusCode)
                {
                    [DQPapertrailLogger component:@"authentication-controller" category:@"request-for-me" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                        return @{@"token": facebookToken ?: [NSNull null]};
                    }];
                    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                        [hud hideAnimated:YES];
                        if (error)
                        {
                            [DQPapertrailLogger component:@"authentication-controller" category:@"request-for-me-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                return @{@"token": facebookToken ?: [NSNull null],
                                         @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                         @"category": @([error fberrorCategory])};
                            }];
                            [weakSelf.statechart failed:weakSelf error:error];
                        }
                        else
                        {
                            weakSelf.username = [self strippedUsername:user.username];
                            weakSelf.email = [user objectForKey:@"email"];
                            [weakSelf.statechart userNotFound:weakSelf];
                        }
                    }];
                }
                else
                {
                    [weakSelf.statechart failed:weakSelf error:request.error];
                }
            }
            else
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Sign-in is already underway."};
                NSError *error = [NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationDuplicateRequestIgnoredErrorCode userInfo:userInfo];
                [weakSelf.statechart failed:weakSelf error:error];
            }
        }];
    } failureBlock:^(NSError *error) {
        [weakSelf.statechart failed:weakSelf error:error];
        [hud hideAnimated:YES];
    }];
}

- (void)_signUpWithFacebook
{
    [self _attemptSignInWithFacebook];
}

- (void)_attemptSignInWithTwitterInView:(UIView *)view
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:self.modalNavigationController.view.bounds];
    hud.text = DQLocalizedString(@"Authorizing", @"User is being authorized message");
    
    __weak typeof(self) weakSelf = self;
    [self.twitterController reset];
    [self.twitterController requestTwitterAccessInView:view cancellationBlock:^{
        [hud hideAnimated:YES];
        [weakSelf.statechart twitterSheetDismissed:weakSelf];
    } accountSelectedBlock:^{
        [hud showInView:weakSelf.modalNavigationController.view animated:YES];
    } completionBlock:^{
        [weakSelf.authServiceController requestLoginWithTwitterToken:weakSelf.twitterController.twitterAccessToken twitterSecret:weakSelf.twitterController.twitterAccessTokenSecret completionBlock:^(DQHTTPRequest *request) {
            [hud hideAnimated:YES];
            [weakSelf.statechart complete:weakSelf fromService:@(DQAuthenticationSignupServiceNone)];
        } failureBlock:^(DQHTTPRequest *request) {
            [hud hideAnimated:YES];
            if (request)
            {
                if (request.responseStatusCode == DQHTTPRequestForbiddenStatusCode)
                {
                    weakSelf.username = [self strippedUsername:weakSelf.twitterController.twitterUsername];
                    [weakSelf.statechart userNotFound:weakSelf];
                }
                else
                {
                    [weakSelf.statechart failed:weakSelf error:request.error];
                }
            }
            else
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Sign-in is already underway."};
                NSError *error = [NSError errorWithDomain:DQAuthenticationErrorDomain code:DQAuthenticationDuplicateRequestIgnoredErrorCode userInfo:userInfo];
                [weakSelf.statechart failed:weakSelf error:error];
            }
        }];
    } failureBlock:^(NSError *error) {
        [hud hideAnimated:YES];
        [weakSelf.statechart failed:weakSelf error:error];
    }];
}

- (void)_signUpWithTwitterInView:(UIView *)view
{
    [self _attemptSignInWithTwitterInView:view];
}

- (void)_presentAddFriends:(NSNumber *)serviceNumber
{
    if (self.makeAddFriendsViewControllerBlock)
    {
        DQAddFriendsViewController *vc = self.makeAddFriendsViewControllerBlock(self, (DQAuthenticationSignupService)[serviceNumber integerValue]);

        if (vc)
        {
            vc.title = DQLocalizedString(@"Add Friends", @"Title for modal where the user can invite their friends to DrawQuest");

            __weak typeof(self) weakSelf = self;
            __weak typeof(vc) weakVC = vc;
//            vc.navigationItem.leftBarButtonItem = [self newCancelBarButtonItemWithBlock:^(id sender) {
//                // self.publishing == NO when PresentingAddFriends, no need to publish:fromService:
//                [weakVC attemptCancel:^(BOOL cancelled) {
//                    if (cancelled)
//                    {
//                        [weakSelf.statechart cancelAddFriends:weakSelf fromService:serviceNumber];
//                    }
//                }];
//            }];
            vc.navigationItem.hidesBackButton = YES;
            vc.navigationItem.rightBarButtonItem = [self newBarButtonItemWithTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") isPrimaryAction:YES block:^(id sender) {
                // self.publishing == NO when PresentingAddFriends, no need to publish:fromService:
                [weakVC submitWithCancellationBlock:^{
                    // do nothing, we're still presenting
                } completionBlock:^{
                    [weakSelf.statechart complete:weakSelf fromService:serviceNumber];
                } failureBlock:^(NSError *error) {
                    [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Add Friends Failed", @"Add friends error alert title") forError:error];
                }];
            }];
            
            [self.modalNavigationController pushViewController:vc animated:YES];
        }
        else
        {
            // Skip add friends if we don't have one
            [self.statechart complete:self fromService:serviceNumber];
        }
    }
    else
    {
        // If we're not presenting friends, go ahead and wrap it up
        [self.statechart complete:self fromService:serviceNumber];
    }
}

- (void)_signInFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Sign In Failed", @"Sign in failed alert title") forError:error];
}

- (void)_signUpWithDrawQuestFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Sign Up Failed", @"Sign up failed alert title") forError:error];
}

- (void)_signUpWithDrawQuestAndFacebookFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Sign Up Failed", @"Sign up failed alert title") forError:error];
}

- (void)_signUpWithDrawQuestAndTwitterFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Sign Up Failed", @"Sign up failed alert title") forError:error];
}

- (void)_signUpWithFacebookFailedWithError:(NSError *)error
{
    [self failedWithError:error];
}

- (void)_signUpWithTwitterFailedWithError:(NSError *)error
{
    [self failedWithError:error];
}

- (void)_attemptSignInWithFacebookFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Facebook", @"Facebook") forError:error];
}

- (void)_attemptSignInWithTwitterFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Twitter", @"Twitter") forError:error];
}

- (void)_twitterSheetDismissed
{
    [self twitterSheetDismissed];
}

- (void)_cancel
{
    [self cancel];
}

- (void)_complete:(NSNumber *)serviceNumber
{
    [self complete:[serviceNumber integerValue]];
}

@end

@implementation DQAuthenticationControllerStatechart

+ (DQAuthenticationControllerStatechart *)statechart
{
    return (DQAuthenticationControllerStatechart *)[super statechart];
}

#ifdef DEBUG
- (BOOL)shouldLogTransitions
{
    return YES;
}
#endif

@end
