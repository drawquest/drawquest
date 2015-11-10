//
//  DQSegmentedCollectionViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, DQSegmentedCollectionViewControllerStatus)
{
    DQSegmentedCollectionViewControllerStatusDisplayNothing = 0,
    DQSegmentedCollectionViewControllerStatusDisplayHeaderView = 1 << 0,
    DQSegmentedCollectionViewControllerStatusDisplaySegmentedControl = 1 << 1,
    DQSegmentedCollectionViewControllerStatusDisplayErrorView = 1 << 2
};

@class DQSegmentedCollectionViewController;

@protocol DQSegmentedCollectionViewControllerDataSource <NSObject>

@optional

// defaults to 1 (a subclass could override numberOfItemsInSection to bypass this being called)
- (NSInteger)numberOfContentSectionsInCollectionViewController:(DQSegmentedCollectionViewController *)viewController;

// defaults to 0 (a subclass could override numberOfItemsInSection: to bypass this being called)
- (NSInteger)collectionViewController:(DQSegmentedCollectionViewController *)viewController
               numberOfItemsInSection:(NSInteger)section;

// defaults to nil if not implemented (a subclass could override cellForItemAtIndexPath: to bypass this being called)
- (UICollectionViewCell *)collectionViewController:(DQSegmentedCollectionViewController *)viewController
                            cellForItemAtIndexPath:(NSIndexPath *)indexPath;

// defaults to layout.sectionInset if not implemented (a subclass could override insetForSection: to bypass this being called)
- (UIEdgeInsets)collectionViewController:(DQSegmentedCollectionViewController *)viewController
                         insetForSection:(NSInteger)section
                               forLayout:(UICollectionViewFlowLayout *)layout;

// defaults to layout.itemSize if not implemented (a subclass could override sizeforItemAtIndexPath: to bypass this being called)
- (CGSize)collectionViewController:(DQSegmentedCollectionViewController *)viewController
            sizeForItemAtIndexPath:(NSIndexPath *)indexPath
                         forLayout:(UICollectionViewFlowLayout *)layout;

// defaults to NO if not implemented, is called by -reloadData and -setDataSource:
- (BOOL)contentIsPaginatedInCollectionViewController:(DQSegmentedCollectionViewController *)viewController;

// defaults to NO if not implemented (a subclass could override shouldDisplayPagination to bypass this being called)
- (BOOL)hasMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController;

// does nothing if not implemented (a subclass could override loadMorePaginatedContent to bypass this being called)
- (void)loadMorePaginatedContentInCollectionViewController:(DQSegmentedCollectionViewController *)viewController;

// defaults to nil if not implemented, is called by -makeSegmentedControl
- (UIView *)segmentedControlForCollectionViewController:(DQSegmentedCollectionViewController *)viewController;

@end

@interface DQAbstractLoadingCollectionViewCell : UICollectionViewCell
@end

@interface DQSegmentedCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id<DQSegmentedCollectionViewControllerDataSource> dataSource;

@property (nonatomic, readonly, strong) UIView *headerView;
@property (nonatomic, readonly, strong) UIView *errorView;
@property (nonatomic, readonly, strong) UIView *segmentedControl;
@property (nonatomic, assign) DQSegmentedCollectionViewControllerStatus displayStatus;

- (id)initWithHeaderView:(UIView *)headerView errorView:(UIView *)errorView;
- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout MSDesignatedInitializer(initWithHeaderView:errorView:);
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithHeaderView:errorView:);

- (UIView *)makeSegmentedControl;

- (void)reloadData;
- (void)scrollToTop;

- (void)startDisplayingSpinner;
- (void)stopDisplayingSpinner;

- (void)reloadItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

// Template methods - if you override these, you probably do not want to call super

- (Class)loadingCellClass; // returns [DQAbstractLoadingCollectionViewCell class]
- (NSInteger)numberOfContentSections; // returns [self.dataSource numberOfContentSectionsInCollectionViewController:self]
- (NSInteger)numberOfItemsInSection:(NSInteger)section; // returns [self.dataSource collectionViewController:self numberOfItemsInSection:section]
- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath; // returns [self.dataSource collectionViewController:self cellForItemAtIndexPath:indexPath]
- (UIEdgeInsets)insetForSection:(NSInteger)section forLayout:(UICollectionViewFlowLayout *)layout; // returns [self.dataSource collectionViewController:self section forLayout:layout]
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath forLayout:(UICollectionViewFlowLayout *)layout; // returns [self.dataSource collectionView:self sizeForItemAtIndexPath:indexPath forLayout:layout]
- (BOOL)contentIsPaginated; // returns [self.dataSource contentIsPaginatedInCollectionViewController:self]
- (BOOL)hasMorePaginatedContent; // return [self.dataSource hasMorePaginatedContentInCollectionViewController:self]
- (void)loadMorePaginatedContent; // if you override this, you MUST NOT call super
- (void)loadingMorePaginatedContentCompleted; // if you override this, you MUST call super
- (void)loadingMorePaginatedContentFailed; // if you override this, you MUST call super

@end
