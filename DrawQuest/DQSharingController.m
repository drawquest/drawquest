//
//  DQSharingController.m
//  DrawQuest
//
//  Created by David Mauro on 10/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSharingController.h"

// System and Frameworks
#import <Social/SLComposeViewController.h>
#import <FacebookSDK/FacebookSDK.h>

// Views
#import "DQHUDView.h"
#import "DQAlertView.h"

// Controllers
#import "DQPublicServiceController.h"
#import "DQTumblrShareViewController.h"
#import "STHTTPResourceController.h"
#import "DQDataStoreController.h"
#import "DQPapertrailLogger.h"

// Additions
#import "DQAnalyticsConstants.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQSharingController ()

@property (nonatomic, strong) NSDictionary *facebookLoggingParameters;

@end

@implementation DQSharingController

#pragma mark - Helpers

- (void)showAlertWithTitle:(NSString *)inTitle description:(NSString *)inDescription
{
    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:inTitle message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
    [alertView show];
}

- (void)showError:(NSError *)error
{
    [self showAlertWithTitle:nil description:error.dq_displayDescription];
}

#pragma mark - Public Sharing Methods

- (void)showSharingSheetForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"comment_id": comment.serverID ?: @"unknown"};
    [self logEvent:DQAnalyticsEventGalleryShowSharingSheetForComment withParameters:eventLoggingParameters];

    DQShareMessageProvider *shareMessageProvider = [[DQShareMessageProvider alloc] initWithPublicServiceController:self.publicServiceController];
    shareMessageProvider.commentID = comment.serverID;
    DQQuest *quest = [self.dataStoreController questForServerID:comment.questID];
    shareMessageProvider.questTitle = quest.title;
    shareMessageProvider.shareSubject = DQLocalizedString(@"Check out this drawing on DrawQuest!", @"Invitation to view a drawing on DrawQuest prefix message");

    DQShareImageProvider *shareImageProvider = [[DQShareImageProvider alloc] initWithImageURL:[comment imageURLForKey:DQImageKeyGallery] imageController:self.imageController];
    shareImageProvider.shareSubject = DQLocalizedString(@"Check out this drawing on DrawQuest!", @"Invitation to view a drawing on DrawQuest prefix message");

    NSArray *activityItems = [NSArray arrayWithObjects:shareMessageProvider, shareImageProvider, nil];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo];
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    };

    [presentingViewController presentViewController:activityViewController animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }];
}

- (void)showSharingSheetForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"quest_id": quest.serverID ?: @"unknown"};
    [self logEvent:DQAnalyticsEventGalleryShowSharingSheetForQuest withParameters:eventLoggingParameters];

    NSString *shareSubject = [NSString stringWithFormat:DQLocalizedString(@"Come draw \"%@\" with me on DrawQuest!", @"Invitation email for another user to join DrawQuest via a particular Quest subject line"), quest.title];
    DQShareMessageProvider *shareMessageProvider = [[DQShareMessageProvider alloc] initWithPublicServiceController:self.publicServiceController];
    shareMessageProvider.questID = quest.serverID;
    shareMessageProvider.questTitle = quest.title;
    shareMessageProvider.shareSubject = shareSubject;

    DQShareImageProvider *shareImageProvider = [[DQShareImageProvider alloc] initWithImageURL:[quest imageURLForKey:DQImageKeyGallery] imageController:self.imageController];
    shareImageProvider.shareSubject = shareSubject;

    NSArray *activityItems = [NSArray arrayWithObjects:shareMessageProvider, shareImageProvider, nil];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo];
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    };

    [presentingViewController presentViewController:activityViewController animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }];
}

- (void)showTumblrShareForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSString *serverID = comment.serverID;
    NSString *questTitle = comment.questTitle;
    NSString *photoURL = [comment imageURLForKey:DQImageKeyGallery];
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"comment_id": serverID ?: @"unknown"};
    [self showTumblrShareForServerID:serverID fromViewController:presentingViewController withLoggingParameters:eventLoggingParameters questTitle:questTitle photoURL:photoURL isComment:YES];
}

