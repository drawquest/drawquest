//
//  CVSColorPickerViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@class CVSColorPickerViewController;

@protocol CVSColorPickerViewControllerDelegate <NSObject>

- (UIView *)sourceViewForCVSColorPickerViewController:(CVSColorPickerViewController *)vc;
- (NSArray *)colorsForLoggedInAccountForCVSColorPickerViewController:(CVSColorPickerViewController *)vc;

@end

@interface CVSColorPickerViewController : UIViewController

- (id)initWithDelegate:(id<CVSColorPickerViewControllerDelegate>)delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithDelegate:);

@property (nonatomic, readonly, copy) UIColor *selectedColor;
@property (nonatomic, copy) void(^dismissalBlock)(CVSColorPickerViewController *vc);
@property (nonatomic, copy) void(^colorSelectedBlock)(CVSColorPickerViewController *vc, UIColor *selectedColor);
@property (nonatomic, copy) void(^shopBlock)(CVSColorPickerViewController *vc);

- (void)updateOwnedColors;

@end
