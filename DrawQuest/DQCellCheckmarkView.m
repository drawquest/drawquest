//
//  DQCellCheckmarkView.m
//  DrawQuest
//
//  Created by David Mauro on 6/14/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCellCheckmarkView.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

const CGFloat kDQCellCheckmarkViewPadding = 3.0f; // Space between checkmark and label

@interface DQCellCheckmarkView ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIGestureRecognizer *tapGestureRecognizer;

@end

@implementation DQCellCheckmarkView

- (id)initWithLabelText:(NSString *)labelText
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        UIImage *image = [UIImage imageNamed:@"checkMark"];

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _imageView = [[UIImageView alloc] initWithImage:image];

        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor dq_cellCheckmarkFontColor];
        _label.font = [UIFont dq_cellCheckmarkLabelFont];
        _label.text = labelText;
        [_label sizeToFit];
        _label.frameX = image.size.width + kDQCellCheckmarkViewPadding;

        // vertically align subview so to be on integral pixels
        CGFloat largerHeight = MAX(image.size.height, self.label.frameHeight);
        _label.frameY = (int)(largerHeight - self.label.frameHeight)/2;
        _imageView.frameY = (int)(largerHeight - image.size.height)/2;

        [self addSubview:_imageView];
        [self addSubview:_label];
        self.frame = CGRectUnion(_imageView.frame, _label.frame);
    }
    return self;
}

#pragma mark - Tapped

- (void)dqCellCheckmarkTapped:(DQCellCheckmarkView *)checkmarkView
{
    if (self.tappedBlock)
    {
        self.tappedBlock(checkmarkView);
    }
}

- (void)setTappedBlock:(DQCellCheckmarkViewBlock)tappedBlock
{
    if (_tappedBlock)
    {
        [self removeGestureRecognizer:self.tapGestureRecognizer];
        self.tapGestureRecognizer = nil;
    }
    _tappedBlock = [tappedBlock copy];
    if (tappedBlock)
    {
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dqCellCheckmarkTapped:)];
        [self addGestureRecognizer:self.tapGestureRecognizer];
    }
}

@end
