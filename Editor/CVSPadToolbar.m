//
//  CVSPadToolbar.m
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPadToolbar.h"

#import "CVSBrushPickerViewController.h"

#import "DQButton.h"

#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface CVSPadToolbar ()

@property (nonatomic, strong) DQButton *trashButton;
@property (nonatomic, strong) NSLayoutConstraint *brushPickerWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *eraserWidthConstraint;

@end

@implementation CVSPadToolbar

- (id)initWithSelectedColor:(UIColor *)color brushPicker:(CVSBrushPickerViewController *)brushPicker
{
    self = [super initWithSelectedColor:color brushPicker:brushPicker];
    if (self)
    {
        self.brushPicker = brushPicker;

        _trashButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_trashCan"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _trashButton.translatesAutoresizingMaskIntoConstraints = NO;
        _trashButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
        __weak typeof(self) weakSelf = self;
        _trashButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.trashButtonTappedBlock)
            {
                weakSelf.trashButtonTappedBlock(button);
            }
        };
        [self addSubview:_trashButton];

        // The brush picker will be part of the toolbar
        UIView *brushPickerView = brushPicker.view;
        brushPickerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:brushPickerView];

        // Toolbar Layout
        NSDictionary *variableBindings = @{@"_brushPicker": brushPickerView, @"_eraserButton": self.eraserButton, @"_colorButton": self.colorButton, @"_trashButton": _trashButton, @"_undoButton": self.undoButton, @"_redoButton": self.redoButton, @"_hideButton": self.hideButton};
        NSDictionary *metrics = @{};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_brushPicker(>=60)]-1-[_colorButton(115)]-1-[_trashButton(==_colorButton)]-1-[_undoButton(==_colorButton)]-1-[_redoButton(==_colorButton)]-1-[_hideButton(==_colorButton)]|" options:0 metrics:metrics views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_brushPicker]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_eraserButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_colorButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_trashButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_undoButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_redoButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_hideButton]|" options:0 metrics:nil views:variableBindings]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:brushPickerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:-14.0f]];
    }
    return self;
}

- (void)setStowed:(BOOL)stowed withDuration:(CGFloat)duration distance:(CGFloat)distance
{
    [super setStowed:stowed withDuration:duration distance:distance];

    if ( ! self.brushIsActive)
    {
        [self.eraserButton setCustomViewCanOverlap:( ! stowed && self.enabled) animated:YES];
    }

    [self.brushPicker setStowed:stowed];

    CGFloat bottomConstant = 0.0f;
    if (stowed)
    {
        bottomConstant = distance;
    }
    self.bottomConstraint.constant = bottomConstant;
    [self.superview setNeedsUpdateConstraints];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.superview layoutIfNeeded];
    }];
}

@end
