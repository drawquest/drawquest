//
//  DQCommentPublishController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-08.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentPublishController.h"

#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "DQPublicServiceController.h"
#import "DQAccountController.h"
#import "DQTwitterController.h"
#import "DQNavigationController.h"
#import "DQPublishAuthViewController.h"
#import "DQCommentPublishViewController.h"
#import "CVSEditorViewController.h"
#import "DQAddFriendsViewController.h"
#import "DQPadCommentPublishController.h"
#import "DQPhoneCommentPublishController.h"
#import "DQEmailSharingViewController.h"

#import "DQAlertView.h"
#import "DQHUDView.h"

#import "NSDictionary+DQAPIConveniences.h"

NSString *DQCommentPublishErrorDomain = @"DQCommentPublishErrorDomain";
const NSInteger DQCommentPublishMissingFacebookTokenErrorCode = 1000;
const NSInteger DQCommentPublishMissingTwitterTokenErrorCode = 1001;
const NSInteger DQCommentPublishFailedCode = 1002;
const NSInteger DQCommentPublishMissingBlocksErrorCode = 1003;

@interface DQCommentPublishController () <RCSStatechartContext, MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *statechartStack;

@property (nonatomic, strong) DQCommentPublishViewController *publishViewController;

@property (nonatomic, strong, readwrite) NSArray *emailList;

@property (nonatomic, copy) dispatch_block_t cancellationBlock;
@property (nonatomic, copy) dispatch_block_t completionBlock;
@property (nonatomic, copy) void (^failureBlock)(NSError *error);

@property (nonatomic, assign, getter = isSharingFB) BOOL sharingFB;
@property (nonatomic, assign, getter = isSharingTW) BOOL sharingTW;
@property (nonatomic, assign, getter = isOnboarding) BOOL onboarding;
@property (nonatomic, readwrite, assign) DQAuthenticationSignupService signupService;
@property (nonatomic, copy) dispatch_block_t messageComposeSuccessBlock;

@end

@implementation DQCommentPublishController

@dynamic delegate;

