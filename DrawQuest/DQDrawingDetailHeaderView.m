//
//  DQDrawingDetailHeaderView.m
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQDrawingDetailHeaderView.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

// Views
#import "DQButton.h"
#import "DQPhoneFollowButton.h"
#import "DQPlaybackImageView.h"
#import "DQStarButton.h"
#import "DQTimestampView.h"

@interface DQDrawingDetailHeaderView ()

@property (nonatomic, strong) UIView *whiteSpaceView;
@property (nonatomic, strong) UIView *buttonsView;
@property (nonatomic, strong) DQButton *playButton;
@property (nonatomic, strong) DQButton *shareButton;
@property (nonatomic, strong) DQButton *moreOptionsButton;
@property (nonatomic, strong) DQButton *notesButton;
@property (nonatomic, strong) UIView *dividerOne;
@property (nonatomic, strong) UIView *dividerTwo;
@property (nonatomic, strong) UIView *dividerThree;
@property (nonatomic, strong) UIView *dividerFour;
@property (nonatomic, strong) UIView *headerWrapper;
@property (nonatomic, strong) UIView *footerWrapper;
@property (nonatomic, strong) UIImageView *disclosureImageView;
@property (nonatomic, strong) DQPhoneFollowButton *followButton;
@property (nonatomic, strong) UIView *usernameWrapper;

@end

