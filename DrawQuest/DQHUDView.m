//
//  DQHUDView.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/26/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQHUDView.h"

@interface DQHUDView()

@property (nonatomic, assign) CGRect contentRect;
@property (nonatomic, strong) UIBezierPath *contentRectPath;
@property (nonatomic, assign, getter = isVisible) BOOL visible;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation DQHUDView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = [UIColor clearColor];
    self.alpha = 0.0f;

    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:_indicatorView];

    _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _textLabel.backgroundColor = [UIColor clearColor];
    _textLabel.font = [UIFont boldSystemFontOfSize:24.0f];
    _textLabel.textColor = [UIColor whiteColor];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.text = @"Loading";
    [self addSubview:_textLabel];

    return self;
}


#pragma mark - Accessors

- (void)setText:(NSString *)text
{
    self.textLabel.text = text;
    [self setNeedsLayout];
}

- (NSString *)text
{
    return self.textLabel.text;
}

#pragma mark -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{

}

#pragma mark - Presentation

- (void)showInView:(UIView *)view animated:(BOOL)animated
{
    [view addSubview:self];
    if (!animated) {
        self.alpha = 1.0f;
        [self.indicatorView startAnimating];
        self.visible = YES;
    }
    else {
        const NSTimeInterval animationDuration = 0.200f;
        [UIView animateWithDuration:animationDuration animations:^{
            self.alpha = 1.0f;
            [self.indicatorView startAnimating];
        } completion:^(BOOL finished) {
            self.visible = YES;
        }];
    }
}

- (void)hideAnimated:(BOOL)animated
{
    if (!animated) {
        [self.indicatorView stopAnimating];
        self.alpha = 0.0f;
        [self removeFromSuperview];
        self.visible = NO;
    }
    else {
        const NSTimeInterval animationDuration = 0.200f;
        [UIView animateWithDuration:animationDuration animations:^{
            [self.indicatorView stopAnimating];
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            self.visible = NO;
        }];
    }
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect
{
    float PADDING = 16.0f;
    float WIDTH = MAX(232.0f, self.textLabel.frame.size.width + PADDING * 2);
    float HEIGHT = 199.0f;

    self.contentRect = CGRectMake(roundf(self.bounds.size.width / 2) - roundf(WIDTH / 2), roundf(self.bounds.size.height / 2) - roundf(HEIGHT / 2), WIDTH, HEIGHT);
    self.contentRectPath = [UIBezierPath bezierPathWithRoundedRect:self.contentRect cornerRadius:10.0f];

    [[UIColor colorWithWhite:0.2f alpha:0.8f] set];
    [self.contentRectPath fill];
}

- (void)layoutSubviews
{
    self.indicatorView.center = self.center;
    self.textLabel.frame = (CGRect){.size = [self.textLabel.text sizeWithAttributes:@{NSFontAttributeName: self.textLabel.font}]};
    self.textLabel.center = CGPointMake(self.center.x, self.center.y + 50.0f);
    
    [self setNeedsDisplay];
}

@end
