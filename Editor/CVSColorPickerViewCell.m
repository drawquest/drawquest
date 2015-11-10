//
//  CVSColorPickerViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 9/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSColorPickerViewCell.h"
#import "CVSPhoneColorWell.h"
#import "UIImage+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "UIColor+DQAdditions.h"

@interface CVSColorPickerViewCell ()

@property (nonatomic, strong) CVSPhoneColorWell *colorWell;
@property (nonatomic, strong) UIImageView *checkmark;

@end

@implementation CVSColorPickerViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _colorWell = [[CVSPhoneColorWell alloc] initWithFrame:self.bounds fillColor:nil strokeColor:[UIColor dq_modalTableSeperatorColor] forceOutline:NO];
        [self addSubview:_colorWell];
        
        _checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"color_selected_checkmark"]];
        _checkmark.hidden = YES;
        _checkmark.center = self.boundsCenter;
        [self addSubview:_checkmark];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.colorWell.center = self.boundsCenter;
}

- (void)setColor:(UIColor *)color isSelected:(BOOL)isSelected
{
    [self.colorWell setFillColor:color];
    self.checkmark.hidden = ! isSelected;
}

@end
