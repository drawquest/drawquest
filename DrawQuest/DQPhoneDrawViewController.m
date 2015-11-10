//
//  DQPhoneDrawViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneDrawViewController.h"

#import "DQNotifications.h"

#import "DQSegmentedControl.h"

#import "UIView+STAdditions.h"
#import "UIScrollView+SVPullToRefresh.h"

@interface DQPhoneDrawViewController () <DQSegmentedControlDataSource, DQSegmentedControlDelegate>

@property (nonatomic, readwrite, strong) DQPhoneDrawInboxViewController *inboxViewController;
@property (nonatomic, strong) DQPhoneDrawHistoryViewController  *historyViewController;
@property (nonatomic, strong) DQPhoneDrawAllViewController *allViewController;
@property (nonatomic, strong) DQSegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *whiteSpaceView;
@property (nonatomic, weak) DQViewController *activeContentViewController;
@property (nonatomic, weak) UIView *contentView;

@end

@implementation DQPhoneDrawViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    __weak typeof(self) weakSelf = self;

    // These blocks must be defined
    if ( ! self.showEditorForQuestBlock)
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawViewController: showEditorForQuestBlock property is not defined." userInfo:nil];
    }
    if ( ! self.showGalleryForQuestBlock)
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawViewController: showGalleryForQuestBlock property is not defined." userInfo:nil];
    }

    // Set up child view controllers
    if (self.makeInboxViewControllerBlock)
    {
        self.inboxViewController = self.makeInboxViewControllerBlock(self);
        self.inboxViewController.showEditorForQuestBlock = ^(DQQuest *quest) {
            weakSelf.showEditorForQuestBlock(weakSelf, quest, @"Draw/Inbox");
        };
        self.inboxViewController.showGalleryForQuestBlock = ^(DQQuest *quest) {
            weakSelf.showGalleryForQuestBlock(weakSelf, quest, @"Draw/Inbox");
        };
        self.inboxViewController.didDismissQuestBlock = ^(DQPhoneDrawInboxViewController *vc) {
            [weakSelf.historyViewController refresh];
        };
    }
    else
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawViewController: makeInboxViewControllerBlock property is not defined." userInfo:nil];
    }

    if (self.makeHistoryViewControllerBlock)
    {
        self.historyViewController = self.makeHistoryViewControllerBlock(self);
        self.historyViewController.showGalleryForQuestBlock = ^(DQQuest *quest) {
            weakSelf.showGalleryForQuestBlock(weakSelf, quest, @"Draw/History");
        };
    }
    else
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawViewController: makeHistoryViewControllerBlock property is not defined." userInfo:nil];
    }

    if (self.makeAllViewControllerBlock)
    {
        self.allViewController = self.makeAllViewControllerBlock(self);
        self.allViewController.showGalleryForQuestBlock = ^(DQQuest *quest) {
            weakSelf.showGalleryForQuestBlock(weakSelf, quest, @"Draw/All");
        };
    }
    else
    {
        @throw [NSException exceptionWithName:NSGenericException reason:@"DQPhoneDrawViewController: makeAllViewControllerBlock property is not defined." userInfo:nil];
    }

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentView = contentView;
    [self.view addSubview:contentView];

    self.segmentedControl = [[DQSegmentedControl alloc] initWithFrame:CGRectZero];
    self.segmentedControl.delegate = self;
    self.segmentedControl.dataSource = self;
    self.segmentedControl.frameWidth = 320.0f;
    self.segmentedControl.frameHeight = kDQSegmentedControlDesiredHeight;

    UIView *whiteSpaceView = [[UIView alloc] initWithFrame:CGRectZero];
    whiteSpaceView.frameHeight = 1000.0f;
    whiteSpaceView.backgroundColor = [UIColor whiteColor];
    self.whiteSpaceView = whiteSpaceView;

    // Layout
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(contentView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:viewBindings]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|" options:0 metrics:nil views:viewBindings]];

    // TEMP: This is triggering the segmented control to load a tab since it's not in any view yet.
    [self segmentedControl:self.segmentedControl didSelectSegmentIndex:[self defaultSegmentIndexForSegmentedControl:self.segmentedControl]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:DQApplicationDidChangeAccountNotification object:nil];
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
    [self.inboxViewController resetView];
    [self.historyViewController resetView];
    [self.allViewController resetView];
    [self resetView];
}

