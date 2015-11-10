//
//  DQGridViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQGridViewCell.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

@implementation DQGridViewCell

- (id)initWithReuseIdentifier:(NSString *)identifier
{
    self = [super initWithReuseIdentifier:identifier];
    if (!self) {
        return nil;
    }
    
    self.preferredContentSize = CGSizeMake(190.0f, 180.0f);
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13];
    _titleLabel.textColor = [UIColor dq_homeQuestTitleTextColor];
    _titleLabel.numberOfLines = 2;
    [self addSubview:_titleLabel];
    
    _timestampLabel = [[DQTimestampView alloc] initWithFrame:CGRectZero];
    _timestampLabel.label.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:12];
    _timestampLabel.tintColor = [UIColor dq_homeTimestampTextColor];
    [self addSubview:_timestampLabel];
    
    _imageView = [[DQImageView alloc] initWithFrame:CGRectZero];
    _imageView.internalImageView.layer.borderWidth = 1;
    _imageView.internalImageView.layer.borderColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0) blue:(220/255.0) alpha:1].CGColor;
    [self addSubview:_imageView];
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.imageView prepareForReuse];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentBounds = CGRectInset(self.bounds, 16.0f, 10.0f);
    
    CGRect imageBox;
    CGRect labelsBox;
    CGRectDivide(contentBounds, &imageBox, &labelsBox, 122.0f, CGRectMinYEdge); // 133.0 should be the image height
    
    self.imageView.frame = imageBox;
    
    CGRect titleRect;
    CGRect timestampRect;
    CGRectDivide(labelsBox, &titleRect, &timestampRect, 14.0f, CGRectMinYEdge);
    self.titleLabel.frame = CGRectOffset(titleRect, 0.0f, 10.0f);
    
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectMake(0, self.titleLabel.frame.origin.y, 172, self.titleLabel.frame.size.height);
    self.titleLabel.center = CGPointMake(self.imageView.center.x, self.titleLabel.center.y);
    
    
    self.timestampLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame) + 3, 50, 14);
    self.timestampLabel.center = CGPointMake(self.titleLabel.center.x + 5, self.timestampLabel.center.y);
}

@end
