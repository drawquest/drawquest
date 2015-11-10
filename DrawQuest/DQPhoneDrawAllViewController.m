//
//  DQPhoneDrawAllViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/7/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneDrawAllViewController.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAnalyticsConstants.h"

// Models
#import "DQQuest.h"

// Controllers
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"

// Views
#import "DQCircularMaskImageView.h"
#import "DQQuestViewCell.h"
#import "DQTableView.h"
#import "DQPhoneErrorView.h"

static NSString *DQPhoneDrawAllViewControllerCell = @"DQPhoneDrawAllViewControllerCell";

@interface DQPhoneDrawAllErrorView : DQPhoneErrorView

@end

@interface DQPhoneDrawAllViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *quests;
@property (nonatomic, weak) DQTableView *tableView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) DQPhoneDrawAllErrorView *errorView;

@end

@implementation DQPhoneDrawAllViewController

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
        DQPhoneDrawAllErrorView *errorView = [[DQPhoneDrawAllErrorView alloc] initWithFrame:CGRectZero];
        errorView.errorType = DQPhoneErrorViewTypeEmpty;
        [self.tableView setErrorView:errorView];
        self.errorView = errorView;
    }
    [self.tableView reloadData];
}

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
    [self logEvent:DQAnalyticsEventViewDrawAll withParameters:[self viewEventLoggingParameters]];
    [self loadQuests:nil];
}

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": @"Draw/Inbox"};
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

- (void)loadQuests:(dispatch_block_t)completionBlock
{
    if (self.quests && !completionBlock) // this is from viewDidAppear, not pull to refresh
    {
        return;
    }

    if ( ! self.quests)
    {
        [self startDisplayingSpinner];
    }

    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestTopQuestsWithCompletionBlock:^(DQHTTPRequest *request) {
        NSDictionary *responseDictionary = request.dq_responseDictionary;
        NSArray *quests = responseDictionary.dq_quests;
        [weakSelf.dataStoreController createOrUpdateQuestsFromJSONList:quests inBackground:NO resultsBlock:^(NSArray *objects) {
            [weakSelf stopDisplayingSpinner];
            weakSelf.quests = objects;
            [self reloadData];
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    } failureBlock:^(DQHTTPRequest *request) {
        [weakSelf stopDisplayingSpinner];
        if (completionBlock)
        {
            completionBlock();
        }
        // FIXME: implement
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

    DQQuestViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQPhoneDrawAllViewControllerCell];
    if ( ! cell)
    {
        cell = [[DQQuestViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:DQPhoneDrawAllViewControllerCell];
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

@implementation DQPhoneDrawAllErrorView

- (NSString *)message
{
    switch (self.errorType)
    {
        case DQPhoneErrorViewTypeEmpty:
        default:
            return DQLocalizedString(@"No quests to display.", @"No quests found on server display message");
            break;
    }
}

@end
