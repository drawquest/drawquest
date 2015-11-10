//
//  DQTableView.m
//  DrawQuest
//
//  Created by David Mauro on 9/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTableView.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQTableView ()

@property (nonatomic, weak) UIView *tableHeaderWrapperView;
@property (nonatomic, weak) UIView *headerView;
@property (nonatomic, weak) UIView *errorView;
@property (nonatomic, strong) NSLayoutConstraint *errorViewTopConstraint;

@end

@implementation DQTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self)
    {
        self.alwaysBounceVertical = YES;
        
        UIView *tableHeaderWrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        tableHeaderWrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tableHeaderWrapperView = tableHeaderWrapperView;
        self.tableHeaderView = tableHeaderWrapperView;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundView = nil;
        self.backgroundColor = [UIColor clearColor];
        self.separatorColor = [UIColor dq_phoneTableSeperatorColor];
    }
    return self;
}

- (void)setHeaderView:(UIView *)headerView
{
    if (self.headerView)
    {
        [self.headerView removeFromSuperview];
    }
    if (headerView)
    {
        [self.tableHeaderWrapperView addSubview:headerView];
        headerView.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.tableHeaderWrapperView addConstraint:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:headerView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
        [self.tableHeaderWrapperView addConstraint:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.superview attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:headerView.superview attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f];
        constraint.priority -= 1;
        [self.tableHeaderWrapperView addConstraint:constraint];
    }
    self.tableHeaderWrapperView.frameHeight = headerView.frameHeight + self.errorView.frameHeight;
    self.tableHeaderView = self.tableHeaderWrapperView;

    _headerView = headerView;
}

- (void)setErrorView:(UIView *)errorView
{
    if (self.errorView)
    {
        [self.errorView removeFromSuperview];
    }
    if (errorView)
    {
        [self.tableHeaderWrapperView addSubview:errorView];
        errorView.translatesAutoresizingMaskIntoConstraints = NO;

        self.errorViewTopConstraint = [NSLayoutConstraint constraintWithItem:errorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:errorView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        [self.tableHeaderWrapperView addConstraint:self.errorViewTopConstraint];

        [self.tableHeaderWrapperView addConstraint:[NSLayoutConstraint constraintWithItem:errorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:errorView.superview attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:errorView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:errorView.superview attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f];
        constraint.priority -= 1;
        [self.tableHeaderWrapperView addConstraint:constraint];
    }
    self.tableHeaderWrapperView.frameHeight = self.headerView.frameHeight + errorView.frameHeight;
    self.tableHeaderView = self.tableHeaderWrapperView;

    _errorView = errorView;
}

- (void)updateConstraints
{
    if (self.errorViewTopConstraint)
    {
        // Put the Error View vertically centered but mostly tending towards the top
        CGFloat padding = (self.frameHeight - self.headerView.frameHeight - self.errorView.frameHeight)/6;
        self.errorViewTopConstraint.constant = self.headerView.frameHeight + padding;
    }

    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateConstraints];

    if (self.errorView)
    {
        self.tableHeaderView.frameHeight = self.errorView.frameMaxY;
    }
    else
    {
        self.tableHeaderView.frameHeight = self.headerView.frameHeight;
    }
}

@end
