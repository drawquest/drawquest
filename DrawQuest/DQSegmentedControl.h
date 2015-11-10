//
//  DQSegmentedControl.h
//  DrawQuest
//
//  Created by David Mauro on 9/19/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

static const CGFloat kDQSegmentedControlDesiredHeight = 50.0f; // TODO this should move to view metrics

typedef NS_ENUM(NSUInteger, DQSegmentedControlViewOption) {
    DQSegmentedControlViewOptionGrid,
    DQSegmentedControlViewOptionList,
    DQSegmentedControlViewOptionCount,
    DQSegmentedControlViewOptionNotFound = NSNotFound
};

@class DQSegmentedControl;

@protocol DQSegmentedControlDelegate <NSObject>

- (void)segmentedControl:(DQSegmentedControl *)segmentedControl didSelectSegmentIndex:(NSUInteger)index;

@optional

- (void)segmentedControl:(DQSegmentedControl *)segmentedControl didSelectViewOption:(DQSegmentedControlViewOption)viewOption;

@end

@protocol DQSegmentedControlDataSource <NSObject>

- (NSArray *)itemsForSegmentedControl:(DQSegmentedControl *)segmentedControl;

@optional

- (BOOL)shouldDisplayViewOptionsForSegmentedControl:(DQSegmentedControl *)segmentedControl;
- (DQSegmentedControlViewOption)defaultViewOptionForSegmentedControl:(DQSegmentedControl *)segmentedControl;
- (NSUInteger)defaultSegmentIndexForSegmentedControl:(DQSegmentedControl *)segmentedControl;

@end

@interface DQSegmentedControl : UIView

@property (nonatomic, weak) id<DQSegmentedControlDelegate> delegate;
@property (nonatomic, weak) id<DQSegmentedControlDataSource> dataSource;
@property (nonatomic, readonly, assign) DQSegmentedControlViewOption currentViewOption;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;

@end
