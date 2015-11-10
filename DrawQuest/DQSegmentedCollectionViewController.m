//
//  DQSegmentedCollectionViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSegmentedCollectionViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "UIScrollView+SVPullToRefresh.h"

typedef NS_OPTIONS(NSUInteger, DQSegmentedCollectionViewControllerDataSourceCache)
{
    DQSegmentedCollectionViewControllerDataSourceCacheNumberOfContentSections = 1 << 0,
    DQSegmentedCollectionViewControllerDataSourceCacheNumberOfItemsInSection = 1 << 1,
    DQSegmentedCollectionViewControllerDataSourceCacheCellForItemAtIndexPath = 1 << 2,
    DQSegmentedCollectionViewControllerDataSourceCacheInsetForSectionForLayout = 1 << 3,
    DQSegmentedCollectionViewControllerDataSourceCacheSizeForItemAtIndexPathForLayout = 1 << 4,
    DQSegmentedCollectionViewControllerDataSourceCacheContentIsPaginated = 1 << 5,
    DQSegmentedCollectionViewControllerDataSourceCacheHasMorePaginatedContent = 1 << 6,
    DQSegmentedCollectionViewControllerDataSourceCacheLoadMorePaginatedContent = 1 << 7
};

@interface DQSegmentedCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView *headerViewWrapper;
@property (nonatomic, assign) CGFloat headerViewPreviousHeight;
@property (nonatomic, readwrite, strong) UIView *segmentedControl;
@property (nonatomic, strong) NSLayoutConstraint *errorTopConstraint;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL paginationLoading;

@end

@implementation DQSegmentedCollectionViewController
{
    DQSegmentedCollectionViewControllerDataSourceCache _dataSourceRespondsToFlags;
    BOOL _cachedContentIsPaginated;
    NSInteger _cachedNumberOfContentSections;
    BOOL _cachedHasMorePaginatedContent;
    BOOL _GUARD_settingContentOffsetInViewDidLayoutSubviews;
}

