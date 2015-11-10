//
//  DQHeaderWithTableView.h
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQSegmentedControl.h"

@interface DQHeaderWithTableView : UIView

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) DQSegmentedControl *segmentedControl;
@property (nonatomic, strong, readonly) UIView *headerView;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;

- (id)initWithHeaderView:(UIView *)headerView segmentedControl:(BOOL)hasSegmentedControl;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithHeaderView:segmentedControl:);

- (void)reloadData;
- (void)hideHeaderView:(BOOL)hide;

@end