+ (void)initialize
{
    if (self == [DQCommentPublishController class])
    {
        id<RCSStatechart> Base                           = [DQCommentPublishControllerStatechart statechart];
        id<RCSStatechart> Error                          = [Base statechartNamed:@"Error"];
        id<RCSStatechart> Start                          = [Base statechartNamed:@"Start"];

        id<RCSStatechart> PresentingAuth                 = [Base statechartNamed:@"PresentingAuth"];
        id<RCSStatechart> Authenticating                 = [Base statechartNamed:@"Authenticating"];

        id<RCSStatechart> PresentingShare                = [Base statechartNamed:@"PresentingShare"];
        id<RCSStatechart> PresentingShareOnboarding      = [Base statechartNamed:@"PresentingShareOnboarding"];

        id<RCSStatechart> Posting                        = [Base statechartNamed:@"Posting"];
        id<RCSStatechart> PostingOnboarding              = [Base statechartNamed:@"PostingOnboarding"];
        id<RCSStatechart> PostingFirstPost               = [Base statechartNamed:@"PostingFirstPost"];

        id<RCSStatechart> PresentingGallery              = [Base statechartNamed:@"PresentingGallery"];
        id<RCSStatechart> PresentingGalleryOnboarding    = [Base statechartNamed:@"PresentingGalleryOnboarding"];
        id<RCSStatechart> PresentingGalleryFirstPost     = [Base statechartNamed:@"PresentingGalleryFirstPost"];

        id<RCSStatechart> PresentingAddFriendsOnboarding = [Base statechartNamed:@"PresentingAddFriendsOnboarding"];

        id<RCSStatechart> PresentingNiceJobOnboarding    = [Base statechartNamed:@"PresentingNiceJobOnboarding"];
        id<RCSStatechart> PresentingNiceJobFirstPost     = [Base statechartNamed:@"PresentingNiceJobFirstPost"];

        id<RCSStatechart> Cancelled                      = [Base statechartNamed:@"Cancelled"];
        id<RCSStatechart> Complete                       = [Base statechartNamed:@"Complete"];

        SEL auth        = [Base transitionToErrorStatechartWhen:@selector(auth:)];
        SEL authOption  = [Base transitionToErrorStatechartWhen:@selector(auth:withOption:)];
        SEL authTwitter = [Base transitionToErrorStatechartWhen:@selector(authTwitter:fromView:)];
        SEL post        = [Base transitionToErrorStatechartWhen:@selector(post:)];
        SEL signedUp    = [Base transitionToErrorStatechartWhen:@selector(signedUp:)];
        SEL signedIn    = [Base transitionToErrorStatechartWhen:@selector(signedIn:)];
        SEL firstPost   = [Base transitionToErrorStatechartWhen:@selector(firstPost:)];
        SEL gallery     = [Base transitionToErrorStatechartWhen:@selector(gallery:)];
        SEL twitterSheetDismissed = [Base transitionToErrorStatechartWhen:@selector(twitterSheetDismissed:)];
        SEL cancel      = [Base transitionToErrorStatechartWhen:@selector(dqCancelTask:)];
        SEL complete    = [Base transitionToErrorStatechartWhen:@selector(complete:)];
        SEL failedError = [Base transitionToErrorStatechartWhen:@selector(failed:error:)];

        [Base declareErrorStatechart:Error];
        [Base declareStartStatechart:Start];

        [Start when:auth transitionTo:PresentingAuth before:@selector(_presentAuth)];
        [Start when:signedIn transitionTo:PresentingShare before:@selector(_presentShare)];

        [PresentingAuth when:cancel transitionTo:Cancelled before:@selector(_cancelPresentingAuth)];
        [PresentingAuth when:authOption push:Authenticating before:@selector(_authenticateWithOption:)];
        [PresentingAuth when:authTwitter push:Authenticating before:@selector(_authenticateWithTwitterFromView:)];

        [Authenticating popWhen:twitterSheetDismissed];
        [Authenticating when:cancel transitionTo:Cancelled after:@selector(_cancelPresentingAuth)];
        [Authenticating popWhen:failedError before:@selector(_authenticatingFailedWithError:)];
        [Authenticating when:signedIn transitionTo:PresentingShare before:@selector(_presentShare)];
        [Authenticating when:signedUp transitionTo:PresentingShareOnboarding before:@selector(_presentShare)];

        [PresentingShare when:cancel transitionTo:Cancelled before:@selector(_cancelPresentingShare)];
        [PresentingShare when:post push:Posting before:@selector(_post)];
        [PresentingShare when:firstPost push:PostingFirstPost before:@selector(_post)];

        [PresentingShareOnboarding when:cancel transitionTo:Cancelled before:@selector(_cancelPresentingShare)];
        [PresentingShareOnboarding when:firstPost push:PostingOnboarding before:@selector(_post)];

        [Posting popWhen:failedError before:@selector(_postingFailedWithError:)];
        [Posting when:gallery transitionTo:PresentingGallery before:@selector(_presentGallery)];

        [PostingFirstPost popWhen:failedError before:@selector(_postingFailedWithError:)];
        [PostingFirstPost when:gallery transitionTo:PresentingGalleryFirstPost before:@selector(_presentGallery)];

        [PostingOnboarding popWhen:failedError before:@selector(_postingFailedWithError:)];
        [PostingOnboarding when:gallery transitionTo:PresentingGalleryOnboarding before:@selector(_presentGallery)];

        [PresentingGallery when:complete transitionTo:Complete before:@selector(_completePresentingGallery)];

        [PresentingGalleryOnboarding when:complete transitionTo:PresentingAddFriendsOnboarding before:@selector(_presentAddFriends)];

        [PresentingGalleryFirstPost when:complete transitionTo:PresentingNiceJobFirstPost before:@selector(_presentNiceJob)];

        [PresentingAddFriendsOnboarding when:cancel transitionTo:PresentingNiceJobOnboarding before:@selector(_presentNiceJob)];
        [PresentingAddFriendsOnboarding when:complete transitionTo:PresentingNiceJobOnboarding before:@selector(_presentNiceJob)];

        [PresentingNiceJobOnboarding when:complete transitionTo:Complete before:@selector(_completePresentingNiceJob)];

        [PresentingNiceJobFirstPost when:complete transitionTo:Complete before:@selector(_completePresentingNiceJob)];
    }
}

