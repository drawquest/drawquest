//
//  DQPhoneDrawInboxViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneDrawInboxViewController.h"

// Models
#import "DQQuest.h"

// Views
#import "DQQuestOfTheDayView.h"
#import "DQQuestViewCell.h"
#import "DQCircularMaskImageView.h"
#import "DQTableView.h"
#import "DQAlertView.h"
#import "DQTimestampView.h"
#import "DQPhoneErrorView.h"

// Controllers
#import "DQPrivateServiceController.h"
#import "DQDataStoreController.h"

// Additions
#import "UIView+STAdditions.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"

NSString *const DQDrawInboxViewControllerClearBadgeNotification = @"DQDrawInboxViewControllerClearBadgeNotification";

static NSString *DQPhoneDrawInboxViewControllerCell = @"InboxCell";

@interface DQPhoneDrawInboxErrorView : DQPhoneErrorView

@end

@interface DQPhoneDrawInboxViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *quests;
@property (nonatomic, strong) DQQuest *questOfTheDay;
@property (nonatomic, strong) DQQuestOfTheDayView *headerView;
@property (nonatomic, weak) DQPhoneDrawInboxErrorView *errorView;
@property (nonatomic, weak) DQTableView *tableView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;

@end

@implementation DQPhoneDrawInboxViewController

- (void)loadView
{
    __weak typeof(self) weakSelf = self;

    // Required blocks
    if ( ! self.showEditorForQuestBlock)
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawInboxViewController: showEditorForQuestBlock block property is not defined." userInfo:nil];
    }
    if ( ! self.showGalleryForQuestBlock)
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawInboxViewController: showGalleryForQuestBlock block property is not defined." userInfo:nil];
    }

    DQQuestOfTheDayView *headerView = [[DQQuestOfTheDayView alloc] initWithFrame:CGRectZero];
    headerView.frameHeight = kDQQuestOfTheDayViewHeightEstimate;
    headerView.drawQuestBlock = ^{
        weakSelf.showEditorForQuestBlock(weakSelf.questOfTheDay);
    };
    headerView.viewQuestBlock = ^{
        weakSelf.showGalleryForQuestBlock(weakSelf.questOfTheDay);
    };
    headerView.showProfileBlock = ^{
        NSString *username = (self.questOfTheDay.attributionUsername.length > 0) ? self.questOfTheDay.attributionUsername : self.questOfTheDay.authorUsername;
        [weakSelf showProfileForUsername:username source:@"Draw/Inbox"];
    };
    self.headerView = headerView;

    DQTableView *tableView = [[DQTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.rowHeight = kDQQuestViewCellHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
    self.tableView = tableView;
    self.view = tableView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewDrawInbox withParameters:[self viewEventLoggingParameters]];
    [self loadQuests:nil];
    if (self.shouldSendClearBadgeNotification && self.tableView.contentOffset.y <= 30.0)
    {
        [self sendClearBadgeNotification];
    }
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [self resetView];
    }
    [super didReceiveMemoryWarning];
}

- (void)resetView
{
    self.quests = nil;
    self.questOfTheDay = nil;
    self.headerView = nil;
    self.tableView = nil;
    self.view = nil;
}

- (void)didPullToRefreshWithCompletionBlock:(dispatch_block_t)completionBlock
{
    [self loadQuests:completionBlock];
}

#pragma mark - Event Logging

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": @"Draw/Inbox"};
}

#pragma mark - Quest of the Day

- (void)configureHeaderForQuestOfTheDay
{
    if (self.questOfTheDay)
    {
        self.headerView.questTitleLabel.text = self.questOfTheDay.title;
        self.headerView.timestampLabel.timestamp = self.questOfTheDay.timestamp;
        self.headerView.questTemplateImageView.imageURL = [self.questOfTheDay imageURLForKey:DQImageKeyHomePageFeatured];
        if (self.questOfTheDay.attributionUsername.length > 0)
        {
            self.headerView.attributionLabel.text = self.questOfTheDay.attributionCopy;
            self.headerView.usernameLabel.text = self.questOfTheDay.attributionUsername;
            self.headerView.avatarImageView.imageURL = self.questOfTheDay.attributionAvatarUrl;
        }
        else
        {
            self.headerView.usernameLabel.text = self.questOfTheDay.authorUsername;
            self.headerView.avatarImageView.imageURL = self.questOfTheDay.authorAvatarUrl;
        }
        [self.tableView setHeaderView:self.headerView];
    }
    else
    {
        [self.tableView setHeaderView:nil];
    }
}

#pragma mark -

- (void)reloadData
{
    NSInteger count = [self tableView:self.tableView numberOfRowsInSection:0] + (self.questOfTheDay ? 1 : 0);
    if (count && self.errorView)
    {
        self.errorView = nil;
        [self.tableView setErrorView:self.errorView];
    }
    else if (! count && self.errorView == nil)
    {
        DQPhoneDrawInboxErrorView *errorView = [[DQPhoneDrawInboxErrorView alloc] initWithFrame:CGRectZero];
        errorView.errorType = DQPhoneErrorViewTypeEmpty;
        __weak typeof(self) weakSelf = self;
        errorView.buttonTappedBlock = ^{
            if (weakSelf.requestPublishQuestBlock)
            {
                weakSelf.requestPublishQuestBlock(weakSelf);
            }
        };
        [self.tableView setErrorView:errorView];
        self.errorView = errorView;
    }
    [self.tableView reloadData];
}

