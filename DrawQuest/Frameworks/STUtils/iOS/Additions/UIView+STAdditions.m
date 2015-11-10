//
//  UIView+STAdditions.m
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "UIView+STAdditions.h"
#import "STUtils.h"


@implementation UIView (STAdditions)

#pragma mark Accessors/Mutators

- (BOOL)isTransparent;
{
    return self.alpha == 0.0f;
}

- (void)setTransparent:(BOOL)transparent;
{
    self.alpha = transparent ? 0.0f : 1.0f;
}

- (CGPoint)frameOrigin
{
    return self.frame.origin;
}

- (void)setFrameOrigin:(CGPoint)frameOrigin
{
    CGRect frame = self.frame;
    frame.origin = frameOrigin;
    self.frame = frame;
}
- (CGFloat)frameX;
{
    return self.frame.origin.x;
}

- (void)setFrameX:(CGFloat)x;
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)frameY;
{
    return self.frame.origin.y;
}

- (void)setFrameY:(CGFloat)y;
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGSize)boundsSize
{
    return self.bounds.size;
}

- (void)setBoundsSize:(CGSize)boundsSize
{
    CGRect bounds = self.bounds;
    if (!CGSizeEqualToSize(bounds.size, boundsSize))
    {
        bounds.size = boundsSize;
        self.bounds = bounds;
    }
}

- (CGFloat)frameWidth;
{
    return self.frame.size.width;
}

- (void)setFrameWidth:(CGFloat)width;
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)frameHeight;
{
    return self.frame.size.height;
}

- (void)setFrameHeight:(CGFloat)height;
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGPoint)boundsCenter
{
    return CGPointMake([self boundsCenterX], [self boundsCenterY]);
}

- (CGFloat)boundsCenterX
{
    return CGRectGetMidX(self.bounds);
}

- (CGFloat)frameCenterX
{
    return CGRectGetMidX(self.frame);
}

- (void)setFrameCenterX:(CGFloat)frameCenterX
{
    CGPoint center = self.center;
    center.x = frameCenterX;
    self.center = center;
}

- (CGFloat)boundsCenterY
{
    return CGRectGetMidY(self.bounds);
}

- (CGFloat)frameCenterY
{
    return CGRectGetMidY(self.frame);
}

- (void)setFrameCenterY:(CGFloat)frameCenterY
{
    CGPoint center = self.center;
    center.y = frameCenterY;
    self.center = center;
}

- (CGFloat)frameMaxX
{
    return CGRectGetMaxX(self.frame);
}

- (void)setFrameMaxX:(CGFloat)frameMaxX
{
    CGRect frame = self.frame;
    frame.origin.x = frameMaxX - frame.size.width;
    self.frame = frame;
}

- (CGFloat)frameMaxY
{
    return CGRectGetMaxY(self.frame);
}

- (void)setFrameMaxY:(CGFloat)frameMaxY
{
    CGRect frame = self.frame;
    frame.origin.y = frameMaxY - frame.size.height;
    self.frame = frame;
}

#pragma mark Subviews

