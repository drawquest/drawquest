//
//  DQTintedTableViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTintedTableViewCell.h"

@implementation DQTintedTableViewCell

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.textLabel.textColor = self.tintColor;
}

@end
