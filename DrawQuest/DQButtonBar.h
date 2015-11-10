//
//  DQButtonBar.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/12/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat kDQButtonBarButtonSize;
extern const CGFloat kDQButtonBarButtonSpacing;

@protocol DQButtonBarDelegate;

@interface DQButtonBar : UIControl

@property (nonatomic, weak) id<DQButtonBarDelegate> delegate;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, assign, getter = isDisclosingButtonGroup) BOOL disclosingButtonGroup;
@property (nonatomic, strong) UIButton *disclosureButton;

- (void)discloseButtonGroupAtIndex:(NSUInteger)index;
- (void)hideActiveButtonGroup;

@end

@protocol DQButtonBarDelegate <NSObject>
@required
- (BOOL)buttonBar:(DQButtonBar *)buttonBar shouldDiscloseButtonGroupAtIndex:(NSUInteger)index;
- (NSArray *)buttonBar:(DQButtonBar *)buttonBar buttonGroupAtIndex:(NSUInteger)index;

@optional
- (void)buttonBarDidClose;

@end
