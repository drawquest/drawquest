//
//  DQQuestPublishController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestPublishController.h"

#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "DQPublicServiceController.h"
#import "DQAccountController.h"
#import "DQDataStoreController.h"
#import "DQFacebookController.h"
#import "DQTwitterController.h"
#import "DQNavigationController.h"
#import "DQQuestPublishViewController.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAddFriendsViewController.h"
#import "DQAlertView.h"
#import "DQHUDView.h"

#import "DQQuest.h"

#import "DQPadQuestPublishController.h"
#import "DQPhoneQuestPublishController.h"
#import "DQEmailSharingViewController.h"

NSString *DQQuestPublishErrorDomain = @"DQQuestPublishErrorDomain";
const NSInteger DQQuestPublishMissingFacebookTokenErrorCode = 1000;
const NSInteger DQQuestPublishMissingTwitterTokenErrorCode = 1001;
const NSInteger DQQuestPublishFailedCode = 1002;
const NSInteger DQQuestPublishMissingBlocksErrorCode = 1003;

@interface DQQuestPublishController () <RCSStatechartContext, MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *statechartStack;

@property (nonatomic, strong) DQQuestPublishViewController *publishViewController;

@property (nonatomic, copy) dispatch_block_t cancellationBlock;
@property (nonatomic, copy) dispatch_block_t completionBlock;
@property (nonatomic, copy) dispatch_block_t messageComposeSuccessBlock;
@property (nonatomic, copy) void (^failureBlock)(NSError *error);

@property (nonatomic, assign, getter = isSharingFB) BOOL sharingFB;
@property (nonatomic, assign, getter = isSharingTW) BOOL sharingTW;
@property (nonatomic, readwrite, strong) DQQuestUpload *questUpload;
@property (nonatomic, readwrite, strong) DQQuest *quest;

@property (nonatomic, strong) DQHUDView *uploadingHUDView;

@end

@implementation DQQuestPublishController

@dynamic delegate;

