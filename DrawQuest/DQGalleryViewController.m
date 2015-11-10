//
//  DQGalleryViewController.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/3/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQGalleryViewController.h"

#import "DQPadGalleryViewController.h"
#import "DQPhoneGalleryViewController.h"
#import "DQHUDView.h"
#import "DQAlertView.h"

#import "DQQuest.h"
#import "DQComment.h"
#import "DQCommentUpload.h"

#import "DQHTTPRequest.h"
#import "DQDataStoreController.h"
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"

#import "DQAnalyticsConstants.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQGalleryViewController ()

@property (nonatomic, readwrite, copy) NSString *source;
@property (nonatomic, copy) NSString *alertViewCommentID;

@end

@implementation DQGalleryViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentPlayedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQQuestFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
}

- (id)initWithQuestID:(NSString *)inQuestID focusedCommentID:(NSString *)inScrolledCommentID source:(NSString *)source publishing:(BOOL)isPublishing newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager delegate:(id<DQViewControllerDelegate>)delegate
{
    if ([self class] == [DQGalleryViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadGalleryViewController alloc] initWithQuestID:inQuestID focusedCommentID:inScrolledCommentID source:source publishing:isPublishing newPlaybackDataManager:newPlaybackDataManager delegate:delegate];
        }
        else
        {
            self = [[DQPhoneGalleryViewController alloc] initWithQuestID:inQuestID focusedCommentID:inScrolledCommentID source:source publishing:isPublishing newPlaybackDataManager:newPlaybackDataManager delegate:delegate];
        }
    }
    else
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [super initWithNibName:@"DQGalleryViewController" bundle:nil delegate:delegate];
        }
        else
        {
            self = [super initWithNibName:nil bundle:nil delegate:delegate];
        }
        if (self)
        {
            _questID = [inQuestID copy];
            _source = [source copy];
            _focusedCommentID = [inScrolledCommentID copy];
            _playbackDataManager = newPlaybackDataManager;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentUploadCompleted:) name:DQCommentUploadCompletedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentPlayed:) name:DQCommentPlayedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentFlagged:) name:DQCommentFlaggedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(questFlagged:) name:DQQuestFlaggedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDeleted:) name:DQCommentDeletedNotification object:nil];
        }
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self logEvent:DQAnalyticsEventViewGallery withParameters:[self viewEventLoggingParameters]];

    if (self.galleryViewControllerFirstTimeViewDidAppearBlock)
    {
        self.galleryViewControllerFirstTimeViewDidAppearBlock(self);
        self.galleryViewControllerFirstTimeViewDidAppearBlock = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.view = nil;
        self.loadingView = nil;
        self.alertViewCommentID = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark - Error Handling

- (void)showError:(NSError *)inError
{
    [self showErrorWithTitle:nil andDescription:inError.dq_displayDescription];
}

- (void)showErrorWithTitle:(NSString *)inTitle andDescription:(NSString *)inDescription
{
    if (!inTitle) {
        inTitle = DQLocalizedString(@"Error", @"Generic error alert title");
    }

    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:inTitle message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [errorAlert show];
}

#pragma mark - Event Logging

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": self.source ?: @"unknown", @"quest_id": self.questID ?: @"unknown"};
}

- (NSDictionary *)eventLoggingParameters
{
    return @{@"source": (self.source ? [self.source stringByAppendingString:@"/Gallery"] : @"Gallery"), @"quest_id": self.questID ?: @"unknown"};
}

#pragma mark - 

- (void)commentFlagged:(NSNotification *)notification
{
    // Subclasses must override this
}

- (void)questFlagged:(NSNotification *)notification
{
    // Subclasses must override this
}

- (void)commentDeleted:(NSNotification *)notification
{
    // Subclasses must override this
}

- (void)commentPlayed:(NSNotification *)notification
{
    // Subclasses must override this
}

- (void)commentUploadCompleted:(NSNotification *)notification
{
    // Subclasses must override this
}

#pragma mark - Actions

- (void)displayProfileForUserWithUsername:(NSString *)username fromGalleryObject:(DQModelObject *)galleryObject
{
    if (self.displayProfileForUserNameBlock)
    {
        // set the focusedCommentID so that if a profile gets pushed on top of the gallery,
        // and we get a memory warning, when the gallery reloads, it will load with this
        // as the focusedComment instead of the one passed into the initializer
        // (ie: you won't "lose your place")
        if ([galleryObject isKindOfClass:[DQComment class]])
        {
            self.focusedCommentID = galleryObject.serverID;
        }
        self.displayProfileForUserNameBlock(self, username);
    }
}

- (void)cameraRollButtonTappedForComment:(DQComment *)comment fromView:(UIView *)view
{
    if (self.saveToCameraRollBlock)
    {
        self.saveToCameraRollBlock(self, comment, view);
    }
}

- (void)flagButtonTappedForComment:(DQComment *)comment
{
    __weak typeof(self) weakSelf = self;
    self.alertViewCommentID = comment.serverID;
    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Flag Drawing", @"Flag an inappropriate drawing for staff review title") message:DQLocalizedString(@"Are you sure you want to flag this drawing as inappropriate?", @"Flag an inappropriate drawing for staff review message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Flag", @"Flag an inappropriate drawing or Quest for staff review alert confirmation button title"), nil];
    alertView.dq_cancellationBlock = ^(DQAlertView *alert) {
        weakSelf.alertViewCommentID = nil;
    };
    alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex != [alert cancelButtonIndex] && weakSelf.alertViewCommentID)
        {
            [weakSelf logEvent:DQAnalyticsEventFlag withParameters:[weakSelf eventLoggingParameters]];
            [weakSelf.dataStoreController flagCommentWithServerID:weakSelf.alertViewCommentID];
            [weakSelf.privateServiceController requestFlagForCommentWithServerID:weakSelf.alertViewCommentID];
        }
        weakSelf.alertViewCommentID = nil;
    };
    [alertView show];
}

- (void)deleteButtonTappedForComment:(DQComment *)comment
{
    __weak typeof(self) weakSelf = self;
    self.alertViewCommentID = comment.serverID;
    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Delete Drawing", @"Delete a drawing alert title") message:DQLocalizedString(@"Are you sure you want to permanently delete your drawing?", @"Delete a drawing alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Delete", @"Destroy item alert confirmation button title"), nil];
    alertView.dq_cancellationBlock = ^(DQAlertView *alert) {
        weakSelf.alertViewCommentID = nil;
    };
    alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex != [alert cancelButtonIndex] && weakSelf.alertViewCommentID)
        {
            [weakSelf logEvent:DQAnalyticsEventDelete withParameters:[weakSelf eventLoggingParameters]];
            [weakSelf.dataStoreController deleteCommentWithServerID:weakSelf.alertViewCommentID];
            [weakSelf.privateServiceController requestDeleteCommentWithServerID:weakSelf.alertViewCommentID];
        }
        weakSelf.alertViewCommentID = nil;
    };
    [alertView show];
}

@end
