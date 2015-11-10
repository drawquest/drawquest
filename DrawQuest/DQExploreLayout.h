//
//  DQExploreLayout.h
//  DrawQuest
//
//  Created by Dirk on 4/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DQExploreLayoutDelegate <UICollectionViewDelegate>
@optional
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface DQExploreLayout : UICollectionViewLayout
@end
