//
//  DQQuestOfTheDayView.m
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestOfTheDayView.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

// Views
#import "DQButton.h"
#import "DQCircularMaskImageView.h"
#import "DQImageView.h"
#import "DQTimestampView.h"

NSString *const DQQuestOfTheDayViewDidMoveToWindowNotification = @"DQQuestOfTheDayViewDidMoveToWindowNotification";

static const CGFloat kDQQuestOfTheDayViewInnerPadding = 10.0f;
static const CGFloat kDQQuestOfTheDayViewButtonWidth = 70.0f;
static const CGFloat kDQQuestOfTheDayViewButtonHeight = 35.0f;

@interface DQQuestOfTheDayView ()

@property (nonatomic, strong) UIView *usernameWrapper;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) DQButton *viewQuestButton;
@property (nonatomic, strong) DQButton *drawQuestButton;
@property (nonatomic, strong) UIView *viewQuestButtonBorder;
@property (nonatomic, strong) UIView *drawQuestButtonBorder;
@property (nonatomic, strong) NSLayoutConstraint *attributionConstraint;

@end

@implementation DQQuestOfTheDayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        __weak typeof(self) weakSelf = self;

        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.layer.cornerRadius = 10.0f;
        _contentView.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
        _contentView.layer.borderWidth = 1.0f;
        [self addSubview:_contentView];

        _questTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _questTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_questTitleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _questTitleLabel.userInteractionEnabled = YES;
        _questTitleLabel.textColor = self.tintColor;
        _questTitleLabel.font = [UIFont dq_questOfTheDayTitleFont];
        [_contentView addSubview:_questTitleLabel];

        _timestampLabel = [[DQTimestampView alloc] initWithFrame:CGRectZero];
        _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_timestampLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_timestampLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        _timestampLabel.tintColor = [UIColor dq_timestampColor];
        _timestampLabel.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        [_contentView addSubview:_timestampLabel];

        _questTemplateImageView = [[DQImageView alloc] initWithFrame:CGRectZero];
        _questTemplateImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _questTemplateImageView.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
        _questTemplateImageView.layer.borderWidth = 1.0f;
        [_contentView addSubview:_questTemplateImageView];

        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarImageView.image = [UIImage imageNamed:@"questbot_small"];
        [_contentView addSubview:_avatarImageView];

        _usernameWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        _usernameWrapper.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameWrapper.userInteractionEnabled = YES;
        [_contentView addSubview:_usernameWrapper];

        _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.textColor = self.tintColor;
        _usernameLabel.font = [UIFont dq_questOfTheDayTitleFont];
        [_usernameWrapper addSubview:_usernameLabel];

        _attributionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _attributionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _attributionLabel.textColor = [UIColor dq_phoneGrayTextColor];
        _attributionLabel.font = [UIFont dq_phoneQuestAttributionLabelFont];
        [_usernameWrapper addSubview:_attributionLabel];

        _viewQuestButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_gallery"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _viewQuestButton.translatesAutoresizingMaskIntoConstraints = NO;
        _viewQuestButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _viewQuestButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.viewQuestBlock)
            {
                weakSelf.viewQuestBlock();
            }
        };
        [_contentView addSubview:_viewQuestButton];

        _viewQuestButtonBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _viewQuestButtonBorder.translatesAutoresizingMaskIntoConstraints = NO;
        _viewQuestButtonBorder.backgroundColor = [UIColor dq_phoneDivider];
        [_contentView addSubview:_viewQuestButtonBorder];

        _drawQuestButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_draw_pencil"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _drawQuestButton.translatesAutoresizingMaskIntoConstraints = NO;
        _drawQuestButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _drawQuestButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.drawQuestBlock)
            {
                weakSelf.drawQuestBlock();
            }
        };
        [_contentView addSubview:_drawQuestButton];

        _drawQuestButtonBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _drawQuestButtonBorder.translatesAutoresizingMaskIntoConstraints = NO;
        _drawQuestButtonBorder.backgroundColor = [UIColor dq_phoneDivider];
        [_contentView addSubview:_drawQuestButtonBorder];

        // Layout
        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_contentView);
        NSDictionary *metrics = @{@"padding":@(kDQFormPhoneWideImageOuterPadding)};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[_contentView]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-padding-[_contentView]-padding-|" options:0 metrics:metrics views:viewBindings]];

        viewBindings = NSDictionaryOfVariableBindings(_usernameWrapper, _attributionLabel, _questTitleLabel, _timestampLabel, _questTemplateImageView, _avatarImageView, _usernameLabel, _viewQuestButton, _viewQuestButtonBorder, _drawQuestButton, _drawQuestButtonBorder);
        metrics = @{@"padding": @(kDQQuestOfTheDayViewInnerPadding), @"buttonWidth": @(kDQQuestOfTheDayViewButtonWidth), @"buttonHeight": @(kDQQuestOfTheDayViewButtonHeight)};
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[_questTitleLabel]->=padding-[_timestampLabel]-padding-|" options:NSLayoutFormatAlignAllCenterY metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=padding-[_timestampLabel]" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_questTemplateImageView]|" options:0 metrics:nil views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[_avatarImageView]-padding-[_usernameWrapper]->=padding-[_viewQuestButtonBorder(1)][_viewQuestButton(==buttonWidth)][_drawQuestButtonBorder(1)][_drawQuestButton(==buttonWidth)]|" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-padding-[_questTitleLabel]-padding-[_questTemplateImageView]-padding-[_viewQuestButtonBorder(==buttonHeight,==_avatarImageView,==_usernameWrapper,==_viewQuestButton,==_drawQuestButtonBorder,==_drawQuestButton)]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_avatarImageView]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_usernameWrapper]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_viewQuestButton]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_drawQuestButtonBorder]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_drawQuestButton]-padding-|" options:0 metrics:metrics views:viewBindings]];

        [_usernameWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_usernameLabel]|" options:0 metrics:metrics views:viewBindings]];
        [_usernameWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_attributionLabel]|" options:0 metrics:metrics views:viewBindings]];
        [_usernameWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_attributionLabel]" options:0 metrics:metrics views:viewBindings]];
        [_usernameWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_usernameLabel]|" options:0 metrics:metrics views:viewBindings]];
        self.attributionConstraint = [NSLayoutConstraint constraintWithItem:_usernameLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_attributionLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-2.0f];
        [_usernameWrapper addConstraint:self.attributionConstraint];

        // 4 x 3 size for template image
        [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_questTemplateImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_questTemplateImageView attribute:NSLayoutAttributeWidth multiplier:0.75f constant:0.0f]];

        // square for avatar image
        [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_avatarImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_avatarImageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0f]];

        // Gesture Recognizers for Editor
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shouldShowEditor:)];
        [_questTitleLabel addGestureRecognizer:tapRecognizer];
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shouldShowEditor:)];
        [_questTemplateImageView addGestureRecognizer:tapRecognizer];
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shouldShowEditor:)];
        [_timestampLabel addGestureRecognizer:tapRecognizer];

        // For avatar & username
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showProfile:)];
        [_avatarImageView addGestureRecognizer:tapRecognizer];
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showProfile:)];
        [_usernameWrapper addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.window)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DQQuestOfTheDayViewDidMoveToWindowNotification
                                                            object:self
                                                          userInfo:nil];
    }
}

- (void)updateConstraints
{
    [self.usernameWrapper removeConstraint:self.attributionConstraint];
    if ([self.attributionLabel.text length])
    {
        self.attributionConstraint = [NSLayoutConstraint constraintWithItem:_usernameLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_attributionLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-2.0f];
    }
    else
    {
        self.attributionConstraint = [NSLayoutConstraint constraintWithItem:_usernameLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_usernameLabel.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0f];
    }
    [self.usernameWrapper addConstraint:self.attributionConstraint];

    [super updateConstraints];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.questTitleLabel.textColor = self.tintColor;
    self.usernameLabel.textColor = self.tintColor;
}

#pragma mark - Actions

- (void)shouldShowEditor:(id)sender
{
    if (self.drawQuestBlock)
    {
        self.drawQuestBlock();
    }
}

- (void)showProfile:(id)sender
{
    if (self.showProfileBlock)
    {
        self.showProfileBlock();
    }
}

@end
