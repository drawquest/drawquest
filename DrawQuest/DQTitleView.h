//
//  DQTitleView.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/22/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQTitleViewStyleNavigationBar = 0,
    DQTitleViewStyleToolbar
} DQTitleViewStyle;

@interface DQTitleView : UIView

@property (nonatomic, copy) NSString *text;

// designated initializer
- (id)initWithStyle:(DQTitleViewStyle)style;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithStyle:);

@end
