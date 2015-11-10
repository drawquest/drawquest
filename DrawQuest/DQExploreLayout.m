//
//  DQExploreLayout.m
//  DrawQuest
//
//  Created by Dirk on 4/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQExploreLayout.h"

static const CGSize kSmallItemSize = { 219.0f, 165.0f };
static const CGSize kLargeItemSize = { 470.0f, 352.0f };
static const UIEdgeInsets kSectionInsets = { 30.0f, 14.0f, 30.0f, 14.0f };

static const CGFloat kInterItemSpacing = 30.0f;
static const NSInteger kItemsPerRow = 5;

@interface DQExploreLayout()
@property(nonatomic, strong) NSMutableArray *layoutAttributes;  // array of UICollectionViewLayoutAttributes
@property(nonatomic, strong) NSMutableArray *pendingLayoutAttributes;
@property(nonatomic) CGSize contentSize;
@end

@implementation DQExploreLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    if(!self.layoutAttributes)
    {
        [self doNewLayout];
        self.layoutAttributes = self.pendingLayoutAttributes;
    }
    
    // create a predicate to find cells that intersect with the passed rectangle, then use it to filter the array of layout attributes
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes ,NSDictionary *bindings) {
        CGRect cellFrame = layoutAttributes.frame;
        return CGRectIntersectsRect(cellFrame,rect);
    }];
    NSArray *filteredLayoutAttributes = [self.layoutAttributes filteredArrayUsingPredicate:predicate];
    
    // return the filtered array
    return filteredLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    NSInteger cellIndex = indexPath.item;
    NSInteger row = cellIndex / kItemsPerRow;
    CGFloat topOfRow = row * (kLargeItemSize.height + kInterItemSpacing) + kSectionInsets.top;
    int position = cellIndex % kItemsPerRow;
    
    if (row % 2 == 0) {
        if (position == 0) {
            layoutAttributes.size = kLargeItemSize;
            layoutAttributes.frame = (CGRect) { { kSectionInsets.left, topOfRow }, kLargeItemSize };
        } else {
            layoutAttributes.size = kSmallItemSize;
            CGFloat topEdge;
            CGFloat leftEdge;
            if (position == 1 || position == 2) {
                topEdge = topOfRow;
            } else {
                topEdge = topOfRow + kLargeItemSize.height - kSmallItemSize.height;
            }
            
            if (position == 1 || position == 3) {
                leftEdge = kSectionInsets.left + kLargeItemSize.width + kInterItemSpacing;
            } else {
                leftEdge = kSectionInsets.left + kLargeItemSize.width + kInterItemSpacing + kSmallItemSize.width + kInterItemSpacing;
            }
            layoutAttributes.frame = (CGRect) { { leftEdge, topEdge }, layoutAttributes.size };
        }
    } else {
        if (position < 4) {
            layoutAttributes.size = kSmallItemSize;
            CGFloat topEdge;
            CGFloat leftEdge;
            if (position == 0 || position == 1) {
                topEdge = topOfRow;
            } else {
                topEdge = topOfRow + kLargeItemSize.height - kSmallItemSize.height;
            }
            
            if (position == 0 || position == 2) {
                leftEdge = kSectionInsets.left;
            } else {
                leftEdge = kSectionInsets.left + (kSmallItemSize.width + kInterItemSpacing);
            }
            layoutAttributes.frame = (CGRect) { { leftEdge, topEdge }, layoutAttributes.size };
        } else {
            layoutAttributes.size = kLargeItemSize;
            layoutAttributes.frame = (CGRect) { { kSectionInsets.left + kInterItemSpacing + (kSmallItemSize.width * 2) + kInterItemSpacing, topOfRow }, kLargeItemSize };
        }
    }

    return layoutAttributes;
}

-(void)doNewLayout
{
    // find out how many cells there are
    NSUInteger cellCount = [self.collectionView numberOfItemsInSection:0];
    
    // now build the array of layout attributes
    self.pendingLayoutAttributes = [NSMutableArray arrayWithCapacity:cellCount];
    
    for(NSUInteger cellIndex = 0; cellIndex < cellCount; ++cellIndex)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:cellIndex inSection:0];
        UICollectionViewLayoutAttributes *layoutAttributes = (UICollectionViewLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:indexPath];
        self.pendingLayoutAttributes[cellIndex] = layoutAttributes;
    }
}

- (void)invalidateLayout
{
    [super invalidateLayout];
    self.layoutAttributes = nil;
}

- (CGSize)collectionViewContentSize
{
    NSUInteger cellCount = [self.collectionView numberOfItemsInSection:0];
    NSUInteger numberOfRows = (cellCount + kItemsPerRow - 1) / kItemsPerRow;
    
    CGFloat rowHeight = kLargeItemSize.height + kInterItemSpacing;
    return CGSizeMake(self.collectionView.frame.size.width, (numberOfRows * rowHeight) + kSectionInsets.top + kSectionInsets.bottom);
}

@end
