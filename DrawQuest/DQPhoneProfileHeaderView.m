//
//  DQPhoneProfileHeaderView.m
//  DrawQuest
//
//  Created by David Mauro on 10/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneProfileHeaderView.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

// Views
#import "DQCircularMaskImageView.h"

NSString *const DQPhoneProfileHeaderViewSocialTypeFacebook = @"DQPhoneProfileHeaderViewSocialTypeFacebook";
NSString *const DQPhoneProfileHeaderViewSocialTypeTwitter = @"DQPhoneProfileHeaderViewSocialTypeTwitter";
NSString *const DQPhoneProfileHeaderViewSocialTypeDrawQuest = @"DQPhoneProfileHeaderViewSocialTypeDrawQuest";
NSString *const DQPhoneProfileHeaderViewSocialTypeTumblr = @"DQPhoneProfileHeaderViewSocialTypeTumblr";

@interface DQPhoneProfileHeaderView ()

@property (nonatomic, strong) UIView *informationView;
@property (nonatomic, strong) UIView *linksView;
@property (nonatomic, strong) UIView *followOrCoinsView;
@property (nonatomic, strong) UIView *socialView;
@property (nonatomic, strong) UIView *horizontalDivider;
@property (nonatomic, strong) UIView *verticalDivider;

@property (nonatomic, strong) NSDictionary *socialImagesByType;
@property (nonatomic, strong) NSMutableDictionary *socialButtonsByType;

@end

