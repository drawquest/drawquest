//
//  DQDrawingDetailViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQDrawingDetailViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "DQAnalyticsConstants.h"
#import "DQNotifications.h"

// Models
#import "DQComment.h"
#import "DQQuest.h"
#import "DQActivityItem.h"

// Controllers
#import "DQDataStoreController.h"
#import "DQPlaybackDataManager.h"
#import "DQSharingController.h"
#import "DQPublicServiceController.h"
#import "DQDataStoreController.h"

// View Controllers
#import "DQPhoneProfileViewController.h"

// Views
#import "DQDrawingDetailHeaderView.h"
#import "DQHUDView.h"
#import "DQPlaybackImageView.h"
#import "DQReactionViewCell.h"
#import "DQTableView.h"
#import "DQStarButton.h"
#import "DQTimestampView.h"

static NSString *DQReactionViewCellIdentifier = @"DQReactionViewCellIdentifier";

@interface DQDrawingDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) DQPlaybackDataManager *playbackDataManager;
@property (nonatomic, strong) DQComment *comment;
@property (nonatomic, strong) DQQuest *quest;
@property (nonatomic, strong) DQSharingController *sharingController;
@property (nonatomic, weak) DQTableView *tableView;
@property (nonatomic, weak) DQDrawingDetailHeaderView *headerView;
@property (nonatomic, weak) DQHTTPRequest *dataRequest;
@property (nonatomic, copy) NSString *source;
@end

@implementation DQDrawingDetailViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentRefreshedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
}

- (id)initWithComment:(DQComment *)comment inQuest:(DQQuest *)quest newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _playbackDataManager = newPlaybackDataManager;
        _comment = comment;
        _quest = quest;
        _source = [source copy];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentRefreshed:) name:DQCommentRefreshedNotification object:nil];
    }
    return self;
}

- (void)commentRefreshed:(NSNotification *)notification
{
    DQComment *comment = [notification object];
    DQComment *current = self.comment;
    if ((comment == current) || [comment.serverID isEqualToString:current.serverID])
    {
        self.comment = comment;
        if ([self isViewLoaded])
        {
            [self reloadData];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    __weak typeof(self) weakSelf = self;
    DQDrawingDetailHeaderView *headerView = [[DQDrawingDetailHeaderView alloc] initWithFrame:CGRectZero];
    headerView.frameHeight = kDQDrawingDetailHeaderViewHeightEstimate;
    headerView.starButton.commentID = self.comment.serverID;
    headerView.imageTappedBlock = ^(DQDrawingDetailHeaderView *view) {
        [weakSelf showZoomableImageForComment:self.comment fromView:view.playbackImageView];
    };
    headerView.playbackButtonTappedBlock = ^(DQDrawingDetailHeaderView *headerView, DQButton *playbackButton) {
        [weakSelf tappedPlaybackButton:playbackButton forPlaybackImageView:headerView.playbackImageView comment:weakSelf.comment withRequestFinishedBlock:^(DQComment *newComment) {
            if (newComment)
            {
                weakSelf.comment = newComment;
                [weakSelf reloadData];
            }
        }];
    };
    headerView.moreOptionsSelectedBlock = ^{
        [weakSelf tappedMoreOptionsButtonForComment:weakSelf.comment source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Drawing-Detail"] : @"Drawing-Detail")];
    };
    headerView.showProfileBlock = ^ {
        if ([weakSelf pushedFromProfileForUsername:weakSelf.comment.authorName])
        {
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [weakSelf showProfileForUsername:weakSelf.comment.authorName source:weakSelf.source];
        }
    };
    headerView.shareButtonTappedBlock = ^(DQDrawingDetailHeaderView *view) {
        [weakSelf tappedShareButtonForComment:weakSelf.comment source:(weakSelf.source ? [weakSelf.source stringByAppendingString:@"/Drawing-Detail"] : @"Drawing-Detail")];
    };
    if ( ! [self.comment.authorName isEqualToString:self.loggedInAccount.username])
    {
        [headerView displayFollowButtonForUsername:self.comment.authorName];
    }
    self.headerView = headerView;

    DQTableView *tableView = [[DQTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = kDQReactionViewCellHeight;
    [tableView setHeaderView:headerView];
    [self.view addSubview:tableView];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]
    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(tableView);
    NSDictionary *metrics = @{};

    DQVisualConstraints(self.view, @"H:|[tableView]|");
    DQVisualConstraints(self.view, @"V:|[tableView]|");

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions

    self.tableView = tableView;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];
}

- (BOOL)pushedFromProfileForUsername:(NSString *)username
{
    __block BOOL result = NO;
    if (self.navigationController)
    {
        NSArray *vcs = self.navigationController.viewControllers;
        if ([vcs count] > 1)
        {
            [vcs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                if (vc == self)
                {
                    *stop = YES;
                    if (idx) // then vc isn't the root
                    {
                        UIViewController *prev = vcs[idx-1];
                        if ([prev isKindOfClass:[DQPhoneProfileViewController class]])
                        {
                            DQPhoneProfileViewController *pvc = (DQPhoneProfileViewController *)prev;
                            if ([pvc.userName isEqualToString:username])
                            {
                                result = YES;
                            }
                        }
                    }
                }
            }];
        }
    }
    return result;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateHeader];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentFlagged:) name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDeleted:) name:DQCommentDeletedNotification object:nil];

    [self refreshData:nil];
}

