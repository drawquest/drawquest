//
//  DQCollectionViewGridCell.m
//  DrawQuest
//
//  Created by David Mauro on 9/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCommentGridCollectionViewCell.h"
#import "UIColor+DQAdditions.h"

@implementation DQCommentGridCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapGestureRecognizer];

        _imageView = [[DQImageView alloc] initWithFrame:self.bounds];
        _imageView.layer.borderColor = [[UIColor dq_drawingThumbStrokeColor] CGColor];
        _imageView.layer.borderWidth = 0.5f;
        [self addSubview:_imageView];
    }
    return self;
}

- (void)prepareForReuse
{
    self.cellTappedBlock = nil;
    [self.imageView prepareForReuse];
    self.imageView.frame = self.bounds;
    [super prepareForReuse];
}

#pragma mark - Actions

- (void)cellTapped:(id)sender
{
    if (self.cellTappedBlock)
    {
        self.cellTappedBlock();
    }
}

@end
