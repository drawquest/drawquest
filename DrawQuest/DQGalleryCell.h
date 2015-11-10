//
//  DQGalleryCell.h
//  DrawQuest
//
//  Created by Dirk on 3/22/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQGalleryCell;

@protocol DQGalleryCellDelegate <NSObject>

- (void)galleryCellDidFocus:(DQGalleryCell *)cell;

@end

@interface DQGalleryCell : UICollectionViewCell

@property (nonatomic, weak) id<DQGalleryCellDelegate> delegate;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id<UITableViewDataSource, UITableViewDelegate> tableViewDataSource;
@property (nonatomic, readonly, assign, getter = isFocused) BOOL focused;

@property (nonatomic, copy) void (^dq_notificationHandlerBlock)(DQGalleryCell *cell, NSNotification *notification);
- (void)dq_notificationHandler:(NSNotification *)notification;

@end
