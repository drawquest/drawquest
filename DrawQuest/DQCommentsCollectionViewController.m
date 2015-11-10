//
//  DQCommentsCollectionViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentsCollectionViewController.h"

#import "DQSegmentedControl.h"
#import "DQCommentGridCollectionViewCell.h"
#import "DQCommentListCollectionViewCell.h"
#import "DQCollectionViewUploadCell.h"
#import "DQButton.h"
#import "DQTimestampView.h"

#import "UIView+STAdditions.h"
#import "UIColor+DQAdditions.h"

static NSString *DQCommentsCollectionViewControllerGridCell = @"DQCommentsCollectionViewControllerGridCell";
static NSString *DQCommentsCollectionViewControllerListCell = @"DQCommentsCollectionViewControllerListCell";
static NSString *DQCommentsCollectionViewControllerUploadCell = @"DQCommentsCollectionViewControllerUploadCell";

@interface DQCommentsCollectionViewController () <UICollectionViewDelegateFlowLayout, DQSegmentedControlDelegate, DQSegmentedControlDataSource>

@property (nonatomic, weak) UICollectionViewFlowLayout *layout;
@property (nonatomic, weak) DQSegmentedControl *weakSegmentedControl;

@end

@implementation DQCommentsCollectionViewController

@dynamic dataSource;

- (void)setDataSource:(id<DQCommentsCollectionViewControllerDataSource>)dataSource
{
    [super setDataSource:dataSource];
}

- (id<DQCommentsCollectionViewControllerDataSource>)dataSource
{
    return (id<DQCommentsCollectionViewControllerDataSource>)[super dataSource];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView registerClass:[DQCommentGridCollectionViewCell class] forCellWithReuseIdentifier:DQCommentsCollectionViewControllerGridCell];
    [self.collectionView registerClass:[DQCommentListCollectionViewCell class] forCellWithReuseIdentifier:DQCommentsCollectionViewControllerListCell];
    [self.collectionView registerClass:[DQCollectionViewUploadCell class] forCellWithReuseIdentifier:DQCommentsCollectionViewControllerUploadCell];

    // SegmentedCollectionViewController inits with a new flow layout
    self.layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)updateNoteCountForCommentAtIndex:(NSUInteger)index
{
    if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionList)
    {
        NSUInteger commentsSection = 1;
        if ([self.dataSource respondsToSelector:@selector(commentsSectionIndexForCollectionViewController:)])
        {
            commentsSection = [self.dataSource commentsSectionIndexForCollectionViewController:self];
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:commentsSection];
        DQComment *comment = [self.dataSource collectionViewController:self commentForIndexPath:indexPath];
        DQCommentListCollectionViewCell *listCell = (DQCommentListCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        listCell.notesCount = comment.numberOfReactions;
    }
}

#pragma mark -

- (UIView *)makeSegmentedControl
{
    DQSegmentedControl *segmentedControl = [[DQSegmentedControl alloc] initWithFrame:CGRectZero];
    segmentedControl.delegate = self;
    segmentedControl.dataSource = self;
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segmentedControl.frameHeight = kDQSegmentedControlDesiredHeight;
    self.weakSegmentedControl = segmentedControl;
    return segmentedControl;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    [self.delegate collectionViewController:self scrollViewDidScroll:scrollView];
}

#pragma mark - DQSegmentedCollectionViewController Template Methods

- (UIEdgeInsets)insetForSection:(NSInteger)section forLayout:(UICollectionViewFlowLayout *)layout
{
    NSUInteger commentUploadsSection = 0;
    NSUInteger commentsSection = 1;
    if ([self.dataSource respondsToSelector:@selector(commentUploadsSectionIndexForCollectionViewController:)])
    {
        commentUploadsSection = [self.dataSource commentUploadsSectionIndexForCollectionViewController:self];
    }
    if ([self.dataSource respondsToSelector:@selector(commentsSectionIndexForCollectionViewController:)])
    {
        commentsSection = [self.dataSource commentsSectionIndexForCollectionViewController:self];
    }

    UIEdgeInsets returnInset = UIEdgeInsetsZero;
    if (section == commentUploadsSection)
    {
        // Don't inset the commentUploads section if it's empty
        if ([self collectionView:self.collectionView numberOfItemsInSection:section] > 0)
        {
            if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionGrid)
            {
                returnInset = UIEdgeInsetsMake(10.0f, 6.0f, 0.0f, 0.0f);;
            }
            else if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionList)
            {
                returnInset = UIEdgeInsetsMake(8.0f, 8.0f, 0.0f, 0.0f);
            }
        }
    }
    else if (section == commentsSection)
    {
        if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionGrid)
        {
            returnInset = UIEdgeInsetsMake(10.0f, 6.0f, 10.0f, 6.0f);
        }
        else if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionList)
        {
            returnInset = UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f);
        }
    }
    else
    {
        // Unknown section, let the dataSource handle it
        if ([self.dataSource respondsToSelector:@selector(collectionViewController:insetForUnknownSection:)])
        {
            returnInset = [self.dataSource collectionViewController:self insetForUnknownSection:section];
        }
    }
    return returnInset;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath forLayout:(UICollectionViewFlowLayout *)layout
{
    NSUInteger commentUploadsSection = 0;
    NSUInteger commentsSection = 1;
    if ([self.dataSource respondsToSelector:@selector(commentUploadsSectionIndexForCollectionViewController:)])
    {
        commentUploadsSection = [self.dataSource commentUploadsSectionIndexForCollectionViewController:self];
    }
    if ([self.dataSource respondsToSelector:@selector(commentsSectionIndexForCollectionViewController:)])
    {
        commentsSection = [self.dataSource commentsSectionIndexForCollectionViewController:self];
    }

    CGSize size = CGSizeZero;
    if (indexPath.section == commentUploadsSection)
    {
        if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionGrid)
        {
            size = CGSizeMake(314.0f, kDQFormPhoneThumbnailHeight);
        }
        else if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionList)
        {
            size = CGSizeMake(310.0f, 44.0f);
        }
    }
    else if (indexPath.section == commentsSection)
    {
        if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionGrid)
        {
            size = CGSizeMake(kDQFormPhoneThumbnailWidth, kDQFormPhoneThumbnailHeight);
        }
        else if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionList)
        {
            size = CGSizeMake(kDQCollectionViewListCellWidth, kDQCollectionViewListCellHeight);
        }
    }
    else
    {
        // Unknown section, let the dataSource handle it
        if ([self.dataSource respondsToSelector:@selector(collectionViewController:sizeForUnknownItemAtIndexPath:)])
        {
            size = [self.dataSource collectionViewController:self sizeForUnknownItemAtIndexPath:indexPath];
        }
    }
    return size;
}

