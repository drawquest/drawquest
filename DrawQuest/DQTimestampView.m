//
//  DQTimestampView.m
//  DrawQuest
//
//  Created by David Mauro on 9/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTimestampView.h"

#import "DQPadTimestampView.h"
#import "DQPhoneTimestampView.h"

#import "UIView+STAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

@implementation DQTimestampView

- (id)initWithFrame:(CGRect)frame
{
    if ([self class] == [DQTimestampView class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadTimestampView alloc] initWithFrame:frame];
        }
        else
        {
            self = [[DQPhoneTimestampView alloc] initWithFrame:frame];
        }
    }
    else
    {
        self = [super initWithFrame:frame];
        if (self)
        {
            _label = [[UILabel alloc] initWithFrame:CGRectZero];
            _label.backgroundColor = [UIColor clearColor];
            _label.font = [UIFont dq_timestampFont];
            _label.textColor = self.tintColor;
            [self addSubview:_label];

            _image = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"timestamp_clock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            [self addSubview:_image];
        }
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.label.textColor = self.tintColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.label sizeToFit];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeMake(self.image.frameWidth + self.label.frameWidth + kDQTimestampViewSpacing, self.label.frameHeight);
    return size;
}

- (void)sizeToFit
{
    [self.label sizeToFit];
    CGRect bounds = CGRectZero;
    bounds.size = [self intrinsicContentSize];
    self.bounds = bounds;
    [self setNeedsLayout];
}

- (NSString *)intervalText
{
    // NSLog(@"----------------------------------------------");
    // NSLog(@"intervalText: timestamp: %@", self.timestamp);
    // NSLog(@"intervalText: timeIntervalSinceNow: %f", [self.timestamp timeIntervalSinceNow]);
    NSTimeInterval interval = MAX(0, -[self.timestamp timeIntervalSinceNow]);
    // NSLog(@"intervalText: interval: %f", interval);
    NSString *intervalText = @"";
    if (interval < 5)
    {
        // NSLog(@"intervalText: option a");
        intervalText = DQLocalizedStringWithDefaultValue(@"TimestampTimesJustNow", nil, nil, @"just now", @"Timestamp label for an item that showed up in the last few seconds");
    }
    else if (interval < 60)
    {
        // NSLog(@"intervalText: option b");
        intervalText = [NSString stringWithFormat:DQLocalizedStringWithDefaultValue(@"TimestampTimesSeconds", nil, nil, @"%ds", @"Simple time unit suffix indicating seconds, e.g.: 5s"), (int)(interval)];
    }
    else if (interval/60 < 60)
    {
        // NSLog(@"intervalText: option c");
        intervalText = [NSString stringWithFormat:DQLocalizedStringWithDefaultValue(@"TimestampTimesMinutes", nil, nil, @"%dm", @"Simple time unit suffix indicating minutes, e.g.: 5m"), (int)(interval/60)];
    }
    else if (interval/(60*60) < 24)
    {
        // NSLog(@"intervalText: option d");
        intervalText = [NSString stringWithFormat:DQLocalizedStringWithDefaultValue(@"TimestampTimesHours", nil, nil, @"%dh", @"Simple time unit suffix indicating hours, e.g.: 5h"), (int)(interval/(60*60))];
    }
    else if (interval/(60*60*24) < 7)
    {
        // NSLog(@"intervalText: option e");
        intervalText = [NSString stringWithFormat:DQLocalizedStringWithDefaultValue(@"TimestampTimesDays", nil, nil, @"%dd", @"Simple time unit suffix indicating days, e.g.: 5d"), (int)(interval/(60*60*24))];
    }
    else if (interval/(60*60*24*365) < 1)
    {
        // NSLog(@"intervalText: option f");
        intervalText = [NSString stringWithFormat:DQLocalizedStringWithDefaultValue(@"TimestampTimesWeeks", nil, nil, @"%dw", @"Simple time unit suffix indicating weeks, e.g.: 5w"), (int)(interval/(60*60*24*7))];
    }
    // We should skip month intervals because it looks like minutes (m)
    else
    {
        // NSLog(@"intervalText: option g");
        intervalText = [NSString stringWithFormat:DQLocalizedStringWithDefaultValue(@"TimestampTimesYears", nil, nil, @"%dy", @"Simple time unit suffix indicating years, e.g.: 5y"), (int)(interval/(60*60*24*365))];
    }
    return intervalText;
}

- (void)setTimestamp:(NSDate *)timestamp
{
    _timestamp = timestamp;
    self.label.text = [self intervalText];
    [self sizeToFit];
}

@end
