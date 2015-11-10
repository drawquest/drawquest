// CVSTemplateImage.m
// DrawQuest
// Created by Justin Carlson on 11/3/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>
#import "CVSTemplateImage.h"

static bool IsCGImageOpaque(CGImageRef pImage) {
    if (!pImage) {
        assert(0 && "invalid image");
        return false;
    }
    assert(!CGImageIsMask(pImage));
    // quick check the image's channel info...
    const CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(pImage);
    switch (alphaInfo) {
        case kCGImageAlphaNone :
        case kCGImageAlphaNoneSkipLast :
        case kCGImageAlphaNoneSkipFirst :
            return true;

        case kCGImageAlphaPremultipliedLast :
        case kCGImageAlphaPremultipliedFirst :
        case kCGImageAlphaLast :
        case kCGImageAlphaFirst :
        case kCGImageAlphaOnly :
            break;
    }
    @autoreleasepool {
        // ...before evaluating the image's content
        CIImage * const input = [CIImage imageWithCGImage:pImage];
        assert(input);
        // not available in iOS 7
        CIFilter * const filter = [CIFilter filterWithName:@"CIAreaMinimumAlpha"];
        if (!filter) {
            // seems simpler to just take the render hit than determine this at this stage.
            // @todo come back to this later
            return false;
        }
        [filter setDefaults];
        [filter setValue:input forKey:kCIInputImageKey];
        [filter setValue:[CIVector vectorWithCGRect:input.extent] forKey:kCIInputExtentKey];
        CIImage * const output = [filter valueForKey:kCIOutputImageKey];
        assert(output);
        const CGRect extent = output.extent;
        if (CGRectIsNull(extent) || CGRectIsEmpty(extent)) {
            assert(0 && "invalid result");
            return false;
        }
        CIContext * const context = [CIContext contextWithOptions:[NSDictionary dictionary]];
        assert(context);

        const size_t Width = 1;
        const size_t Height = 1;
        const size_t NComponentsPerPixel = 4;
        uint8_t outRenderedBitmapData[NComponentsPerPixel*Width*Height] = {0};
        const ptrdiff_t NBytesPerRow = NComponentsPerPixel*Width;
        const CGRect bounds = CGRectMake(0, 0, Width, Height);
        const CIFormat format = kCIFormatARGB8;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        [context render:output toBitmap:outRenderedBitmapData rowBytes:NBytesPerRow bounds:bounds format:format colorSpace:colorSpace];
        CGColorSpaceRelease(colorSpace);
        const uint8_t minAlpha = outRenderedBitmapData[0];
        printf("Min alpha of template image: %i\n", (int)minAlpha);
        return UINT8_MAX == minAlpha;
    }
}

@implementation CVSTemplateImage
{
    UIImage * image;
    bool isOpaque;
}

+ (instancetype)templateImageWithUIImage:(UIImage *)pImage
{
    assert(pImage);
    return [[self alloc] initWithUIImage:pImage];
}

+ (instancetype)templateImageWithEmptyTemplateImage
{
    // locate and open the empty template placeholder image. using the system cache for this one.
    NSString * const EmptyTemplateAsset = @"quest_with_no_template_image";
    UIImage * const asset = [UIImage imageNamed:EmptyTemplateAsset];
    assert(asset);
    return [self templateImageWithUIImage:asset];
}

- (instancetype)initWithUIImage:(UIImage *)pImage
{
    assert(pImage);
    self = [super init];
    if (!self) {
        return nil;
    }
    if (!pImage) {
        assert(0 && "invalid parameter");
        return nil;
    }
    image = pImage;
    isOpaque = IsCGImageOpaque(image.CGImage);
    return self;
}

- (UIImage *)image
{
    assert(image);
    return image;
}

- (CGImageRef)CGImage
{
    CGImageRef result = self.image.CGImage;
    assert(result);
    return result;
}

- (BOOL)isOpaque
{
    return isOpaque;
}

@end
