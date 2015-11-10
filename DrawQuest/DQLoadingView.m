//
//  DQLoadingView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/18/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQLoadingView.h"
#import "STUtils.h"

@interface DQLoadingView()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation DQLoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_activityIndicator startAnimating];
    [self addSubview:_activityIndicator];
        
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _activityIndicator.frame = [self centeredSubRectOfSize:CGSizeMake(100.0, 100.0)];
}


@end
