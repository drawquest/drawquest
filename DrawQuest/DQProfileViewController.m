//
//  DQProfileViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQProfileViewController.h"

// Additions
#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"

// Model
#import "DQAccount.h"
#import "DQUser.h"

// Controllers
#import "DQDataStoreController.h"
#import "DQPrivateServiceController.h"

// View Controllers
#import "DQPadProfileViewController.h"
#import "DQPhoneProfileViewController.h"

@implementation DQProfileViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQAvatarChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQProfileUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationCoinBalanceUpdatedNotication object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQQuestUploadCompletedNotification object:nil];
}

- (id)initWithUserName:(NSString *)inUserName source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate
{
    if ([self class] == [DQProfileViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadProfileViewController alloc] initWithUserName:inUserName source:source delegate:delegate];
        }
        else
        {
            self = [[DQPhoneProfileViewController alloc] initWithUserName:inUserName source:source delegate:delegate];
        }
    }
    else
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [super initWithNibName:@"DQProfileView" bundle:nil delegate:delegate];
        }
        else
        {
            self = [super initWithNibName:nil bundle:nil delegate:delegate];
        }
        if (self)
        {
            _userName = [inUserName copy];
            _source = [source copy];
            _isForLoggedInUser = (self.loggedIn && [self.loggedInAccount.username isEqualToString:inUserName]) || ( ! self.loggedIn && inUserName == nil);
            _followState = DQFollowStateIndeterminate;

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDeleted:) name:DQCommentDeletedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentUploadCompleted:) name:DQCommentUploadCompletedNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(questUploadCompleted:) name:DQQuestUploadCompletedNotification object:nil];
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileUpdated:) name:DQAvatarChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileUpdated:) name:DQProfileUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coinBalanceUpdated:) name:DQApplicationCoinBalanceUpdatedNotication object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.isForLoggedInUser) {
        [self logEvent:DQAnalyticsEventViewOwnProfile withParameters:[self viewEventLoggingParameters]];
    } else {
        [self logEvent:DQAnalyticsEventViewOtherUserProfile withParameters:[self viewEventLoggingParameters]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQAvatarChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQProfileUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationCoinBalanceUpdatedNotication object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark - Event Logging

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": self.source ?: @"unknown"};
}

- (NSDictionary *)eventLoggingParameters
{
    return @{@"source": (self.source ? [self.source stringByAppendingString:@"/Profile"] : @"Profile")};
}

#pragma mark - Error Handling

- (void)showError:(NSError *)inError
{
    [self showErrorWithTitle:nil description:inError.dq_displayDescription];
}

- (void)showErrorWithTitle:(NSString *)title description:(NSString *)description
{
    if (!title) {
        title = DQLocalizedString(@"Error", @"Generic error alert title");
    }

    if (!description) {
        description = DQLocalizedString(@"Unknown error.", @"Unknown error alert message");
    }

    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
    [errorAlert show];
}

#pragma mark - Notifications (Subclasses should implement)

- (void)usersUpdated:(NSNotification *)inNotification
{
    return;
}

- (void)profileUpdated:(NSNotification *)inNotification
{
    return;
}

- (void)coinBalanceUpdated:(NSNotification *)inNotification
{
    return;
}

- (void)commentDeleted:(NSNotification *)notification
{
    return;
}

- (void)commentUploadCompleted:(NSNotification *)notification
{
    return;
}

- (void)questUploadCompleted:(NSNotification *)notification
{
    return;
}

@end
