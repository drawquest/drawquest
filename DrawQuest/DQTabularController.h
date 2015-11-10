//
//  DQTabularController.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-11.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DQTabularControllerDelegate;
@class DQTabularItem;

@interface DQTabularController : UIViewController

@property (nonatomic, readonly, copy) NSArray *items;
@property (nonatomic, readonly, assign) NSUInteger selectedIndex;
@property (nonatomic, weak) id<DQTabularControllerDelegate> delegate;

- (instancetype)initWithItems:(NSArray *)items delegate:(id<DQTabularControllerDelegate>)delegate startIndex:(NSUInteger)startIndex;
- (DQTabularItem *)itemForIndex:(NSUInteger)index;

- (void)setSelectedIndex:(NSUInteger)selectedIndex;

@end

@protocol DQTabularControllerDelegate <NSObject>

- (void)tabularController:(DQTabularController *)tabularController displayViewController:(UIViewController *)viewController;
- (void)tabularController:(DQTabularController *)tabularController hideViewController:(UIViewController *)viewController;

@optional

- (BOOL)tabularController:(DQTabularController *)tabularController shouldSelectItem:(DQTabularItem *)item atIndex:(NSUInteger)index;
- (void)tabularController:(DQTabularController *)tabularController didSelectItem:(DQTabularItem *)item atIndex:(NSUInteger)index;

@end
