//
//  DQCommentsCollectionViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSegmentedCollectionViewController.h"

#import "DQComment.h"
#import "DQCommentUpload.h"
#import "DQSegmentedControl.h"

@class DQButton;
@class DQPlaybackImageView;

@class DQCommentsCollectionViewController, DQCommentListCollectionViewCell;

@protocol DQCommentsCollectionViewControllerDelegate <NSObject>

- (void)collectionViewController:(DQCommentsCollectionViewController *)viewController didSelectSegmentIndex:(NSUInteger)index;
- (void)collectionViewController:(DQCommentsCollectionViewController *)viewController scrollViewDidScroll:(UIScrollView *)scrollView;

@end

@protocol DQCommentsCollectionViewControllerDataSource <DQSegmentedCollectionViewControllerDataSource>

- (NSString *)loggedInUsernameForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
- (DQComment *)collectionViewController:(DQCommentsCollectionViewController *)viewController commentForIndexPath:(NSIndexPath *)indexPath;
- (DQCommentUpload *)collectionViewController:(DQCommentsCollectionViewController *)viewController commentUploadForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionViewController:(DQCommentsCollectionViewController *)viewController replaceCommentAtIndexPath:(NSIndexPath *)indexPath withComment:(DQComment *)newComment;
- (NSArray *)segmentItemsForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
- (BOOL)collectionViewController:(DQCommentsCollectionViewController *)viewController shouldDisplayFollowButtonForComment:(DQComment *)comment;

@optional

- (DQSegmentedControlViewOption)defaultViewOptionForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
- (NSUInteger)defaultSegmentIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
- (NSUInteger)commentUploadsSectionIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
- (NSUInteger)commentsSectionIndexForCollectionViewController:(DQCommentsCollectionViewController *)viewController;
- (UICollectionViewCell *)collectionViewController:(DQCommentsCollectionViewController *)viewController cellForUnknownItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)collectionViewController:(DQSegmentedCollectionViewController *)viewController sizeForUnknownItemAtIndexPath:(NSIndexPath *)indexPath;
- (UIEdgeInsets)collectionViewController:(DQSegmentedCollectionViewController *)viewController insetForUnknownSection:(NSInteger)section;

@end

@interface DQCommentsCollectionViewController : DQSegmentedCollectionViewController

@property (nonatomic, strong) UIView *headerViewWrapper;
@property (nonatomic, weak) id<DQCommentsCollectionViewControllerDelegate> delegate;
@property (nonatomic, weak) id<DQCommentsCollectionViewControllerDataSource> dataSource;
@property (nonatomic, copy) void (^imageTappedBlock)(DQComment *comment, UIView *imageView);
@property (nonatomic, copy) void (^showDrawingDetailBlock)(DQComment *comment);
@property (nonatomic, copy) void (^showUserProfileBlock)(DQComment *comment);
@property (nonatomic, copy) void (^playbackBlock)(DQButton *playbackButton, DQPlaybackImageView *playbackView, DQComment *comment);
@property (nonatomic, copy) void (^retryCommentUploadBlock)(DQCommentUpload *commentUpload, UIButton *sender);
@property (nonatomic, copy) void (^cancelCommentUploadBlock)(DQCommentUpload *commentUpload, UIButton *sender);
@property (nonatomic, copy) void (^showMoreOptionsBlock)(DQComment *);
@property (nonatomic, copy) void (^shareCommentBlock)(DQComment *);
@property (nonatomic, assign) DQSegmentedCollectionViewControllerStatus displayStatus;
@property (nonatomic, copy) void (^commentViewedBlock)(DQCommentsCollectionViewController *collectionViewController, NSString *commentID);

- (void)updateNoteCountForCommentAtIndex:(NSUInteger)index;

@end