- (void)resetView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationDidChangeAccountNotification object:nil];
    self.contentView = nil;
    self.activeContentViewController = nil;
    self.inboxViewController = nil;
    self.historyViewController = nil;
    self.view = nil;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.whiteSpaceView.frameWidth = self.segmentedControl.frameWidth;
}

- (void)showQuestOfTheDay
{
    if ([self isViewLoaded])
    {
        self.segmentedControl.selectedSegmentIndex = 0;
    }
}

#pragma mark - Child view controllers

- (void)addContentChildViewController:(UIViewController *)vc
{
    [self addChildViewController:vc];
    [self.contentView addSubview:vc.view];

    [self.whiteSpaceView removeFromSuperview];
    [vc.view addSubview:self.whiteSpaceView];
    [vc.view sendSubviewToBack:self.whiteSpaceView];

    // This needs to happen to make sure autoResizing triggers for child views
    vc.view.frame = CGRectZero;
    vc.view.frame = self.contentView.bounds;
    // Put the segmented controller directly into the view and assume it is a scroll view
    // FIXME: We need to come up with a proper solution to this.
    [vc.view addSubview:self.segmentedControl];
    self.segmentedControl.frameY = -self.segmentedControl.frameHeight;

    UIScrollView *scrollView = (UIScrollView *)vc.view;
    [scrollView setContentInset:UIEdgeInsetsMake(self.segmentedControl.frameHeight, 0.0f, 0.0f, 0.0f)];
    [scrollView setContentOffset:CGPointMake(0.0f, -self.segmentedControl.frameHeight)];

    scrollView.dq_pullToRefreshYOriginOffset = -self.segmentedControl.frameHeight;

    self.whiteSpaceView.frameMaxY = -self.segmentedControl.frameHeight;

    __weak typeof(self) weakSelf = self;
    __weak typeof(scrollView) weakScrollView = scrollView;
    [scrollView addPullToRefreshWithActionHandler:^{
        [weakSelf.activeContentViewController didPullToRefreshWithCompletionBlock:^{
            [weakScrollView.pullToRefreshView stopAnimating];
        }];
    }];

    [self.contentView setNeedsLayout];
}

- (void)removeContentViewController:(UIViewController *)vc
{
    [self.segmentedControl removeFromSuperview];
    [vc.view removeFromSuperview];
    [vc removeFromParentViewController];
}

#pragma mark - DQSegmentedControlDataSource methods

- (NSArray *)itemsForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    // TODO: make this server-controllable?
    return @[DQLocalizedStringWithDefaultValue(@"NewTabTitle", nil, nil, @"New", @"Tab title which shows the newest items in reverse chron order"), DQLocalizedStringWithDefaultValue(@"RecentTabTitle", nil, nil, @"Recent", @"Tab title which shows items the user has recently completed"), DQLocalizedStringWithDefaultValue(@"AllTabTitle", nil, nil, @"All", @"Tab title which shows all items")];
}

- (NSUInteger)defaultSegmentIndexForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    return 0;
}

#pragma mark - DQSegmentedControlDelegate methods

- (void)segmentedControl:(DQSegmentedControl *)segmentedControl didSelectSegmentIndex:(NSUInteger)index
{
    [self removeContentViewController:self.activeContentViewController];
    if (index == 0)
    {
        self.activeContentViewController = self.inboxViewController;
    }
    else if (index == 1)
    {
        self.activeContentViewController = self.historyViewController;
    }
    else if (index == 2)
    {
        self.activeContentViewController = self.allViewController;
    }
    else
    {
        self.activeContentViewController = nil;
    }

    if (self.activeContentViewController)
    {
        [self addContentChildViewController:self.activeContentViewController];
    }
}

@end