@implementation DQDrawingDetailHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        __weak typeof(self) weakSelf = self;

        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.layer.shadowOpacity = 0.05f;
        self.layer.shadowRadius = 0.0f;

        _whiteSpaceView = [[UIView alloc] initWithFrame:CGRectZero];
        _whiteSpaceView.frameHeight = 1000.0f;
        _whiteSpaceView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_whiteSpaceView];

        _headerWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        _headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *profileTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showProfile:)];
        [_headerWrapper addGestureRecognizer:profileTapRecognizer];
        [self addSubview:_headerWrapper];

        _footerWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        _footerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_footerWrapper];

        _playbackImageView = [[DQPlaybackImageView alloc] initForCommentWithServerID:nil frame:CGRectZero];
        _playbackImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _playbackImageView.layer.borderWidth = 1.0f;
        _playbackImageView.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
        UITapGestureRecognizer *imageDoubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageDoubleTapped:)];
        imageDoubleTapRecognizer.numberOfTapsRequired = 2;
        [_playbackImageView addGestureRecognizer:imageDoubleTapRecognizer];
        UITapGestureRecognizer *imageTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [imageTapRecognizer requireGestureRecognizerToFail:imageDoubleTapRecognizer];
        [_playbackImageView addGestureRecognizer:imageTapRecognizer];
        UIPinchGestureRecognizer *imagePinchedRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(imagePinched:)];
        [_playbackImageView addGestureRecognizer:imagePinchedRecognizer];
        [self addSubview:_playbackImageView];

        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_headerWrapper addSubview:_avatarImageView];

        _usernameWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        _usernameWrapper.translatesAutoresizingMaskIntoConstraints = NO;
        [_headerWrapper addSubview:_usernameWrapper];

        _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.textColor = self.tintColor;
        _usernameLabel.font = [UIFont dq_listCellUsernameFont];
        [_usernameWrapper addSubview:_usernameLabel];

        _timestampView = [[DQTimestampView alloc] initWithFrame:CGRectZero];
        _timestampView.translatesAutoresizingMaskIntoConstraints = NO;
        _timestampView.tintColor = [UIColor dq_timestampColor];
        [_usernameWrapper addSubview:_timestampView];

        _disclosureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_phone"]];
        _disclosureImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_headerWrapper addSubview:_disclosureImageView];

        _followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectZero];
        _followButton.translatesAutoresizingMaskIntoConstraints = NO;
        _followButton.hidden = YES;
        [_headerWrapper addSubview:_followButton];

        _playButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                  selectedImage:[[UIImage imageNamed:@"button_pause"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _playButton.translatesAutoresizingMaskIntoConstraints = NO;
        _playButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _playButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.playbackButtonTappedBlock)
            {
                weakSelf.playbackButtonTappedBlock(weakSelf, button);
            }
        };
        _playButton.selectedBlock = ^(DQButton *button, BOOL isSelected) {
            button.tintColor = isSelected ? [UIColor dq_homeTabColor] : [UIColor dq_phoneButtonOffColor];
        };
        [_footerWrapper addSubview:_playButton];

        _starButton = [[DQStarButton alloc] init];
        _starButton.translatesAutoresizingMaskIntoConstraints = NO;
        _starButton.eventLoggingParameters = @{@"view:": @"phone_detail"};
        [_footerWrapper addSubview:_starButton];

        _shareButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_share"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _shareButton.translatesAutoresizingMaskIntoConstraints = NO;
        _shareButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _shareButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.shareButtonTappedBlock)
            {
                weakSelf.shareButtonTappedBlock(weakSelf);
            }
        };
        [_footerWrapper addSubview:_shareButton];

        _moreOptionsButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _moreOptionsButton.translatesAutoresizingMaskIntoConstraints = NO;
        _moreOptionsButton.tintColor = [UIColor dq_phoneButtonOffColor];
        _moreOptionsButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.moreOptionsSelectedBlock)
            {
                weakSelf.moreOptionsSelectedBlock();
            }
            else
            {
                @throw [NSException exceptionWithName:NSGenericException reason:@"DQDrawingDetailHeaderView: moreOptionsSelectedBlock was not provided." userInfo:nil];
            }
        };
        [_footerWrapper addSubview:_moreOptionsButton];

        _notesButton = [[DQButton alloc] initWithFrame:CGRectZero];
        _notesButton.translatesAutoresizingMaskIntoConstraints = NO;
        _notesButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _notesButton.titleLabel.minimumScaleFactor = 0.5f;
        _notesButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 3.0f, 0.0f, 3.0f);
        [_notesButton setTitleColor:[UIColor dq_phoneButtonOffColor] forState:UIControlStateNormal];
        _notesButton.titleLabel.font = [UIFont dq_listCellNotesFont];
        _notesButton.userInteractionEnabled = NO;
        [_footerWrapper addSubview:_notesButton];

        _dividerOne = [[UIView alloc] initWithFrame:CGRectZero];
        _dividerOne.translatesAutoresizingMaskIntoConstraints = NO;
        _dividerOne.backgroundColor = [UIColor dq_phoneDivider];
        [_footerWrapper addSubview:_dividerOne];

        _dividerTwo = [[UIView alloc] initWithFrame:CGRectZero];
        _dividerTwo.translatesAutoresizingMaskIntoConstraints = NO;
        _dividerTwo.backgroundColor = [UIColor dq_phoneDivider];
        [_footerWrapper addSubview:_dividerTwo];

        _dividerThree = [[UIView alloc] initWithFrame:CGRectZero];
        _dividerThree.translatesAutoresizingMaskIntoConstraints = NO;
        _dividerThree.backgroundColor = [UIColor dq_phoneDivider];
        [_footerWrapper addSubview:_dividerThree];

        _dividerFour = [[UIView alloc] initWithFrame:CGRectZero];
        _dividerFour.translatesAutoresizingMaskIntoConstraints = NO;
        _dividerFour.backgroundColor = [UIColor dq_phoneDivider];
        [_footerWrapper addSubview:_dividerFour];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_headerWrapper, _footerWrapper, _playbackImageView, _avatarImageView, _usernameWrapper, _usernameLabel, _timestampView, _disclosureImageView, _followButton, _playButton, _starButton, _shareButton, _moreOptionsButton, _notesButton, _dividerOne, _dividerTwo, _dividerThree, _dividerFour);
        NSDictionary *metrics = @{@"priority": @(UILayoutPriorityDefaultHigh), @"hInset": @(8), @"headerHeight": @(50), @"footerHeight": @(35), @"imageHeight":@(228), @"buttonWidth": @(55)};

        DQVisualConstraints(self, @"H:|-hInset@priority-[_headerWrapper]-hInset@priority-|");
        DQVisualConstraints(self, @"H:|-hInset@priority-[_playbackImageView]-hInset@priority-|");
        DQVisualConstraints(self, @"H:|[_footerWrapper]|");
        DQVisualConstraints(self, @"V:|[_headerWrapper(headerHeight)][_playbackImageView(imageHeight)]-6@priority-[_footerWrapper(footerHeight)]-6@priority-|");

        DQVisualConstraintsWithOptions(_headerWrapper, @"H:|[_avatarImageView]-8-[_usernameWrapper]", NSLayoutFormatAlignAllCenterY);
        DQVisualConstraints(_headerWrapper, @"H:[_disclosureImageView]-5-|");
        DQVisualConstraints(_headerWrapper, @"H:[_followButton(55)]|");
        DQVisualConstraints(_headerWrapper, @"V:[_followButton(29)]");
        DQVisualConstraints(_headerWrapper, @"V:|-8-[_avatarImageView]-5-|");

        DQVisualConstraints(_footerWrapper, @"H:|[_playButton(buttonWidth)][_dividerOne(1)][_starButton(buttonWidth)][_dividerTwo(1)][_shareButton(buttonWidth)][_dividerThree(1)][_moreOptionsButton(buttonWidth)][_dividerFour(1)][_notesButton]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_playButton]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_starButton]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_shareButton]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_moreOptionsButton]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_notesButton]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_dividerOne]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_dividerTwo]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_dividerThree]|");
        DQVisualConstraints(_footerWrapper, @"V:|[_dividerFour]|");

        DQVisualConstraints(_usernameWrapper, @"H:|[_usernameLabel]");
        DQVisualConstraints(_usernameWrapper, @"H:|[_timestampView]");
        DQVisualConstraints(_usernameWrapper, @"V:|[_usernameLabel][_timestampView]|");

        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_notesButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_dividerFour attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
        constraint.priority = UILayoutPriorityDefaultHigh;
        [_footerWrapper addConstraint:constraint];

        [_headerWrapper addConstraint:[NSLayoutConstraint constraintWithItem:_disclosureImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_avatarImageView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
        [_headerWrapper addConstraint:[NSLayoutConstraint constraintWithItem:_followButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_avatarImageView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];

        // 1 x 1 size for avatar
        [_headerWrapper addConstraint:[NSLayoutConstraint constraintWithItem:_avatarImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_avatarImageView attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f]];
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

    self.whiteSpaceView.frameWidth = self.frameWidth;
    self.whiteSpaceView.frameMaxY = 0.0f;
}

#pragma mark - 

- (void)showProfile:(id)sender
{
    if (self.showProfileBlock)
    {
        self.showProfileBlock();
    }
}

- (void)imageDoubleTapped:(id)sender
{
    [self.starButton star];
}

- (void)imageTapped:(id)sender
{
    if (self.imageTappedBlock)
    {
        self.imageTappedBlock(self);
    }
}

- (void)imagePinched:(UIPinchGestureRecognizer *)pinch
{
    if (pinch.state == UIGestureRecognizerStateBegan && self.imageTappedBlock)
    {
        self.imageTappedBlock(self);
    }
}

- (void)setNotesCount:(NSInteger)notesCount
{
    _notesCount = notesCount;
    if (notesCount == 1)
    {
        [self.notesButton setTitle:[NSString stringWithFormat:DQLocalizedString(@"%ld Note", @"Number of notes users have left on a drawing, singular count"), (long)notesCount] forState:UIControlStateNormal];
    }
    else
    {
        [self.notesButton setTitle:[NSString stringWithFormat:DQLocalizedString(@"%ld Notes", @"Number of notes users have left on a drawing, plural count"), (long)notesCount] forState:UIControlStateNormal];
    }
}

- (void)displayFollowButtonForUsername:(NSString *)username
{
    self.followButton.username = username;
    self.followButton.hidden = NO;
    self.disclosureImageView.hidden = YES;
}

@end
