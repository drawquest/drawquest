//
//  DQGalleryCell.m
//  DrawQuest
//
//  Created by Dirk on 3/22/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGalleryCell.h"
#import "DQGalleryCellTableHeader.h"
#import "DQFlowLayoutAttributes.h"
#import <UIKit/UIKit.h>

@interface DQGalleryCell ()

@property (nonatomic, assign) BOOL wasJustCreated;

@end

@implementation DQGalleryCell

@dynamic focused;

- (void)dealloc
{
    // prepareForReuse might not be called, so be safe
    if (_dq_notificationHandlerBlock)
    {
        _dq_notificationHandlerBlock(self, nil);
        _dq_notificationHandlerBlock = nil;
    }
    _delegate = nil;
    DQGalleryCellTableHeader *headerView = (DQGalleryCellTableHeader *)_tableView.tableHeaderView;
    [headerView prepareForReuse];
    _tableViewDataSource = nil;
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
    [_tableView reloadData];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.contentInset = UIEdgeInsetsMake(62.0, 0.0, 62.0, 0.0);
        DQGalleryCellTableHeader *commentHeader = [[DQGalleryCellTableHeader alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 560.0f, 550.0f)];
        tableView.tableHeaderView = commentHeader;
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:tableView];
        _tableView = tableView;
        // If we set the headerView to dimmed right now it causes weird bugs.
        // But we need a way to trigger a dataReload in applyLayoutAttributes:
        // without triggering it more often than it needs. :(
        _wasJustCreated = YES;
    }
    return self;
}

- (void)dq_notificationHandler:(NSNotification *)notification
{
    if (self.dq_notificationHandlerBlock)
    {
        self.dq_notificationHandlerBlock(self, notification);
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    if (self.dq_notificationHandlerBlock)
    {
        self.dq_notificationHandlerBlock(self, nil);
        self.dq_notificationHandlerBlock = nil;
    }
    self.delegate = nil;
    DQGalleryCellTableHeader *headerView = (DQGalleryCellTableHeader *)self.tableView.tableHeaderView;
    [headerView prepareForReuse];
    self.tableViewDataSource = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    [self.tableView reloadData];
}

- (void)applyLayoutAttributes:(DQFlowLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];

    DQGalleryCellTableHeader *headerView = (DQGalleryCellTableHeader *)self.tableView.tableHeaderView;

    if (self.tableViewDataSource && (!layoutAttributes.dimmed) && (headerView.dimmed || self.wasJustCreated))
    {
        self.wasJustCreated = NO;
        [headerView setDimmed:NO];
        self.tableView.dataSource = self.tableViewDataSource;
        self.tableView.delegate = self.tableViewDataSource;
        [self.tableView setUserInteractionEnabled:YES];
        [self.tableView reloadData];
        [self.delegate galleryCellDidFocus:self];
    }
    else if (layoutAttributes.dimmed && (!headerView.dimmed))
    {
        [headerView setDimmed:YES];
        self.tableView.dataSource = nil;
        self.tableView.delegate = nil;
        [self.tableView setUserInteractionEnabled:NO];
        [self.tableView reloadData];
    }
}

- (BOOL)isFocused
{
    return self.tableView.userInteractionEnabled;
}

@end
