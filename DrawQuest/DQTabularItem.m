//
//  DQTabularItem.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTabularItem.h"
#import "UIFont+DQAdditions.h"

@interface DQTabularItem ()
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, strong) UIImage *icon;
@property (nonatomic, readwrite, strong) UIViewController *viewController;
@property (nonatomic, readwrite, strong) UIImage *compositeImage;
@end

@implementation DQTabularItem

+ (instancetype)tabularItemWithViewController:(UIViewController *)viewController title:(NSString *)title icon:(UIImage *)icon
{
    DQTabularItem *item = [[self alloc] init];

    item.title = title;
    item.icon = icon;
    item.viewController = viewController;

    [[NSNotificationCenter defaultCenter] addObserver:item selector:@selector(_didReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    return item;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)_didReceiveMemoryWarningNotification:(NSNotification *)notification
{
    self.compositeImage = nil;
}

- (UIImage *)compositeImage
{
    // Since DQTabularItem is immutable, we can safely cache the generated
    // image to save drawing it again.
    if (_compositeImage)
    {
        return _compositeImage;
    }

    UIFont *font = [UIFont dq_onboardTabsFont];
    CGSize textSize = [self.title sizeWithAttributes:@{NSFontAttributeName: font}];
    CGSize size = CGSizeZero;
    size.width = self.icon.size.width + 4 + textSize.width;
    size.height = MAX(self.icon.size.height, textSize.height);

    _compositeImage = [self _compositeImageForIcon:self.icon text:self.title font:font contextSize:size];

    return _compositeImage;
}

#pragma mark - Helper for generating asset image

typedef NS_ENUM(char, DQAssetCenteredDirection)
{
    DQTabularItemCenteredDirectionVertical = 0,
    DQTabularItemCenteredDirectionHorizontal,
};

- (CGPoint)_pointForCenteredAssetWithinSize:(CGSize)size direction:(DQAssetCenteredDirection)direction height:(CGFloat)height edgeInsets:(UIEdgeInsets)edgeInsets
{
    CGFloat centerY = size.height / 2.0f;
    return (CGPoint){ .x = edgeInsets.left, .y = centerY - edgeInsets.top - height / 2.0f - edgeInsets.bottom };
}

- (UIImage *)_compositeImageForIcon:(UIImage *)icon text:(NSString *)text font:(UIFont *)font contextSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);

    CGPoint textPoint = [self _pointForCenteredAssetWithinSize:size direction:DQTabularItemCenteredDirectionVertical height:font.pointSize edgeInsets:UIEdgeInsetsMake(0, icon.size.width + 4, 1, 2)];
    [text drawAtPoint:textPoint withAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor whiteColor]}];

    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, size.height);
    CGContextConcatCTM(context, flipVertical);
    CGPoint imagePoint = [self _pointForCenteredAssetWithinSize:size direction:DQTabularItemCenteredDirectionVertical height:icon.size.height edgeInsets:UIEdgeInsetsZero];
    CGContextDrawImage(context, (CGRect){ imagePoint, icon.size }, icon.CGImage);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
