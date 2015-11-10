//
//  DQView.m
//  DrawQuest
//
//  Created by David Mauro on 11/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQView.h"

@implementation DQView

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    if (self.dq_tintColorDidChangeBlock)
    {
        self.dq_tintColorDidChangeBlock(self);
    }
}

@end
