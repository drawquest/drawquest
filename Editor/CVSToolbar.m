//
//  CVSToolbar.m
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSToolbar.h"

// Views
#import "CVSPadToolbar.h"
#import "CVSPhoneToolbar.h"
#import "CVSPhoneColorWell.h"
#import "CVSBrushView.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface CVSToolbar ()

@property (nonatomic, weak) CVSPhoneColorWell *colorPreview;

@end

@implementation CVSToolbar

- (id)initWithSelectedColor:(UIColor *)color brushPicker:(CVSBrushPickerViewController *)brushPicker
{
    if ([self class] == [CVSToolbar class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[CVSPadToolbar alloc] initWithSelectedColor:color brushPicker:brushPicker];
        }
        else
        {
            self = [[CVSPhoneToolbar alloc] initWithSelectedColor:color brushPicker:brushPicker];
        }
    }
    else
    {
        self = [super initWithFrame:CGRectZero];
        if (self)
        {
            _enabled = YES;
            _brushIsActive = YES;

            self.layer.shadowColor = [[UIColor blackColor] CGColor];
            self.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
            self.layer.shadowOpacity = 0.05f;
            self.layer.shadowRadius = 0.0f;

            self.backgroundColor = [UIColor dq_editorToolbarDividerColor];

            CVSBrushView *eraserPreview = [[CVSBrushView alloc] initWithBrushType:CVSBrushTypeEraser activeColor:color hasSmile:YES];
            _eraserButton = [[CVSToolbarButton alloc] init];
            _eraserButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
            _eraserButton.translatesAutoresizingMaskIntoConstraints = NO;
            _eraserButton.customView = eraserPreview;
            [_eraserButton addTarget:self action:@selector(eraserButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_eraserButton];

            CVSPhoneColorWell *colorPreview = [[CVSPhoneColorWell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 31.0f, 31.0f) fillColor:color strokeColor:[UIColor colorWithRed: 0.229 green: 0.229 blue: 0.229 alpha: 1] forceOutline:YES];
            _colorPreview = colorPreview;
            _colorButton = [[CVSToolbarButton alloc] init];
            _colorButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
            _colorButton.translatesAutoresizingMaskIntoConstraints = NO;
            _colorButton.customView = colorPreview;
            [_colorButton addTarget:self action:@selector(colorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_colorButton];

            _undoButton = [[UIButton alloc] init];
            _undoButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
            _undoButton.translatesAutoresizingMaskIntoConstraints = NO;
            UIImage *undoImage = [[UIImage imageNamed:@"button_bottom_undo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_undoButton setImage:undoImage forState:UIControlStateNormal];
            [_undoButton addTarget:self action:@selector(undoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_undoButton];

            _redoButton = [[UIButton alloc] init];
            _redoButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
            _redoButton.translatesAutoresizingMaskIntoConstraints = NO;
            UIImage *redoImage = [[UIImage imageNamed:@"button_bottom_redo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_redoButton setImage:redoImage forState:UIControlStateNormal];
            [_redoButton addTarget:self action:@selector(redoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_redoButton];

            _hideButton = [[UIButton alloc] init];
            _hideButton.backgroundColor = [UIColor dq_editorToolbarBackgroundColor];
            _hideButton.translatesAutoresizingMaskIntoConstraints = NO;
            UIImage *hideImage = [[UIImage imageNamed:@"button_bottom_nav_hide"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_hideButton setImage:hideImage forState:UIControlStateNormal];
            [_hideButton addTarget:self action:@selector(hideButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_hideButton];

            // Let subviews do the layout
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat padding = (self.brushPicker.view.frameWidth - [self.brushPicker widthOfBrushes])/([self.brushPicker numberOfBrushes]) - 1.0f; // minus 1 is just to be safe since this is a min
    self.brushPicker.flowLayout.sectionInset = UIEdgeInsetsMake(0.0f, padding/2.0f, 0.0f, padding/2.0f);
    self.brushPicker.flowLayout.minimumInteritemSpacing = padding;
}

#pragma mark - Public

- (void)setBrushIsActive:(BOOL)brushIsActive
{
    _brushIsActive = brushIsActive;
    [self.eraserButton setCustomViewCanOverlap: ! brushIsActive animated:YES];
}

- (void)setBrushIsActiveWithNoBrushAnimation:(BOOL)brushIsActive
{
    _brushIsActive = brushIsActive;
    [self.eraserButton setCustomViewCanOverlap: ! brushIsActive animated:YES];
}

- (void)setSelectedColor:(UIColor *)color
{
    [self.colorPreview setFillColor:color];
}

- (void)setSelectedBrushType:(CVSBrushType)brushType
{
    // Only used by phone
}

- (void)setEnabled:(BOOL)enabled withDuration:(CGFloat)duration
{
    _enabled = enabled;
}

- (void)setStowed:(BOOL)stowed withDuration:(CGFloat)duration distance:(CGFloat)distance
{
    _stowed = stowed;
}

- (void)enableUndo:(BOOL)enabled
{
    self.undoButton.enabled = enabled;
}

- (void)enableRedo:(BOOL)enabled
{
    self.redoButton.enabled = enabled;
}

- (CGPoint)hideButtonCenter
{
    return self.hideButton.center;
}

#pragma mark - Actions

- (void)eraserButtonTapped:(id)sender
{
    if (self.eraserButtonTappedBlock)
    {
        self.eraserButtonTappedBlock(sender);
    }
}

- (void)colorButtonTapped:(id)sender
{
    if (self.colorButtonTappedBlock)
    {
        self.colorButtonTappedBlock(sender);
    }
}

- (void)undoButtonTapped:(id)sender
{
    if (self.undoButtonTappedBlock)
    {
        self.undoButtonTappedBlock(sender);
    }
}

- (void)redoButtonTapped:(id)sender
{
    if (self.redoButtonTappedBlock)
    {
        self.redoButtonTappedBlock(sender);
    }
}

- (void)hideButtonTapped:(id)sender
{
    if (self.hideButtonTappedBlock)
    {
        self.hideButtonTappedBlock(sender);
    }
}

- (void)dimmerViewTapped:(id)sender
{
    if (self.disabledToolbarTappedBlock)
    {
        self.disabledToolbarTappedBlock(self);
    }
}

@end