- (void)showTumblrShareForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSString *serverID = quest.serverID;
    NSString *questTitle = quest.title;
    NSString *photoURL = [quest imageURLForKey:DQImageKeyGallery];
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"quest_id": serverID ?: @"unknown"};
    [self showTumblrShareForServerID:serverID fromViewController:presentingViewController withLoggingParameters:eventLoggingParameters questTitle:questTitle photoURL:photoURL isComment:NO];
}

- (void)showTwitterShareForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSString *serverID = comment.serverID;
    NSString *questTitle = comment.questTitle;
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"comment_id": serverID ?: @"unknown"};
    [self showTwitterShareForServerID:serverID fromViewController:presentingViewController withLoggingParameters:eventLoggingParameters questTitle:questTitle isComment:YES];
}

- (void)showTwitterShareForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSString *serverID = quest.serverID;
    NSString *questTitle = quest.title;
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"quest_id": serverID ?: @"unknown"};
    [self showTwitterShareForServerID:serverID fromViewController:presentingViewController withLoggingParameters:eventLoggingParameters questTitle:questTitle isComment:NO];
}

- (void)showFacebookShareForComment:(DQComment *)comment fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSString *serverID = comment.serverID;
    NSString *questTitle = comment.questTitle;
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"comment_id": serverID ?: @"unknown"};
    [self showFacebookShareForServerID:serverID fromViewController:presentingViewController withLoggingParameters:eventLoggingParameters questTitle:questTitle isComment:YES];
}

- (void)showFacebookShareForQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController source:(NSString *)source
{
    NSString *serverID = quest.serverID;
    NSString *questTitle = quest.title;
    NSDictionary *eventLoggingParameters = @{@"source": source ?: @"unknown", @"quest_id": serverID ?: @"unknown"};
    [self showFacebookShareForServerID:serverID fromViewController:presentingViewController withLoggingParameters:eventLoggingParameters questTitle:questTitle isComment:NO];
}

#pragma mark - Private Sharing Methods

#pragma mark - Tumblr
#pragma mark - UIWebView

- (void)showTumblrShareForServerID:(NSString *)serverID fromViewController:(UIViewController *)presentingViewController withLoggingParameters:(NSDictionary *)loggingParameters questTitle:(NSString *)questTitle photoURL:(NSString *)photoURL isComment:(BOOL)isComment
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:presentingViewController.view.bounds];
    [hud showInView:presentingViewController.view animated:YES];
    hud.text = DQLocalizedString(@"Loading", @"The user must wait as a request is currently being made.");

    __weak typeof(self) weakSelf = self;
    void (^requestCompletionBlock)(DQHTTPRequest *request, id JSONObject) = ^(DQHTTPRequest *request, id JSONObject){
        [hud hideAnimated:YES];
        if (request.error)
        {
            [weakSelf showAlertWithTitle:nil description:request.error.dq_displayDescription];
        }
        else
        {
            NSString *shareURLString = [(NSDictionary *)JSONObject objectForKey:DQAPIKeyStringShareURL];
            NSString *caption = [NSString stringWithFormat:@"Check out this drawing on DrawQuest: \"%@\" %@", questTitle, shareURLString];
            DQTumblrShareViewController *tumblrShareController = [[DQTumblrShareViewController alloc] initWithPhotoURL:photoURL clickThruURL:shareURLString caption:caption tags:@"DrawQuest" tumblrSuccessRegexPattern:weakSelf.tumblrSuccessRegexPattern];
            tumblrShareController.shareSuccessBlock = ^(DQTumblrShareViewController *vc) {
                [weakSelf logEvent:DQAnalyticsEventGalleryShareToTumblr withParameters:loggingParameters];
            };
            DQController *controller = nil;
            if (weakSelf.makeControllerBlock)
            {
                controller = weakSelf.makeControllerBlock(weakSelf);
            }
            __weak typeof(presentingViewController) weakPVC = presentingViewController;
            tumblrShareController.navigationItem.rightBarButtonItem = [controller newBarButtonItemWithTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") isPrimaryAction:YES block:^(id sender) {
                [weakPVC dismissViewControllerAnimated:YES completion:nil];
            }];
            tumblrShareController.title = DQLocalizedString(@"Share on Tumblr", @"Share drawing to Tumblr modal title");
            DQNavigationController *navController = nil;
            if (weakSelf.makeNavigationControllerBlock)
            {
                navController = weakSelf.makeNavigationControllerBlock(weakSelf, tumblrShareController);
                [presentingViewController presentViewController:navController animated:YES completion:nil];
            }
        }
    };
    if (isComment)
    {
        [self.publicServiceController requestShareURLForCommentID:serverID channel:DQAPIValueShareChannelTypeTumblr withCompletionBlock:requestCompletionBlock];
    }
    else
    {
        [self.publicServiceController requestShareURLForQuestID:serverID channel:DQAPIValueShareChannelTypeTumblr withCompletionBlock:requestCompletionBlock];
    }
}


