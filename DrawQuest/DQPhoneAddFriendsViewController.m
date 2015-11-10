//
//  DQPhoneAddFriendsViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneAddFriendsViewController.h"

// Controllers
#import "DQFacebookController.h"
#import "DQTwitterController.h"
#import "DQFacebookFriendsCoordinator.h"
#import "DQTwitterFriendsCoordinator.h"
#import "DQAddressBookCoordinator.h"
#import "DQAbstractServiceController.h"
#import "DQPrivateServiceController.h"
#import "DQDataStoreController.h"

// Models
#import "DQQuest.h"

// View Controllers
#import "DQFriendListViewController.h"

// Views
#import "DQPhoneFriendListCell.h"
#import "DQAddFriendsAuthorizeView.h"
#import "DQAlertView.h"
#import "DQHUDView.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQAnalyticsConstants.h"

static NSString *DQPhoneAddFriendsViewControllerReuseIdentifier = @"DQPhoneAddFriendsViewControllerReuseIdentifier";
static NSString *DQPhoneAddFriendsErrorDomain = @"DQPhoneAddFriendsErrorDomain";
static const NSInteger kDQPhoneAddFriendsUnknownErrorCode = 1000;
static const NSInteger kDQPhoneAddFriendsFacebookUnknownErrorCode = 1001;
static const NSInteger kDQPhoneAddFriendsTwitterUnknownErrorCode = 1002;

@interface DQPhoneAddFriendsViewController ()

@property (nonatomic, strong) DQFriendListViewController *facebookFriendListViewController;
@property (nonatomic, strong) DQFriendListViewController *twitterFriendListViewController;
@property (nonatomic, strong) DQFriendListViewController *addressBookViewController;
@property (nonatomic, strong) NSString *questID;

@property (nonatomic, strong) NSArray *tabItems;
@property (nonatomic, weak) DQFriendListViewController *activeViewController;

@property (nonatomic, strong) DQAddFriendsAuthorizeView *authorizeView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, weak) UIView *segmentedControlWrapper;
@property (nonatomic, weak) UISegmentedControl *segmentedControl;

@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, assign) NSUInteger *emailsSent;

@end

@implementation DQPhoneAddFriendsViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController featureInviteFromFacebook:(BOOL)featureInviteFromFacebook featureInviteFromTwitter:(BOOL)featureInviteFromTwitter questID:(NSString *)questID
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        __weak typeof(self) weakSelf = self;
        void (^messageForInviteBlock)(NSString *, void (^)(NSString *)) = ^(NSString *inChannel, void (^completionBlock)(NSString *)) {
            [weakSelf.privateServiceController requestInviteMessageForChannel:inChannel withQuestID:weakSelf.questID completionBlock:^(DQHTTPRequest *request, NSDictionary *responseDictionary) {
                NSString *defaultMessage = nil;
                if (weakSelf.questID)
                {
                    DQQuest *quest = [weakSelf.dataStoreController questForServerID:weakSelf.questID];
                    defaultMessage = DQLocalizedString(@"Come draw \"%@\" with me on DrawQuest! http://www.example.com/download", @"Invitation message for a user to come draw a specific Quest");
                    defaultMessage = [NSString stringWithFormat:defaultMessage, quest.title];
                    if ([inChannel isEqualToString:DQAPIValueShareChannelTypeTwitter])
                    {
                        defaultMessage = DQLocalizedString(@"Come draw \"%@\" with me on @DrawQuest! http://www.example.com/download", @"Twitter specific invitation message for a user to come draw a specific Quest");
                        defaultMessage = [NSString stringWithFormat:defaultMessage, quest.title];
                    }
                    else if ([inChannel isEqualToString:DQAPIValueShareChannelTypeEmail])
                    {
                        defaultMessage = DQLocalizedString(@"I'm using DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad. DrawQuest sends you daily drawing challenges and allows you to create your own to share with friends. I thought you might enjoy this Quest: \"%@\" \n\nDownload DrawQuest for free here: http://www.example.com/download", @"Email specific invitation message for a user to come draw a specific Quest");
                        defaultMessage = [NSString stringWithFormat:defaultMessage, quest.title];
                    }
                }
                else
                {
                    defaultMessage = DQLocalizedString(@"I'm using DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad. Come draw with me! http://www.example.com/download", @"Invitation message for another user to join DrawQuest");
                    if ([inChannel isEqualToString:DQAPIValueShareChannelTypeTwitter])
                    {
                        defaultMessage = DQLocalizedString(@"I'm using @DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad. Come draw with me! http://www.example.com/download", @"Twitter specific invitation message for another user to join DrawQuest");
                    }
                    else if ([inChannel isEqualToString:DQAPIValueShareChannelTypeEmail])
                    {
                        defaultMessage = DQLocalizedString(@"I'm using DrawQuest, a free creative drawing app for iPhone, iPod touch, and iPad. DrawQuest sends you daily drawing challenges and allows you to create your own to share with friends. You can follow me in the app as \"%@\" \n\n Download DrawQuest for free here: http://www.example.com/download", @"Email specific invitation message for another user to join DrawQuest, includes the inviting user's username");
                        defaultMessage = [NSString stringWithFormat:defaultMessage, self.loggedInAccount.username];
                    }
                }
                if (completionBlock)
                {
                    if (request.error)
                    {
                        completionBlock(defaultMessage);
                    }
                    else
                    {
                        if (responseDictionary.dq_sharingMessage)
                        {
                            completionBlock(responseDictionary.dq_sharingMessage);
                        }
                        else
                        {
                            completionBlock(defaultMessage);
                        }
                    }
                }
            }];
        };
        DQFacebookFriendsCoordinator *facebookCoordinator = [[DQFacebookFriendsCoordinator alloc] initWithFacebookController:facebookController privateServiceController:self.privateServiceController];
        facebookCoordinator.messageForInviteBlock = messageForInviteBlock;
        _facebookFriendListViewController = [[DQFriendListViewController alloc] initWithDataSource:facebookCoordinator delegate:facebookCoordinator];

        DQTwitterFriendsCoordinator *twitterCoordinator = [[DQTwitterFriendsCoordinator alloc] initWithTwitterController:twitterController publicServiceController:self.publicServiceController privateServiceController:self.privateServiceController];
        twitterCoordinator.messageForInviteBlock = messageForInviteBlock;
        _twitterFriendListViewController = [[DQFriendListViewController alloc] initWithDataSource:twitterCoordinator delegate:twitterCoordinator];

        DQAddressBookCoordinator *addressBookCoordinator = [[DQAddressBookCoordinator alloc] initWithPublicServiceController:self.publicServiceController privateServiceController:self.privateServiceController];
        NSString *subjectLine = DQLocalizedString(@"Come draw with me on DrawQuest!", @"Invite a friend via email message subject");
        if (questID)
        {
            DQQuest *quest = [self.dataStoreController questForServerID:questID];
            subjectLine = DQLocalizedString(@"Come draw \"%@\" with me on DrawQuest!", @"Invitation email for another user to join DrawQuest via a particular Quest subject line");
            subjectLine = [NSString stringWithFormat:subjectLine, quest.title];
        }
        addressBookCoordinator.subjectLine = subjectLine;
        addressBookCoordinator.messageForInviteBlock = messageForInviteBlock;
        addressBookCoordinator.presentActionSheetBlock = ^(UIActionSheet *sheet) {
            if (weakSelf.presentActionSheetBlock)
            {
                weakSelf.presentActionSheetBlock(sheet);
            }
        };
        addressBookCoordinator.presentViewControllerBlock = ^(UIViewController *vc) {
            [weakSelf presentViewController:vc animated:YES completion:nil];
        };
        addressBookCoordinator.logFollowBlock = ^(DQAddressBookCoordinator *c) {
            [weakSelf logEvent:DQAnalyticsEventFollow withParameters:@{@"source": @"Add-Friends"}];
        };
        _addressBookViewController = [[DQFriendListViewController alloc] initWithDataSource:addressBookCoordinator delegate:addressBookCoordinator];

        _questID = questID;

        // Set up the tabs
        NSDictionary *facebookItem = @{@"title": DQLocalizedString(@"Facebook", @"Facebook"), @"viewController": self.facebookFriendListViewController};
        NSDictionary *twitterItem = @{@"title": DQLocalizedString(@"Twitter", @"Twitter"), @"viewController": self.twitterFriendListViewController};
        NSDictionary *contactsItem = @{@"title": DQLocalizedString(@"Contacts", @"A label for inviting other users from the Address Book"), @"viewController": self.addressBookViewController}; // FIXME: Make contacts view controller

        NSArray *tabs = @[];
        if (featureInviteFromFacebook && featureInviteFromTwitter)
        {
            if ([facebookController hasOpenFacebookSession] && ! [twitterController hasUnverifiedTwitterAuthCredentials])
            {
                tabs = [NSArray arrayWithObjects:facebookItem, twitterItem, contactsItem, nil];
            }
            else
            {
                tabs = [NSArray arrayWithObjects:twitterItem, facebookItem, contactsItem, nil];
            }
        }
        else if ( ! featureInviteFromFacebook)
        {
            tabs = [NSArray arrayWithObjects:twitterItem, contactsItem, nil];
        }
        else if ( ! featureInviteFromTwitter)
        {
            tabs = [NSArray arrayWithObjects:facebookItem, contactsItem, nil];
        }
        _tabItems = tabs;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    NSMutableArray *tabTitles = [[NSMutableArray alloc] init];
    for (NSDictionary *tabItem in self.tabItems)
    {
        [tabTitles addObject:tabItem[@"title"]];
    }

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerView = headerView;

    UIView *segmentedControlWrapper = [[UIView alloc] initWithFrame:CGRectZero];
    self.segmentedControlWrapper = segmentedControlWrapper;
    segmentedControlWrapper.backgroundColor = [UIColor whiteColor];
    segmentedControlWrapper.layer.shadowColor = [[UIColor blackColor] CGColor];
    segmentedControlWrapper.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    segmentedControlWrapper.layer.shadowOpacity = 0.05f;
    segmentedControlWrapper.layer.shadowRadius = 0.0f;
    [headerView addSubview:segmentedControlWrapper];

    self.authorizeView = [[DQAddFriendsAuthorizeView alloc] initWithFrame:CGRectZero];
    [headerView addSubview:self.authorizeView];

    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:tabTitles];
    self.segmentedControl = segmentedControl;
    [segmentedControl addTarget:self action:@selector(didSelectNewSegmentIndex:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl setTitleTextAttributes:@{NSFontAttributeName: [UIFont dq_phoneSegmentedControlFont]} forState:UIControlStateNormal];
    [headerView addSubview:segmentedControl];

    [self.view addSubview:headerView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ( ! self.viewHasAppeared)
    {
        self.viewHasAppeared = YES;

        // Kick off with the first tab
        self.segmentedControl.selectedSegmentIndex = 0;
        [self didSelectNewSegmentIndex:nil];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGFloat padding = 10.0f;
    CGFloat height = 30.0f;

    self.headerView.frameWidth = self.headerView.superview.frameWidth;

    self.segmentedControlWrapper.frameWidth = self.headerView.frameWidth;
    self.segmentedControlWrapper.frameHeight = height + 2 * padding;

    self.segmentedControl.frame = CGRectMake(padding, padding, self.view.frameWidth - 2 * padding, height);

    self.authorizeView.frameWidth = self.headerView.frameWidth;
    self.authorizeView.frameHeight = self.view.frameHeight - self.segmentedControlWrapper.frameHeight;
    self.authorizeView.frameY = self.segmentedControl.frameMaxY;

    self.headerView.frameHeight = self.segmentedControlWrapper.frameHeight + ((self.authorizeView.hidden) ? 0.0f : self.authorizeView.frameHeight);
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.viewHasAppeared = NO;
        self.headerView = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)didSelectNewSegmentIndex:(id)sender
{
    NSInteger index = self.segmentedControl.selectedSegmentIndex;
    DQFriendListViewController *friendListViewController = [self.tabItems objectAtIndex:index][@"viewController"];

    [self showActivityIndicator];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t permissionsReady = ^{
        [friendListViewController loadFriendsWithCompletionBlock:^{
            // Only display if the tab is still the active tab
            if (friendListViewController == [weakSelf.tabItems objectAtIndex:weakSelf.segmentedControl.selectedSegmentIndex][@"viewController"])
            {
                [weakSelf displayViewController:friendListViewController];
            }
        } failureBlock:^(NSError *error) {
            NSString *errorMessage = @" ";
            errorMessage = [errorMessage stringByAppendingString:DQLocalizedString(@"Error: ", @"Generic error message prefix")];
            errorMessage = [errorMessage stringByAppendingString:error.dq_displayDescription ?: @"Unknown"];
            [weakSelf displayAuthorizeViewWithMessage:errorMessage button:nil];
        } noFriendsBlock:^{
            [weakSelf displayAuthorizeViewWithMessage:[friendListViewController emptyFriendListMessage] button:nil];
        }];
    };

    DQButton *button = [friendListViewController requestAccessButtonWithTappedBlock:^(DQButton *button) {
        [friendListViewController requestPermissionsWithCancellationBlock:^{
            // Do nothing on cancellation.
        } completionBlock:^{
            permissionsReady();
        } failureBlock:^(NSError *error) {
            NSString *errorMessage = @" ";
            errorMessage = [errorMessage stringByAppendingString:DQLocalizedString(@"Error: ", @"Generic error message prefix")];
            errorMessage = [errorMessage stringByAppendingString:error.dq_displayDescription ?: @"Unknown"];
            NSString *message = [[friendListViewController authorizationFailedMessage] stringByAppendingString:errorMessage];
            [weakSelf displayAuthorizeViewWithMessage:message button:button];
        } accountSelectedBlock:^{
            [weakSelf showActivityIndicator];
        } fromView:button];
    }];

    [friendListViewController hasPermissions:^(BOOL result) {
        if (result)
        {
            permissionsReady();
        }
        else
        {
            [weakSelf displayAuthorizeViewWithMessage:[friendListViewController authorizationRequestMessage] button:button];
        }
    } failureBlock:^(NSError *error) {
        NSString *errorMessage = @" ";
        errorMessage = [errorMessage stringByAppendingString:DQLocalizedString(@"Error: ", @"Generic error message prefix")];
        errorMessage = [errorMessage stringByAppendingString:error.dq_displayDescription ?: @"Unknown"];
        [weakSelf displayAuthorizeViewWithMessage:errorMessage button:button];
    }];
}

- (void)displayHeader
{
    self.activeViewController.tableView.tableHeaderView = nil;
    [self.view addSubview:self.headerView];
}

- (void)addHeaderToTableView
{
    self.headerView.frameHeight = self.segmentedControlWrapper.frameHeight + ((self.authorizeView.hidden) ? 0.0f : self.authorizeView.frameHeight);
    self.activeViewController.tableView.tableHeaderView = self.headerView;
}

- (void)displayViewController:(DQFriendListViewController *)viewController
{
    self.authorizeView.hidden = YES;
    [self addChildViewController:viewController];
    viewController.view.frame = self.view.bounds;
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    self.activeViewController = viewController;

    [self addHeaderToTableView];
}

- (void)hideViewController:(DQFriendListViewController *)viewController
{
    viewController.tableView.tableHeaderView = nil;
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void)showActivityIndicator
{
    if (self.activeViewController)
    {
        [self hideViewController:self.activeViewController];
    }
    [self displayHeader];
    self.authorizeView.hidden = NO;
    [self.authorizeView showActivityIndicator];
}

- (void)displayAuthorizeViewWithMessage:(NSString *)message button:(UIButton *)button
{
    self.authorizeView.hidden = NO;
    [self.authorizeView setMessage:message withButton:button];
}

#pragma mark - Submittal

- (void)submitInviteAndFollowRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __block BOOL facebookRequestsDone = NO;
    __block BOOL twitterRequestsDone = NO;
    __block BOOL addressBookRequestsDone = NO;

    __block NSError *facebookRequestsError = nil;
    __block NSError *twitterRequestsError = nil;
    __block NSError *addressBookRequestsError = nil;

    dispatch_block_t errorBlock = ^{
        if (facebookRequestsDone && twitterRequestsDone && addressBookRequestsDone)
        {
            // both requests have completed, and the second one failed, calling errorBlock
            // or, the first one failed and the second one completed but requestsFinishedBlock
            // called errorBlock because it noticed that one of the errors was set
            if (failureBlock)
            {
                if (facebookRequestsError)
                {
                    failureBlock(facebookRequestsError);
                }
                else if (twitterRequestsError)
                {
                    failureBlock(twitterRequestsError);
                }
                else if (addressBookRequestsError)
                {
                    failureBlock(addressBookRequestsError);
                }
                else
                {
                    // this really shouldn't happen because this is only called if one of those errors is
                    // set to a non-nil value, so this message should never see the user. Included for the
                    // sake of completeness and so that if you DO see this error, you can find it in the
                    // source and fix the bug
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
                    NSError *error = [NSError errorWithDomain:DQPhoneAddFriendsErrorDomain code:kDQPhoneAddFriendsUnknownErrorCode userInfo:userInfo];
                    failureBlock(error);
                }
            }
        }
    };

    dispatch_block_t requestsFinishedBlock = ^{
        if (facebookRequestsDone && twitterRequestsDone && addressBookRequestsDone)
        {
            // both requests have completed, and the second one to complete did not fail
            // but the first one might have, so check first
            if (facebookRequestsError || twitterRequestsError || addressBookRequestsError)
            {
                errorBlock();
            }
            else
            {
                if (completionBlock)
                {
                    completionBlock();
                }
            }
        }
    };

    [self.facebookFriendListViewController sendPendingRequestsWithCancellationBlock:cancellationBlock completionBlock:^{
        facebookRequestsDone = YES;
        requestsFinishedBlock();
    } failureBlock:^(NSError *error) {
        facebookRequestsDone = YES;
        if (error)
        {
            facebookRequestsError = error;
            errorBlock();
        }
        else
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
            facebookRequestsError = [NSError errorWithDomain:DQPhoneAddFriendsErrorDomain code:kDQPhoneAddFriendsFacebookUnknownErrorCode userInfo:userInfo];
            errorBlock();
        }
    }];

    [self.twitterFriendListViewController sendPendingRequestsWithCancellationBlock:cancellationBlock completionBlock:^{
        twitterRequestsDone = YES;
        requestsFinishedBlock();
    } failureBlock:^(NSError *error) {
        twitterRequestsDone = YES;
        if (error)
        {
            twitterRequestsError = error;
            errorBlock();
        }
        else
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
            twitterRequestsError = [NSError errorWithDomain:DQPhoneAddFriendsErrorDomain code:kDQPhoneAddFriendsTwitterUnknownErrorCode userInfo:userInfo];
            errorBlock();
        }
    }];

    [self.addressBookViewController sendPendingRequestsWithCancellationBlock:cancellationBlock completionBlock:^{
        addressBookRequestsDone = YES;
        requestsFinishedBlock();
    } failureBlock:^(NSError *error) {
        addressBookRequestsDone = YES;
        if (error)
        {
            addressBookRequestsError = error;
            errorBlock();
        }
        else
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
            addressBookRequestsError = [NSError errorWithDomain:DQPhoneAddFriendsErrorDomain code:kDQPhoneAddFriendsFacebookUnknownErrorCode userInfo:userInfo];
            errorBlock();
        }
    }];
}

