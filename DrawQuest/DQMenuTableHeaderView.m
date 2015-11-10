//
//  DQMenuTableHeaderView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQMenuTableHeaderView.h"

#import "UIFont+DQAdditions.h"

@implementation DQMenuTableHeaderView
{
    CGGradientRef _gradient;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _titleY = 0;
    
    self.backgroundColor = [UIColor colorWithRed:(254/255.0) green:(209/255.0) blue:(106/255.0) alpha:1];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:25];
    _titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:_titleLabel];
    
    return self;
}


#pragma mark - UIView


- (void)layoutSubviews
{
    CGRect titleFrame = CGRectMake(64.0f, _titleY, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    _titleLabel.frame = titleFrame;
    
}

@end
