//
//  CVSToolbar.h
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVSDrawingTypes.h"
#import "CVSToolbarButton.h"
#import "CVSBrushPickerViewController.h"

static const CGFloat kCVSPadToolbarHeight = 67.0f;
static const CGFloat kCVSPhoneToolbarHeight = 50.0f;
static const CGFloat kCVSPhoneToolbarDisabledBottomConstant = 20.0f;

@interface CVSToolbar : UIView

@property (nonatomic, strong) UIView *brushView;
@property (nonatomic, strong, readonly) CVSToolbarButton *eraserButton;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) CVSToolbarButton *colorButton;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *redoButton;
@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, weak) CVSBrushPickerViewController *brushPicker;

@property (nonatomic, assign, getter = isEnabled) BOOL enabled;
@property (nonatomic, assign, getter = isStowed) BOOL stowed;
@property (nonatomic, assign) BOOL brushIsActive;

@property (nonatomic, copy) void(^brushButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^eraserButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^colorButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^undoButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^redoButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^hideButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^trashButtonTappedBlock)(UIButton *button);
@property (nonatomic, copy) void(^disabledToolbarTappedBlock)(CVSToolbar *toolbar);

- (id)initWithSelectedColor:(UIColor *)color brushPicker:(CVSBrushPickerViewController *)brushPicker;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithSelectedColor:brushPicker:);

- (void)setSelectedColor:(UIColor *)color;
- (void)setSelectedBrushType:(CVSBrushType)brushType;
- (void)setStowed:(BOOL)stowed withDuration:(CGFloat)duration distance:(CGFloat)distance;
- (void)setEnabled:(BOOL)enabled withDuration:(CGFloat)duration;
- (void)setBrushIsActiveWithNoBrushAnimation:(BOOL)brushIsActive;

- (void)enableUndo:(BOOL)enabled;
- (void)enableRedo:(BOOL)enabled;

- (CGPoint)hideButtonCenter;

@end