#pragma mark - Twitter
#pragma mark - SLComposeViewController

- (void)showTwitterShareForServerID:(NSString *)serverID fromViewController:(UIViewController *)presentingViewController withLoggingParameters:(NSDictionary *)loggingParameters questTitle:(NSString *)questTitle isComment:(BOOL)isComment
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:presentingViewController.view.bounds];
    [hud showInView:presentingViewController.view animated:YES];
    hud.text = DQLocalizedString(@"Loading", @"The user must wait as a request is currently being made.");

    __weak typeof(self) weakSelf = self;
    void (^requestCompletionBlock)(DQHTTPRequest *request, id JSONObject) = ^(DQHTTPRequest *request, id JSONObject){
        [hud hideAnimated:YES];

        if (request.error)
        {
            [self showError:request.error];
        }
        else
        {
            // FIXME: move this to DQTwitterController
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
            {
                SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                tweetSheet.completionHandler = ^(SLComposeViewControllerResult result) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (result == SLComposeViewControllerResultDone) {
                            [weakSelf logEvent:DQAnalyticsEventGalleryShareToTwitter withParameters:loggingParameters];
                        }
                    });
                };
                NSString *message = [(NSDictionary *)JSONObject objectForKey:DQAPIKeyStringMessage];
                if ( ! message)
                {
                    message = DQLocalizedString(@"\"%@\" via @DrawQuest", @"Share a drawing via Twitter message with Quest title");
                    message = [NSString stringWithFormat:message, questTitle];
                }
                [tweetSheet setInitialText:message];
                [presentingViewController presentViewController:tweetSheet animated:YES completion:nil];
            }
            else
            {
                // Show alert telling user to go to settings
                [self showAlertWithTitle:DQLocalizedString(@"No Twitter Accounts", @"No Twitter accounts are configured on device error alert tile") description:DQLocalizedString(@"There are no Twitter accounts configured. You can add or create a Twitter account in Settings on your device.", @"No Twitter accounts are configured on device error alert message")];
            }
        }
    };
    if (isComment)
    {
        [self.publicServiceController requestShareURLForCommentID:serverID channel:DQAPIValueShareChannelTypeTwitter withCompletionBlock:requestCompletionBlock];
    }
    else
    {
        [self.publicServiceController requestShareURLForQuestID:serverID channel:DQAPIValueShareChannelTypeTwitter withCompletionBlock:requestCompletionBlock];
    }
}


#pragma mark - Facebook
#pragma mark - Facebook App -fallback-> SLComposeViewController -fallback-> Facebook SDK