+ (void)initialize
{
    if (self == [DQQuestPublishController class])
    {
        id<RCSStatechart> Base                           = [DQQuestPublishControllerStatechart statechart];
        id<RCSStatechart> Error                          = [Base statechartNamed:@"Error"];
        id<RCSStatechart> Start                          = [Base statechartNamed:@"Start"];

        id<RCSStatechart> PresentingAuth                 = [Base statechartNamed:@"PresentingAuth"];
        id<RCSStatechart> PresentingQuestTitle           = [Base statechartNamed:@"PresentingQuestTitle"];
        id<RCSStatechart> PresentingShare                = [Base statechartNamed:@"PresentingShare"];

        id<RCSStatechart> Posting                        = [Base statechartNamed:@"Posting"];

        id<RCSStatechart> PresentingGallery              = [Base statechartNamed:@"PresentingGallery"];

        id<RCSStatechart> Cancelled                      = [Base statechartNamed:@"Cancelled"];
        id<RCSStatechart> Complete                       = [Base statechartNamed:@"Complete"];

        SEL auth        = [Base transitionToErrorStatechartWhen:@selector(auth:)];
        SEL share       = [Base transitionToErrorStatechartWhen:@selector(share:)];
        SEL post        = [Base transitionToErrorStatechartWhen:@selector(post:)];
        SEL signedIn    = [Base transitionToErrorStatechartWhen:@selector(signedIn:)];
        SEL gallery     = [Base transitionToErrorStatechartWhen:@selector(gallery:)];
        SEL back        = [Base transitionToErrorStatechartWhen:@selector(backTask:)];
        SEL cancel      = [Base transitionToErrorStatechartWhen:@selector(dqCancelTask:)];
        SEL complete    = [Base transitionToErrorStatechartWhen:@selector(complete:)];
        SEL failedMessage = [Base transitionToErrorStatechartWhen:@selector(failed:message:)];
        SEL failedError = [Base transitionToErrorStatechartWhen:@selector(failed:error:)];

        [Base declareErrorStatechart:Error];
        [Base declareStartStatechart:Start];

        [Start when:auth transitionTo:PresentingAuth before:@selector(_presentAuth)];
        [Start when:signedIn transitionTo:PresentingQuestTitle before:@selector(_presentQuestTitle)];

        [PresentingAuth when:cancel transitionTo:Cancelled before:@selector(_cancelPresentingAuth)];
        [PresentingAuth when:signedIn transitionTo:PresentingQuestTitle before:@selector(_presentQuestTitle)];
        [PresentingAuth when:failedError transitionTo:Cancelled before:@selector(_authenticatingFailedWithError:)];

        [PresentingQuestTitle when:cancel transitionTo:Cancelled before:@selector(_cancelPresentingQuestTitle)];
        [PresentingQuestTitle when:share push:PresentingShare before:@selector(_presentShare)];

        [PresentingShare when:back transitionTo:PresentingQuestTitle];
        [PresentingShare when:post push:Posting before:@selector(_post)];

        [Posting popWhen:failedMessage before:@selector(_postingFailedWithMessage:)];
        [Posting popWhen:failedError before:@selector(_postingFailedWithError:)];
        [Posting when:gallery transitionTo:PresentingGallery before:@selector(_presentGallery)];

        [PresentingGallery when:complete transitionTo:Complete before:@selector(_completePresentingGallery)];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQQuestUploadProgressChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQQuestUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQQuestUploadCompletedNotification object:nil];
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate accountController:(DQAccountController *)accountController questUpload:(DQQuestUpload *)questUpload questUploadController:(DQQuestUploadController *)questUploadController
{
    if ([self class] == [DQQuestPublishController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadQuestPublishController alloc] initWithDelegate:delegate accountController:accountController questUpload:questUpload questUploadController:questUploadController];
        }
        else
        {
            self = [[DQPhoneQuestPublishController alloc] initWithDelegate:delegate accountController:accountController questUpload:questUpload questUploadController:questUploadController];
        }
    }
    else
    {
        self = [super initWithDelegate:delegate];
        if (self)
        {
            _statechartStack = [NSMutableArray new];
            _statechart = [[DQQuestPublishControllerStatechart statechart] startStatechart];
            _accountController = accountController;
            _questUpload = questUpload;
            _questUploadController = questUploadController;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadProgressChanged:) name:DQQuestUploadProgressChangedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStatusChanged:) name:DQQuestUploadStatusChangedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadCompleted:) name:DQQuestUploadCompletedNotification object:nil];
        }
    }
    return self;
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

