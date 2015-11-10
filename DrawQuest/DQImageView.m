//
//  DQImageView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/12/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQImageView.h"
#import "UIColor+DQAdditions.h"
#import "UIImageView+WebCache.h"

static const CGFloat DQImageViewDefaultCornerRadius = 0.0f;


@interface DQImageView()

@property (nonatomic, strong) UIImageView *frameImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) BOOL hasSetImageMask;

@end

@implementation DQImageView

@dynamic image;
@dynamic frameImage;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    _cornerRadius = DQImageViewDefaultCornerRadius;

    _internalImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _internalImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _internalImageView.contentMode = UIViewContentModeScaleAspectFill;
    _internalImageView.clipsToBounds = YES;
    _internalImageView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_internalImageView];
        
    return self;
}

- (void)prepareForReuse
{
    self.internalImageView.image = nil;
    if (self.hasSetImageMask)
    {
        self.hasSetImageMask = NO;
        self.internalImageView.layer.mask = nil;
    }
    self.cornerRadius = 0.0;
    [self.activityIndicatorView removeFromSuperview];
    self.activityIndicatorView = nil;
    [self.accessoryView removeFromSuperview];
    self.accessoryView = nil;
    self.accessoryViewCenterBlock = nil;
}

#pragma mark - Accessors

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (UIImage *)image
{
    return self.internalImageView.image;
}

- (void)setImage:(UIImage *)image
{
    if (self.activityIndicatorView)
    {
        [self.activityIndicatorView removeFromSuperview];
        self.activityIndicatorView = nil;
    }
    self.internalImageView.image = image;
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
    if (!self.internalImageView.image)
    {
        self.internalImageView.image = placeholderImage;
    }
    if (self.activityIndicatorView)
    {
        [self.activityIndicatorView removeFromSuperview];
        self.activityIndicatorView = nil;
    }
    [self updateImageState];
}

- (void)setImageURL:(NSString *)imageURL
{
    if ([imageURL length])
    {
        [self setImageWithURL:imageURL placeholderImage:self.placeholderImage completionBlock:nil failureBlock:nil];
    }
    else
    {
        self.internalImageView.image = self.placeholderImage;
    }
}

- (void)setImageWithURL:(NSString *)imageURL placeholderImage:(UIImage *)placeholder completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    _placeholderImage = placeholder;
    if ((!self.internalImageView.image || self.internalImageView.image == self.placeholderImage) && !self.activityIndicatorView)
    {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.center = self.internalImageView.center;
        self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.internalImageView addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }
    __weak typeof(self) weakSelf = self;
    [self.internalImageView sd_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:placeholder options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (weakSelf.activityIndicatorView)
        {
            [weakSelf.activityIndicatorView removeFromSuperview];
            weakSelf.activityIndicatorView = nil;
        }
        if (image)
        {
            if (completionBlock)
            {
                completionBlock();
            }
        }
        else if (failureBlock)
        {
            failureBlock(error);
        }
    }];
}

- (void)setFrameImage:(UIImage *)frameImage
{
    if (frameImage && !_frameImageView) {
        _frameImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _frameImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _frameImageView.image = frameImage;
        _frameImageView.backgroundColor = [UIColor clearColor];
        [self insertSubview:_frameImageView aboveSubview:self.internalImageView];
    } else {
        [_frameImageView removeFromSuperview];
        _frameImageView = nil;
    }
    [self updateImageState];
}

- (UIImage *)frameImage
{
    return _frameImageView.image;
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    [_accessoryView removeFromSuperview];
    _accessoryView = accessoryView;
    [self addSubview:_accessoryView];
    [self updateImageState];
}

#pragma mark - Image State

- (void)updateImageState
{
    [self bringSubviewToFront:self.accessoryView];
    [self sendSubviewToBack:self.frameImageView];
    [self sendSubviewToBack:self.internalImageView];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = self.bounds;

    if (self.cornerRadius)
    {
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.internalImageView.bounds cornerRadius:self.cornerRadius].CGPath;
        self.internalImageView.layer.mask = maskLayer;
        self.hasSetImageMask = YES;
    }
    else if (self.hasSetImageMask)
    {
        self.hasSetImageMask = NO;
        self.internalImageView.layer.mask = nil;
    }

    if (self.accessoryView && self.accessoryViewCenterBlock)
    {
        self.accessoryView.center = self.accessoryViewCenterBlock(bounds);
    }
}

@end
