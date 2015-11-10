//
//  UIImage+DQAdditions.m
//  DrawQuest
//
//  Created by David Mauro on 7/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "UIImage+DQAdditions.h"

@implementation UIImage (DQADditions)

+ (instancetype)shopColorWithColor:(UIColor *)inColor isPurchased:(BOOL)isPurchased
{
    UIImage *baseImage = [UIImage imageNamed:@"modal_color_base"];
    
    if( ! inColor)
    {
        return baseImage;
    }
    
    // These images could stand to be cached somewhere, don't want to composite everytime
    
    UIGraphicsBeginImageContextWithOptions(baseImage.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f, baseImage.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGRect rect = CGRectMake(0.0f, 0.0f, baseImage.size.width, baseImage.size.height);
    
    CGContextDrawImage(context, rect, baseImage.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextClipToMask(context, rect, baseImage.CGImage);
    CGContextSetFillColorWithColor(context, inColor.CGColor);
    CGContextFillRect(context, rect);
    
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextDrawImage(context, rect, [UIImage imageNamed:@"modal_color_transparent_shadowing"].CGImage);
    
    UIImage *purchasedCheckmark = [UIImage imageNamed:@"color_owned_checkmark"];
    CGRect checkmarkRect = CGRectMake((int)((baseImage.size.width - purchasedCheckmark.size.width)/2),
                                      (int)((baseImage.size.height - purchasedCheckmark.size.height)/2),
                                      purchasedCheckmark.size.width,
                                      purchasedCheckmark.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    if (isPurchased)
    {
        CGContextDrawImage(context, checkmarkRect, purchasedCheckmark.CGImage);
    }
    
    UIImage *compositedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return compositedImage;
}

+ (UIImage *)screenshot
{
    CGSize imageSize = CGSizeZero;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        imageSize = [UIScreen mainScreen].bounds.size;
    } else {
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }

    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        } else {
            [window.layer renderInContext:context];
        }
        CGContextRestoreGState(context);
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
