//
//  DQFlowLayout.m
//  DrawQuest
//
//  Created by Dirk on 3/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQFlowLayout.h"
#import "DQFlowLayoutAttributes.h"

@implementation DQFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    CGRect visibleRect = {.origin = self.collectionView.contentOffset, .size = self.collectionView.bounds.size};
    CGFloat activeCellDistance = MAXFLOAT;
    DQFlowLayoutAttributes *activeCellAttributes = nil;

    for (DQFlowLayoutAttributes *attributes in array) {
        if (CGRectIntersectsRect(attributes.frame, visibleRect)) {
            [self setFrameForSupplementalViewOfKind:UICollectionElementKindSectionHeader];
            [self setFrameForSupplementalViewOfKind:UICollectionElementKindSectionFooter];

            CGFloat distance = ABS(CGRectGetMidX(visibleRect) - attributes.center.x);
            if (distance < activeCellDistance)
            {
                activeCellDistance = distance;
                activeCellAttributes = attributes;
            }
            attributes.dimmed = YES;
        }
    }
    activeCellAttributes.dimmed = NO;

    return array;
}

+ (Class)layoutAttributesClass
{
    return [DQFlowLayoutAttributes class];
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);

    NSArray* array = [super layoutAttributesForElementsInRect:targetRect];

    // NSMutableString *log = [[NSMutableString alloc] init];
    // [log appendFormat:@"\n======\nproposedContentOffset: %@", NSStringFromCGPoint(proposedContentOffset)];
    // [log appendFormat:@"\nvelocity: %@", NSStringFromCGPoint(velocity)];
    // [log appendFormat:@"\nself.collectionViewContentSize: %@", NSStringFromCGSize(self.collectionViewContentSize)];
    // [log appendFormat:@"\nhorizontalCenter: %f", horizontalCenter];
    // [log appendFormat:@"\ntargetRect: %@", NSStringFromCGRect(targetRect)];
    // [log appendFormat:@"\narray: %@", array];
    for (UICollectionViewLayoutAttributes* layoutAttributes in array)
    {
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
        // [log appendFormat:@"\n---\nitemHorizontalCenter: %f", itemHorizontalCenter];
        if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment))
        {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
            // [log appendFormat:@"\noffsetAdjustment = %f", offsetAdjustment];
        }
        else
        {
            // [log appendFormat:@"\nskipping..."];
        }
    }

    CGPoint result = CGPointMake(MIN(MAX(proposedContentOffset.x + offsetAdjustment, 0.0), self.collectionViewContentSize.width - CGRectGetWidth(self.collectionView.frame)), proposedContentOffset.y);
    // [log appendFormat:@"\n---\nresult: %@", NSStringFromCGPoint(result)];
    // NSLog(@"%@", log);
    return result;
}

- (void)setFrameForSupplementalViewOfKind:(NSString*)kind
{
    DQFlowLayoutAttributes *attributes = [[[self class] layoutAttributesClass] layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    if (attributes) {
        CGRect frame = [attributes frame];
        frame.origin.x -= CGRectGetWidth(frame);
        attributes.frame = frame;
    }
}


@end
