//
//  UIImage+DQAdditions.h
//  DrawQuest
//
//  Created by David Mauro on 7/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DQAdditions)

+ (instancetype)shopColorWithColor:(UIColor *)inColor isPurchased:(BOOL)isPurchased;
+ (instancetype)screenshot;

@end