- (id)initWithDelegate:(id<DQCommentPublishControllerDelegate>)delegate accountController:(DQAccountController *)accountController commentUploadController:(DQCommentUploadController *)commentUploadController
{
    if ([self class] == [DQCommentPublishController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadCommentPublishController alloc] initWithDelegate:delegate accountController:accountController commentUploadController:commentUploadController];
        }
        else
        {
            self = [[DQPhoneCommentPublishController alloc] initWithDelegate:delegate accountController:accountController commentUploadController:commentUploadController];
        }
    }
    else
    {
        self = [super initWithDelegate:delegate];
        if (self)
        {
            _statechartStack = [NSMutableArray new];
            _statechart = [[DQCommentPublishControllerStatechart statechart] startStatechart];
            _accountController = accountController;
            _commentUploadController = commentUploadController;
            _shareFlags = [NSMutableArray new];
        }
    }
    return self;
}

- (id<DQCommentPublishControllerDelegate>)delegate
{
    return (id<DQCommentPublishControllerDelegate>)[super delegate];
}

- (void)setDelegate:(id<DQCommentPublishControllerDelegate>)delegate
{
    [super setDelegate:delegate];
}

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

- (void)presentInModalNavigationController:(DQNavigationController *)modalNavigationController
                   forEditorViewController:(CVSEditorViewController *)editorViewController
                         cancellationBlock:(dispatch_block_t)cancellationBlock
                           completionBlock:(dispatch_block_t)completionBlock
                              failureBlock:(void (^)(NSError *error))failureBlock
{
    self.modalNavigationController = modalNavigationController;
    self.editorViewController = editorViewController;
    self.cancellationBlock = cancellationBlock;
    self.completionBlock = completionBlock;
    self.failureBlock = failureBlock;

    if (self.loggedIn)
    {
        [self.statechart signedIn:self];
    }
    else
    {
        [self.statechart auth:self];
    }
}

- (void)presentingShareCancelTapped:(id)sender
{
    [self.statechart dqCancelTask:self];
}

- (void)presentingSharePostTapped:(id)sender
{
    if (self.onboarding && !(self.sharingFB || self.sharingTW))
    {
        DQAlertView *confirmation = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Are you sure?", @"Destructive request alert confirmation title")
                                                               message:DQLocalizedString(@"DrawQuest is more fun when you share with friends. Would you still like to continue without sharing?", @"Post without sharing alert message")
                                                              delegate:nil
                                                     cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view")
                                                     otherButtonTitles:DQLocalizedString(@"Yes, continue", @"Post without sharing alert confirmation button title"), nil];
        __weak typeof(self) weakSelf = self;
        confirmation.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                if (weakSelf.onboarding || !weakSelf.loggedInAccount.hasPublishedAComment)
                {
                    [weakSelf.statechart firstPost:weakSelf];
                }
                else
                {
                    [weakSelf.statechart post:weakSelf];
                }
            }
        };
        [confirmation show];
    }
    else if (self.onboarding || !self.loggedInAccount.hasPublishedAComment)
    {
        [self.statechart firstPost:self];
    }
    else
    {
        [self.statechart post:self];
    }
}

- (void)presentingNiceJobDoneTapped:(id)sender
{
    [self.statechart complete:self];
}

- (void)setSharingFB:(BOOL)sharingFB
{
    [self setSharingFB:sharingFB withCancellationBlock:nil completionBlock:nil failureBlock:nil];
}