- (NSInteger)numberOfContentSections
{
    if ([self.dataSource respondsToSelector:@selector(numberOfContentSectionsInCollectionViewController:)])
    {
        return [self.dataSource numberOfContentSectionsInCollectionViewController:self];
    }
    else
    {
        return 2;
    }
}

- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger commentUploadsSection = 0;
    NSUInteger commentsSection = 1;
    if ([self.dataSource respondsToSelector:@selector(commentUploadsSectionIndexForCollectionViewController:)])
    {
        commentUploadsSection = [self.dataSource commentUploadsSectionIndexForCollectionViewController:self];
    }
    if ([self.dataSource respondsToSelector:@selector(commentsSectionIndexForCollectionViewController:)])
    {
        commentsSection = [self.dataSource commentsSectionIndexForCollectionViewController:self];
    }

    UICollectionViewCell *cell;
    if (indexPath.section == commentUploadsSection)
    {
        DQCommentUpload *commentUpload = [self.dataSource collectionViewController:self commentUploadForIndexPath:indexPath];
        DQCollectionViewUploadCell *uploadCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:DQCommentsCollectionViewControllerUploadCell forIndexPath:indexPath];
        [uploadCell initializeWithCommentUpload:commentUpload];
        __weak typeof(self) weakSelf = self;
        __weak typeof(commentUpload) weakCommentUpload = commentUpload;
        uploadCell.cancelButtonTappedBlock = ^(UIButton *sender) {
            if (weakSelf.cancelCommentUploadBlock)
            {
                weakSelf.cancelCommentUploadBlock(weakCommentUpload, sender);
            }
        };
        uploadCell.retryButtonTappedBlock = ^(UIButton *sender) {
            if (weakSelf.retryCommentUploadBlock)
            {
                weakSelf.retryCommentUploadBlock(weakCommentUpload, sender);
            }
        };
        cell = uploadCell;
    }
    else if (indexPath.section == commentsSection)
    {
        DQComment *comment = [self.dataSource collectionViewController:self commentForIndexPath:indexPath];
        if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionGrid)
        {
            DQCommentGridCollectionViewCell *gridCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:DQCommentsCollectionViewControllerGridCell forIndexPath:indexPath];
            // Temp hack fix
            [gridCell prepareForReuse];
            __weak typeof(self) weakSelf = self;
            gridCell.cellTappedBlock = ^{
                if (weakSelf.showDrawingDetailBlock)
                {
                    weakSelf.showDrawingDetailBlock([weakSelf.dataSource collectionViewController:weakSelf commentForIndexPath:indexPath]);
                }
            };
            gridCell.imageView.imageURL = [comment imageURLForKey:DQImageKeyArchive];
            cell = gridCell;
        }
        else if (self.weakSegmentedControl.currentViewOption == DQSegmentedControlViewOptionList)
        {
            __weak typeof(self) weakSelf = self;
            DQCommentListCollectionViewCell *listCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:DQCommentsCollectionViewControllerListCell forIndexPath:indexPath];
            NSString *commentID = comment.serverID;
            if (self.commentViewedBlock)
            {
                self.commentViewedBlock(self, commentID);
            }
            listCell.playbackImageView.commentID = commentID;
            listCell.playbackImageView.imageURL = [comment imageURLForKey:DQImageKeyPhoneGallery];
            listCell.avatarImageView.imageURL = comment.authorAvatarURL;
            listCell.usernameLabel.text = comment.authorName;
            listCell.notesCount = comment.numberOfReactions;
            listCell.timestampView.timestamp = comment.timestamp;
            listCell.starButton.commentID = commentID;


            [[NSNotificationCenter defaultCenter] addObserver:listCell selector:@selector(dq_notificationHandler:) name:DQCommentRefreshedNotification object:nil];
            listCell.dq_notificationHandlerBlock = ^(DQCommentListCollectionViewCell *cell, NSNotification *notification) {
                if (notification)
                {
                    DQComment *newComment = [notification object];
                    if ([newComment.serverID isEqualToString:commentID])
                    {
                        if ([weakSelf.dataSource collectionViewController:weakSelf
                                                replaceCommentAtIndexPath:indexPath
                                                              withComment:newComment])
                        {
                            // we *could* push more into the cell than just notesCount
                            cell.notesCount = newComment.numberOfReactions;
                        }
                    }
                }
                else
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:cell name:DQCommentRefreshedNotification object:nil];
                }
            };


            if ([self.dataSource collectionViewController:self shouldDisplayFollowButtonForComment:comment])
            {
                [listCell displayFollowButtonForUsername:comment.authorName];
            }
            listCell.showDrawingDetailBlock = ^{
                if (weakSelf.showDrawingDetailBlock)
                {
                    weakSelf.showDrawingDetailBlock([weakSelf.dataSource collectionViewController:weakSelf commentForIndexPath:indexPath]);
                }
            };
            listCell.imageTappedBlock = ^(DQCommentListCollectionViewCell *cell){
                if (weakSelf.imageTappedBlock)
                {
                    weakSelf.imageTappedBlock([weakSelf.dataSource collectionViewController:weakSelf commentForIndexPath:indexPath], cell.playbackImageView);
                }
            };
            listCell.showUserProfileBlock = ^{
                if (weakSelf.showUserProfileBlock)
                {
                    weakSelf.showUserProfileBlock([weakSelf.dataSource collectionViewController:weakSelf commentForIndexPath:indexPath]);
                }
            };
            listCell.playbackBlock = ^(DQButton *playbackButton, DQPlaybackImageView *playbackImageView, DQCommentListCollectionViewCell *cell) {
                if (weakSelf.playbackBlock)
                {
                    weakSelf.playbackBlock(playbackButton, playbackImageView, [weakSelf.dataSource collectionViewController:weakSelf commentForIndexPath:indexPath]);
                }
            };
            listCell.showMoreOptionsBlock = ^{
                if (weakSelf.showMoreOptionsBlock)
                {
                    weakSelf.showMoreOptionsBlock(comment);
                }
            };
            listCell.shareButtonTappedBlock = ^(DQCommentListCollectionViewCell *cell){
                if (weakSelf.shareCommentBlock)
                {
                    weakSelf.shareCommentBlock([weakSelf.dataSource collectionViewController:weakSelf commentForIndexPath:indexPath]);
                }
            };
            cell = listCell;
        }
    }
    else
    {
        // Unknown section, let the dataSource handle it
        if ([self.dataSource respondsToSelector:@selector(collectionViewController:cellForUnknownItemAtIndexPath:)])
        {
            cell = [self.dataSource collectionViewController:self cellForUnknownItemAtIndexPath:indexPath];
        }
    }
    return cell;
}

