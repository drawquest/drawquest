//
//  DQPadTimestampView.m
//  DrawQuest
//
//  Created by David Mauro on 11/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadTimestampView.h"

#import "UIView+STAdditions.h"

@implementation DQPadTimestampView

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.label sizeToFit];
    self.label.frameX = self.image.frameMaxX + kDQTimestampViewSpacing;
    self.label.frameCenterY = self.image.frameCenterY;
}

@end
