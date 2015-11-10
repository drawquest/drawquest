//
//  DQPhoneGalleryHeaderView.m
//  DrawQuest
//
//  Created by David Mauro on 9/27/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneGalleryHeaderView.h"

#import "DQButton.h"
#import "DQCircularMaskImageView.h"

#import "DQViewMetricsConstants.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

static const CGFloat kDQPhoneGalleryHeaderViewButtonWidth = 49.0f;
static const CGFloat kDQPhoneGalleryHeaderViewButtonHeight = 38.0f;

@interface DQPhoneGalleryHeaderView ()

@property (nonatomic, strong) UIView *inviteButtonBorder;
@property (nonatomic, strong) UIView *shareButtonBorder;
@property (nonatomic, strong) UIView *moreOptionsButtonBorder;
@property (nonatomic, strong) DQButton *inviteButton;
@property (nonatomic, strong) DQButton *shareButton;
@property (nonatomic, strong) DQButton *moreOptionsButton;
@property (nonatomic, strong) NSLayoutConstraint *questTemplateImageHeightConstraint;
@property (nonatomic, strong) UIView *noTemplateDivider;
@property (nonatomic, strong) NSArray *attributionConstraints;

@end

@implementation DQPhoneGalleryHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        __weak typeof(self) weakSelf = self;

        self.backgroundColor = [UIColor whiteColor];
        
        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showProfile:)];
        [_avatarImageView addGestureRecognizer:avatarTap];
        _avatarImageView.userInteractionEnabled = YES;
        [self addSubview:_avatarImageView];

        _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.textColor = self.tintColor;
        _usernameLabel.font = [UIFont dq_questHeaderUsernameFont];
        UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showProfile:)];
        [_usernameLabel addGestureRecognizer:usernameTap];
        _usernameLabel.userInteractionEnabled = YES;
        [self addSubview:_usernameLabel];

        _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _descriptionLabel.textColor = [UIColor dq_modalPrimaryTextColor];
        _descriptionLabel.font = [UIFont dq_questHeaderDescriptionFont];
        _descriptionLabel.adjustsFontSizeToFitWidth = YES;
        _descriptionLabel.minimumScaleFactor = 0.5f;
        [self addSubview:_descriptionLabel];

        _timestampLabel = [[DQTimestampView alloc] initWithFrame:CGRectZero];
        _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_timestampLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        _timestampLabel.tintColor = [UIColor dq_timestampColor];
        _timestampLabel.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
        [self addSubview:_timestampLabel];

        _inviteButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_invite"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _inviteButton.translatesAutoresizingMaskIntoConstraints = NO;
        _inviteButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _inviteButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.inviteToQuestBlock)
            {
                weakSelf.inviteToQuestBlock();
            }
        };
        [self addSubview:_inviteButton];

        _shareButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _shareButton.translatesAutoresizingMaskIntoConstraints = NO;
        _shareButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _shareButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.shareButtonTappedBlock)
            {
                weakSelf.shareButtonTappedBlock();
            }
        };
        [self addSubview:_shareButton];

        _moreOptionsButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _moreOptionsButton.translatesAutoresizingMaskIntoConstraints = NO;
        _moreOptionsButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _moreOptionsButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.moreOptionsBlock)
            {
                weakSelf.moreOptionsBlock();
            }
        };
        [self addSubview:_moreOptionsButton];

        _inviteButtonBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _inviteButtonBorder.translatesAutoresizingMaskIntoConstraints = NO;
        _inviteButtonBorder.backgroundColor = [UIColor dq_phoneDivider];
        [self addSubview:_inviteButtonBorder];

        _shareButtonBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _shareButtonBorder.translatesAutoresizingMaskIntoConstraints = NO;
        _shareButtonBorder.backgroundColor = [UIColor dq_phoneDivider];
        [self addSubview:_shareButtonBorder];

        _moreOptionsButtonBorder = [[UIView alloc] initWithFrame:CGRectZero];
        _moreOptionsButtonBorder.translatesAutoresizingMaskIntoConstraints = NO;
        _moreOptionsButtonBorder.backgroundColor = [UIColor dq_phoneDivider];
        [self addSubview:_moreOptionsButtonBorder];

        _questTemplateImageView = [[DQImageView alloc] initWithFrame:CGRectZero];
        _questTemplateImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _questTemplateImageView.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
        _questTemplateImageView.layer.borderWidth = 1.0f;
        _questTemplateImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(questTemplateTapped:)];
        [_questTemplateImageView addGestureRecognizer:tapRecognizer];
        [self addSubview:_questTemplateImageView];

        _noTemplateDivider = [[UIView alloc] initWithFrame:CGRectZero];
        _noTemplateDivider.translatesAutoresizingMaskIntoConstraints = NO;
        _noTemplateDivider.hidden = YES;
        _noTemplateDivider.backgroundColor = [UIColor dq_phoneDivider];
        [self addSubview:_noTemplateDivider];

        // Layout
        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_avatarImageView, _usernameLabel, _descriptionLabel, _timestampLabel, _inviteButtonBorder, _shareButtonBorder, _moreOptionsButtonBorder, _inviteButton, _shareButton, _moreOptionsButton, _questTemplateImageView, _noTemplateDivider);
        NSDictionary *metrics = @{@"padding": @(kDQFormPhoneWideImageOuterPadding), @"usernameVerticalSpacing": @(8), @"spacing": @(10), @"buttonWidth": @(kDQPhoneGalleryHeaderViewButtonWidth), @"buttonHeight": @(kDQPhoneGalleryHeaderViewButtonHeight)};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-spacing-[_avatarImageView]-padding-[_usernameLabel]->=padding-[_inviteButtonBorder(1)][_inviteButton(buttonWidth)][_shareButtonBorder(1)][_shareButton(buttonWidth)][_moreOptionsButtonBorder(1)][_moreOptionsButton(buttonWidth)]|" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_avatarImageView]-padding-[_descriptionLabel(<=_usernameLabel)]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_avatarImageView]-padding-[_timestampLabel]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[_questTemplateImageView]-padding-|" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_noTemplateDivider]|" options:0 metrics:metrics views:viewBindings]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_avatarImageView(buttonHeight)]-spacing-[_questTemplateImageView]|" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_noTemplateDivider(1)]|" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_inviteButtonBorder(buttonHeight)]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_inviteButton(buttonHeight)]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_shareButtonBorder(buttonHeight)]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_shareButton(buttonHeight)]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_moreOptionsButtonBorder(buttonHeight)]" options:0 metrics:metrics views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-spacing-[_moreOptionsButton(buttonHeight)]" options:0 metrics:metrics views:viewBindings]];

        self.attributionConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-usernameVerticalSpacing-[_usernameLabel]-1-[_descriptionLabel][_timestampLabel]" options:0 metrics:metrics views:viewBindings];
        [self addConstraints:self.attributionConstraints];

        // 1x1 size for avatar
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_avatarImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_avatarImageView attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f]];
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.usernameLabel.textColor = self.tintColor;
}

