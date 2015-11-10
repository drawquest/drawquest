//
//  DQTableView.h
//  DrawQuest
//
//  Created by David Mauro on 9/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQTableView : UITableView

- (void)setHeaderView:(UIView *)headerView;
- (void)setErrorView:(UIView *)errorView;

@end
