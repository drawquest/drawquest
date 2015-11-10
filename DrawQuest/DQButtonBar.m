//
//  DQButtonBar.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/12/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQButtonBar.h"

const CGFloat kDQButtonBarButtonSize = 50.0f;
const CGFloat kDQButtonBarButtonSpacing = 4.0f;
static const NSTimeInterval kDQButtonBarShowHideAnimationDuration = 0.2f;

@interface DQButtonBar()

@property (nonatomic, strong) NSArray *activeButtonGroup;
@property (nonatomic, assign) NSUInteger activeIndex;

@end

@implementation DQButtonBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _disclosingButtonGroup = NO;
    _disclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _disclosureButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
    [_disclosureButton setImage:[UIImage imageNamed:@"button_icon_close"] forState:UIControlStateNormal];
    [_disclosureButton addTarget:self action:@selector(hideActiveButtonGroup) forControlEvents:UIControlEventTouchUpInside];
    _disclosureButton.layer.cornerRadius = 25;
    _disclosureButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _disclosureButton.layer.borderWidth = 2;
    _disclosureButton.backgroundColor = [UIColor colorWithRed:(96 / 255.0) green:(227 / 255.0) blue:(182 / 255.0) alpha:1];
    
    return self;
}


#pragma mark - Accessors

- (void)setButtons:(NSArray *)buttons
{
    if([_buttons isEqualToArray:buttons]) {
        return;
    }
    
    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _buttons = buttons;

    [self layoutButtons];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutButtons];
}

#pragma mark - Button Group Management

- (void)discloseButtonGroupAtIndex:(NSUInteger)index
{
    if (!self.delegate) {
        return;
    }
    
    BOOL shouldDisclose = [self.delegate buttonBar:self shouldDiscloseButtonGroupAtIndex:index];
    if (!shouldDisclose) {
        return;
    }
    
    UIButton *disclosingButton = [self.buttons objectAtIndex:index];
    NSArray *buttonGroup = [self.delegate buttonBar:self buttonGroupAtIndex:index];
    
    // Hide the buttons under the disclosing button so they appaear to come from under it
    [buttonGroup enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        UIControl *button = (UIControl *)object;
        button.hidden = YES;
        button.center = disclosingButton.center;
        [self addSubview:button];
    }];
    
    // Disable all buttons but the disclosing button
    [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        UIControl *button = (UIControl *)object;
        if (![button isEqual:disclosingButton]) {
            button.enabled = NO;
        }
    }];
    
    [UIView animateWithDuration:kDQButtonBarShowHideAnimationDuration animations:^{
        NSArray *displacedButtons = [self.buttons subarrayWithRange:NSMakeRange(0, index + 1)];
        
        // Get the total width of the buttons to be added
        __block CGFloat incomingButtonsWidth = 0.0f;
        [buttonGroup enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            UIControl *button = (UIControl *)object;
            incomingButtonsWidth += CGRectGetWidth(button.frame) + kDQButtonBarButtonSpacing;
        }];
        
        // Move the buttons to be displaced out of the way
        [displacedButtons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            UIControl *button = (UIControl *)object;
            CGFloat deltaX = incomingButtonsWidth;
            button.transform = CGAffineTransformMakeTranslation(-deltaX, 0.0f);
        }];
        
        // Animate in the new buttons
        __block CGFloat cursor = CGRectGetMinX(disclosingButton.frame);
        [buttonGroup enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            UIControl *button = (UIControl *)object;
            CGFloat padding = (idx) ? kDQButtonBarButtonSpacing : 0.0f;
            button.center = CGPointMake(cursor + padding + roundf(CGRectGetWidth(button.frame) / 2), CGRectGetMidY(self.bounds));
            button.hidden = NO;
            cursor = CGRectGetMaxX(button.frame);
        }];
        
        self.disclosureButton.hidden = NO;
        self.disclosureButton.center = CGPointMake(cursor + kDQButtonBarButtonSpacing + roundf(CGRectGetWidth(self.disclosureButton.frame) / 2), CGRectGetMidY(self.bounds));
        

    } completion:^(BOOL finished) {
        disclosingButton.hidden = YES;
        [self addSubview:self.disclosureButton];
    }];
    
    
    self.disclosingButtonGroup = YES;
    self.activeButtonGroup = buttonGroup;
    self.activeIndex = index;
}

- (void)hideActiveButtonGroup
{
    if (!self.activeButtonGroup) {
        return;
    }
    
    UIControl *disclosingButton = [self.buttons objectAtIndex:self.activeIndex];
    NSArray *displacedButtons = [self.buttons subarrayWithRange:NSMakeRange(0, self.activeIndex + 1)];
    
    // Re-enable disabled buttons
    [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        UIControl *button = (UIControl *)object;
        if (![button isEqual:disclosingButton]) {
            button.enabled = YES;
        }
    }];
    
    [UIView animateWithDuration:kDQButtonBarShowHideAnimationDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.activeButtonGroup enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            UIControl *button = (UIControl *)object;
            [self sendSubviewToBack:button];
            button.center = disclosingButton.center;
        }];
        
        disclosingButton.hidden = NO;
        self.disclosureButton.hidden = YES;
        [self.disclosureButton removeFromSuperview];
        
        [displacedButtons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            UIControl *button = (UIControl *)object;
            button.transform = CGAffineTransformConcat(button.transform, CGAffineTransformInvert(button.transform));
        }];

    } completion:^(BOOL finished) {
        [self.activeButtonGroup makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.activeButtonGroup = nil;
        self.disclosingButtonGroup = NO;
        
        [self.delegate buttonBarDidClose];
    }];
}

#pragma mark -

- (void)layoutButtons
{
    [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Right-justify the buttons
    __block CGFloat totalWidth = 0.0f;
    [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        UIButton *button = (UIButton *)object;
        totalWidth += CGRectGetWidth(button.frame);
    }];
    
    totalWidth += ([self.buttons count] - 1) * kDQButtonBarButtonSpacing;

    CGRect buttonRect = CGRectMake(CGRectGetMaxX(self.bounds) -  totalWidth, 0.0f, totalWidth, CGRectGetHeight(self.bounds));
    __block CGFloat cursor = CGRectGetMinX(buttonRect);
    [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        UIControl *button = (UIControl *)object;
        CGFloat padding = (idx) ? kDQButtonBarButtonSpacing : 0.0f;
        button.center = CGPointMake(cursor + padding + roundf(CGRectGetWidth(button.frame) / 2), CGRectGetMidY(buttonRect));
        [self addSubview:button];
        cursor = CGRectGetMaxX(button.frame);
    }];
}

@end
