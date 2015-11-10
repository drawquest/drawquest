//
//  DQTabularItem.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DQTabularItem : NSObject
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, strong) UIImage *icon;
@property (nonatomic, readonly, strong) UIViewController *viewController;
@property (nonatomic, readonly, strong) UIImage *compositeImage;

+ (instancetype)tabularItemWithViewController:(UIViewController *)viewController title:(NSString *)title icon:(UIImage *)icon;

@end
