//
//  UIView+STAdditions.h
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIView (STAdditions)

// toggles between alpha 0.0f / 1.0f
@property (nonatomic, getter=isTransparent) BOOL transparent;
@property (nonatomic) CGPoint frameOrigin;
@property (nonatomic) CGFloat frameX;
@property (nonatomic) CGFloat frameY;
@property (nonatomic) CGSize boundsSize;
@property (nonatomic) CGFloat frameWidth;
@property (nonatomic) CGFloat frameHeight;
@property (nonatomic, readonly) CGPoint boundsCenter;
@property (nonatomic, readonly) CGFloat boundsCenterX;
@property (nonatomic) CGFloat frameCenterX;
@property (nonatomic, readonly) CGFloat boundsCenterY;
@property (nonatomic) CGFloat frameCenterY;
@property (nonatomic) CGFloat frameMaxX;
@property (nonatomic) CGFloat frameMaxY;

#pragma mark Subviews
- (BOOL)containsSubview:(UIView *)subview;
- (BOOL)containsSubviewOfClass:(Class)subviewClass;

#pragma mark Sliding Overlay Views
- (void)slideOutViewForView:(UIView *)inView fromLeft:(BOOL)fromLeft withBounce:(BOOL)bounce fade:(BOOL)fade duration:(NSTimeInterval)duration;
- (void)presentOverlayView:(UIView *)overlayView withAnimation:(BOOL)animation;
- (void)presentOverlayView:(UIView *)overlayView withAnimation:(BOOL)animation underStatusBar:(BOOL)underStatusBar;
- (void)removeOverlayView:(UIView *)overlayView withAnimation:(BOOL)animation;
- (void)crossfadeSubview:(UIView *)subview toView:(UIView *)fadeView;

#pragma mark Animation Convenience Methods
- (void)fadeOut;
- (void)pageCurlTransition;
- (void)pageCurlTransitionWithDuration:(NSTimeInterval)duration;
- (void)shake;

#pragma mark Convenience Frame Setters
- (void)setHeight:(CGFloat)height;
- (void)setWidth:(CGFloat)width;
- (void)setOriginY:(CGFloat)originY;

#pragma mark Centering Convenience Methods
- (CGRect)centeredSubRectOfSize:(CGSize)subRectSize;
- (CGRect)centeredSubRectOfSize:(CGSize)subRectSize insideRect:(CGRect)inRect;
- (CGRect)centeredSubRectOfSize:(CGSize)subRectSize insideRect:(CGRect)inRect offset:(CGSize)offset;
- (CGRect)subrectOfSize:(CGSize)subRectSize insideRect:(CGRect)fullRect forContentMode:(UIViewContentMode)inContentMode;

#pragma mark Misc. Utilities
- (UIImage *)renderToImage;

@end