- (void)updateConstraints
{
    if (self.questTemplateImageView.hidden)
    {
        self.questTemplateImageHeightConstraint = [NSLayoutConstraint constraintWithItem:_questTemplateImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_questTemplateImageView attribute:NSLayoutAttributeWidth multiplier:0.0f constant:0.0f];
    }
    else
    {
        self.questTemplateImageHeightConstraint = [NSLayoutConstraint constraintWithItem:_questTemplateImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_questTemplateImageView attribute:NSLayoutAttributeWidth multiplier:0.75f constant:0.0f];
    }
    [self addConstraint:self.questTemplateImageHeightConstraint];

    [self removeConstraints:self.attributionConstraints];
    NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_usernameLabel, _descriptionLabel, _timestampLabel);
    NSDictionary *metrics = @{@"usernameVerticalSpacing": @(8)};
    if (self.hasAttributedAuthor)
    {
        self.attributionConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-usernameVerticalSpacing-[_descriptionLabel][_usernameLabel]-1-[_timestampLabel]" options:0 metrics:metrics views:viewBindings];
    }
    else
    {
        self.attributionConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-usernameVerticalSpacing-[_usernameLabel]-1-[_descriptionLabel][_timestampLabel]" options:0 metrics:metrics views:viewBindings];
    }
    [self addConstraints:self.attributionConstraints];

    [super updateConstraints];
}

#pragma mark -

- (void)setTemplateImageURL:(NSString *)imageURL
{
    if (imageURL)
    {
        self.noTemplateDivider.hidden = YES;
        self.questTemplateImageView.hidden = NO;
        self.questTemplateImageView.imageURL = imageURL;
    }
    else
    {
        self.noTemplateDivider.hidden = NO;
        self.questTemplateImageView.hidden = YES;
    }
    [self setNeedsUpdateConstraints];
}

- (void)questTemplateTapped:(id)sender
{
    if (self.showEditorBlock)
    {
        self.showEditorBlock();
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