- (void)setSharingFB:(BOOL)sharingFB withCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    _sharingFB = sharingFB;

    if (sharingFB)
    {
        __weak typeof(self) weakSelf = self;
        [self requestFacebookPublishAccessFromViewController:self.publishViewController feature:@"share-comment-while-publishing" cancellationBlock:^{
            [weakSelf.publishViewController setSharingFB:NO];
            weakSelf.sharingFB = NO;
            [weakSelf.shareFlags removeObject:DQAPIValueShareChannelTypeFacebook];
            [weakSelf refreshRewardsInfo];
            if (cancellationBlock)
            {
                cancellationBlock();
            }
        } completionBlock:^(NSString *facebookToken) {
            [weakSelf.publishViewController setSharingFB:YES];
            [weakSelf.shareFlags addObject:DQAPIValueShareChannelTypeFacebook];
            [weakSelf refreshRewardsInfo];
            if (completionBlock)
            {
                completionBlock();
            }
        } failureBlock:^(NSError *error) {
            [weakSelf.publishViewController setSharingFB:NO];
            weakSelf.sharingFB = NO;
            [weakSelf.shareFlags removeObject:DQAPIValueShareChannelTypeFacebook];
            [weakSelf refreshRewardsInfo];
            [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") message:error.dq_displayDescription];
            if (failureBlock)
            {
                failureBlock(error);
            }
        }];
    }
    else
    {
        [self.publishViewController setSharingFB:sharingFB];
        [self.shareFlags removeObject:DQAPIValueShareChannelTypeFacebook];
        [self refreshRewardsInfo];
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (void)setSharingTW:(BOOL)sharingTW
{
    [self setSharingTW:sharingTW withCancellationBlock:nil completionBlock:nil failureBlock:nil];
}

- (void)setSharingTW:(BOOL)sharingTW withCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    _sharingTW = sharingTW;

    if (sharingTW)
    {
        __weak typeof(self) weakSelf = self;
        [self requestTwitterAccessInView:[self.publishViewController twitterSharingView] fromViewController:self.publishViewController withCancellationBlock:^{
            [weakSelf.publishViewController setSharingTW:NO];
            weakSelf.sharingTW = NO;
            [weakSelf.shareFlags removeObject:DQAPIValueShareChannelTypeTwitter];
            [weakSelf refreshRewardsInfo];
            if (cancellationBlock)
            {
                cancellationBlock();
            }
        } accountSelectedBlock:^{
            // should it do something here?
        } completionBlock:^{
            [weakSelf.publishViewController setSharingTW:YES];
            [weakSelf.shareFlags addObject:DQAPIValueShareChannelTypeTwitter];
            [weakSelf refreshRewardsInfo];
            if (completionBlock)
            {
                completionBlock();
            }
        } failureBlock:^(NSError *error) {
            [weakSelf.publishViewController setSharingTW:NO];
            weakSelf.sharingTW = NO;
            [weakSelf.shareFlags removeObject:DQAPIValueShareChannelTypeTwitter];
            [weakSelf refreshRewardsInfo];
            [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") forError:error];
            if (failureBlock)
            {
                failureBlock(error);
            }
        }];
    }
    else
    {
        [self.publishViewController setSharingTW:sharingTW];
        [self.shareFlags removeObject:DQAPIValueShareChannelTypeTwitter];
        [self refreshRewardsInfo];
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (void)refreshRewardsInfo
{
    if (self.editorViewController)
    {
        [self.publicServiceController requestPostingRewardsForQuestID:self.editorViewController.quest.serverID shareFlags:self.shareFlags withCompletionBlock:^(DQHTTPRequest *request, id JSONObject) {
            if (request && [JSONObject isKindOfClass:[NSDictionary class]])
            {
                [self.publishViewController setRewardsInfo:(NSDictionary *)JSONObject];
            }
        } failureBlock:nil];
        // FIXME: This should probably handle failure somehow
    }
}

- (void)failedWithError:(NSError *)error
{
    if (self.failureBlock)
    {
        self.failureBlock(error);
    }
    self.modalNavigationController = nil;
    self.editorViewController = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)cancel
{
    if (self.cancellationBlock)
    {
        self.cancellationBlock();
    }
    self.modalNavigationController = nil;
    self.editorViewController = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)complete
{
    if (self.completionBlock)
    {
        self.completionBlock();
    }
    self.modalNavigationController = nil;
    self.editorViewController = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (NSString *)publishingTitle
{
    return @"";
}

#pragma mark -
#pragma mark DQCommentPublishViewControllerDataSource methods

- (BOOL)isSharingWithFacebookForCommentPublishViewController:(DQCommentPublishViewController *)pvc
{
    return self.sharingFB;
}

- (void)commentPublishViewController:(DQCommentPublishViewController *)pvc setSharingWithFacebook:(BOOL)sharingWithFacebook
{
    self.sharingFB = sharingWithFacebook;
}

- (BOOL)isSharingWithTwitterForCommentPublishViewController:(DQCommentPublishViewController *)pvc
{
    return self.sharingTW;
}

- (void)commentPublishViewController:(DQCommentPublishViewController *)pvc setSharingWithTwitter:(BOOL)sharingWithTwitter
{
    self.sharingTW = sharingWithTwitter;
}

#pragma mark -
#pragma mark DQCommentPublishViewControllerDelegate methods

- (void)publishViewController:(DQCommentPublishViewController *)publishViewController didSelectShareOption:(DQPublishShareOptionsViewType)shareType fromShareOptionsView:(DQPublishShareOptionsView *)view
{
    if (shareType == DQPublishShareOptionsViewTypeFacebook)
    {
        [view showActivityForShareOption:shareType isActive:YES];
        [self setSharingFB:!_sharingFB withCancellationBlock:^{
            [view showActivityForShareOption:shareType isActive:NO];
        }completionBlock:^{
            [view showActivityForShareOption:shareType isActive:NO];
        } failureBlock:^(NSError *error) {
            [view showActivityForShareOption:shareType isActive:NO];
        }];
    }
    else if (shareType == DQPublishShareOptionsViewTypeTwitter)
    {
        [view showActivityForShareOption:shareType isActive:YES];
        [self setSharingTW:!_sharingTW withCancellationBlock:^{
            [view showActivityForShareOption:shareType isActive:NO];
        }completionBlock:^{
            [view showActivityForShareOption:shareType isActive:NO];
        } failureBlock:^(NSError *error) {
            [view showActivityForShareOption:shareType isActive:NO];
        }];
    }
    else if (shareType == DQPublishShareOptionsViewTypeEmail)
    {
        DQEmailSharingViewController *vc = [[DQEmailSharingViewController alloc] initWithEmailList:self.emailList];
        vc.title = DQLocalizedString(@"Email", @"Email");
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        DQButton *doneButton = [DQButton buttonWithType:UIButtonTypeCustom];
        [doneButton setTintColorForTitle:YES];
        [doneButton setTitle:DQLocalizedString(@"Done", @"User is done with this action button title") forState:UIControlStateNormal];
        [doneButton sizeToFit];
        __weak typeof(vc) weakVC = vc;
        __weak typeof(self) weakSelf = self;
        doneButton.tappedBlock = ^(DQButton *button) {
            NSArray *emailList = weakVC.emailList;
            [view shareOption:shareType highlight:([emailList count] > 0)];
            weakSelf.emailList = emailList;
            [weakSelf.publishViewController dismissViewControllerAnimated:YES completion:nil];
        };
        vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
        [self.publishViewController presentViewController:navController animated:YES completion:nil];
    }
    else if (shareType == DQPublishShareOptionsViewTypeTextMessage)
    {
        if([MFMessageComposeViewController canSendText] && [MFMessageComposeViewController canSendAttachments])
        {
            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
            controller.messageComposeDelegate = self;
            NSString *message = DQLocalizedString(@"Check out this drawing I made on DrawQuest: \"%@\"\n\n You should download the app at http://example.com/download", @"Share via text message body");
            message = [NSString stringWithFormat:message, self.editorViewController.quest.title];
            controller.body = message;
            NSData *imageData = UIImagePNGRepresentation([self.editorViewController.editorView imageRepresentation]);
            NSString *filename = [self.editorViewController.quest.title stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            filename = [NSString stringWithFormat:@"%@.png", filename];
            [controller addAttachmentData:imageData typeIdentifier:(__bridge NSString *)kUTTypePNG filename:filename];

            self.messageComposeSuccessBlock = ^{
                [view flashSuccessForShareOption:shareType];
            };

            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            [self.publishViewController presentViewController:controller animated:YES completion:nil];
        }
        else
        {
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Messages Error", @"Messages app error title") message:DQLocalizedString(@"There was an error opening the Messages app.", @"Messages app error message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)refreshRewardsInfoForCommentPublishViewController:(DQCommentPublishViewController *)pvc
{
    [self refreshRewardsInfo];
}

#pragma mark -
#pragma mark MFMessageComposeViewControllerDelegate Methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    __weak typeof(self) weakSelf = self;
    [self.publishViewController dismissViewControllerAnimated:YES completion:^{
        if (result == MessageComposeResultSent && weakSelf.messageComposeSuccessBlock)
        {
            weakSelf.messageComposeSuccessBlock();
            weakSelf.messageComposeSuccessBlock = nil;
        }
    }];
}

@end

#pragma mark -

@implementation DQCommentPublishController (PrivateMethods)

- (void)_presentAuth
{
    if (self.makePublishAuthViewControllerBlock)
    {
        __weak typeof(self) weakSelf = self;
        self.modalNavigationController = self.makeModalNavigationControllerBlock(self);
        DQPublishAuthViewController *vc = self.makePublishAuthViewControllerBlock(self);
        vc.title = DQLocalizedString(@"Join DrawQuest", @"Sign up modal title");
        vc.navigationItem.leftBarButtonItem = [self newCancelBarButtonItemWithBlock:^(id sender) {
            [weakSelf.statechart dqCancelTask:weakSelf];
        }];
        vc.facebookBlock = ^(DQPublishAuthViewController *c) {
            [weakSelf.statechart auth:weakSelf withOption:@(DQAuthenticationOptionFacebookSignUp)];
        };
        vc.twitterBlock = ^(DQPublishAuthViewController *c, UIView *sender) {
            [weakSelf.statechart authTwitter:weakSelf fromView:sender];
        };
        vc.drawQuestBlock = ^(DQPublishAuthViewController *c) {
            [weakSelf.statechart auth:weakSelf withOption:@(DQAuthenticationOptionEmailSignUp)];
        };
        vc.signInBlock = ^(DQPublishAuthViewController *c) {
            [weakSelf.statechart auth:weakSelf withOption:@(DQAuthenticationOptionSignIn)];
        };
        [self.modalNavigationController setViewControllers:@[vc]];
        [self.editorViewController presentViewController:self.modalNavigationController animated:YES completion:nil];
    }
    else
    {
        // TODO: fail
    }
}

- (void)_cancelPresentingAuth
{
    __weak typeof(self) weakSelf = self;
    [self.editorViewController dismissViewControllerAnimated:YES completion:^{
        [weakSelf cancel];
    }];
}

- (void)_authenticateWithTwitterFromView:(UIView *)sender
{
    __weak typeof(self) weakSelf = self;
    [self _authenticateWithOption:@(DQAuthenticationOptionTwitterSignUp) fromView:sender twitterSheetDismissedBlock:^{
        [weakSelf.statechart pop:weakSelf];
    } cancellationBlock:^{
        [weakSelf.statechart dqCancelTask:weakSelf];
    }];
}

- (void)_authenticateWithOption:(NSNumber *)optionNumber
{
    __weak typeof(self) weakSelf = self;
    [self _authenticateWithOption:optionNumber fromView:nil twitterSheetDismissedBlock:^{
        // this won't be called - any twitter popover a user might see in the course
        // of doing this flow would be internal to a modal and would be handled
        // internally by that modal
        [weakSelf.statechart dqCancelTask:weakSelf];
    } cancellationBlock:^{
        [weakSelf.statechart dqCancelTask:weakSelf];
    }];
}

- (void)_authenticateWithOption:(NSNumber *)optionNumber fromView:(UIView *)sender twitterSheetDismissedBlock:(dispatch_block_t)twitterSheetDismissedBlock cancellationBlock:(dispatch_block_t)cancellationBlock
{
    __weak typeof(self) weakSelf = self;
    [self.delegate commentPublishController:self authenticateFromEditor:self.editorViewController modalNavigationController:self.modalNavigationController withOption:[optionNumber integerValue] fromView:sender twitterSheetDismissedBlock:^{
        if (twitterSheetDismissedBlock)
        {
            twitterSheetDismissedBlock();
        }
    } cancellationBlock:^{
        if (cancellationBlock)
        {
            cancellationBlock();
        }
    } completionBlock:^(DQAuthenticationSignupService signupService, DQNavigationController *modalNavigationController) {
        self.signupService = signupService;
        self.modalNavigationController = modalNavigationController;
        self.onboarding = signupService != DQAuthenticationSignupServiceNone;

        if (self.onboarding)
        {
            [weakSelf.statechart signedUp:weakSelf];
        }
        else
        {
            [weakSelf.statechart signedIn:weakSelf];
        }
    } failureBlock:^(NSError *error) {
        [weakSelf.statechart failed:weakSelf error:error];
    }];
}

- (void)_authenticatingFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Sign Up Failed", @"Sign up failed alert title") forError:error];
}

- (void)_presentShare
{
    // initialize these variables without triggering the setters
    _sharingFB = self.accountController.loggedInAccount.shareToFacebookOn || self.signupService == DQAuthenticationSignupServiceFacebook;
    _sharingTW = self.accountController.loggedInAccount.shareToTwitterOn || self.signupService == DQAuthenticationSignupServiceTwitter;

    if (self.sharingFB)
    {
        [self.shareFlags addObject:DQAPIValueShareChannelTypeFacebook];
    }
    if (self.sharingTW)
    {
        [self.shareFlags addObject:DQAPIValueShareChannelTypeTwitter];
    }

    if (self.makePublishViewControllerBlock)
    {
        self.publishViewController = self.makePublishViewControllerBlock(self);
        // Initialize toggle values
        [self.publishViewController setSharingFB:_sharingFB];
        [self.publishViewController setSharingTW:_sharingTW];

        self.publishViewController.title = [self publishingTitle];

        if (self.onboarding)
        {
            self.publishViewController.navigationItem.hidesBackButton = YES;
        }
        else
        {
            self.publishViewController.navigationItem.leftBarButtonItem = [self newCancelBarButtonItemWithAction:@selector(presentingShareCancelTapped:)];
        }

        __weak typeof(self) weakSelf = self;
        void (^postBlock)(id) = ^(id sender) {

            DQHUDView *hud = [[DQHUDView alloc] initWithFrame:weakSelf.publishViewController.view.bounds];
            hud.text = DQLocalizedString(@"Authorizing", @"User is being authorized message");

            [weakSelf.publishViewController submitPublishToFacebook:weakSelf.sharingFB publishToTwitter:weakSelf.sharingTW beginAuthorizingFacebookBlock:^{
                [hud showInView:weakSelf.modalNavigationController.view animated:YES];
            } endAuthorizingFacebookBlock:^{
                [hud hideAnimated:YES];
            } cancellationBlock:^{
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"Authorization was cancelled.", @"The user cancelled authorization message")};
                NSError *error = [NSError errorWithDomain:DQCommentPublishErrorDomain code:DQCommentPublishFailedCode userInfo:userInfo];
                [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Authorization Error", @"User authorization error alert title") forError:error];
            } completionBlock:^{
                [weakSelf presentingSharePostTapped:nil];
            } failureBlock:^(NSError *error) {
                [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Authorization Error", @"User authorization error alert title") forError:error];
            }];
        };

        UIBarButtonItem *postButton = [self newBarButtonItemWithTitle:DQLocalizedString(@"Post", @"Begin upload button title") isPrimaryAction:YES block:postBlock];
        self.publishViewController.submitButtonTappedBlock = ^(DQCommentPublishViewController *vc, DQButton *button) {
            postBlock(button);
        };
        self.publishViewController.navigationItem.rightBarButtonItem = postButton;

        if (self.modalNavigationController.presentingViewController)
        {
            [self.modalNavigationController pushViewController:self.publishViewController animated:YES];
        }
        else
        {
            [self.modalNavigationController setViewControllers:@[self.publishViewController]];
            [self.editorViewController presentViewController:self.modalNavigationController animated:YES completion:nil];
        }
    }
    else
    {
        // FIXME: fail
    }
}

- (void)_cancelPresentingShare
{
    __weak typeof(self) weakSelf = self;
    [self.editorViewController dismissViewControllerAnimated:YES completion:^{
        [weakSelf cancel];
    }];
}

- (void)_post
{
    NSString *facebookAccessToken = self.sharingFB ? [self openFacebookSessionAccessToken] : nil;
    NSString *twitterAccessToken = self.sharingTW ? self.twitterAccessToken : nil;
    NSString *twitterAccessTokenSecret = self.sharingTW ? self.twitterAccessTokenSecret : nil;
    NSError *error = nil;
    
    if ([self.shareFlags containsObject:DQAPIValueShareChannelTypeFacebook] && !facebookAccessToken.length)
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"Unable to share to Facebook due to an unknown error.", @"Unknown Facebook upload error message")};
        error = [NSError errorWithDomain:DQCommentPublishErrorDomain code:DQCommentPublishMissingFacebookTokenErrorCode userInfo:userInfo];
    }
    else if ([self.shareFlags containsObject:DQAPIValueShareChannelTypeTwitter] && (!twitterAccessToken.length || !twitterAccessTokenSecret.length))
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"Unable to share to Twitter due to an unknown error.", @"Unknown Twitter upload error message")};
        error = [NSError errorWithDomain:DQCommentPublishErrorDomain code:DQCommentPublishMissingTwitterTokenErrorCode userInfo:userInfo];
    }
    else if (self.makeModalNavigationControllerBlock)
    {
        [self.accountController setShareToFacebookOn:self.sharingFB completionBlock:nil failureBlock:nil];
        [self.accountController setShareToTwitterOn:self.sharingTW completionBlock:nil failureBlock:nil];
        // save the image and playback data to the area where the uploader will read it
        if ([self.editorViewController publish]) // TODO: refactor this publish method into this class
        {
            self.accountController.loggedInAccount.hasPublishedAComment = YES;
            // Dismiss the publish sheet
            self.facebookAccessToken = facebookAccessToken;
            self.twitterAccessToken = twitterAccessToken;
            self.twitterAccessTokenSecret = twitterAccessTokenSecret;
            [self _postComplete];
        }
        else
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"There was a problem saving the drawing, DrawQuest is unable to post.", @"Unknown DrawQuest upload error message")};
            error = [NSError errorWithDomain:DQCommentPublishErrorDomain code:DQCommentPublishFailedCode userInfo:userInfo];
        }
    }
    else
    {
        error = [NSError errorWithDomain:DQCommentPublishErrorDomain code:DQCommentPublishMissingBlocksErrorCode userInfo:@{NSLocalizedDescriptionKey: NSStringFromSelector(_cmd)}];
    }
    
    if (error)
    {
        [self.statechart failed:self error:error];
    }
}

