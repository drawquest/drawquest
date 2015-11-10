//
//  DQTitleView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/22/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQTitleView.h"

#import "UIFont+DQAdditions.h"

static CGFloat kDQTitleViewNavigationBarOffset = 39.0f;
static const CGFloat kDQTitleViewToolbarOffset = 22.0f;

@interface DQTitleView ()

@property (strong, nonatomic) UILabel *label;
@property (nonatomic, assign) DQTitleViewStyle style;

@end

@implementation DQTitleView

- (id)initWithStyle:(DQTitleViewStyle)style
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 500.0f, 81.0f)];
    if (!self) {
        return nil;
    }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if (DQSystemVersionAtLeast(@"7.0"))
        kDQTitleViewNavigationBarOffset = 0.0f;
#endif

    self.backgroundColor = [UIColor clearColor];
    
    _style = style;
    
    _label = [[UILabel alloc] initWithFrame:CGRectZero];
    _label.backgroundColor = [UIColor clearColor];
    _label.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:25];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.textColor = [UIColor whiteColor];
    
    
    [self addSubview:_label];
    
    return self;
}


#pragma mark - Accessors

- (void)setText:(NSString *)text
{
    self.label.text = text;
}

- (CGFloat)offsetForStyle:(DQTitleViewStyle)style
{
    CGFloat offset = 0.0;
    if (style == DQTitleViewStyleNavigationBar) {
        offset = kDQTitleViewNavigationBarOffset;
    } else if (style == DQTitleViewStyleToolbar) {
        offset = kDQTitleViewToolbarOffset;
    }
    
    return offset;
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    self.label.frame = CGRectMake(bounds.origin.x, (self.style == DQTitleViewStyleNavigationBar)?25:22, bounds.size.width, self.label.font.pointSize+5.0f);
}

@end
