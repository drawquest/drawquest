//
//  DQReusableBannerView.m
//  DrawQuest
//
//  Created by David Mauro on 11/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQReusableBannerView.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

@interface DQReusableBannerView ()

@property (nonatomic, strong) UIImageView *disclosureImageView;

@end

@implementation DQReusableBannerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = self.tintColor;
        self.layer.cornerRadius = 6.0f;

        _disclosureImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"icon_disclosure_phone"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _disclosureImageView.tintColor = [UIColor whiteColor];
        _disclosureImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _disclosureImageView.alpha = 0.5;
        [self addSubview:_disclosureImageView];

        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_imageView];

        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:18.0f];
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.numberOfLines = 0;
        [self addSubview:_messageLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tap];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_disclosureImageView, _imageView, _messageLabel);
        NSDictionary *metrics = @{@"priority": @(UILayoutPriorityDefaultHigh)};

        DQVisualConstraints(self, @"H:|-5@priority-[_imageView]-8@priority-[_messageLabel]-10@priority-[_disclosureImageView]-10@priority-|");
        DQVisualConstraints(self, @"V:[_imageView]|");

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_disclosureImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_disclosureImageView.superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_messageLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_messageLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.backgroundColor = self.tintColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.messageLabel.text = nil;
    self.imageView.image = nil;
    self.cellTappedBlock = nil;
}

- (void)cellTapped:(id)sender
{
    if (self.cellTappedBlock)
    {
        self.cellTappedBlock(self);
    }
}

@end