- (id)initWithHeaderView:(UIView *)headerView errorView:(UIView *)errorView
{
    self = [super initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    if (self)
    {
        _headerView = headerView;
        _headerViewPreviousHeight = CGFLOAT_MAX;
        _errorView = errorView;
    }
    return self;
}

- (void)setDataSource:(id<DQSegmentedCollectionViewControllerDataSource>)dataSource
{
    _dataSource = dataSource;
    DQSegmentedCollectionViewControllerDataSourceCache flags = 0;
    if ([dataSource respondsToSelector:@selector(numberOfContentSectionsInCollectionViewController:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheNumberOfContentSections;
    if ([dataSource respondsToSelector:@selector(collectionViewController:numberOfItemsInSection:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheNumberOfItemsInSection;
    if ([dataSource respondsToSelector:@selector(collectionViewController:cellForItemAtIndexPath:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheCellForItemAtIndexPath;
    if ([dataSource respondsToSelector:@selector(collectionViewController:insetForSection:forLayout:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheInsetForSectionForLayout;
    if ([dataSource respondsToSelector:@selector(collectionViewController:sizeForItemAtIndexPath:forLayout:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheSizeForItemAtIndexPathForLayout;
    if ([dataSource respondsToSelector:@selector(contentIsPaginatedInCollectionViewController:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheContentIsPaginated;
    if ([dataSource respondsToSelector:@selector(hasMorePaginatedContentInCollectionViewController:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheHasMorePaginatedContent;
    if ([dataSource respondsToSelector:@selector(loadMorePaginatedContentInCollectionViewController:)]) flags |= DQSegmentedCollectionViewControllerDataSourceCacheLoadMorePaginatedContent;
    _dataSourceRespondsToFlags = flags;
    [self resetCachedData];
}

- (void)prepareLoadingCell:(DQAbstractLoadingCollectionViewCell *)view atIndexPath:(NSIndexPath *)indexPath
{

}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.alwaysBounceVertical = YES;

    self.view.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[self loadingCellClass] forCellWithReuseIdentifier:@"PaginationLoading"];

    self.segmentedControl = [self makeSegmentedControl];

    self.headerViewWrapper = [[UIView alloc] initWithFrame:CGRectZero];
    [self.collectionView addSubview:self.headerViewWrapper];

    CGFloat headerHeight = 0.0f;

    if (self.headerView)
    {
        self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.headerViewWrapper addSubview:self.headerView];
        self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.headerView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.headerViewWrapper addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.headerView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
        [self.headerViewWrapper addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.headerView.superview attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.headerView.superview attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f];
        constraint.priority -= 1;
        [self.headerViewWrapper addConstraint:constraint];
        if (self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayHeaderView)
        {
            headerHeight += self.headerView.frameHeight;
        }
    }

    if (self.errorView)
    {
        [self.headerViewWrapper addSubview:self.errorView];
        self.errorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.errorView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        self.errorTopConstraint = [NSLayoutConstraint constraintWithItem:self.errorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.headerView ?: self.headerViewWrapper attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        [self.headerViewWrapper addConstraint:self.errorTopConstraint];
        [self.headerViewWrapper addConstraint:[NSLayoutConstraint constraintWithItem:self.errorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.errorView.superview attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.errorView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.errorView.superview attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f];
        constraint.priority -= 1;
        [self.headerViewWrapper addConstraint:constraint];
        if (self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayErrorView)
        {
            headerHeight += self.errorView.frameHeight;
        }
    }

    if (self.segmentedControl)
    {
        self.segmentedControl.frameY = (self.headerView) ? self.headerView.frameMaxY : 0.0f;
        [self.headerViewWrapper addSubview:self.segmentedControl];
        if (self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl)
        {
            headerHeight += self.segmentedControl.frameHeight;
        }
    }

    self.headerViewWrapper.frameHeight = headerHeight;
    self.headerViewWrapper.frameWidth = self.collectionView.frameWidth;
    self.headerViewWrapper.frameY = -headerHeight;

    self.collectionView.contentInset = UIEdgeInsetsMake(headerHeight, 0.0f, 0.0f, 0.0f);
    [self scrollToTop];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGFloat headerHeight = 0.0f;
    if (self.headerView && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayHeaderView)
    {
        self.headerView.hidden = NO;
        headerHeight += self.headerView.frameHeight;
    }
    else
    {
        self.headerView.hidden = YES;
    }

    if (self.errorView && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayErrorView)
    {
        self.errorView.hidden = NO;
        headerHeight += self.errorView.frameHeight;
    }
    else
    {
        self.errorView.hidden = YES;
    }

    if (self.segmentedControl && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl)
    {
        self.segmentedControl.hidden = NO;
        self.segmentedControl.frameY = (self.headerView && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayHeaderView) ? self.headerView.frameMaxY : 0.0f;
        headerHeight += self.segmentedControl.frameHeight;
    }
    else
    {
        self.segmentedControl.hidden = YES;
    }

    self.headerViewWrapper.frameHeight = headerHeight;
    self.headerViewWrapper.frameY = -headerHeight;
    BOOL adjustedContentInset = NO;
    if (headerHeight > self.collectionView.contentInset.top)
    {
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(headerHeight, 0.0f, 0.0f, 0.0f);
        adjustedContentInset = YES;
        self.collectionView.contentInset = contentInsets;
        if (self.collectionView.pullToRefreshView)
        {
            [self.collectionView.pullToRefreshView setOriginalContentInset:contentInsets];
        }
    }

    // Change contentOffset if we adjusted the inset or if the headerView size changes
    if (adjustedContentInset || (self.headerView && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayHeaderView && headerHeight != self.headerViewPreviousHeight))
    {
        self.headerViewPreviousHeight = self.headerViewWrapper.frameHeight;
        _GUARD_settingContentOffsetInViewDidLayoutSubviews = YES;
        [self scrollToTop];
        _GUARD_settingContentOffsetInViewDidLayoutSubviews = NO;
    }

    // Update spinner position
    self.spinner.frameY = self.collectionView.contentSize.height + 20.0f;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    if (self.errorView)
    {
        [self.headerViewWrapper removeConstraint:self.errorTopConstraint];

        if (self.headerView && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplayHeaderView)
        {
            self.errorTopConstraint = [NSLayoutConstraint constraintWithItem:self.errorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.headerView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        }
        else
        {
            self.errorTopConstraint = [NSLayoutConstraint constraintWithItem:self.errorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.errorView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        }

        if (self.segmentedControl && self.displayStatus & DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl)
        {
            self.errorTopConstraint.constant += self.segmentedControl.frameHeight;
        }

        [self.headerViewWrapper addConstraint:self.errorTopConstraint];
    }
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.headerViewWrapper = nil;
        self.segmentedControl = nil;
        self.errorTopConstraint = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark - Public methods

- (UIView *)makeSegmentedControl
{
    UIView *segmentedControl = nil;
    if ([self.dataSource respondsToSelector:@selector(segmentedControlForCollectionViewController:)])
    {
        segmentedControl = [self.dataSource segmentedControlForCollectionViewController:self];
    }
    return segmentedControl;
}

- (void)reloadData
{
    [self resetCachedData];
    [self.collectionView reloadData];
}

- (void)scrollToTop
{
    self.collectionView.contentOffset = CGPointMake(0.0f, -self.headerViewWrapper.frameHeight);
}

- (void)setDisplayStatus:(DQSegmentedCollectionViewControllerStatus)displayStatus
{
    _displayStatus = displayStatus;
    [self.view setNeedsUpdateConstraints];
    [self reloadData];
}

- (void)startDisplayingSpinner
{
    if (self.spinner)
    {
        [self stopDisplayingSpinner];
    }
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner = spinner;
    spinner.frameCenterX = self.collectionView.frameCenterX;
    spinner.frameY = self.collectionView.contentSize.height + 20.0f;
    [self.collectionView addSubview:spinner];
    [spinner startAnimating];
}

- (void)stopDisplayingSpinner
{
    [self.spinner removeFromSuperview];
    self.spinner = nil;
}

- (void)reloadItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:section]]];
}

#pragma mark -
#pragma mark Template Methods

- (Class)loadingCellClass
{
    return [DQAbstractLoadingCollectionViewCell class];
}

- (NSInteger)numberOfContentSections
{
    if (_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheNumberOfContentSections)
    {
        return [self.dataSource numberOfContentSectionsInCollectionViewController:self];
    }
    else
    {
        return 1;
    }
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    if (_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheNumberOfItemsInSection)
    {
        return [self.dataSource collectionViewController:self numberOfItemsInSection:section];
    }
    else
    {
        return 0;
    }
}

- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheCellForItemAtIndexPath)
    {
        return [self.dataSource collectionViewController:self cellForItemAtIndexPath:indexPath];
    }
    else
    {
        return nil;
    }
}

- (UIEdgeInsets)insetForSection:(NSInteger)section forLayout:(UICollectionViewFlowLayout *)layout
{
    if (_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheInsetForSectionForLayout)
    {
        return [self.dataSource collectionViewController:self insetForSection:section forLayout:layout];
    }
    else
    {
        return layout.sectionInset;
    }
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath forLayout:(UICollectionViewFlowLayout *)layout
{
    if (_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheSizeForItemAtIndexPathForLayout)
    {
        return [self.dataSource collectionViewController:self sizeForItemAtIndexPath:indexPath forLayout:layout];
    }
    else
    {
        return layout.itemSize;
    }
}

- (void)resetCachedData
{
    _cachedNumberOfContentSections = [self numberOfContentSections];
    _cachedContentIsPaginated = [self contentIsPaginated];
    _cachedHasMorePaginatedContent = _cachedContentIsPaginated && [self hasMorePaginatedContent];
}

- (BOOL)contentIsPaginated
{
    return ((_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheContentIsPaginated) &&
            [self.dataSource contentIsPaginatedInCollectionViewController:self]);
}

- (BOOL)hasMorePaginatedContent
{
    return ((_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheHasMorePaginatedContent) &&
            [self.dataSource hasMorePaginatedContentInCollectionViewController:self]);
}

- (void)loadMorePaginatedContent
{
    if (_dataSourceRespondsToFlags & DQSegmentedCollectionViewControllerDataSourceCacheLoadMorePaginatedContent)
    {
        [self.dataSource loadMorePaginatedContentInCollectionViewController:self];
    }
    else
    {
        // this method is only called if content is paginated and there's more paginated content, so either
        // the dataSource method should be implemented or this method should be overridden (WITHOUT calling super)
        // given that this code is now running, neither was done, and this is therefore a loading failure
        [self loadingMorePaginatedContentFailed];
    }
}

- (void)loadingMorePaginatedContentCompleted
{
    self.paginationLoading = NO;
    [self reloadData];
}

- (void)loadingMorePaginatedContentFailed
{
    self.paginationLoading = NO;
    [self reloadData];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // _cachedhasMorePaginatedContent implies _cachedContentIsPaginated
    if (!_GUARD_settingContentOffsetInViewDidLayoutSubviews
        && _cachedHasMorePaginatedContent && ( ! self.paginationLoading))
    {
        CGFloat scrollViewHeight = scrollView.frame.size.height;
        CGFloat scrollContentSizeHeight = scrollView.contentSize.height;
        CGFloat scrollOffset = scrollView.contentOffset.y;

        if (scrollOffset + scrollViewHeight >= scrollContentSizeHeight - 50.0)
        {
            self.paginationLoading = YES;
            [self loadMorePaginatedContent];
        }
    }
}

#pragma mark -
#pragma mark UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger adjustment = _cachedContentIsPaginated ? 1 : 0;
    return adjustment + _cachedNumberOfContentSections;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_cachedContentIsPaginated && (indexPath.section == _cachedNumberOfContentSections))
    {
        DQAbstractLoadingCollectionViewCell *result = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"PaginationLoading" forIndexPath:indexPath];
        [self prepareLoadingCell:result atIndexPath:indexPath];
        return result;
    }
    else
    {
        return [self cellForItemAtIndexPath:indexPath];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (_cachedContentIsPaginated && (section == _cachedNumberOfContentSections))
    {
        return _cachedHasMorePaginatedContent ? 1 : 0;
    }
    else
    {
        return [self numberOfItemsInSection:section];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (_cachedContentIsPaginated && (section == _cachedNumberOfContentSections))
    {
        return UIEdgeInsetsZero;
    }
    else
    {
        return [self insetForSection:section forLayout:(UICollectionViewFlowLayout *)collectionViewLayout];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_cachedContentIsPaginated && (indexPath.section == _cachedNumberOfContentSections))
    {
        return CGSizeMake(collectionView.bounds.size.width, 44.0);
    }
    else
    {
        return [self sizeForItemAtIndexPath:indexPath forLayout:(UICollectionViewFlowLayout *)collectionViewLayout];
    }
}

@end

@interface DQAbstractLoadingCollectionViewCell ()

@property (nonatomic, strong) UIView *wrapperView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *label;

@end

@implementation DQAbstractLoadingCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        _wrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        _wrapperView.translatesAutoresizingMaskIntoConstraints = NO;

        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.text = DQLocalizedString(@"Loading...", @"Data is being loaded from server indicator label");
        _label.font = [UIFont dq_phoneUserCellDetailFont];
        _label.textColor = [UIColor dq_phoneGrayTextColor];
        [_label sizeToFit];

        [self.contentView addSubview:_wrapperView];
        [_wrapperView addSubview:_spinner];
        [_wrapperView addSubview:_label];

        // Vertical
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_wrapperView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_wrapperView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_wrapperView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_wrapperView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];

        // Horizontal
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_spinner attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_label attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-10.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_wrapperView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_spinner attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_wrapperView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_label attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_wrapperView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow)
    {
        [self.spinner startAnimating];
    }
    else
    {
        [self.spinner stopAnimating];
    }
}

- (void)prepareForReuse
{
    [self.spinner stopAnimating];
    [super prepareForReuse];
}

@end
