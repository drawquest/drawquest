//
//  CVSPhoneColorWell.h
//  DrawQuest
//
//  Created by David Mauro on 9/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVSPhoneColorWell : UIView

@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) BOOL *forceOutline;

- (id)initWithFrame:(CGRect)frame fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor forceOutline:(BOOL)forceOutline;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithFrame:fillColor:strokeColor:forceOutline:);

@end