- (void)loadQuests:(dispatch_block_t)completionBlock
{
    if (self.quests && self.questOfTheDay && !completionBlock) // this is from viewDidAppear, not pull to refresh
    {
        return;
    }

    if ( ! self.questOfTheDay && ! self.quests)
    {
        [self startDisplayingSpinner];
    }
    
    __weak typeof(self) weakSelf = self;
    double timestamp = [[NSDate date] timeIntervalSince1970];
    [self.privateServiceController requestQuestInboxWithCompletionBlock:^(DQHTTPRequest *request) {
        weakSelf.loggedInAccount.drawTabBadgeTimestamp = @(timestamp);
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *quests = responseDictionary.dq_quests;
        NSDictionary *currentQuestInfo = responseDictionary.dq_currentQuest;

        dispatch_block_t updateQuests = ^{
            [weakSelf configureHeaderForQuestOfTheDay];
            [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:NO resultsBlock:^(NSArray *objects) {
                [weakSelf stopDisplayingSpinner];
                weakSelf.quests = objects;
                [self reloadData];
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        };

        if (currentQuestInfo)
        {
            [self.dataStoreController createOrUpdateQuestsFromJSONList:[NSArray arrayWithObject:currentQuestInfo] inBackground:NO resultsBlock:^(NSArray *objects) {
                weakSelf.questOfTheDay = [objects objectAtIndex:0];
                updateQuests();
            }];
        }
        else
        {
            weakSelf.questOfTheDay = nil;
            updateQuests();
        }

        if (self.shouldSendClearBadgeNotification && ( ! self.questOfTheDay) && ( ! [weakSelf.quests count]))
        {
            [self sendClearBadgeNotification];
        }

    } failureBlock:^(DQHTTPRequest *request) {
        [weakSelf stopDisplayingSpinner];
        if (completionBlock)
        {
            completionBlock();
        }
        // TODO
    }];
}

- (void)startDisplayingSpinner
{
    if (self.spinner)
    {
        [self stopDisplayingSpinner];
    }
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frameCenterX = self.view.frameCenterX;
    spinner.frameY = 20.0f;
    [self.view addSubview:spinner];
    [spinner startAnimating];
    self.spinner = spinner;
}

- (void)stopDisplayingSpinner
{
    [self.spinner removeFromSuperview];
    self.spinner = nil;
}

- (void)sendClearBadgeNotification
{
    self.shouldSendClearBadgeNotification = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:DQDrawInboxViewControllerClearBadgeNotification object:nil userInfo:nil];
}

#pragma mark -
#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // once you're near the top, send the notification
    if (self.shouldSendClearBadgeNotification && (scrollView == self.tableView) && scrollView.contentOffset.y <= 30.0)
    {
        [self sendClearBadgeNotification];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.quests count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DQQuest *quest = [self.quests objectAtIndex:indexPath.row];

    DQQuestViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQPhoneDrawInboxViewControllerCell];
    if ( ! cell)
    {
        cell = [[DQQuestViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:DQPhoneDrawInboxViewControllerCell];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.questTitleLabel.text = quest.title;
    cell.questTemplateImageView.imageURL = [quest imageURLForKey:DQImageKeyArchive];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        DQQuest *quest = [self.quests objectAtIndex:indexPath.row];
        NSMutableArray *quests = [NSMutableArray arrayWithArray:self.quests];
        [quests removeObjectAtIndex:indexPath.row];
        self.quests = [NSArray arrayWithArray:quests];

        if (indexPath.row == [self.quests count])
        {
            [tableView reloadData];
        }
        else
        {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }

        __weak typeof(self) weakSelf = self;
        [self.privateServiceController requestDismissQuestWithID:quest.serverID completionBlock:^(DQHTTPRequest *request) {
            // Do nothing, success is assumed.
            if (weakSelf.didDismissQuestBlock)
            {
                weakSelf.didDismissQuestBlock(weakSelf);
            }
        } failureBlock:^(DQHTTPRequest *request) {
            NSString *title = request.error.dq_displayDescription ? DQLocalizedString(@"Unable to dismiss", @"Quest could not be dismissed from Inbox error alert title") : DQLocalizedString(@"Error", @"Generic error alert title");
            NSString *message = request.error.dq_displayDescription ?: DQLocalizedString(@"We were unable to remove the quest from your inbox. Please try again later.", @"Quest could not be dismissed from Inbox error alert message");
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alert show];
        }];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view");
}

#pragma mark - UITableViewDelegate methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DQQuest *quest = [self.quests objectAtIndex:indexPath.row];
    self.showGalleryForQuestBlock(quest);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

@end

@implementation DQPhoneDrawInboxErrorView

- (NSString *)message
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
        default:
            return DQLocalizedString(@"Come back tomorrow for a new Quest, or create your own!", @"User should return for a new Quest tomorrow, or they can create a Quest themselves display message");
            break;
    }
}

- (NSString *)buttonTitle
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
        default:
            return DQLocalizedString(@"Create a Quest", @"Prompt to create a new Quest");
            break;
    }
}

- (UIImage *)image
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
        default:
            return [UIImage imageNamed:@"questBot_spot_sparse_state"];
            break;
    }
}

@end