#pragma mark - DQSegmentedControlDelegate Methods

- (void)segmentedControl:(DQSegmentedControl *)segmentedControl didSelectSegmentIndex:(NSUInteger)index
{
    [self.delegate collectionViewController:self didSelectSegmentIndex:index];
}

- (void)segmentedControl:(DQSegmentedControl *)segmentedControl didSelectViewOption:(DQSegmentedControlViewOption)viewOption
{
    if (viewOption == DQSegmentedControlViewOptionGrid)
    {
        self.layout.minimumLineSpacing = 10.0f;
        self.layout.minimumInteritemSpacing = 10.0f;
    }
    else if (viewOption == DQSegmentedControlViewOptionList)
    {
        self.layout.minimumLineSpacing = 8.0f;
        self.layout.minimumInteritemSpacing = 0.0f;
    }
    [self reloadData];
}

#pragma mark - DQSegmentedControlDataSource Methods

- (NSArray *)itemsForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    return [self.dataSource segmentItemsForCollectionViewController:self];
}

- (BOOL)shouldDisplayViewOptionsForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    return YES;
}

- (DQSegmentedControlViewOption)defaultViewOptionForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    DQSegmentedControlViewOption value = 0;
    if ([self.dataSource respondsToSelector:@selector(defaultViewOptionForCollectionViewController:)])
    {
        value = [self.dataSource defaultViewOptionForCollectionViewController:self];
    }
    return value;
}

- (NSUInteger)defaultSegmentIndexForSegmentedControl:(DQSegmentedControl *)segmentedControl
{
    NSUInteger value = 0;
    if ([self.dataSource respondsToSelector:@selector(defaultSegmentIndexForCollectionViewController:)])
    {
        value = [self.dataSource defaultSegmentIndexForCollectionViewController:self];
    }
    return value;
}

@end