- (void)_postComplete
{
    __weak typeof(self) weakSelf = self;

    DQNavigationController *strongModalNavigationController = self.modalNavigationController;
    [self.editorViewController dismissViewControllerAnimated:YES completion:^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.publishViewController = nil;
        strongSelf.modalNavigationController = strongSelf.makeModalNavigationControllerBlock(strongSelf);
        [strongModalNavigationController self]; // just to ensure the old instance survives past the previous line, see dq-434
        [strongSelf.statechart gallery:strongSelf];
    }];
}

- (void)_postingFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Post Error", @"Upload error alert title") forError:error];
}

- (void)_presentGallery
{
    // subclasses must override this
}

- (void)_completePresentingGallery
{
    // nothing right now
    [self complete];
}

- (void)_presentAddFriends
{
    // subclasses must override this
}

- (void)_presentNiceJob
{
    // subclasses must override this
}

- (void)_completePresentingNiceJob
{
    // subclasses must override this
    [self complete];
}

@end

@implementation DQCommentPublishControllerStatechart

+ (DQCommentPublishControllerStatechart *)statechart
{
    return (DQCommentPublishControllerStatechart *)[super statechart];
}

#ifdef DEBUG
- (BOOL)shouldLogTransitions
{
    return YES;
}
#endif

@end
