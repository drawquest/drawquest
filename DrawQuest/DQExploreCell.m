//
//  DQExploreCell.m
//  DrawQuest
//
//  Created by Dirk on 4/15/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQExploreCell.h"

static const CGRect kLargeImageRect = { { 15, 0 }, { 470.0f, 352.0f } };
static const CGRect kSmallImageRect = { { 15, 0 }, { 219.0f, 165.0f } };

@implementation DQExploreCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        DQImageView *imageView = [[DQImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:imageView];
        _imageView = imageView;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.imageView prepareForReuse];
}

- (void)setComment:(DQExploreComment *)comment
{
    _comment = comment;
    if (self.cellSize == DQExploreCellSizeSmall)
    {
        [self.imageView setImageURL:[comment imageURLForKey:DQImageKeyArchive]];
    }
    else
    {
        [self.imageView setImageURL:[comment imageURLForKey:DQImageKeyGallery]];
    }
}

- (void)setCellSize:(DQExploreCellSize)size backgroundColorPatternImage:(UIColor *)backgroundColorPatternImage
{
    _cellSize = size;
    if (size == DQExploreCellSizeSmall)
    {
        [self.imageView setFrame:kSmallImageRect];
    }
    else
    {
        [self.imageView setFrame:kLargeImageRect];
    }
    [self setBackgroundColor:backgroundColorPatternImage];
}

- (void)setCellSize:(DQExploreCellSize)size
{
    _cellSize = size;
    if (size == DQExploreCellSizeSmall)
    {
        [self.imageView setFrame:kSmallImageRect];
    }
    else
    {
        [self.imageView setFrame:kLargeImageRect];
    }
    
    self.imageView.layer.borderWidth = 1;
    self.imageView.layer.borderColor = [UIColor colorWithRed:(233/255.0) green:(233/255.0) blue:(233/255.0) alpha:1].CGColor;
}


@end