- (BOOL)containsSubview:(UIView *)subview;
{
    NSArray *views = self.subviews;
    
    for (UIView *currentView in views) {
        if (currentView == subview) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)containsSubviewOfClass:(Class)subviewClass;
{
    NSArray *views = self.subviews;
    
    for (UIView *currentView in views) {
        if ([currentView isKindOfClass:subviewClass] || [currentView containsSubviewOfClass:subviewClass]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark Sliding Overlay Views

- (void)slideOutViewForView:(UIView *)inView fromLeft:(BOOL)fromLeft withBounce:(BOOL)bounce fade:(BOOL)fade duration:(NSTimeInterval)duration;
{
    UIView *outViewSuperView = self.superview;
    UIView *outView = self;
    
    // insert inView
    if (fade) {
        inView.transparent = YES;
        inView.hidden = NO;
    }
    
    if (inView.superview != outViewSuperView) {
        [outViewSuperView addSubview:inView];
    }
    
    // move inView outside the super bounds
    CGRect inViewFrame = inView.frame;
    CGRect outViewFrame = outView.frame;
    CGRect superBounds = outViewSuperView.bounds;
    
    inViewFrame.origin.x = fromLeft ? -inViewFrame.size.width : superBounds.size.width;
    inViewFrame.origin.y = outViewFrame.origin.y;
    inView.frame = inViewFrame;
    
    // calculate outView's new frame
    CGRect newOutViewFrame = outViewFrame;
    newOutViewFrame.origin.x = fromLeft ? superBounds.size.width : -outViewFrame.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        inView.frame = outViewFrame;
        outView.frame = newOutViewFrame;
        
        if (fade) {
            inView.transparent = NO;
            outView.transparent = YES;
        }
    } completion:NULL];
}

- (void)presentOverlayView:(UIView *)overlayView withAnimation:(BOOL)animation;
{
    [self presentOverlayView:overlayView withAnimation:animation underStatusBar:NO];
}

- (void)presentOverlayView:(UIView *)overlayView withAnimation:(BOOL)animation underStatusBar:(BOOL)underStatusBar;
{
    if (overlayView.superview != self) {
        [self addSubview:overlayView];
    }
    
    // Move the overlay view outside the container view bounds
    CGRect overlayViewFrame = overlayView.frame;
    overlayViewFrame.origin.y = -overlayViewFrame.size.height;
    overlayView.frame = overlayViewFrame;
    
    CGRect newOverlayViewFrame = overlayViewFrame;
    newOverlayViewFrame.origin.y = self.frame.origin.y;
    
    if (underStatusBar) {
        newOverlayViewFrame.origin.y -= [UIApplication sharedApplication].statusBarFrame.size.height;
    }
        
    [UIView animateWithDuration:STDefaultAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{        
        overlayView.frame = newOverlayViewFrame;
    } completion:NULL];
}

- (void)removeOverlayView:(UIView *)overlayView withAnimation:(BOOL)animation;
{
    CGRect overlayViewFrame = overlayView.frame;
    
    // Move the overlay view outside the container view bounds
    CGRect newOverlayViewFrame = overlayViewFrame;
    newOverlayViewFrame.origin.y = -overlayViewFrame.size.height;
    
    [UIView animateWithDuration:STDefaultAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        overlayView.frame = newOverlayViewFrame;
    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
    }];
}

- (void)crossfadeSubview:(UIView *)subview toView:(UIView *)fadeView;
{
    if (![self containsSubview:subview] || [self containsSubview:fadeView]) {
        // Remove any existing animations
        [self.layer removeAllAnimations];
    }
    
    fadeView.frame = subview.frame;
    
    fadeView.transparent = YES;
    fadeView.hidden = NO;
    [self addSubview:fadeView];
    
    [UIView animateWithDuration:0.5 animations:^{
        subview.transparent = YES;
        fadeView.transparent = NO;
        fadeView.hidden = NO;
    } completion:^(BOOL finished) {        
        subview.hidden = YES;
        [subview removeFromSuperview];
    }];
}

#pragma mark Animation Convenience Methods

- (void)fadeOut;
{
    [UIView animateWithDuration:STDefaultAnimationDuration animations:^{
        self.transparent = YES;
    } completion:^(BOOL finished) {
        self.transparent = NO;
        [self removeFromSuperview];
    }];
}

- (void)pageCurlTransition;
{
    [self pageCurlTransitionWithDuration:1.0];
}

- (void)pageCurlTransitionWithDuration:(NSTimeInterval)duration;
{
    UIView *doNothingView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:doNothingView];
    
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCurlUp animations:^{
        [doNothingView removeFromSuperview];
    } completion:NULL];
}

- (void)shake;
{
    // create the path for the keyframe animation
    const NSUInteger bounceOffsetCount = 9;
    CGFloat bounceOffsets[] = {-13.0f, 13.0f, -10.0f, 7.0f, -5.0f, 3.0f, -2.0f, 1.0f, 0.0f};
    CGPoint containerOrigin = self.center;
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, containerOrigin.x, containerOrigin.y);
    for (NSUInteger index = 0; index < bounceOffsetCount; index++) {
        CGPathAddLineToPoint(path, NULL, containerOrigin.x + bounceOffsets[index], containerOrigin.y);
    }
    
    CAKeyframeAnimation *keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    keyframeAnimation.path = path;
    keyframeAnimation.duration = 1.5;
    keyframeAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.5f :1.8f :0.5f :0.7f];
    
    // release the path
    CFRelease(path);
    
    // start animating
    [self.layer addAnimation:keyframeAnimation forKey:@"animatePosition"];
}

