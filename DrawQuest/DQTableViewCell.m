//
//  DQTableViewCell.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-02.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTableViewCell.h"

@implementation DQTableViewCell

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    if (self.dq_tintColorDidChangeBlock)
    {
        self.dq_tintColorDidChangeBlock(self);
    }
}

@end
