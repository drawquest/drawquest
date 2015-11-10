//
//  DQBasementButton.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQBasementButton.h"

@interface DQBasementButton ()

@property (strong, nonatomic) UIButton *internalButton;
@property (strong, nonatomic) DQBadgeView *badgeView;
@property (nonatomic, weak) UIButton *biggerButton;

@end

@implementation DQBasementButton

- (id)initWithStyle:(DQBasementButtonStyle)style
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 48.0f)];
    if (!self) {
        return nil;
    }

    _internalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _internalButton.frame = CGRectMake(0.0f, 15.0f, 22.0f, 19.0f);
    [_internalButton setImage:[UIImage imageNamed:@"button_topNav_menu"] forState:UIControlStateNormal];
    [self addSubview:_internalButton];
    
    _badgeView = [[DQBadgeView alloc] init];
    _badgeView.hidden = YES;
    _badgeView.center = CGPointMake(CGRectGetMaxX(_internalButton.frame) + 15, CGRectGetMinY(_internalButton.frame));
    [self addSubview:_badgeView];

    UIButton *biggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:biggerButton];
    self.biggerButton = biggerButton;

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.biggerButton.frame = self.bounds;
}

- (void)setBadgeCount:(NSUInteger)badgeCount
{
    _badgeCount = badgeCount;
    
    self.badgeView.badgeCount = badgeCount;
    self.badgeView.hidden = _badgeCount == 0;
}

#pragma mark - 

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    [self.biggerButton addTarget:target action:action forControlEvents:controlEvents];
}

@end

@implementation DQBadgeView

- (id)init
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 42.0f, 28.0f)];
    if (!self) {
        return nil;
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    _badgeCount = 0;
    _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _countLabel.backgroundColor = [UIColor colorWithRed:(254/255.0) green:(209/255.0) blue:(106/255.0) alpha:1];
    _countLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    _countLabel.textAlignment = NSTextAlignmentCenter;
    _countLabel.textColor = [UIColor whiteColor];
    _countLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)_badgeCount];
    _countLabel.layer.cornerRadius = 12.0f;
    [self addSubview:_countLabel];
    
    return self;
}


#pragma mark - Accessors

- (void)setBadgeCount:(NSUInteger)badgeCount
{
    _badgeCount = badgeCount;
    
    self.countLabel.text =  [NSString stringWithFormat:@"%lu", (unsigned long)_badgeCount];
    self.countLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

#pragma mark - UIView

- (void)layoutSubviews
{
    self.countLabel.frame = CGRectInset(self.bounds, 8.0f, 3.0f);
}

@end
