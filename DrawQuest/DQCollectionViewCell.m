//
//  DQCollectionViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 11/6/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCollectionViewCell.h"

#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

static const CGFloat kDQCollectionViewCellDividerInset = 15.0f;

@interface DQCollectionViewCell ()

@property (nonatomic, strong) UIView *divider;

@end

@implementation DQCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self.contentView addGestureRecognizer:tgr];

        _divider = [[UIView alloc] initWithFrame:CGRectZero];
        _divider.hidden = YES;
        _divider.backgroundColor = [UIColor dq_phoneTableSeperatorColor];
        [self.contentView addSubview:_divider];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.divider.frameWidth = self.contentView.frameWidth - kDQCollectionViewCellDividerInset;
    self.divider.frameHeight = 0.5f;
    self.divider.frameX = kDQCollectionViewCellDividerInset;
    self.divider.frameMaxY = self.contentView.frameHeight;
}

- (void)cellTapped:(id)sender
{
    if (self.cellTappedBlock)
    {
        self.cellTappedBlock(self);
    }
}

- (BOOL)hasDivider
{
    return self.divider.hidden;
}

- (void)setHasDivider:(BOOL)hasDivider
{
    self.divider.hidden = ! hasDivider;
}

@end
