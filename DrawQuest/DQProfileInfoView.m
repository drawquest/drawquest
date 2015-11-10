//
//  DQProfileInfoView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQProfileInfoView.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "STUtils.h"

@implementation DQProfileInfoView
{
    CGRect _innerRect;
    CGRect _topRect;
    CGRect _bottomRect;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
        
    self.backgroundColor = [UIColor clearColor];
    
    _topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _topLabel.backgroundColor = [UIColor clearColor];
    _topLabel.textColor = [UIColor whiteColor];
    _topLabel.font = [UIFont dq_profileFollowStatsFont];
    [self addSubview:_topLabel];
    
    _bottomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _bottomLabel.backgroundColor = [UIColor clearColor];
    _bottomLabel.textColor = [UIColor whiteColor];
    _bottomLabel.font = [UIFont dq_profileFollowLabelFont];
    [self addSubview:_bottomLabel];
    
    _accessoryType = DQProfileInfoViewAccessoryTypeNone;
    
    _accessoryImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _accessoryImageView.backgroundColor = [UIColor clearColor];
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _innerRect = CGRectInset(self.bounds, 8.0f, 8.0f);
    CGRectDivide(_innerRect, &_topRect, &_bottomRect, roundf(CGRectGetHeight(_innerRect) / 2), CGRectMinYEdge);
}


- (void)setAccessoryType:(DQProfileInfoViewAccessoryType)accessoryType
{
    _accessoryType = accessoryType;
    
    if (accessoryType == DQProfileInfoViewAccessoryTypeCoin) {
        _accessoryImageView.image = [UIImage imageNamed:@"icon_coin"];
        [self addSubview:_accessoryImageView];
    } else {
        [_accessoryImageView removeFromSuperview];
    }
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect
{
    CGRect bounds = self.bounds;
    UIBezierPath *backgroundPath  = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:20.0f];
    
    // Fill and stroke the outer rect
    [backgroundPath addClip];
    
    [[UIColor whiteColor] set];
    [backgroundPath fill];
    [[UIColor dq_colorWithRed:160.0 green:185.0f blue:41.0f] set];
    backgroundPath.lineWidth = 6.0f;
    [backgroundPath stroke];
    
    UIBezierPath *topPath = [UIBezierPath bezierPathWithRoundedRect:_topRect byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(12.0f, 12.0f)];
    [[UIColor dq_colorWithRed:178.0f green:211.0f blue:42.0f] set];
    [topPath fill];
    
    UIBezierPath *bottomPath = [UIBezierPath bezierPathWithRoundedRect:_bottomRect byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(12.0f, 12.0f)];
    [[UIColor dq_colorWithRed:149.0f green:176.0f blue:36.0f] set];
    [bottomPath fill];

    UIBezierPath *dividerPath = [UIBezierPath bezierPath];
    [dividerPath moveToPoint:_bottomRect.origin];
    [dividerPath addLineToPoint:CGPointMake(CGRectGetMaxX(_bottomRect), CGRectGetMinY(_bottomRect))];
    dividerPath.lineWidth = 8.0f;
    [[UIColor dq_colorWithRed:141.0f green:167.0f blue:34.0f] set];
    [dividerPath stroke];
}

- (void)layoutSubviews
{
    self.topLabel.frame = CGRectInset(_topRect, 10.0f, 0.0f);
    
    CGSize accessorySize = (_accessoryType != DQProfileInfoViewAccessoryTypeNone) ? CGSizeMake(self.accessoryImageView.image.size.width, self.accessoryImageView.image.size.height) : CGSizeZero;
    CGRect accessoryRect;
    CGRect labelRect;
    CGRectDivide(_bottomRect, &accessoryRect, &labelRect, accessorySize.width, CGRectMinXEdge);
    labelRect = CGRectInset(labelRect, 13.0f, 0.0f);
    accessoryRect.origin.x += 10.0f;

    if (self.bottomLabelAlignment == NSTextAlignmentCenter)
    {
        self.bottomLabel.textAlignment = self.bottomLabelAlignment;
        self.bottomLabel.frame = labelRect;
    }
    else
    {
        [self.bottomLabel sizeToFit];
        self.bottomLabel.frameOrigin = CGPointMake(CGRectGetMinX(labelRect), CGRectGetMinY(labelRect));
        self.bottomLabel.frameHeight = CGRectGetHeight(labelRect);
    }
    if (self.bottomUIView)
    {
        CGRect bottomUIViewRect;
        if (self.bottomLabel.hidden)
        {
            bottomUIViewRect = _bottomRect;
        }
        else
        {
            CGRect unused;
            CGRectDivide(_bottomRect, &unused, &bottomUIViewRect, CGRectGetMaxX(self.bottomLabel.frame), CGRectMinXEdge);
        }
        bottomUIViewRect = CGRectInset(bottomUIViewRect, 10.0f, 0.0f);
        self.bottomUIView.frame = bottomUIViewRect;
    }

    self.accessoryImageView.frame = [self centeredSubRectOfSize:accessorySize insideRect:accessoryRect];
}

-(void)setBottomUIView:(UIView *)bottomUIView
{
    if (self.bottomUIView)
    {
        [self.bottomUIView removeFromSuperview];
    }
    _bottomUIView = bottomUIView;
    [self addSubview:bottomUIView];
}

@end
