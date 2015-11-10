//
//  DQColorPaletteView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQColorPaletteView.h"
#import "UIImage+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "UIView+STAdditions.h"

@interface DQColorPaletteView()

@property (strong, nonatomic) NSMutableArray *colorViews;

@end

@implementation DQColorPaletteView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _colorViews = [[NSMutableArray alloc] init];
    
    return self;
}


#pragma mark - Accessors

- (void)setColors:(NSArray *)colors
{
    _colors = colors;
    
    [self updateColorViews];
}

#pragma mark - Configuration

- (void)updateColorViews
{
    [self.colorViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.colorViews removeAllObjects];
    
    [self.colors enumerateObjectsUsingBlock:^(NSDictionary *color, NSUInteger idx, BOOL *stop) {
        UIImage *colorImage = [UIImage shopColorWithColor:[UIColor dq_colorWithRGBArray:color.dq_colorRGBInfo] isPurchased:color.dq_colorIsPurchased];
        UIImageView *colorView = [[UIImageView alloc] initWithImage:colorImage];
        colorView.layer.contentsScale = [UIScreen mainScreen].scale;
        [self.colorViews addObject:colorView];
        [self addSubview:colorView];
    }];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGPoint cursor = CGPointMake(20.0f, CGRectGetMidY(self.bounds));
    for (UIView *colorView in self.colorViews)
    {
        colorView.center = cursor;
        // Ensure the color image view is aligned to the pixel grid
        colorView.frameX = (int)colorView.frameX;
        colorView.frameY = (int)colorView.frameY;
        cursor.x += CGRectGetWidth(colorView.frame) + 10.0;
    }
}

@end
