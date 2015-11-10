//
//  DQAddFriendsViewController.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-05-31.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTwitterController.h"
#import "DQPrivateServiceController.h"
#import "DQAddFriendsViewController.h"
#import "DQAddFriendsAuthorizeView.h"
#import "DQAnalyticsConstants.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIButton+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQAbstractServiceController.h"
#import "DQFriendListViewController.h"
#import "DQButton.h"
#import "DQCellCheckmarkView.h"
#import "DQTabularController.h"
#import "DQTabularItem.h"
#import "DQFacebookFriendsCoordinator.h"
#import "DQTwitterFriendsCoordinator.h"
#import "DQAlertView.h"
#import "DQHUDView.h"
#import "NSDictionary+DQAPIConveniences.h"

#import <MessageUI/MessageUI.h>

NSString *DQAddFriendsErrorDomain = @"DQAddFriendsErrorDomain";
const NSInteger DQAddFriendsUnknownErrorCode = 1000;
const NSInteger DQAddFriendsFacebookUnknownErrorCode = 1001;
const NSInteger DQAddFriendsTwitterUnknownErrorCode = 1002;

const CGFloat kDQAddFriendsViewInset = 14.0f;
const CGFloat kDQAddFriendsCornerRadius = 10.0f;
const CGFloat kDQAddFriendsBorderWidth = 2.0f;

static const CGFloat kDQAddFriendsViewControllerWidth = 540.0f;
static const CGFloat kDQAddFriendsViewControllerHeight = 500.0f;
static const CGFloat kDQAddFriendsViewControllerInset = 15.0f;
static const CGFloat kDQAddFriendsViewControllerTabHeight = 54.0f;


@interface DQAddFriendsViewController () <MFMailComposeViewControllerDelegate, DQTabularControllerDelegate>

@property (nonatomic, strong) DQTabularController *tabularController;
@property (nonatomic, strong) UILabel *sectionLabel;

@property (nonatomic, strong) DQFriendListViewController *facebookFriendListViewController;
@property (nonatomic, strong) DQFriendListViewController *twitterFriendListViewController;
@property (nonatomic, strong) DQAddFriendsAuthorizeView *authorizeView;
@property (nonatomic, assign) NSUInteger *emailsSent;
@property (nonatomic, strong) UISegmentedControl *segmentControl;

@property (nonatomic, readonly, assign) BOOL shouldPutFacebookBeforeTwitter;

@end

