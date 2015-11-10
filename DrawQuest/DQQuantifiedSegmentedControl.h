//
//  DQQuantifiedSegmentedControl.h
//  DrawQuest
//
//  Created by David Mauro on 10/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

static const CGFloat kDQQuantifiedSegmentedControlDesiredHeight = 62.0f;

@class DQQuantifiedSegmentedControl;

@protocol DQQuantifiedSegmentedControlDelegate <NSObject>

- (void)segmentedControl:(DQQuantifiedSegmentedControl *)segmentedControl didSelectSegmentAtIndex:(NSInteger)index;

@end

@interface DQQuantifiedSegmentedControl : UIView

@property (nonatomic, weak) id<DQQuantifiedSegmentedControlDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;

- (id)initWithItems:(NSArray *)items;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithItems:);

- (void)setCount:(NSString *)count forSegmentIndex:(NSInteger)index;

@end