- (void)showFacebookShareForServerID:(NSString *)serverID fromViewController:(UIViewController *)presentingViewController withLoggingParameters:(NSDictionary *)loggingParameters questTitle:(NSString *)questTitle isComment:(BOOL)isComment
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:presentingViewController.view.bounds];
    [hud showInView:presentingViewController.view animated:YES];
    hud.text = DQLocalizedString(@"Loading", @"The user must wait as a request is currently being made.");

    __weak typeof(self) weakSelf = self;
    void (^requestCompletionBlock)(DQHTTPRequest *request, id JSONObject) = ^(DQHTTPRequest *request, id JSONObject){
        [hud hideAnimated:YES];

        if (request.error)
        {
            [self showError:request.error];
        }
        else
        {
            NSString *shareURLString = [(NSDictionary *)JSONObject objectForKey:DQAPIKeyStringShareURL];
            NSURL *shareURL = [NSURL URLWithString:shareURLString];

            FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
            params.link = shareURL;
            if ([FBDialogs canPresentShareDialogWithParams:params])
            {
                // Switch to FB app for share if available
                NSString *facebookToken = [self openFacebookSessionAccessToken];
                [DQPapertrailLogger component:@"sharing-controller" category:@"present-share-dialog-with-link" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"token": facebookToken ?: [NSNull null],
                             @"share-url-string": shareURLString ?: [NSNull null]};
                }];
                [FBDialogs presentShareDialogWithLink:shareURL handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                    if (error)
                    {
                        [DQPapertrailLogger component:@"sharing-controller" category:@"present-share-dialog-with-link-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                            return @{@"token": facebookToken ?: [NSNull null],
                                     @"share-url-string": shareURLString ?: [NSNull null],
                                     @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                     @"category": @([error fberrorCategory])};
                        }];
                        DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                        [alert show];
                    }
                    else
                    {
                        [weakSelf logEvent:DQAnalyticsEventShareCommentToFacebook withParameters:loggingParameters];
                    }
                }];
            }
            else
            {
                // Use SLComposeViewController if they don't have the app installed
                if (NSClassFromString(@"SLComposeViewController") != nil && [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
                {
                    SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                    facebookSheet.completionHandler = ^(SLComposeViewControllerResult result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (result == SLComposeViewControllerResultDone) {
                                [weakSelf logEvent:DQAnalyticsEventGalleryShareToFacebook withParameters:loggingParameters];
                            }
                            [presentingViewController dismissViewControllerAnimated:YES completion:nil];
                        });
                    };

                    [facebookSheet addURL:shareURL];
                    [presentingViewController presentViewController:facebookSheet animated:YES completion:nil];
                }
                // Use Facebook SDK if they don't have any FB accounts in settings
                else
                {
                    // Because this UI is blocking, we can just track the last logginParams received
                    NSMutableDictionary *params = [@{
                                                     @"name" : @"DrawQuest",
                                                     @"caption" : [NSString stringWithFormat:DQLocalizedString(@"Check out this drawing on DrawQuest: \"%@\"", @"Invitation message to view a drawing on DrawQuest with Quest title"), questTitle],
                                                     @"description" : @"",
                                                     @"link" : shareURLString,
                                                     @"picture" : @"" } mutableCopy];

                    NSString *facebookToken = [self openFacebookSessionAccessToken];
                    [DQPapertrailLogger component:@"sharing-controller" category:@"present-feed-dialog" dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                        return @{@"token": facebookToken ?: [NSNull null],
                                 @"share-url-string": shareURLString ?: [NSNull null]};
                    }];
                    __weak typeof(self) weakSelf = self;
                    self.facebookLoggingParameters = loggingParameters;
                    [FBWebDialogs presentFeedDialogModallyWithSession:[FBSession activeSession] parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                        if (error)
                        {
                            NSString *facebookToken = [weakSelf openFacebookSessionAccessToken];
                            self.facebookLoggingParameters = nil;
                            [DQPapertrailLogger component:@"sharing-controller" category:@"present-feed-dialog-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                return @{@"token": facebookToken ?: [NSNull null],
                                         @"share-url-string": shareURLString ?: [NSNull null],
                                         @"reason": [error userInfo][FBErrorLoginFailedReason] ?: [NSNull null],
                                         @"category": @([error fberrorCategory])};
                            }];
                        }
                        else
                        {
                            if (result == FBWebDialogResultDialogNotCompleted)
                            {
                                // User clicked the "x" icon
                                NSLog(@"User canceled story publishing.");
                            }
                            else
                            {
                                // Handle the publish feed callback
                                NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                if (![urlParams objectForKey:@"post_id"])
                                {
                                    // User clicked the Cancel button
                                    NSLog(@"User canceled story publishing.");
                                }
                                else
                                {
                                    // User clicked the Share button
                                    [weakSelf logEvent:DQAnalyticsEventGalleryShareToFacebook withParameters:weakSelf.facebookLoggingParameters];
                                }
                            }
                        }
                        weakSelf.facebookLoggingParameters = nil;
                    }];
                }
            }
        }
    };
    if (isComment)
    {
        [self.publicServiceController requestShareURLForCommentID:serverID channel:DQAPIValueShareChannelTypeFacebook withCompletionBlock:requestCompletionBlock];
    }
    else
    {
        [self.publicServiceController requestShareURLForQuestID:serverID channel:DQAPIValueShareChannelTypeFacebook withCompletionBlock:requestCompletionBlock];
    }
}

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs)
    {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

@end

#pragma mark - UIActivityItemProviders

@interface DQShareMessageProvider ()

@property (nonatomic, weak) DQPublicServiceController *publicServiceController;
@property (nonatomic, assign) BOOL isComment;

@end

@implementation DQShareMessageProvider

- (id)initWithPublicServiceController:(DQPublicServiceController *)publicServiceController
{
    // We don't need a placeholder item because we ensure something will return below
    self = [super initWithPlaceholderItem:@""];
    if (self)
    {
        _publicServiceController = publicServiceController;
    }
    return self;
}

- (id)item
{
    __block NSString *returnMessage;

    if (self.commentID || self.questID)
    {
        __weak typeof(self) weakSelf = self;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *shareChannel;
            if (weakSelf.activityType == UIActivityTypePostToFacebook)
            {
                shareChannel = DQAPIValueShareChannelTypeFacebook;
            }
            else if (weakSelf.activityType == UIActivityTypePostToTwitter)
            {
                shareChannel = DQAPIValueShareChannelTypeTwitter;
            }
            else if (weakSelf.activityType == UIActivityTypePostToFlickr)
            {
                shareChannel = DQAPIValueShareChannelTypeFlickr;
            }
            else if (weakSelf.activityType == UIActivityTypeMail)
            {
                shareChannel = DQAPIValueShareChannelTypeEmail;
            }
            else if (weakSelf.activityType == UIActivityTypeMessage)
            {
                shareChannel = DQAPIValueShareChannelTypeTextMessage;
            }
            else if (weakSelf.activityType == UIActivityTypeCopyToPasteboard)
            {
                shareChannel = DQAPIValueShareChannelTypeClipboard;
            }

            if (shareChannel)
            {
                void (^requestCompletionBlock)(DQHTTPRequest *request, id JSONObject) = ^(DQHTTPRequest *request, id JSONObject) {
                    returnMessage = [(NSDictionary *)JSONObject objectForKey:DQAPIKeyStringMessage];
                    dispatch_semaphore_signal(semaphore);
                };

                if (weakSelf.commentID)
                {
                    [weakSelf.publicServiceController requestShareURLForCommentID:weakSelf.commentID channel:shareChannel withCompletionBlock:requestCompletionBlock];
                }
                else if (weakSelf.questID)
                {
                    [weakSelf.publicServiceController requestShareURLForQuestID:weakSelf.questID channel:shareChannel withCompletionBlock:requestCompletionBlock];
                }
            }
            else
            {
                dispatch_semaphore_signal(semaphore);
            }
        });
        double delayInSeconds = 60.0;
        dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_semaphore_wait(semaphore, waitTime);
    }

    if ( ! returnMessage)
    {
        if (self.questID)
        {
            if (self.activityType == UIActivityTypePostToTwitter)
            {
                returnMessage = DQLocalizedString(@"Come draw \"%@\" with me on @DrawQuest! %@", @"Twitter specific invitation message to come draw a particular Quest");
            }
            else if (self.activityType == UIActivityTypeMail)
            {
                returnMessage = DQLocalizedString(@" I'm using DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad. DrawQuest sends you daily drawing challenges and allows you to create your own to share with friends. I thought you might enjoy this Quest: \"%@\" \n\nDownload DrawQuest for free here: %@", @"Email specific invitation message to come draw a particular Quest");
            }
            else
            {
                returnMessage = DQLocalizedString(@"Come draw \"%@\" with me on DrawQuest! %@", @"Invitation message to come draw a particular Quest");
            }
            returnMessage = [NSString stringWithFormat:returnMessage, self.questTitle, @"http://example.com/download"];
        }
        else
        {
            if (self.activityType == UIActivityTypePostToTwitter)
            {
                returnMessage = DQLocalizedString(@"\"%@\" via @DrawQuest", @"Share a drawing via Twitter message with Quest title");
                returnMessage = [NSString stringWithFormat:returnMessage, self.questTitle];
            }
            else if (self.activityType == UIActivityTypeMail)
            {
                returnMessage = DQLocalizedString(@"I thought you'd like this drawing made with DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad: \"%@\" \n\nDownload DrawQuest for free here: %@", @"Email specific invitation message to view a drawing");
                returnMessage = [NSString stringWithFormat:returnMessage, self.questTitle, @"http://example.com/download"];
            }
            else if (self.activityType == UIActivityTypePostToFacebook)
            {
                returnMessage = DQLocalizedString(@"Check out this drawing on DrawQuest: \"%@\"", @"Invitation message to view a drawing on DrawQuest with Quest title");
                returnMessage = [NSString stringWithFormat:returnMessage, self.questTitle];
            }
            else
            {
                returnMessage = DQLocalizedString(@"Check out this drawing on DrawQuest: \"%@\" \n\nDownload DrawQuest for free here: %@", @"Invitation message to view a drawing on DrawQuest followed by download link");
                returnMessage = [NSString stringWithFormat:returnMessage, self.questTitle, @"http://example.com/download"];
            }
        }
    }

    return returnMessage;
}