@implementation DQAddFriendsViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController signupService:(DQAuthenticationSignupService)signupService featureInviteFromFacebook:(BOOL)featureInviteFromFacebook featureInviteFromTwitter:(BOOL)featureInviteFromTwitter
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        __weak typeof(self) weakSelf = self;
        void (^messageForInviteBlock)(NSString *, void (^)(NSString *)) = ^(NSString *inChannel, void (^completionBlock)(NSString *)) {
            [weakSelf.privateServiceController requestInviteMessageForChannel:inChannel withQuestID:nil completionBlock:^(DQHTTPRequest *request, NSDictionary *responseDictionary) {
                NSString *defaultMessage = DQLocalizedString(@"Come draw with me on DrawQuest! http://www.example.com/download", @"Generic invitation to DrawQuest message");
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
        
        if (signupService == DQAuthenticationSignupServiceFacebook || ([facebookController hasOpenFacebookSession] && ! [twitterController hasUnverifiedTwitterAuthCredentials]))
        {
            _shouldPutFacebookBeforeTwitter = YES;
        }

        NSArray *items = [self arrayOfTabularItemsWithFacebook:featureInviteFromFacebook twitter:featureInviteFromTwitter];
        _tabularController = [[DQTabularController alloc] initWithItems:items delegate:self startIndex:0];
    }
    return self;
}

#pragma mark - View controller lifecycle

- (void)loadView
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kDQAddFriendsViewControllerWidth, kDQAddFriendsViewControllerHeight)];
    containerView.backgroundColor = [UIColor whiteColor];
    self.view = containerView;

    self.sectionLabel = [[UILabel alloc] init];
    self.sectionLabel.textColor = [UIColor dq_modalTableHeaderTextColor];
    self.sectionLabel.font = [UIFont dq_modalTableHeaderFont];
    //[self.view addSubview:self.sectionLabel];

    self.authorizeView = [[DQAddFriendsAuthorizeView alloc] initWithFrame:[self contentRect]];
    [self.view addSubview:self.authorizeView];

    [self addChildViewController:self.tabularController];
    //[self.view addSubview:self.tabularController.view];
    [self.tabularController didMoveToParentViewController:self];
    
    //Segment Control
    NSMutableArray *arrayOfServiceTitles = [[NSMutableArray alloc] init];
    for (DQTabularItem *item in self.tabularController.items)
    {
        [arrayOfServiceTitles addObject:item.title];
    }
    _segmentControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithArray:arrayOfServiceTitles]];
    [_segmentControl addTarget:self action:@selector(segmentControlValueChanged) forControlEvents:UIControlEventValueChanged];
    [_segmentControl setTintColor:[UIColor colorWithRed:(91/255.0) green:(230/255.0) blue:(183/255.0) alpha:1]];
    [_segmentControl setFrame:CGRectMake(32, 60, 480, 29)];
    _segmentControl.selectedSegmentIndex = 0;
    [self.view addSubview:_segmentControl];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.tabularController.view.frame = CGRectMake(kDQAddFriendsViewInset, kDQAddFriendsViewInset, kDQAddFriendsViewControllerWidth - 2 * kDQAddFriendsViewInset, kDQAddFriendsViewControllerTabHeight);

    CGSize constrainSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 2 * kDQAddFriendsViewControllerInset, CGRectGetHeight(self.view.frame) - 2 * kDQAddFriendsViewControllerInset);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = self.sectionLabel.lineBreakMode;
    CGSize expectedSectionLabelSize = [self.sectionLabel.text boundingRectWithSize:constrainSize options:0 attributes:@{NSFontAttributeName: self.sectionLabel.font, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;

    self.sectionLabel.frame = CGRectMake(CGRectGetMinX(self.view.frame) + kDQAddFriendsViewControllerInset,
                                         kDQAddFriendsViewControllerTabHeight + kDQAddFriendsViewControllerInset * 2,
                                         expectedSectionLabelSize.width,
                                         expectedSectionLabelSize.height);

    self.authorizeView.frame = CGRectMake(0, 105, 540, 525);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (void)segmentControlValueChanged{
    [self.tabularController setSelectedIndex:_segmentControl.selectedSegmentIndex];
}

#pragma mark - Container View Controller Methods

- (CGRect)contentRect
{
    CGFloat yOffset = CGRectGetMaxY(self.sectionLabel.frame) + kDQAddFriendsViewControllerInset;
    return CGRectMake(kDQAddFriendsViewControllerInset,
                      yOffset,
                      CGRectGetWidth(self.view.frame) - kDQAddFriendsViewControllerInset * 2,
                      CGRectGetHeight(self.view.frame) - kDQAddFriendsViewControllerInset - yOffset);
}

- (void)displayViewController:(UIViewController *)viewController
{
    self.authorizeView.hidden = YES;
    [self addChildViewController:viewController];
    viewController.view.frame = [self contentRect];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)hideViewController:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

#pragma mark - Authorize View

- (void)showActivityIndicator
{
    self.authorizeView.hidden = NO;
    [self.authorizeView showActivityIndicator];
}

- (void)displayAuthorizeViewWithMessage:(NSString *)message button:(UIButton *)button
{
    self.authorizeView.hidden = NO;
    [self.authorizeView setMessage:message withButton:button];
}

#pragma mark - Tabular controller delegate

- (void)tabularController:(DQTabularController *)tabularController displayViewController:(UIViewController *)viewController
{
    DQFriendListViewController *friendListViewController = (DQFriendListViewController *)viewController;

    [self showActivityIndicator];
    
    __weak typeof(self) weakSelf = self;

    dispatch_block_t permissionsReady = ^{
        [friendListViewController loadFriendsWithCompletionBlock:^{
            // Only display if the tab is still the active tab
            if (friendListViewController == [weakSelf.tabularController itemForIndex:weakSelf.tabularController.selectedIndex].viewController)
            {
                [weakSelf displayViewController:friendListViewController];
            }
        } failureBlock:^(NSError *error) {
            NSString *errorMessage = DQLocalizedString(@"Error: ", @"Generic error message prefix");
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
            NSString *errorMessage = DQLocalizedString(@"Error: ", @"Generic error message prefix");
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
        NSString *errorMessage = DQLocalizedString(@"Error: ", @"Generic error message prefix");
        errorMessage = [errorMessage stringByAppendingString:error.dq_displayDescription ?: @"Unknown"];
        [weakSelf displayAuthorizeViewWithMessage:errorMessage button:button];
    }];
}

#pragma mark - Tabular Controller Delegate


- (void)tabularController:(DQTabularController *)tabularController hideViewController:(UIViewController *)viewController
{
    [self hideViewController:viewController];
}

- (void)tabularController:(DQTabularController *)tabularController didSelectItem:(DQTabularItem *)item atIndex:(NSUInteger)index
{
    if (index == 2)
    {
        // Special case email
        if (self.inviteEmailBlock)
        {
            self.inviteEmailBlock(self);
        }

        [self displayAuthorizeViewWithMessage:nil button:nil];
    }

    NSString *serviceName = [[self.tabularController itemForIndex:index] valueForKey:@"title"];
    self.sectionLabel.text = [NSString stringWithFormat:DQLocalizedString(@"%@ Friends", @"this will end up being something like 'Twitter Friends' or 'Facebook Friends'"), serviceName];
    [self.sectionLabel sizeToFit];
    [self.sectionLabel setNeedsDisplay];
}

#pragma mark - Submittal

- (void)attemptCancel:(void (^)(BOOL))completionBlock
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

- (void)submitInviteAndFollowRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    __block BOOL facebookRequestsDone = NO;
    __block BOOL twitterRequestsDone = NO;

    __block NSError *facebookRequestsError = nil;
    __block NSError *twitterRequestsError = nil;

    dispatch_block_t errorBlock = ^{
        if (facebookRequestsDone && twitterRequestsDone)
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
                else
                {
                    // this really shouldn't happen because this is only called if one of those errors is
                    // set to a non-nil value, so this message should never see the user. Included for the
                    // sake of completeness and so that if you DO see this error, you can find it in the
                    // source and fix the bug
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: DQLocalizedString(@"An unknown error occurred.", @"Generic unknown error message")};
                    NSError *error = [NSError errorWithDomain:DQAddFriendsErrorDomain code:DQAddFriendsUnknownErrorCode userInfo:userInfo];
                    failureBlock(error);
                }
            }
        }
    };

    dispatch_block_t requestsFinishedBlock = ^{
        if (facebookRequestsDone && twitterRequestsDone)
        {
            // both requests have completed, and the second one to complete did not fail
            // but the first one might have, so check first
            if (facebookRequestsError || twitterRequestsError)
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
            facebookRequestsError = [NSError errorWithDomain:DQAddFriendsErrorDomain code:DQAddFriendsFacebookUnknownErrorCode userInfo:userInfo];
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
            twitterRequestsError = [NSError errorWithDomain:DQAddFriendsErrorDomain code:DQAddFriendsTwitterUnknownErrorCode userInfo:userInfo];
            errorBlock();
        }
    }];
}

