//
//  DQAbstractAuthViewController+TemplateMethods.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-30.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractAuthViewController.h"

@interface DQAbstractAuthViewController (TemplateMethods)

- (void)finish;
- (NSUInteger)numberOfFields;
- (void)customizeField:(UITextField *)textField atIndex:(NSUInteger)index;
- (NSString *)placeholderForFieldAtIndex:(NSUInteger)field;
- (NSUInteger)indexOfUsernameField;
- (NSUInteger)indexOfPasswordField;
- (NSUInteger)indexOfEmailField;
- (NSString *)textForTopLabel;
- (NSString *)textForSocialLabel;
- (NSString *)headerImageName;
- (BOOL)showSwitchButton;
- (NSString *)switchQuestionText;
- (NSString *)switchActionText;
- (void)customizeViewWithBottomView:(UIView *)bottomView;
- (void)viewDidLayoutSubviewsCustomizeLayoutWithBottomView:(UIView *)bottomView;
- (BOOL)validateFormAndReportErrors;

@end
