//
//  DQBasementButton.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQBasementButtonStyleNavigationBar,
    DQBasementButtonStyleToolbar
} DQBasementButtonStyle;

@interface DQBasementButton : UIView

@property (nonatomic, assign) NSUInteger badgeCount;

// designated initializer
- (id)initWithStyle:(DQBasementButtonStyle)style;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithStyle:);
- (id)init MSDesignatedInitializer(initWithStyle:);

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end


@interface DQBadgeView : UIView

@property (nonatomic, assign) NSUInteger badgeCount;
@property (nonatomic, strong) UILabel *countLabel;

@end
