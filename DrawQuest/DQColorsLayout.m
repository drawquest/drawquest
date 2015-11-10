//
//  DQColorsLayout.m
//  DrawQuest
//
//  Created by David Mauro on 7/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQColorsLayout.h"

@interface DQColorsLayout ()

@property(nonatomic, strong) NSMutableArray *layoutAttributes;  // array of UICollectionViewLayoutAttributes
@property(nonatomic, strong) NSMutableArray *pendingLayoutAttributes;
@property(nonatomic) CGSize contentSize;

@end

@implementation DQColorsLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    if(!self.layoutAttributes)
    {
        [self doNewLayout];
        self.layoutAttributes = self.pendingLayoutAttributes;
    }
    
    // create a predicate to find cells that intersect with the passed rectangle, then use it to filter the array of layout attributes
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        CGRect cellFrame = layoutAttributes.frame;
        return (BOOL)CGRectIntersectsRect(cellFrame,rect);
    }];
    NSArray *filteredLayoutAttributes = [self.layoutAttributes filteredArrayUsingPredicate:predicate];
    
    // return the filtered array
    return filteredLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger cellIndex = indexPath.item;
    NSInteger row = cellIndex / kDQColorsLayoutItemsPerRow;
    CGFloat cellY = row * (kDQColorsLayoutItemHeight + kDQColorsLayoutItemSpacing);
    int position = cellIndex % kDQColorsLayoutItemsPerRow;
    CGFloat cellX = position * (kDQColorsLayoutItemWidth + kDQColorsLayoutItemSpacing);
    
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(cellX, cellY, kDQColorsLayoutItemWidth, kDQColorsLayoutItemHeight);
    
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
    NSUInteger numberOfRows = (cellCount + kDQColorsLayoutItemsPerRow - 1) / kDQColorsLayoutItemsPerRow;
    
    CGFloat rowHeight = kDQColorsLayoutItemHeight + kDQColorsLayoutItemSpacing;
    return CGSizeMake(self.collectionView.frame.size.width, (numberOfRows * rowHeight));
}

@end
