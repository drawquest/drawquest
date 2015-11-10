//
//  DQAlmostThereViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-25.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAlmostThereViewController.h"
#import "DQAbstractAuthViewController+TemplateMethods.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

@interface DQAlmostThereViewController ()

@property (nonatomic, weak) UILabel *keepItClassyLabel;

@end

@implementation DQAlmostThereViewController

- (void)customizeViewWithBottomView:(UIView *)bottomView
{
    UILabel *keepItClassyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    keepItClassyLabel.numberOfLines = 2;
    keepItClassyLabel.backgroundColor = [UIColor clearColor];
    keepItClassyLabel.font = [UIFont dq_signInLabelFont];
    keepItClassyLabel.textColor = [UIColor dq_authTextSwitchQuestionColor];
    keepItClassyLabel.textAlignment = NSTextAlignmentCenter;
    keepItClassyLabel.text = DQLocalizedString(@"I agree to keep my artwork classy\nand appropriate for all ages.", @"Code of conduct agreement label");
    [self.view addSubview:keepItClassyLabel];
    self.keepItClassyLabel = keepItClassyLabel;
}

- (void)viewDidLayoutSubviewsCustomizeLayoutWithBottomView:(UIView *)bottomView
{
    [super viewDidLayoutSubviewsCustomizeLayoutWithBottomView:bottomView];
    self.keepItClassyLabel.frame = (CGRect){.size = CGSizeMake(405.0f, 50.0f)};
    self.keepItClassyLabel.center = CGPointMake(self.view.center.x, CGRectGetMaxY(bottomView.frame) + 48.0f);
}

- (NSString *)textForTopLabel
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        return DQLocalizedString(@"Almost There...", @"Title for sign up modal when the user is nearly finished signing up");
    }
    else
    {
        return DQLocalizedString(@"Join", @"Title for sign up modal");
    }
}

- (NSString *)headerImageName
{
    return nil;
}

- (BOOL)showSocialLoginButtons
{
    return NO;
}

- (BOOL)showSwitchButton
{
    return NO;
}

@end