- (void)refreshData:(dispatch_block_t)completionBlock
{
    if (self.dataRequest)
    {
        // it would be nice if we could attach completion block to the completion of the dataRequest,
        // but we don't have that kind of nice thing architecturally right now :(
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        self.dataRequest = [self.publicServiceController requestCommentWithServerID:self.comment.serverID completionBlock:^(DQHTTPRequest *request) {
            NSDictionary *dict = request.dq_responseDictionary;
            NSArray *comments = dict.dq_comments;
            NSDictionary *questDict = dict.dq_quest;
            NSString *questID = questDict.dq_serverID;
            [weakSelf.dataStoreController createOrUpdateCommentsForQuestID:questID fromJSONList:comments questJSONDictionary:questDict inBackground:NO resultsBlock:^(NSArray *objects) {
                if ([objects count])
                {
                    weakSelf.quest = [weakSelf.dataStoreController questForServerID:weakSelf.quest.serverID];
                    weakSelf.comment = [weakSelf.dataStoreController commentForServerID:weakSelf.comment.serverID];
                    [weakSelf reloadData];
                    weakSelf.dataRequest = nil;
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }
                else
                {
                    weakSelf.dataRequest = nil;
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }
            }];
        } failureBlock:^(DQHTTPRequest *request) {
            // FIXME: handle error
            weakSelf.dataRequest = nil;
            if (completionBlock)
            {
                completionBlock();
            }
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewDrawingDetail withParameters:[self viewEventLoggingParameters]];
    [self.tableView setHeaderView:self.headerView];
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf refreshData:^{
            [weakSelf.tableView.pullToRefreshView stopAnimating];
        }];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [self resetView];
    }
    [super didReceiveMemoryWarning];
}

- (void)accountChanged:(NSNotification *)notification
{
    [self resetView];
}

- (void)resetView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentFlaggedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
    self.tableView = nil;
    self.view = nil;
}

#pragma mark -

- (void)reloadData
{
    [self updateHeader];
    [self.tableView reloadData];
}

- (void)updateHeader
{
    self.headerView.playbackImageView.commentID = self.comment.serverID;
    self.headerView.playbackImageView.imageURL = [self.comment imageURLForKey:DQImageKeyPhoneGallery];
    self.headerView.avatarImageView.imageURL = self.comment.authorAvatarURL;
    self.headerView.usernameLabel.text = self.comment.authorName;
    self.headerView.notesCount = self.comment.numberOfReactions;
    self.headerView.timestampView.timestamp = self.comment.timestamp;
}

#pragma mark - Actions

- (void)commentFlagged:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.comment.serverID isEqualToString:comment.serverID])
    {
        if (self.dismissBlock)
        {
            self.dismissBlock();
        }
    }
}

- (void)commentDeleted:(NSNotification *)notification
{
    DQComment *comment = [[notification userInfo] objectForKey:DQCommentObjectNotificationKey];
    if ([self.comment.serverID isEqualToString:comment.serverID])
    {
        if (self.dismissBlock)
        {
            self.dismissBlock();
        }
    }
}

#pragma mark - Event Logging

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": self.source ?: @"unknown", @"comment_id": self.comment.serverID ?: @"unknown"};
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.comment.numberOfReactions;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DQReactionViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQReactionViewCellIdentifier];
    if ( ! cell)
    {
        cell = [[DQReactionViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:DQReactionViewCellIdentifier];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *reactionInfo = [self.comment.sortedReactions objectAtIndex:indexPath.row];
    DQReactionViewCellType *cellType;
    int reactionType = reactionInfo.dq_reactionActivityType;
    if (reactionType == DQActivityItemTypeStar)
    {
        cellType = DQReactionViewCellTypeStarred;
    }
    else if (reactionType == DQActivityItemTypePlayback)
    {
        cellType = DQReactionViewCellTypePlayed;
    }
    else
    {
        cellType = DQReactionViewCellTypeNotFound;
    }
    cell.reactionType = cellType;
    cell.usernameLabel.text = reactionInfo.dq_userInfo.dq_userName;
    cell.avatarImageView.imageURL = reactionInfo.dq_userInfo.dq_galleryUserAvatarURL;
    [cell setTimestamp:reactionInfo.dq_timestamp];

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *reactionInfo = [self.comment.sortedReactions objectAtIndex:indexPath.row];
    [self showProfileForUsername:reactionInfo.dq_userInfo.dq_userName source:(self.source ? [self.source stringByAppendingString:@"/Drawing-Detail"] : @"Drawing-Detail")];
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
