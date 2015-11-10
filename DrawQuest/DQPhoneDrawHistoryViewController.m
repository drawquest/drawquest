//
//  DQPhoneDrawHistoryViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneDrawHistoryViewController.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"

// Models
#import "DQQuest.h"

// Controllers
#import "DQPrivateServiceController.h"
#import "DQDataStoreController.h"

// Views
#import "DQCircularMaskImageView.h"
#import "DQQuestViewCell.h"
#import "DQTableView.h"
#import "DQPhoneErrorView.h"

static NSString *DQPhoneDrawHistoryViewControllerCell = @"DQPhoneDrawHistoryViewControllerCell";

@interface DQPhoneDrawHistoryErrorView : DQPhoneErrorView

@end

@interface DQPhoneDrawHistoryViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *quests;
@property (nonatomic, weak) DQTableView *tableView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) DQPhoneDrawHistoryErrorView *errorView;
@property (nonatomic, weak) DQHTTPRequest *loadingRequest;

@end

@implementation DQPhoneDrawHistoryViewController

- (void)loadView
{
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
    [self logEvent:DQAnalyticsEventViewDrawHistory withParameters:[self viewEventLoggingParameters]];
    [self loadQuests:nil];
}

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": @"Draw/History"};
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
    self.tableView = nil;
    self.view = nil;
}

- (void)didPullToRefreshWithCompletionBlock:(dispatch_block_t)completionBlock
{
    [self loadQuests:completionBlock];
}

#pragma mark - 

- (void)refresh
{
    if (self.quests)
    {
        [self loadQuests:^{}];
    }
}

- (void)reloadData
{
    NSInteger count = [self tableView:self.tableView numberOfRowsInSection:0];
    if (count && self.errorView)
    {
        self.errorView = nil;
        [self.tableView setErrorView:self.errorView];
    }
    else if (! count && self.errorView == nil)
    {
        DQPhoneDrawHistoryErrorView *errorView = [[DQPhoneDrawHistoryErrorView alloc] initWithFrame:CGRectZero];
        errorView.errorType = DQPhoneErrorViewTypeEmpty;
        [self.tableView setErrorView:errorView];
        self.errorView = errorView;
    }
    [self.tableView reloadData];
}

- (void)loadQuests:(dispatch_block_t)completionBlock
{
    if (self.loadingRequest)
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        if (self.quests && !completionBlock) // this is from viewDidAppear, not refresh or pull to refresh
        {
            return;
        }

        if ( ! self.quests)
        {
            [self startDisplayingSpinner];
        }

        __weak typeof(self) weakSelf = self;
        self.loadingRequest = [self.privateServiceController requestQuestHistoryWithCompletionBlock:^(DQHTTPRequest *request) {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            NSArray *quests = responseDictionary.dq_quests;
            [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:NO resultsBlock:^(NSArray *objects) {
                [weakSelf stopDisplayingSpinner];
                weakSelf.quests = objects;
                [self reloadData];
                weakSelf.loadingRequest = nil;
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            [weakSelf stopDisplayingSpinner];
            weakSelf.loadingRequest = nil;
            // FIXME: handle failure
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
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

#pragma mark - UITableViewDataSource Methods

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

    DQQuestViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQPhoneDrawHistoryViewControllerCell];
    if ( ! cell)
    {
        cell = [[DQQuestViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:DQPhoneDrawHistoryViewControllerCell];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.questTitleLabel.text = quest.title;
    cell.questTemplateImageView.imageURL = [quest imageURLForKey:DQImageKeyArchive];

    return cell;
}

#pragma mark - UITableViewDelegate methods

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

@implementation DQPhoneDrawHistoryErrorView

- (NSString *)message
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
        default:
            return DQLocalizedString(@"You haven't drawn anything yet! Quests you've drawn in will appear here.", @"The user's history is empty because they haven't completed any Quests display message");
            break;
    }
}

@end
