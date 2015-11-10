//
//  DQButton.m
//  DrawQuest
//
//  Created by David Mauro on 6/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQButton.h"

@interface DQButton ()

@property (nonatomic, weak) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) UIColor *backupTitleColor;
@property (nonatomic, strong) UIColor *backupBackgroundColor;

@end

@implementation DQButton

+ (instancetype)buttonWithImage:(UIImage *)normalImage selectedImage:(UIImage *)selectedImage
{
    DQButton *result = [[self class] buttonWithType:UIButtonTypeCustom];
    result.frame = CGRectMake(0.0f, 0.0f, normalImage.size.width, normalImage.size.height);
    [result setImage:normalImage forState:UIControlStateNormal];
    [result setImage:selectedImage forState:UIControlStateSelected];
    return result;
}

+ (instancetype)buttonWithImage:(UIImage *)image
{
    DQButton *result = [[self class] buttonWithType:UIButtonTypeCustom];
    result.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    [result setImage:image forState:UIControlStateNormal];
    return result;
}

- (void)setTappedBlock:(DQButtonBlock)tappedBlock
{
    if (_tappedBlock)
    {
        [self removeTarget:self action:@selector(dq_buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    _tappedBlock = [tappedBlock copy];
    if (tappedBlock)
    {
        [self addTarget:self action:@selector(dq_buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)dq_buttonTapped:(DQButton *)button
{
    self.tappedBlock(button);
}

- (void)disableWithActivityIndicator
{
    self.enabled = NO;
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = self.frame;
    [spinner startAnimating];
    [self.superview addSubview:spinner];
    self.spinner = spinner;
}

- (void)enableAndRemoveActivityIndicator
{
    self.enabled = YES;
    [self.spinner removeFromSuperview];
    self.spinner = nil;
}

- (void)setTintColorForTitle:(BOOL)tintColorForTitle
{
    if (_tintColorForTitle)
    {
        if (!tintColorForTitle)
        {
            [super setTitleColor:self.backupTitleColor forState:UIControlStateNormal];
            self.backupTitleColor = nil;
        }
    }
    else
    {
        if (tintColorForTitle)
        {
            self.backupTitleColor = [self titleColorForState:UIControlStateNormal];
            [super setTitleColor:self.tintColor forState:UIControlStateNormal];
        }
    }
    _tintColorForTitle = tintColorForTitle;
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
    if (state == UIControlStateNormal)
    {
        if (self.tintColorForTitle)
        {
            self.backupTitleColor = color;
        }
        else
        {
            [super setTitleColor:color forState:state];
        }
    }
    else
    {
        [super setTitleColor:color forState:state];
    }
}

- (void)setTintColorForBackground:(BOOL)tintColorForBackground
{
    if (_tintColorForBackground)
    {
        if (!tintColorForBackground)
        {
            [super setBackgroundColor:self.backupBackgroundColor];
            self.backupTitleColor = nil;
        }
    }
    else
    {
        if (tintColorForBackground)
        {
            self.backupTitleColor = [self titleColorForState:UIControlStateNormal];
            [super setBackgroundColor:self.tintColor];
        }
    }
    _tintColorForBackground = tintColorForBackground;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (self.tintColorForBackground)
    {
        self.backupBackgroundColor = backgroundColor;
    }
    else
    {
        [super setBackgroundColor:backgroundColor];
    }
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    if (self.tintColorForTitle)
    {
        [super setTitleColor:self.tintColor forState:UIControlStateNormal];
    }
    if (self.tintColorForBackground)
    {
        [super setBackgroundColor:self.tintColor];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if (self.selectedBlock)
    {
        self.selectedBlock(self, selected);
    }
}

@end
