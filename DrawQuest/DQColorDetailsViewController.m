//
//  DQColorDetailsViewController.m
//  DrawQuest
//
//  Created by David Mauro on 7/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQColorDetailsViewController.h"
#import "DQCellCheckmarkView.h"
#import "DQButton.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIButton+DQAdditions.h"
#import "UIImage+DQAdditions.h"
#import "UIView+STAdditions.h"

static const CGFloat kDQColorPopoverViewWidth = 185.0f;
static const CGFloat kDQColorPopoverViewHeight = 85.0f;
static const CGFloat kDQColorPopoverViewInset = 0.0f;

@interface DQColorDetailsViewController ()

@property (nonatomic, weak) UILabel *colorNameLabel;
@property (nonatomic, weak) DQButton *purchaseButton;
@property (nonatomic, weak) UILabel *purchasedView;
@property (nonatomic, weak) UIImageView *colorImageView;

@property (nonatomic, assign) BOOL isPurchased;

@end

@implementation DQColorDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.view.frame = CGRectMake(0.0f, 0.0f, kDQColorPopoverViewWidth, kDQColorPopoverViewHeight);
    self.view.backgroundColor = [UIColor clearColor];
    
    UILabel *colorNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    colorNameLabel.numberOfLines = 1;
    colorNameLabel.font = [UIFont dq_modalTableCellDetailFont];
    colorNameLabel.textColor = [UIColor dq_modalPrimaryTextColor];
    colorNameLabel.textAlignment = NSTextAlignmentCenter;
    colorNameLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:colorNameLabel];
    self.colorNameLabel = colorNameLabel;
    
    DQButton *purchaseButton = [DQButton dq_buttonForCellAction];
    [purchaseButton setImage:[UIImage imageNamed:@"icon_coin"] forState:UIControlStateNormal];
    [purchaseButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 7.0f)];
    [purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [purchaseButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [purchaseButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0, 0.0f)];
    purchaseButton.titleLabel.font = [UIFont dq_coinsButtonFont];
    purchaseButton.frameWidth = CGRectGetWidth(purchaseButton.frame) + 10.0f;
    __weak typeof(self) weakSelf = self;
    purchaseButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.purchaseButtonTappedBlock)
        {
            weakSelf.purchaseButtonTappedBlock(button);
        }
    };
    [self.view addSubview:purchaseButton];
    self.purchaseButton = purchaseButton;
    
    UILabel *purchasedView = [[UILabel alloc] initWithFrame:CGRectZero];
    [purchasedView setText:DQLocalizedString(@"Purchased", @"Shop item has been purchased indicator label")];
    purchasedView.backgroundColor = [UIColor clearColor];
    purchasedView.textColor = [UIColor dq_cellCheckmarkFontColor];
    purchasedView.font = [UIFont dq_cellCheckmarkLabelFont];
    [self.view addSubview:purchasedView];
    self.purchasedView = purchasedView;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.purchasedView sizeToFit];
    [self.colorNameLabel setText:self.colorName];
    CGSize labelSize = [self.colorName sizeWithAttributes:@{NSFontAttributeName: [UIFont dq_modalTableCellDetailFont]}];
    
    CGRect bounds = CGRectInset(self.view.bounds, kDQColorPopoverViewInset, kDQColorPopoverViewInset);
    CGRect labelRect;
    CGRect contentRect;
    CGRectDivide(bounds, &labelRect, &contentRect, labelSize.height, CGRectMinYEdge);
    self.colorNameLabel.frame = labelRect;
    
    CGRectDivide(contentRect, &labelRect, &contentRect, 10.0f, CGRectMinYEdge);
    
    CGFloat colorWidth = CGRectGetWidth(self.colorImageView.frame);
    CGFloat purchaseWidth = (self.isPurchased) ? CGRectGetWidth(self.purchasedView.frame) : CGRectGetWidth(self.purchaseButton.frame);
    CGFloat contentWidth = colorWidth + 15.0f + purchaseWidth;
    CGFloat contentPadding = (CGRectGetWidth(contentRect) - contentWidth)/2;
    contentRect = CGRectInset(contentRect, contentPadding, 0.0f);
    
    CGRect colorRect;
    CGRect purchaseRect;
    CGRectDivide(contentRect, &colorRect, &contentRect, colorWidth, CGRectMinXEdge);
    CGRectDivide(contentRect, &purchaseRect, &contentRect, purchaseWidth, CGRectMaxXEdge);
    
    // Ensure the color image view is aligned to the pixel grid
    self.colorImageView.center = CGPointMake((int)CGRectGetMidX(colorRect), (int)CGRectGetMidY(colorRect));
    
    CGPoint purchaseCenter = CGPointMake(CGRectGetMidX(purchaseRect), CGRectGetMidY(purchaseRect));
    self.purchaseButton.center = purchaseCenter;
    self.purchasedView.center = purchaseCenter;
    
    [self.purchaseButton setTitle:[NSString stringWithFormat:@"%@", self.cost] forState:UIControlStateNormal];
    
    self.purchaseButton.hidden = self.isPurchased;
    self.purchasedView.hidden = ! self.isPurchased;
}

#pragma mark - Accessors

- (void)setColor:(UIColor *)color isPurchased:(BOOL)isPurchased
{
    self.isPurchased = isPurchased;
    if (self.colorImageView)
    {
        [self.colorImageView removeFromSuperview];
    }
    UIImageView *colorImageView = [[UIImageView alloc] initWithImage:[UIImage shopColorWithColor:color isPurchased:isPurchased]];
    [self.view addSubview:colorImageView];
    self.colorImageView = colorImageView;
}

@end
