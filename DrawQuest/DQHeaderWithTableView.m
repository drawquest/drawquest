//
//  DQHeaderWithTableView.m
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQHeaderWithTableView.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQHeaderWithTableView ()

@property (nonatomic, strong) NSLayoutConstraint *tableHeightConstraint;

@end

@implementation DQHeaderWithTableView

- (id)initWithHeaderView:(UIView *)headerView segmentedControl:(BOOL)hasSegmentedControl
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_scrollView];
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.backgroundView = nil;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorColor = [UIColor dq_modalTableSeperatorColor];
        _tableView.scrollEnabled = NO;
        [_scrollView addSubview:_tableView];

        if (headerView)
        {
            _headerView = headerView;
            _headerView.translatesAutoresizingMaskIntoConstraints = NO;
            [_scrollView addSubview:_headerView];

            [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_headerView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f]];
        }

        if (hasSegmentedControl)
        {
            _segmentedControl = [[DQSegmentedControl alloc] initWithFrame:CGRectZero];
            _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
            [_segmentedControl setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
            [_scrollView addSubview:_segmentedControl];
        }

        // Layout
        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_scrollView, _tableView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollView]|" options:0 metrics:nil views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|" options:0 metrics:nil views:viewBindings]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f]];

        if (hasSegmentedControl)
        {
            NSLayoutConstraint *segmentedControlTop = [NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_segmentedControl.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
            segmentedControlTop.priority = UILayoutPriorityDefaultLow;
            [self addConstraint:segmentedControlTop];
            if (_headerView)
            {
                [self addConstraint:[NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_headerView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
            }
            else
            {
                [self addConstraint:[NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_segmentedControl.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
            }
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_segmentedControl attribute:NSLayoutAttributeHeight multiplier:0.0f constant:kDQSegmentedControlDesiredHeight]];

            NSLayoutConstraint *tableViewTop = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_segmentedControl attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
            tableViewTop.priority = UILayoutPriorityDefaultLow;
            [self addConstraint:tableViewTop];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_segmentedControl attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
        }
        else
        {
            NSLayoutConstraint *tableViewTop = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_tableView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
            tableViewTop.priority = UILayoutPriorityDefaultLow;
            [self addConstraint:tableViewTop];
            if (_headerView)
            {
                [self addConstraint:[NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_headerView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
            }
            else
            {
                [self addConstraint:[NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_tableView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
            }
        }

        // Make sure the scroll view's content size meets the bottom of the tableView
        [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutAttributeBottom toItem:_tableView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
    }
    return self;
}

- (void)updateConstraints
{
    [self removeConstraint:self.tableHeightConstraint];
    self.tableHeightConstraint = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_tableView attribute:NSLayoutAttributeHeight multiplier:0.0f constant:_tableView.contentSize.height];
    [self addConstraint:self.tableHeightConstraint];

    [super updateConstraints];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    [self reloadData];
}

#pragma mark -

- (void)reloadData
{
    [self.tableView reloadData];
    [self setNeedsUpdateConstraints];
}

- (void)hideHeaderView:(BOOL)hide
{
    if (hide)
    {
        [self.headerView removeFromSuperview];
    }
    else
    {
        [self.scrollView addSubview:self.headerView];
        [self.scrollView bringSubviewToFront:self.segmentedControl];
    }
}

@end
