//
//  DQPhoneErrorView.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-10-28.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneErrorView.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

// Views
#import "DQButton.h"

@interface DQPhoneErrorView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) DQButton *button;
@property (nonatomic, strong) NSLayoutConstraint *imageViewTopConstraint;

@end

@implementation DQPhoneErrorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor dq_phoneBackgroundColor];

        _topInset = 20.0f;
        
        _imageView = [[UIImageView alloc] initWithImage:[self image]];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_imageView];

        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _messageLabel.numberOfLines = 0;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = [UIFont dq_galleryErrorMessageFont];
        _messageLabel.textColor = [UIColor dq_modalPrimaryTextColor];
        [self addSubview:_messageLabel];

        _button = [[DQButton alloc] initWithFrame:CGRectZero];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.tintColorForBackground = YES;
        _button.layer.cornerRadius = 5.0f;
        _button.titleLabel.font = [UIFont dq_galleryButtonFont];
        _button.contentEdgeInsets = UIEdgeInsetsMake(5.0f, 10.0f, 5.0f, 10.0f);
        __weak typeof(self) weakSelf = self;
        _button.tappedBlock = ^(DQButton *button) {
            if (weakSelf.buttonTappedBlock)
            {
                weakSelf.buttonTappedBlock();
            }
        };
        [self addSubview:_button];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_imageView, _messageLabel, _button);
        NSDictionary *metrics = @{@"priority": @(UILayoutPriorityDefaultHigh)};

        DQVisualConstraints(self, @"H:|-50@priority-[_messageLabel]-50@priority-|");
        DQVisualConstraints(self, @"H:|-50@priority-[_button]-50@priority-|");
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_button.superview attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
        DQVisualConstraints(self, @"V:[_imageView]-20@priority-[_messageLabel]-15@priority-[_button]->=20@priority-|");
        _imageViewTopConstraint = [NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_imageView.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        _imageViewTopConstraint.priority = UILayoutPriorityDefaultHigh;
        [self addConstraint:_imageViewTopConstraint];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_button.superview attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)updateConstraints
{
    self.imageViewTopConstraint.constant = (self.imageView.image) ? self.topInset : 0.0f;

    [super updateConstraints];
}

- (void)reloadView
{
    self.imageView.image = [self image];
    self.messageLabel.text = [self message];
    [self.button setTitle:[self buttonTitle] forState:UIControlStateNormal];
    [self setNeedsUpdateConstraints];
}

- (void)setErrorType:(DQPhoneErrorViewType)errorType
{
    _errorType = errorType;
    [self reloadView];
}

- (UIImage *)image
{
    return nil; // subclasses must override
}

- (NSString *)message
{
    return nil; // subclasses must override
}

- (NSString *)buttonTitle
{
    return nil; // subclasses must override
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.button.hidden = !self.buttonTappedBlock;
}

@end