- (void)attemptCancel:(void (^)(BOOL cancelled))completionBlock
{
    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Continue without inviting?", @"Continue on and do not invite any users confirmation alert title") message:DQLocalizedString(@"Are you sure you want to continue without inviting any friends?", @"Continue on and do not invite any users confirmation alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view"), nil];
    alertView.dq_completionBlock = ^(DQAlertView *av, NSInteger buttonIndex) {
        if (completionBlock)
        {
            completionBlock(buttonIndex != [av cancelButtonIndex]);
        }
    };
    [alertView show];
}

- (NSUInteger)numberOfInvitesSentOrPending
{
    NSUInteger inviteCount = self.emailsSent;
    inviteCount += [self.facebookFriendListViewController numberOfInvitesSentOrPending];
    inviteCount += [self.twitterFriendListViewController numberOfInvitesSentOrPending];
    return inviteCount;
}

- (void)submitWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:self.view.bounds];
    [hud showInView:self.view animated:YES];

    [self submitInviteAndFollowRequestsWithCancellationBlock:^{
        [hud hideAnimated:YES];
    } completionBlock:^{
        [hud hideAnimated:YES];
        if (completionBlock)
        {
            completionBlock();
        }
    } failureBlock:^(NSError *error) {
        [hud hideAnimated:YES];
        if (failureBlock)
        {
            failureBlock(error);
        }
    }];
}


@end
