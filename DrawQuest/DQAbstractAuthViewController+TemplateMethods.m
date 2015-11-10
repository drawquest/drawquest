//
//  DQAbstractAuthViewController+TemplateMethods.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-30.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractAuthViewController+TemplateMethods.h"

@implementation DQAbstractAuthViewController (TemplateMethods)

- (void)finish
{
}

- (NSUInteger)numberOfFields
{
    return 0;
}

- (void)customizeField:(UITextField *)textField atIndex:(NSUInteger)index
{
}

- (NSString *)placeholderForFieldAtIndex:(NSUInteger)field
{
    return nil;
}

- (NSUInteger)indexOfUsernameField
{
    return NSNotFound;
}

- (NSUInteger)indexOfPasswordField
{
    return NSNotFound;
}

- (NSUInteger)indexOfEmailField
{
    return NSNotFound;
}

- (NSString *)textForTopLabel
{
    return @"";
}

- (NSString *)textForSocialLabel
{
    return @"";
}

- (NSString *)headerImageName
{
    return nil;
}

- (BOOL)showSwitchButton
{
    return YES;
}

- (NSString *)switchQuestionText
{
    return nil;
}

- (NSString *)switchActionText
{
    return nil;
}

- (void)customizeViewWithBottomView:(UIView *)bottomView
{
}

- (void)viewDidLayoutSubviewsCustomizeLayoutWithBottomView:(UIView *)bottomView
{
}

- (BOOL)validateFormAndReportErrors
{
    return NO;
}

@end