#pragma mark Convenience Frame Setters

- (void)setHeight:(CGFloat)height;
{
	CGRect newFrame = self.frame;
	newFrame.size.height = height;
	[self setFrame:newFrame];
}

- (void)setWidth:(CGFloat)width;
{	
	CGRect newFrame = self.frame;
	newFrame.size.width = width;
	[self setFrame:newFrame];
}

- (void)setOriginY:(CGFloat)originY;
{	
	CGRect newFrame = self.frame;
	newFrame.origin.y = originY;
	[self setFrame:newFrame];
}

#pragma mark View Geometry Convenience Methods

- (CGRect)centeredSubRectOfSize:(CGSize)subRectSize;
{
    return [self centeredSubRectOfSize:subRectSize insideRect:self.bounds];
}

- (CGRect)centeredSubRectOfSize:(CGSize)subRectSize insideRect:(CGRect)inRect;
{
    return [self centeredSubRectOfSize:subRectSize insideRect:inRect offset:CGSizeZero];
}

- (CGRect)centeredSubRectOfSize:(CGSize)subRectSize insideRect:(CGRect)inRect offset:(CGSize)offset;
{
    if (CGSizeEqualToSize(subRectSize, inRect.size)) {
        return inRect;
    }
    
    CGFloat frameWidth = inRect.size.width;
    CGFloat halfFrameWidth = floorf(frameWidth / 2.0f);
    CGFloat subRectWidth = subRectSize.width;
    CGFloat halfSubRectWidth = floorf(subRectWidth / 2.0f);
    
    CGFloat frameHeight = inRect.size.height;
    CGFloat halfFrameHeight = floorf(frameHeight / 2.0f);
    CGFloat subRectHeight = subRectSize.height;
    CGFloat halfSubRectHeight = floorf(subRectHeight / 2.0f);
    
    CGFloat subRectX = (halfFrameWidth - halfSubRectWidth) + inRect.origin.x + offset.width;
    CGFloat subRectY = halfFrameHeight - halfSubRectHeight + inRect.origin.y + offset.height;
    
    return CGRectMake(subRectX, subRectY, subRectWidth, subRectHeight);
}

// This isn't very well tested yet, but I'm leaving it here in
// case I want to revisit it later -- Buzz

- (CGRect)subrectOfSize:(CGSize)subRectSize insideRect:(CGRect)fullRect forContentMode:(UIViewContentMode)inContentMode;
{
    CGRect centeredRect = [self centeredSubRectOfSize:subRectSize insideRect:fullRect];
    
    // Initially assume a centered rect
    CGFloat imageX = centeredRect.origin.x;
    CGFloat imageY = centeredRect.origin.y;
    CGFloat subRectWidth = subRectSize.width;
    CGFloat subRectHeight = subRectSize.height;
    
    CGFloat extraWidth = fullRect.size.width - subRectWidth;
    CGFloat extraHeight = fullRect.size.height - subRectHeight;
    
    // Figure out the X if our content mode is off center vertically
    if (inContentMode == UIViewContentModeRight || inContentMode == UIViewContentModeTopRight || inContentMode == UIViewContentModeBottomRight) {
        imageX = extraWidth;
    } else if (inContentMode == UIViewContentModeLeft || inContentMode == UIViewContentModeBottomLeft || inContentMode == UIViewContentModeTopLeft) {
        imageX = 0.0f;
    }
    
    // Figure out the Y if our content mode is off center vertically
    if (inContentMode == UIViewContentModeBottom || inContentMode == UIViewContentModeBottomRight || inContentMode == UIViewContentModeBottomLeft) {
        imageY = extraHeight;
    } else if (inContentMode == UIViewContentModeTop || inContentMode == UIViewContentModeTopLeft || inContentMode == UIViewContentModeTopRight) {
        imageY = 0.0f;
    }
    
    return CGRectMake(imageX, imageY, subRectWidth, subRectHeight);
}

#pragma mark Misc. Utilities

- (UIImage *)renderToImage;
{
    UIImage *theImage = nil;
    
    // render our tile image into a temporary buffer
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f); {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        theImage = UIGraphicsGetImageFromCurrentImageContext();
    } UIGraphicsEndImageContext();
    
    return theImage;
}

@end
