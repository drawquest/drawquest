//
//  DQExploreUserCell.h
//  DrawQuest
//
//  Created by Dirk on 4/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQUser.h"

@class DQExploreUserCell;

@protocol DQExploreUserCellDelegate <NSObject>
- (void)exploreUserCellDidTapFollowUser:(DQExploreUserCell *)cell;
@end

@interface DQExploreUserCell : UICollectionViewCell
@property (nonatomic, weak) id<DQExploreUserCellDelegate> delegate;
@property (nonatomic, strong) DQUser *user;

- (void)setUser:(DQUser *)user loggedInUsername:(NSString *)loggedInUsername;

@end