#pragma mark -
#pragma mark UIActivityItemSource methods

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return self.shareSubject;
}

@end

@interface DQShareImageProvider ()

@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) dispatch_semaphore_t semaphore;

@end

@implementation DQShareImageProvider

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STHTTPResourceControllerImageLoadNotification object:nil];
}

- (id)initWithImageURL:(NSString *)imageURL imageController:(STHTTPResourceController *)imageController
{
    self = [super initWithPlaceholderItem:[[UIImage alloc] init]];
    if (self)
    {
        _imageURL = imageURL;
        _imageController = imageController;
    }
    return self;
}

- (id)item
{
    __weak typeof(self) weakSelf = self;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    self.semaphore = semaphore;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoaded:) name:STHTTPResourceControllerImageLoadNotification object:self.imageURL];
        [self.imageController requestImageForURL:weakSelf.imageURL forceReload:NO];
    });
    double delayInSeconds = 60.0;
    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, waitTime);

    return self.image;
}

- (void)imageLoaded:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STHTTPResourceControllerImageLoadNotification object:nil];
    self.image = [notification.userInfo objectForKey:STHTTPResourceControllerNotificationKeyImage];
    dispatch_semaphore_signal(self.semaphore);
}

#pragma mark -
#pragma mark UIActivityItemSource methods

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return self.shareSubject;
}

@end
