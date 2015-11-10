//
//  DQFunctions.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 8/15/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFunctions.h"

BOOL DQSystemVersionAtLeast(NSString* systemVersionString)
{
    NSComparisonResult result = [[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch];
    return (result != NSOrderedAscending);
}

UIImage *DQImageWithColor(DQColor color) {
    UIColor *imageColor;
    
    switch (color) {
        case DQColorGreen:
            imageColor = [UIColor colorWithRed:(96 / 255.0) green:(227 / 255.0) blue:(182 / 255.0) alpha:1];
            break;
            
        case DQColorBlue:
            imageColor = [UIColor colorWithRed:(107 / 255.0) green:(206 / 255.0) blue:(217 / 255.0) alpha:1];
            break;
            
        case DQColorRed:
            imageColor = [UIColor colorWithRed:(252 / 255.0) green:(134 / 255.0) blue:(155 / 255.0) alpha:1];
            break;
        
        case DQColorGray:
            imageColor = [UIColor colorWithRed:(200 / 255.0) green:(200 / 255.0) blue:(200 / 255.0) alpha:1];
            break;
            
        default:
            imageColor = [UIColor colorWithRed:(96 / 255.0) green:(227 / 255.0) blue:(182 / 255.0) alpha:1];
            break;
    }
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [imageColor CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return image;
}
