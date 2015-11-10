//
//  CVSPhoneToolbar.m
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSPhoneToolbar.h"

// Views
#import "CVSBrushView.h"
#import "CVSToolbarButton.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface CVSPhoneToolbar ()

@property (nonatomic, strong) UIView *dimmerView;
@property (nonatomic, strong) CVSToolbarButton *brushButton;
@property (nonatomic, weak) CVSBrushView *brushPreview;

@end

@implementation CVSPhoneToolbar

- (id)initWithSelectedColor:(UIColor *)color brushPicker:(CVSBrushPickerViewController *)brushPicker
{
    self = [super initWithSelectedColor:color brushPicker:brushPicker];
    if (self)
    {
        self.brushPicker = brushPicker;

        // Set up the brush preview which opens the brush picker
        // Set type to none and we will init the brush type below
        CVSBrushView *brushPreview = [[CVSBrushView alloc] initWithBrushType:CVSBrushTypeNotFound activeColor:color hasSmile:YES];
        _brushButton = [[CVSToolbarButton alloc] init];
        _brushButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];

        _brushButton.translatesAutoresizingMaskIntoConstraints = NO;
        _brushButton.customView = brushPreview;
        _brushButton.customViewCanOverlap = YES;
        [_brushButton addTarget:self action:@selector(brushButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_brushButton];
        self.brushPreview = brushPreview;

        _dimmerView = [[UIView alloc] initWithFrame:CGRectZero];
        _dimmerView.backgroundColor = [UIColor colorWithRed:0.71f green:0.71f blue:0.71f alpha:0.6f];
        _dimmerView.translatesAutoresizingMaskIntoConstraints = NO;
        [_dimmerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimmerViewTapped:)]];
        _dimmerView.alpha = 0.0f;
        _dimmerView.hidden = YES;
        [self addSubview:_dimmerView];

        // Dimmer layout
        NSDictionary *variableBindings = NSDictionaryOfVariableBindings(_dimmerView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_dimmerView]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_dimmerView]|" options:0 metrics:nil views:variableBindings]];

        // Toolbar Layout
        variableBindings = @{@"_brushButton": _brushButton, @"_eraserButton": self.eraserButton, @"_colorButton": self.colorButton, @"_undoButton": self.undoButton, @"_redoButton": self.redoButton, @"_hideButton": self.hideButton};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_brushButton(>=60)]-1-[_eraserButton(==_brushButton)]-1-[_colorButton(>=40,<=80)]-1-[_undoButton(==_colorButton)]-1-[_redoButton(==_colorButton)]-1-[_hideButton(==_colorButton)]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_brushButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_eraserButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_colorButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_undoButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_redoButton]|" options:0 metrics:nil views:variableBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[_hideButton]|" options:0 metrics:nil views:variableBindings]];

        // Do this seperately to trigger the scaling if needed
        [self setSelectedBrushType:brushPicker.selectedBrush];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat maxBrushViewWidth = self.brushButton.frameWidth - 10.0f;
    if ([CVSBrushView maxWidth] > maxBrushViewWidth)
    {
        self.brushPreview.scale = maxBrushViewWidth/[CVSBrushView maxWidth];
    }
    else
    {
        self.brushPreview.scale = 1.0f;
    }
}

#pragma mark - Public

- (void)setBrushIsActive:(BOOL)brushIsActive
{
    [super setBrushIsActive:brushIsActive];

    [self.brushButton setCustomViewCanOverlap:brushIsActive animated:YES];
}

- (void)setBrushIsActiveWithNoBrushAnimation:(BOOL)brushIsActive
{
    [super setBrushIsActiveWithNoBrushAnimation:brushIsActive];

    [self.brushButton setCustomViewCanOverlap:brushIsActive animated:NO];
}

- (void)setSelectedColor:(UIColor *)color
{
    [super setSelectedColor:color];

    [self.brushPreview setActiveColor:color];
}

- (void)setSelectedBrushType:(CVSBrushType)brushType
{
    [super setSelectedBrushType:brushType];

    [self.brushPreview setBrushType:brushType];
    [self setNeedsLayout];
}

- (void)setEnabled:(BOOL)enabled withDuration:(CGFloat)duration
{
    [super setEnabled:enabled withDuration:duration];

    if ( ! enabled)
    {
        self.dimmerView.hidden = NO;
    }

    UIViewTintAdjustmentMode adjustmentMode = enabled ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;

    self.bottomConstraint.constant = enabled ? 0.0f : kCVSPhoneToolbarDisabledBottomConstant;
    [self.superview setNeedsUpdateConstraints];

    CVSToolbarButton *activeButton = self.brushIsActive ? self.brushButton : self.eraserButton;
    [activeButton setCustomViewCanOverlap:enabled animated:YES];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        weakSelf.tintAdjustmentMode = adjustmentMode;
        weakSelf.dimmerView.alpha = enabled ? 0.0f : 1.0f;
        [weakSelf.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (enabled)
        {
            weakSelf.dimmerView.hidden = YES;
        }
    }];
}

- (void)setStowed:(BOOL)stowed withDuration:(CGFloat)duration distance:(CGFloat)distance
{
    [super setStowed:stowed withDuration:duration distance:distance];

    CVSToolbarButton *activeButton = self.brushIsActive ? self.brushButton : self.eraserButton;
    [activeButton setCustomViewCanOverlap:( ! stowed && self.enabled) animated:YES];

    CGFloat bottomConstant = 0.0f;
    if (stowed)
    {
        bottomConstant = distance;
    }
    else if ( ! self.isEnabled)
    {
        bottomConstant = kCVSPhoneToolbarDisabledBottomConstant;
    }
    self.bottomConstraint.constant = bottomConstant;
    [self.superview setNeedsUpdateConstraints];

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.superview layoutIfNeeded];
    }];
}

#pragma mark - Actions

- (void)brushButtonTapped:(id)sender
{
    if (self.brushButtonTappedBlock)
    {
        self.brushButtonTappedBlock(sender);
    }
}

@end