- (NSUInteger)numberOfInvitesSentOrPending
{
    NSUInteger inviteCount = self.emailsSent;
    inviteCount += [self.facebookFriendListViewController numberOfInvitesSentOrPending];
    inviteCount += [self.twitterFriendListViewController numberOfInvitesSentOrPending];
    return inviteCount;
}

- (void)submitWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:self.view.bounds];
    [hud showInView:self.view animated:YES];

    dispatch_block_t cancelSpinnerCancellationBlock = ^{
        [hud hideAnimated:YES];
        if (cancellationBlock)
        {
            cancellationBlock();
        }
    };
    
    dispatch_block_t cancelSpinnerCompletionBlock = ^{
        [hud hideAnimated:YES];
        if (completionBlock)
        {
            completionBlock();
        }
    };
    
    void (^cancelSpinnerFailureBlock)(NSError *error) = ^(NSError *error) {
        [hud hideAnimated:YES];
        if (failureBlock)
        {
            failureBlock(error);
        }
    };
    
    if (![self numberOfInvitesSentOrPending])
    {
        __weak typeof(self) weakSelf = self;
        [self attemptCancel:^(BOOL cancelled) {
            if (cancelled)
            {
                [weakSelf submitInviteAndFollowRequestsWithCancellationBlock:cancelSpinnerCancellationBlock completionBlock:cancelSpinnerCompletionBlock failureBlock:cancelSpinnerFailureBlock];
            }
            else
            {
                cancelSpinnerCancellationBlock();
            }
        }];
    }
    else
    {
        [self submitInviteAndFollowRequestsWithCancellationBlock:cancelSpinnerCancellationBlock completionBlock:cancelSpinnerCompletionBlock failureBlock:cancelSpinnerFailureBlock];
    }
}

#pragma mark - Helpers

- (NSArray *)arrayOfTabularItemsWithFacebook:(BOOL)facebookOn twitter:(BOOL)twitterOn
{
    DQTabularItem *facebookItem = [self tabularItemForService:DQLocalizedString(@"Facebook", @"Facebook") icon:[UIImage imageNamed:@"modal_icon_facebook"] viewController:self.facebookFriendListViewController];
    DQTabularItem *twitterItem = [self tabularItemForService:DQLocalizedString(@"Twitter", @"Twitter") icon:[UIImage imageNamed:@"modal_icon_twitter"] viewController:self.twitterFriendListViewController];
    DQTabularItem *emailItem = [self tabularItemForService:DQLocalizedString(@"Email", @"Email") icon:[UIImage imageNamed:@"modal_icon_mail"] viewController:nil];

    NSArray *tabs = [[NSArray alloc] init];
    if (facebookOn && twitterOn)
    {
        if (self.shouldPutFacebookBeforeTwitter)
        {
            tabs = [NSArray arrayWithObjects:facebookItem, twitterItem, emailItem, nil];
        }
        else
        {
            tabs = [NSArray arrayWithObjects:twitterItem, facebookItem, emailItem, nil];
        }
    }
    else if ( ! facebookOn)
    {
        tabs = [NSArray arrayWithObjects:twitterItem, emailItem, nil];
    }
    else if ( ! twitterOn)
    {
        tabs = [NSArray arrayWithObjects:facebookItem, emailItem, nil];
    }
    
    return tabs;
}

- (DQTabularItem *)tabularItemForService:(NSString *)serviceName icon:(UIImage *)icon viewController:(UIViewController *)viewController;
{
    DQTabularItem *item = [DQTabularItem tabularItemWithViewController:viewController title:serviceName icon:icon];
    return item;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultSent) {
        [self logEvent:DQAnalyticsEventSendInviteEmail withParameters:nil];
        self.emailsSent += 1;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
