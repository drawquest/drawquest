//
//  DQNavigationBar.m
//  DrawQuest
//
//  Created by David Mauro on 9/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQNavigationBar.h"

static const CGFloat kDQNavigationBarHeight = 64.0f;

@implementation DQNavigationBar

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = CGSizeMake(self.frame.size.width, kDQNavigationBarHeight);
    return newSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // We have to vertically center our UIBarButtonItems
    // iOS 7 seems to reset the origin of the customView to 0,0
    for (UINavigationItem *item in self.items)
    {
        NSArray *items = [item.leftBarButtonItems arrayByAddingObjectsFromArray:item.rightBarButtonItems];
        for (UIBarButtonItem *barButton in items)
        {
            CGRect frame = barButton.customView.frame;
            //frame.origin.y = 20;
            barButton.customView.frame = frame;
        }
        
    }
    
    [self correctSize];
}

- (void)correctSize {
    
    self.frame = CGRectMake(0, 0, self.frame.size.width, 64);
}


@end
