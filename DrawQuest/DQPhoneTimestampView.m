//
//  DQPhoneTimestampView.m
//  DrawQuest
//
//  Created by David Mauro on 11/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneTimestampView.h"

@implementation DQPhoneTimestampView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

        self.image.translatesAutoresizingMaskIntoConstraints = NO;

        // Layout
        NSDictionary *viewBindings = @{@"_label": self.label, @"_image": self.image};
        NSDictionary *metrics = @{@"spacing": @(kDQTimestampViewSpacing)};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_image]-spacing-[_label]" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_label]|" options:0 metrics:nil views:viewBindings]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self invalidateIntrinsicContentSize];
}

- (void)setTimestamp:(NSDate *)timestamp
{
    [super setTimestamp:timestamp];

    [self invalidateIntrinsicContentSize];
}

@end
