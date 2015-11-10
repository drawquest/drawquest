//
//  DQCircularMaskImageView.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-10-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCircularMaskImageView.h"
#import "UIColor+DQAdditions.h"

@implementation DQCircularMaskImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
        self.layer.cornerRadius = frame.size.width / 2.0;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
}

@end