- (void)presentFromViewController:(UIViewController *)presentingViewController
                cancellationBlock:(dispatch_block_t)cancellationBlock
                  completionBlock:(dispatch_block_t)completionBlock
                     failureBlock:(void (^)(NSError *error))failureBlock
{
    self.presentingViewController = presentingViewController;
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

- (void)takeTemplateImage:(UIImage *)templateImage
{
    self.publishViewController.templateImage = templateImage;
    [self.dataStoreController saveContentID:nil forQuestUpload:self.questUpload];
    if (templateImage)
    {
        [self.dataStoreController saveStatus:DQQuestUploadStatusNew forQuestUpload:self.questUpload];
    }
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
        [self requestFacebookPublishAccessFromViewController:self.publishViewController feature:@"share-quest-while-publishing" cancellationBlock:^{
            [weakSelf.publishViewController setSharingFB:NO];
            weakSelf.sharingFB = NO;
            if (cancellationBlock)
            {
                cancellationBlock();
            }
        } completionBlock:^(NSString *facebookToken) {
            [weakSelf.publishViewController setSharingFB:YES];
            [weakSelf.dataStoreController saveShareToFacebook:YES forQuestUpload:weakSelf.questUpload];
            if (completionBlock)
            {
                completionBlock();
            }
        } failureBlock:^(NSError *error) {
            [weakSelf.publishViewController setSharingFB:NO];
            weakSelf.sharingFB = NO;
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
        [self.dataStoreController saveShareToFacebook:NO forQuestUpload:self.questUpload];
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
            if (cancellationBlock)
            {
                cancellationBlock();
            }
        } accountSelectedBlock:^{
            // should it do something here?
        } completionBlock:^{
            [weakSelf.publishViewController setSharingTW:YES];
            [weakSelf.dataStoreController saveShareToTwitter:YES forQuestUpload:weakSelf.questUpload];
            if (completionBlock)
            {
                completionBlock();
            }
        } failureBlock:^(NSError *error) {
            [weakSelf.publishViewController setSharingTW:NO];
            weakSelf.sharingTW = NO;
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
        [self.dataStoreController saveShareToTwitter:NO forQuestUpload:self.questUpload];
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (void)upload
{
    UIView *rootView = self.publishViewController.view.window.rootViewController.view;
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:rootView.bounds];
    hud.text = DQLocalizedString(@"Posting", @"Upload is in progress indicator label");
    self.uploadingHUDView = hud;
    [hud showInView:rootView animated:YES];
    [self.questUploadController uploadQuestUpload:self.questUpload];
}

- (void)uploadProgressChanged:(NSNotification *)notification
{
/*    DQQuestUpload *notificationQuestUpload = [notification userInfo][DQQuestUploadObjectNotificationKey];
    if ([notificationQuestUpload.identifier isEqualToString:self.questUpload.identifier])
    {

    }*/
}

- (void)uploadCompleted:(NSNotification *)notification
{
    DQQuestUpload *notificationQuestUpload = [notification userInfo][DQQuestUploadObjectNotificationKey];
    if ([notificationQuestUpload.identifier isEqualToString:self.questUpload.identifier])
    {
        // tear down the HUD
        [self.uploadingHUDView hideAnimated:YES];
        self.uploadingHUDView = nil;
        self.quest = [notification userInfo][DQQuestObjectNotificationKey];
        [self.statechart gallery:self];
    }
}

- (void)uploadStatusChanged:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSError *error = userInfo[NSUnderlyingErrorKey];
    DQQuestUpload *notificationQuestUpload = [notification object];
    if ([notificationQuestUpload.identifier isEqualToString:self.questUpload.identifier])
    {
        switch (notificationQuestUpload.status)
        {
            case DQQuestUploadStatusFailedUploadingImage:
                [self.uploadingHUDView hideAnimated:YES];
                self.uploadingHUDView = nil;
                if (error)
                {
                    [self.statechart failed:self error:error];
                }
                else
                {
                    [self.statechart failed:self message:DQLocalizedString(@"Uploading the image failed. Try again?", @"The image upload failed, prompt to try the upload again")];
                }
                break;
            case DQQuestUploadStatusFailedPostingQuest:
                [self.uploadingHUDView hideAnimated:YES];
                self.uploadingHUDView = nil;
                if (error)
                {
                    [self.statechart failed:self error:error];
                }
                else
                {
                    [self.statechart failed:self message:DQLocalizedString(@"Posting failed. Try again?", @"The comment upload failed, prompt to try the upload again")];
                }
                break;
            case DQQuestUploadStatusFailedWithInvalidFacebookToken:
                [self.uploadingHUDView hideAnimated:YES];
                self.uploadingHUDView = nil;
                [self.statechart failed:self message:DQLocalizedString(@"Posting to Facebook Failed.\nTry Again?", @"Upload to Facebook failed message")];
                break;
            case DQQuestUploadStatusFailedWithInvalidTwitterToken:
                [self.uploadingHUDView hideAnimated:YES];
                self.uploadingHUDView = nil;
                [self.statechart failed:self message:DQLocalizedString(@"Posting to Twitter Failed.\nTry Again?", @"Upload to Twitter failed message")];
                break;
            case DQQuestUploadStatusUploadingImage:
            case DQQuestUploadStatusPostingQuest:
                break;
            default:
                break;
        }
    }
}

- (void)showError:(NSError *)inError
{
    [self showErrorWithTitle:nil andDescription:inError.dq_displayDescription];
}

- (void)showErrorWithTitle:(NSString *)inTitle andDescription:(NSString *)inDescription
{
    inTitle = inTitle ?: DQLocalizedString(@"Error", @"Generic error alert title");

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:inTitle message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [alert show];
}

- (void)failedWithError:(NSError *)error
{
    [self.uploadingHUDView hideAnimated:YES];
    self.uploadingHUDView = nil;
    if (self.failureBlock)
    {
        self.failureBlock(error);
    }
    self.presentingViewController = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)cancel
{
    [self.uploadingHUDView hideAnimated:YES];
    self.uploadingHUDView = nil;
    if (self.cancellationBlock)
    {
        self.cancellationBlock();
    }
    self.presentingViewController = nil;
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
    self.presentingViewController = nil;
    self.cancellationBlock = nil;
    self.completionBlock = nil;
    self.failureBlock = nil;
}

- (void)authorizePublishToFacebook:(BOOL)publishToFacebook publishToTwitter:(BOOL)publishToTwitter twitterSharingView:(UIView *)twitterSharingView fromViewController:(UIViewController *)presentingViewController beginAuthorizingFacebookBlock:(dispatch_block_t)beginAuthorizingFacebookBlock endAuthorizingFacebookBlock:(dispatch_block_t)endAuthorizingFacebookBlock cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    // Make sure we have authed with any requested services before posting.
    // Authorizations are done linearly and we will stop authing if any
    // cancel or fail.

    NSString *facebookAccessToken = publishToFacebook && [self.facebookController hasOpenFacebookSessionWithPermissions:@[@"email", @"publish_actions"]] ? [self.facebookController openFacebookSessionAccessToken] : nil;
    NSString *twitterAccessToken = publishToTwitter ? self.twitterController.twitterAccessToken : nil;
    NSString *twitterAccessTokenSecret = publishToTwitter ? self.twitterController.twitterAccessTokenSecret : nil;

    __weak typeof(self) weakSelf = self;

    void (^facebookAuthBlock)(dispatch_block_t) = ^(dispatch_block_t facebookCompletionBlock) {
        if (publishToFacebook && ! facebookAccessToken)
        {
            if (beginAuthorizingFacebookBlock)
            {
                beginAuthorizingFacebookBlock();
            }
            [weakSelf requestFacebookPublishAccessFromViewController:presentingViewController feature:@"publish-quest" cancellationBlock:^{
                if (endAuthorizingFacebookBlock)
                {
                    endAuthorizingFacebookBlock();
                }
                if (cancellationBlock)
                {
                    cancellationBlock();
                }
            } completionBlock:^(NSString *facebookToken) {
                if (endAuthorizingFacebookBlock)
                {
                    endAuthorizingFacebookBlock();
                }
                if (facebookCompletionBlock)
                {
                    facebookCompletionBlock();
                }
            } failureBlock:^(NSError *error) {
                if (endAuthorizingFacebookBlock)
                {
                    endAuthorizingFacebookBlock();
                }
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }];
        }
        else if (facebookCompletionBlock)
        {
            facebookCompletionBlock();
        }
    };

    void (^twitterAuthBlock)(dispatch_block_t) = ^(dispatch_block_t twitterCompletionBlock) {
        if (publishToTwitter && ! (twitterAccessToken && twitterAccessTokenSecret))
        {
            [weakSelf requestTwitterAccessInView:twitterSharingView fromViewController:presentingViewController withCancellationBlock:cancellationBlock accountSelectedBlock:nil completionBlock:twitterCompletionBlock failureBlock:failureBlock];
        }
        else if (twitterCompletionBlock)
        {
            twitterCompletionBlock();
        }
    };

    facebookAuthBlock(^{
        twitterAuthBlock(completionBlock);
    });
}

#pragma mark -
#pragma mark DQQuestPublishViewControllerDelegate methods

- (void)publishViewController:(DQQuestPublishViewController *)publishViewController didSelectShareOption:(DQPublishShareOptionsViewType)shareType fromShareOptionsView:(DQPublishShareOptionsView *)view
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
        DQEmailSharingViewController *vc = [[DQEmailSharingViewController alloc] initWithEmailList:self.questUpload.emailList];
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
            [weakSelf.dataStoreController saveEmailList:emailList forQuestUpload:weakSelf.questUpload];
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
            NSString *message = DQLocalizedString(@"I just created a Quest on DrawQuest: \"%@\" Come draw it with me! http://example.com/download", @"Message inviting another to come draw the Quest the user just created");
            message = [NSString stringWithFormat:message, self.publishViewController.questTitle];
            controller.body = message;
            NSData *imageData = UIImagePNGRepresentation(self.publishViewController.templateImage);
            if (imageData)
            {
                NSString *filename = [self.publishViewController.questTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                filename = [NSString stringWithFormat:@"%@.png", filename];
                [controller addAttachmentData:imageData typeIdentifier:(__bridge NSString *)kUTTypePNG filename:filename];
            }

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

@implementation DQQuestPublishController (PrivateMethods)

- (void)_presentAuth
{
    __weak typeof(self) weakSelf = self;
    [self.delegate authenticatedForController:self fromViewController:self.presentingViewController cancellationBlock:^{
        [weakSelf.statechart dqCancelTask:weakSelf];
    } completionBlock:^(DQAuthenticationSignupService service, DQNavigationController *modalNavigationController) {
        [weakSelf.statechart signedIn:weakSelf];
    } failureBlock:^(NSError *error) {
        [weakSelf.statechart failed:weakSelf error:error];
    }];
}

- (void)_cancelPresentingAuth
{
    [self cancel];
}

- (void)_authenticatingFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Sign In Failed", @"Sign in failed alert title") forError:error];
}

- (void)_presentQuestTitle
{
    __weak typeof(self) weakSelf = self;
    self.pushSimilarQuestsViewControllerBlock(self, ^(DQSimilarQuestsViewController *vc) {
        vc.titleField.text = weakSelf.questUpload.title;
        vc.navigationItem.title = DQLocalizedString(@"Create a Quest", @"Prompt to create a new Quest");
        UITextField *titleField = vc.titleField;
        dispatch_block_t nextBlock = ^{
            if ([[titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
            {
                DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Name your Quest!", @"Name required for Quest alert title") message:DQLocalizedString(@"Please enter a title for your Quest to continue.", @"Name required for Quest alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                [weakSelf.dataStoreController saveTitle:titleField.text forQuestUpload:weakSelf.questUpload];
                [weakSelf.statechart share:weakSelf];
            }
        };
        vc.navigationItem.rightBarButtonItem = [weakSelf newNextBarButtonItemWithBlock:^(id sender) {
            nextBlock();
        }];
        vc.returnTappedOnTitleFieldBlock = ^(DQSimilarQuestsViewController *vc) {
            nextBlock();
        };
    }, ^(DQSimilarQuestsViewController *vc) {
        [weakSelf.statechart dqCancelTask:weakSelf];
    });
}

- (void)_presentShare
{
    // initialize these variables without triggering the setters
    _sharingFB = self.accountController.loggedInAccount.shareToFacebookOn;
    _sharingTW = self.accountController.loggedInAccount.shareToTwitterOn;

    [self.dataStoreController saveShareToFacebook:self.sharingFB forQuestUpload:self.questUpload];
    [self.dataStoreController saveShareToTwitter:self.sharingTW forQuestUpload:self.questUpload];

    __weak typeof(self) weakSelf = self;
    self.pushShareQuestViewControllerBlock(self, ^(DQQuestPublishViewController *vc) {
        weakSelf.publishViewController = vc;
        [vc setSharingFB:weakSelf.sharingFB];
        [vc setSharingTW:weakSelf.sharingTW];
        vc.questTitle = weakSelf.questUpload.title;
        vc.templateImage = weakSelf.questUpload.image;
        vc.navigationItem.title = DQLocalizedString(@"Share", @"Drawing being published with options to share the drawing modal title");

        void (^postBlock)(id) = ^(id sender) {
            DQHUDView *hud = [[DQHUDView alloc] initWithFrame:weakSelf.publishViewController.view.window.rootViewController.view.bounds];
            hud.text = DQLocalizedString(@"Authorizing", @"User is being authorized message");

            [weakSelf authorizePublishToFacebook:weakSelf.sharingFB publishToTwitter:weakSelf.sharingTW twitterSharingView:[vc twitterSharingView] fromViewController:vc beginAuthorizingFacebookBlock:^{
                [hud showInView:weakSelf.publishViewController.view.window.rootViewController.view animated:YES];
            } endAuthorizingFacebookBlock:^{
                [hud hideAnimated:YES];
            } cancellationBlock:^{
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"Authorization was cancelled.", @"The user cancelled authorization message")};
                NSError *error = [NSError errorWithDomain:DQQuestPublishErrorDomain code:DQQuestPublishFailedCode userInfo:userInfo];
                [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Authorization Error", @"User authorization error alert title") forError:error];
            } completionBlock:^{
                [weakSelf.statechart post:weakSelf];
            } failureBlock:^(NSError *error) {
                [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Authorization Error", @"User authorization error alert title") forError:error];
            }];
        };
        vc.navigationItem.rightBarButtonItem = [weakSelf newBarButtonItemWithTitle:DQLocalizedString(@"Post", @"Begin upload button title") isPrimaryAction:YES block:postBlock];
        vc.submitButtonTappedBlock = ^(DQQuestPublishViewController *vc, DQButton *button) {
            postBlock(button);
        };
    }, ^(DQQuestPublishViewController *vc) {
        [weakSelf.statechart backTask:weakSelf];
    });
}

- (void)_cancelPresentingQuestTitle
{
    [self cancel];
}

- (void)_post
{
    NSString *facebookToken = self.sharingFB ? [self openFacebookSessionAccessToken] : nil;
    NSString *twitterToken = self.sharingTW ? self.twitterController.twitterAccessToken : nil;
    NSString *twitterTokenSecret = self.sharingTW ? self.twitterController.twitterAccessTokenSecret : nil;
    NSError *error = nil;

    if (self.questUpload.shareToFacebook && !facebookToken.length)
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"Unable to share to Facebook due to an unknown error.", @"Unknown Facebook upload error message")};
        error = [NSError errorWithDomain:DQQuestPublishErrorDomain code:DQQuestPublishMissingFacebookTokenErrorCode userInfo:userInfo];
    }
    else if (self.questUpload.shareToTwitter && (!twitterToken.length || !twitterTokenSecret.length))
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"Unable to share to Twitter due to an unknown error.", @"Unknown Twitter upload error message")};
        error = [NSError errorWithDomain:DQQuestPublishErrorDomain code:DQQuestPublishMissingTwitterTokenErrorCode userInfo:userInfo];
    }
    else
    {
        [self.accountController setShareToFacebookOn:self.sharingFB completionBlock:nil failureBlock:nil];
        [self.accountController setShareToTwitterOn:self.sharingTW completionBlock:nil failureBlock:nil];
        self.accountController.loggedInAccount.hasPublishedAQuest = YES;

        [self.dataStoreController saveFacebookToken:facebookToken twitterToken:twitterToken twitterTokenSecret:twitterTokenSecret forQuestUpload:self.questUpload];

        [self upload];
    }

    if (error)
    {
        [self.statechart failed:self error:error];
    }
}

- (void)_postingFailedWithMessage:(NSString *)message
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Post Error", @"Upload error alert title") message:message];
}

- (void)_postingFailedWithError:(NSError *)error
{
    [self tellUserAboutFailureWithTitle:DQLocalizedString(@"Post Error", @"Upload error alert title") forError:error];
}

- (void)_presentGallery
{
    if (self.showGalleryBlock)
    {
        __weak typeof(self) weakSelf = self;
        self.showGalleryBlock(self, ^(DQGalleryViewController *galleryViewController) {
            [weakSelf.statechart complete:weakSelf];
        });
    }
    else
    {
        // FIXME: fail
    }
}

- (void)_completePresentingGallery
{
    // nothing right now
    [self complete];
}

@end

@implementation DQQuestPublishControllerStatechart

+ (DQQuestPublishControllerStatechart *)statechart
{
    return (DQQuestPublishControllerStatechart *)[super statechart];
}

#ifdef DEBUG
- (BOOL)shouldLogTransitions
{
    return YES;
}
#endif

@end