@implementation DQPhoneProfileHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];

        _informationView = [[UIView alloc] initWithFrame:CGRectZero];
        _informationView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_informationView];

        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_informationView addSubview:_avatarImageView];

        _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.textColor = self.tintColor;
        _usernameLabel.font = [UIFont dq_phoneProfileUsernameFont];
        [_informationView addSubview:_usernameLabel];

        _bioLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _bioLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _bioLabel.textColor = [UIColor dq_phoneGrayTextColor];
        _bioLabel.font = [UIFont dq_phoneProfileBioFont];
        _bioLabel.numberOfLines = 7;
        [_informationView addSubview:_bioLabel];

        _horizontalDivider = [[UIView alloc] initWithFrame:CGRectZero];
        _horizontalDivider.translatesAutoresizingMaskIntoConstraints = NO;
        _horizontalDivider.backgroundColor = [UIColor dq_phoneDivider];
        [self addSubview:_horizontalDivider];

        _linksView = [[UIView alloc] initWithFrame:CGRectZero];
        _linksView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_linksView];

        _followOrCoinsView = [[UIView alloc] initWithFrame:CGRectZero];
        _followOrCoinsView.translatesAutoresizingMaskIntoConstraints = NO;
        [_linksView addSubview:_followOrCoinsView];

        _coinsLabel = [[DQPhoneCoinsLabel alloc] initWithFrame:CGRectZero];
        _coinsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _coinsLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapCoinsRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(coinsLabelTapped:)];
        [_coinsLabel addGestureRecognizer:tapCoinsRecognizer];
        [_followOrCoinsView addSubview:_coinsLabel];

        // Non-interactive temp button
        _followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectZero];
        _followButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_followOrCoinsView addSubview:_followButton];

        _verticalDivider = [[UIView alloc] initWithFrame:CGRectZero];
        _verticalDivider.translatesAutoresizingMaskIntoConstraints = NO;
        _verticalDivider.backgroundColor = [UIColor dq_phoneDivider];
        [_linksView addSubview:_verticalDivider];

        _socialView = [[UIView alloc] initWithFrame:CGRectZero];
        _socialView.translatesAutoresizingMaskIntoConstraints = NO;
        [_linksView addSubview:_socialView];

        _socialImagesByType = @{DQPhoneProfileHeaderViewSocialTypeDrawQuest: [[UIImage imageNamed:@"icon_socialProfile_DrawQuest"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                                DQPhoneProfileHeaderViewSocialTypeFacebook: [[UIImage imageNamed:@"icon_socialProfile_facebook"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                                DQPhoneProfileHeaderViewSocialTypeTwitter: [[UIImage imageNamed:@"icon_socialProfile_twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]/*,
                                DQPhoneProfileHeaderViewSocialTypeTumblr: [[UIImage imageNamed:@"icon_socialProfile_tumblr"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],*/
                                }; // FIXME: make this static

        _socialButtonsByType = [NSMutableDictionary new];

        // Layout
#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]
        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_informationView, _avatarImageView, _usernameLabel, _bioLabel, _horizontalDivider, _linksView, _followOrCoinsView, _coinsLabel, _followButton, _verticalDivider, _socialView);
        NSDictionary *metrics = @{@"priority": @(UILayoutPriorityDefaultHigh), @"padding": @(11), @"avatarWidth": @(110), @"followOrCoinsWidth": @(138), @"linksViewHeight": @(32 + 11), @"followButtonHeight": @(29)};

        DQVisualConstraints(self, @"H:|[_informationView]|");
        DQVisualConstraints(self, @"H:|[_linksView]|");
        DQVisualConstraints(self, @"H:|-padding@priority-[_horizontalDivider]|");
        DQVisualConstraints(self, @"V:|[_informationView][_horizontalDivider(1@priority)][_linksView(linksViewHeight@priority)]|");

        DQVisualConstraints(_informationView, @"H:|-padding@priority-[_avatarImageView(avatarWidth@priority)]-padding@priority-[_usernameLabel]-padding@priority-|");
        DQVisualConstraints(_informationView, @"H:[_avatarImageView]-padding@priority-[_bioLabel]-padding-|");
        DQVisualConstraints(_informationView, @"V:|-padding@priority-[_avatarImageView]-padding@priority-|");
        DQVisualConstraints(_informationView, @"V:|-padding@priority-[_usernameLabel]-3@priority-[_bioLabel]");

        DQVisualConstraints(_linksView, @"H:|[_followOrCoinsView(followOrCoinsWidth@priority)][_verticalDivider(1@priority)][_socialView]|");
        DQVisualConstraints(_linksView, @"V:|[_followOrCoinsView]|");
        DQVisualConstraints(_linksView, @"V:|[_socialView]|");
        DQVisualConstraints(_linksView, @"V:|-padding@priority-[_verticalDivider]|");

        DQVisualConstraints(_followOrCoinsView, @"H:|-padding@priority-[_followButton]-padding@priority-|");
        DQVisualConstraints(_followOrCoinsView, @"V:|-padding@priority-[_followButton(followButtonHeight@priority)]");

        [_followOrCoinsView addConstraint:[NSLayoutConstraint constraintWithItem:_coinsLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_coinsLabel.superview attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
        [_followOrCoinsView addConstraint:[NSLayoutConstraint constraintWithItem:_coinsLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_coinsLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:5.0f]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:_avatarImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_avatarImageView attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.usernameLabel.textColor = self.tintColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    DQButton *lastButton = nil;
    NSMutableArray *activeButtons = [NSMutableArray new];
    NSMutableArray *inactiveButtons = [NSMutableArray new];

    for (NSString *type in @[DQPhoneProfileHeaderViewSocialTypeDrawQuest,
                             DQPhoneProfileHeaderViewSocialTypeFacebook,
                             DQPhoneProfileHeaderViewSocialTypeTwitter/*,
                             DQPhoneProfileHeaderViewSocialTypeTumblr*/])
    {
        DQButton *button = self.socialButtonsByType[type];
        if (button)
        {
            [(button.tag ? activeButtons : inactiveButtons) addObject:button];
        }
    }
    [activeButtons addObjectsFromArray:inactiveButtons];
    for (DQButton *button in activeButtons)
    {
        button.frameX = lastButton.frameMaxX + 11.0f;
        button.frameY = 11.0f;
        lastButton = button;
    }
}

#pragma mark -

- (void)coinsLabelTapped:(id)sender
{
    if (self.showShopBlock)
    {
        self.showShopBlock(self);
    }
}

- (void)setURL:(NSString *)inURL forSocialType:(NSString *const)inType showWhenInactive:(BOOL)showWhenInactive
{
    [self.socialButtonsByType[inType] removeFromSuperview];
    [self.socialButtonsByType removeObjectForKey:inType];
    if (inURL)
    {
        DQButton *button = [DQButton buttonWithImage:self.socialImagesByType[inType]];
        button.tag = 1;
        self.socialButtonsByType[inType] = button;
        button.tappedBlock = ^(DQButton *button) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:inURL]];
        };
        [self.socialView addSubview:button];
    }
    else if (showWhenInactive)
    {
        DQButton *button = [DQButton buttonWithImage:self.socialImagesByType[inType]];
        button.tag = 0;
        button.tintColor = [UIColor dq_phoneProfileSocialLinkInactiveButtonColor];
        self.socialButtonsByType[inType] = button;
        button.tappedBlock = nil; // FIXME: implement
        [self.socialView addSubview:button];
    }
    [self setNeedsLayout];
}

- (void)displayFollowButton:(BOOL)displayFollowButton forUsername:(NSString *)username
{
    self.followButton.hidden = !displayFollowButton;
    self.coinsLabel.hidden = displayFollowButton;

    if (displayFollowButton)
    {
        self.followButton.username = username;
    }
}

@end
