//
//  DQGalleryCellTableHeader.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQGalleryCellTableHeader.h"

#import "DQImageView.h"
#import "DQCircularMaskImageView.h"
#import "DQButtonBar.h"
#import "DQComment.h"
#import "DQCommentUpload.h"
#import "DQUploadOverlay.h"
#import "STUtils.h"
#import "DQAccount.h"
#import "DQDataStoreController.h"
#import "DQStarButton.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

CGFloat DQGalleryCommentFooterViewAvatarWidth = 62.0;
CGFloat DQGalleryCommentFooterViewAvatarHeight = 50.0;
CGFloat DQGalleryCommentFooterViewAvatarPadding = 5.0;
CGFloat DQGalleryCommentFooterViewBorderStrokeWidth = 5.0;
CGFloat DQGalleryCommentFooterViewAvatarFrameWidth = 50.0f;

@interface DQGalleryCellTableHeader ()

@property (nonatomic, strong) DQImageView *drawingView;
@property (nonatomic, strong) UIView *dimmerView;
@property (nonatomic, strong) DQGalleryCommentFooterView *footerView;

@property (nonatomic, strong, readwrite) NSString *commentID;

@end


@interface DQGalleryCommentFooterView () <DQButtonBarDelegate, DQStarButtonDelegate>

@property (nonatomic, assign) BOOL isForUploadingState;

@property (nonatomic, strong) DQCircularMaskImageView *avatarView;

@property (nonatomic, strong) UIImageView *gradientImageView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *starCountLabel;
@property (nonatomic, strong) UILabel *playbackCountLabel;
@property (nonatomic, strong) UIImageView *playbackIconView;
@property (nonatomic, strong) UIImageView *starIconView;

@property (nonatomic, strong) DQButtonBar *buttonBar;
@property (nonatomic, strong) UIButton *playbackButton;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *flagButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *facebookButton;
@property (nonatomic, strong) UIButton *twitterButton;
@property (nonatomic, strong) UIButton *tumblrButton;
@property (nonatomic, strong) UIButton *cameraRollButton;


@end


@implementation DQGalleryCellTableHeader

@synthesize drawingView;
@synthesize footerView;
@synthesize commentID;

#pragma mark Initialization

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadProgressChangedNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.drawingView = [[DQImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.drawingView];
        
        self.uploadOverlay = [[DQUploadOverlay alloc] initWithFrame:CGRectZero];
        self.uploadOverlay.hidden = YES;
        [self.uploadOverlay.retryButton addTarget:self action:@selector(uploadOverlayRetryUploadTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.uploadOverlay.cancelButton addTarget:self action:@selector(uploadOverlayCancelUploadTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.uploadOverlay];
        
        self.dimmerView = [[UIView alloc] initWithFrame:self.bounds];
        self.dimmerView.userInteractionEnabled = NO;
        [self addSubview:self.dimmerView];
        self.dimmerView.hidden = YES;
        
        // Set up the footer view
        self.footerView = [[DQGalleryCommentFooterView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.footerView];
    }
    return self;
    
}


- (void)initializeWithComment:(DQComment *)inComment
{
    self.commentID = inComment.serverID;
    
    self.uploadOverlay.hidden = YES;
    
    self.footerView.isForUploadingState = NO;
    self.footerView.userName = inComment.authorName;
    self.footerView.starCount = [@(inComment.numberOfStars) description];
    self.footerView.playbackCount = [@(inComment.numberOfPlaybacks) description];
    
    self.drawingView.imageURL = [inComment imageURLForKey:DQImageKeyGallery];
    [self.footerView.avatarView setImageWithURL:inComment.authorAvatarURL placeholderImage:nil completionBlock:nil failureBlock:nil];
}

- (DQUploadOverlayState)uploadOverlayStateForCommentUpload:(DQCommentUpload *)cu
{
    DQUploadOverlayState result = DQUploadOverlayStateFailed;
    switch (cu.status)
    {
        case DQCommentUploadStatusUploadingImage:
            result = DQUploadOverlayStateUploadingImage;
            break;
        case DQCommentUploadStatusPostingComment:
            result = DQUploadOverlayStatePostingComment;
            break;
        case DQCommentUploadStatusUploadingPlaybackData:
            result = DQUploadOverlayStateUploadingPlaybackData;
            break;
        case DQCommentUploadStatusFailedNew:
            result = DQUploadOverlayStateFailedNew;
            break;
        case DQCommentUploadStatusFailedUploadingImage:
            result = DQUploadOverlayStateFailedUploadingImage;
            break;
        case DQCommentUploadStatusFailedPostingComment:
            result = DQUploadOverlayStateFailedPostingComment;
            break;
        case DQCommentUploadStatusFailedUploadingPlaybackData:
            result = DQUploadOverlayStateFailedUploadingPlaybackData;
            break;
        case DQCommentUploadStatusFailedWithInvalidFacebookToken:
            result = DQUploadOverlayStateFailedWithInvalidFacebookToken;
            break;
        case DQCommentUploadStatusFailedWithInvalidTwitterToken:
            result = DQUploadOverlayStateFailedWithInvalidTwitterToken;
            break;
        default:
            break;
    }
    return result;
}

- (void)initializeWithCommentUpload:(DQCommentUpload *)inCommentUpload loggedInUsername:(NSString *)loggedInUsername loggedInAvatarURL:(NSString *)loggedInAvatarURL
{
    self.commentUploadIdentifier = inCommentUpload.identifier;
    
    self.uploadOverlay.hidden = NO;

    self.uploadOverlay.state = [self uploadOverlayStateForCommentUpload:inCommentUpload];
    
    self.footerView.isForUploadingState = YES;
    self.footerView.userName = loggedInUsername;
    
    self.drawingView.image = inCommentUpload.image;
    
    self.footerView.avatarView.imageURL = loggedInAvatarURL;
    
    self.uploadOverlay.progressView.progress = [inCommentUpload.uploadProgress floatValue] / 100.0f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStatusChanged:) name:DQCommentUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:DQCommentUploadProgressChangedNotification object:nil];
}

#pragma mark - Actions

- (void)uploadOverlayRetryUploadTapped:(UIButton *)sender
{
    self.uploadOverlay.progressView.progress = 0.0;
    if (self.tappedRetryUploadButtonBlock)
    {
        self.tappedRetryUploadButtonBlock(sender);
    }
}

- (void)uploadOverlayCancelUploadTapped:(UIButton *)sender
{
    if (self.tappedCancelUploadButtonBlock)
    {
        self.tappedCancelUploadButtonBlock(sender);
    }
}

#pragma mark UITableViewCell

- (void)prepareForReuse
{
    self.uploadOverlay.hidden = YES;
    self.uploadOverlay.progressView.progress = 0.0;
    [self.footerView prepareForReuse];
    [self.drawingView prepareForReuse];
    
    self.uploadOverlay.progressView.progress = 0.0;
    self.tappedRetryUploadButtonBlock = nil;
    self.tappedCancelUploadButtonBlock = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadProgressChangedNotification object:nil];
}

#pragma mark Accessors

- (void)setDimmed:(BOOL)dimmed
{
    _dimmed = dimmed;
    [self bringSubviewToFront:self.dimmerView];
    
    self.dimmerView.hidden = !_dimmed;
}

#pragma mark -
#pragma mark Notifications

- (void)uploadStatusChanged:(NSNotification *)inNotification
{
    DQCommentUpload *commentUpload = [inNotification object];
    if (!commentUpload || ![self.commentUploadIdentifier isEqualToString:commentUpload.identifier]) {
        return;
    }

    self.uploadOverlay.state = [self uploadOverlayStateForCommentUpload:commentUpload];
}

- (void)updateProgress:(NSNotification *)inNotification
{
    DQCommentUpload *commentUpload = [[inNotification userInfo] objectForKey:DQCommentUploadObjectNotificationKey];
    if (!commentUpload || ![self.commentUploadIdentifier isEqualToString:commentUpload.identifier]) {
        return;
    }

    self.uploadOverlay.progressView.progress = commentUpload.uploadProgress ? [commentUpload.uploadProgress floatValue] / 100.0f : 0.0;
}

#pragma mark UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Lay out the dimmer view for showing unfocused state
    self.dimmerView.frame = self.bounds;
    
    // Lay out the image view
    CGRect imageFrame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 640, 480);
    self.drawingView.frame = imageFrame;
    
    // Lay out the upload overlay
    self.uploadOverlay.frame = self.drawingView.frame;
    
    // Lay out the footer view
    CGRect footerFrame = CGRectMake(CGRectGetMinX(imageFrame), 480, CGRectGetWidth(imageFrame), 72.0);
    self.footerView.frame = footerFrame;
    
    self.drawingView.layer.borderWidth = 1;
    self.drawingView.layer.borderColor = [UIColor colorWithRed:(218/255.0) green:(218/255.0) blue:(218/255.0) alpha:1].CGColor;
    self.frameHeight -= 7;
}

@end


@implementation DQGalleryCommentFooterView

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        // Set up the gradient image view
        self.gradientImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.gradientImageView.image = DQImageWithColor(DQColorGreen);
        [self addSubview:self.gradientImageView];
        
        // Set up the avatar frame
        self.avatarView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.avatarView];
        [self.avatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageOrUserNameTapped:)]];
        
        // Set up the user name label
        self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.userNameLabel.backgroundColor = [UIColor clearColor];
        self.userNameLabel.textColor = [UIColor whiteColor];
        self.userNameLabel.font = [UIFont dq_galleryFooterUsernameFont];
        self.userNameLabel.userInteractionEnabled = YES;
        [self addSubview:self.userNameLabel];
        [self.userNameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageOrUserNameTapped:)]];
        
        // Set up the star count label
        self.starCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.starCountLabel.backgroundColor = [UIColor clearColor];
        self.starCountLabel.textColor = [UIColor whiteColor];
        self.starCountLabel.font = [UIFont dq_galleryFooterStatsFont];
        self.starCountLabel.text = @"0";
        [self addSubview:self.starCountLabel];
        
        // set up the replay count label
        self.playbackCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.playbackCountLabel.backgroundColor = [UIColor clearColor];
        self.playbackCountLabel.textColor = [UIColor whiteColor];
        self.playbackCountLabel.font = [UIFont dq_galleryFooterStatsFont];
        self.playbackCountLabel.text = @"0";
        [self addSubview:self.playbackCountLabel];
        
        self.starIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_info_panel_star"]];
        [self addSubview:self.starIconView];
        
        self.playbackIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_info_panel_play"]];
        [self addSubview:self.playbackIconView];
        
        self.buttonBar = [[DQButtonBar alloc] initWithFrame:CGRectZero];
        self.buttonBar.delegate = self;
        
        // Actionable Buttons
        self.playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playbackButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.playbackButton setImage:[UIImage imageNamed:@"button_icon_play"] forState:UIControlStateNormal];
        self.playbackButton.layer.cornerRadius = 25;
        self.playbackButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.playbackButton.layer.borderWidth = 2;
        self.playbackButton.backgroundColor = [UIColor colorWithRed:(96 / 255.0) green:(227 / 255.0) blue:(182 / 255.0) alpha:1];
        [self.playbackButton addTarget:self action:@selector(playbackButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.actionButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.actionButton setImage:[UIImage imageNamed:@"button_icon_share"] forState:UIControlStateNormal];
        self.actionButton.layer.cornerRadius = 25;
        self.actionButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.actionButton.layer.borderWidth = 2;
        [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

        self.starButton = [[DQStarButton alloc] initWithNotStarredImage:[UIImage imageNamed:@"button_icon_star"]
                                                           starredImage:[UIImage imageNamed:@"button_icon_star_hit_yellow"]
                                                                   size:CGSizeMake(kDQButtonBarButtonSize, kDQButtonBarButtonSize)];
        
        self.starButton.delegate = self;
        self.starButton.layer.cornerRadius = 25;
        self.starButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.starButton.layer.borderWidth = 2;
        self.starButton.eventLoggingParameters = @{@"view:": @"pad_gallery"};

        self.flagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.flagButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.flagButton setImage:[UIImage imageNamed:@"button_icon_flag"] forState:UIControlStateNormal];
        [self.flagButton addTarget:self action:@selector(flagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.flagButton.layer.cornerRadius = 25;
        self.flagButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.flagButton.layer.borderWidth = 2;
        self.flagButton.backgroundColor = [UIColor dq_warningRed];
        
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.deleteButton setImage:[UIImage imageNamed:@"button_icon_trash"] forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(deleteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.deleteButton.layer.cornerRadius = 25;
        self.deleteButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.deleteButton.layer.borderWidth = 2;
        self.deleteButton.backgroundColor = [UIColor dq_warningRed];
        
        self.facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.facebookButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.facebookButton setImage:[UIImage imageNamed:@"button_icon_facebook"] forState:UIControlStateNormal];
        [self.facebookButton addTarget:self action:@selector(facebookButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.facebookButton.backgroundColor = [UIColor colorWithRed:(96 / 255.0) green:(227 / 255.0) blue:(182 / 255.0) alpha:1];
        self.facebookButton.layer.cornerRadius = 25;
        self.facebookButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.facebookButton.layer.borderWidth = 2;
    
        self.twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.twitterButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.twitterButton setImage:[UIImage imageNamed:@"button_icon_twitter"] forState:UIControlStateNormal];
        [self.twitterButton addTarget:self action:@selector(twitterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.twitterButton.layer.cornerRadius = 25;
        self.twitterButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.twitterButton.layer.borderWidth = 2;

        self.tumblrButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.tumblrButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.tumblrButton setImage:[UIImage imageNamed:@"button_icon_tumblr"] forState:UIControlStateNormal];
        [self.tumblrButton addTarget:self action:@selector(tumblrButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.tumblrButton.layer.cornerRadius = 25;
        self.tumblrButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.tumblrButton.layer.borderWidth = 2;

        self.cameraRollButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cameraRollButton.frame = CGRectMake(0.0f, 0.0f, kDQButtonBarButtonSize, kDQButtonBarButtonSize);
        [self.cameraRollButton setImage:[UIImage imageNamed:@"button_icon_camera"] forState:UIControlStateNormal];
        [self.cameraRollButton addTarget:self action:@selector(cameraRollButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.cameraRollButton.layer.cornerRadius = 25;
        self.cameraRollButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.cameraRollButton.layer.borderWidth = 2;

        self.buttonBar.buttons = @[self.playbackButton, self.actionButton, self.starButton];
        [self addSubview:self.buttonBar];
        
        _isForUploadingState = NO;
        [self updateForUploadingState];
    }
    return self;
}

- (void)starButtonValueChanged {
    if (self.starButton.starState == DQStarStateStarred)
        self.starButton.backgroundColor = [UIColor whiteColor];
    else
        self.starButton.backgroundColor = [UIColor clearColor];
}

#pragma mark Actions

- (void)avatarImageOrUserNameTapped:(UITapGestureRecognizer *)sender
{
    if (self.avatarImageOrUserNameTappedBlock) {
        self.avatarImageOrUserNameTappedBlock();
    }
}

- (void)playbackButtonTapped:(id)sender
{
    if (self.playbackButtonTappedBlock) {
        self.playbackButtonTappedBlock();
    }
}

- (void)flagButtonTapped:(id)sender
{
    if (self.flagButtonTappedBlock) {
        self.flagButtonTappedBlock();
    }
}

- (void)deleteButtonTapped:(id)sender
{
    if (self.deleteButtonTappedBlock) {
        self.deleteButtonTappedBlock();
    }
}

- (void)facebookButtonTapped:(id)sender
{
    if (self.facebookButtonTappedBlock) {
        self.facebookButtonTappedBlock();
    }
}

- (void)twitterButtonTapped:(id)sender
{
    if (self.twitterButtonTappedBlock) {
        self.twitterButtonTappedBlock();
    }
}

- (void)tumblrButtonTapped:(id)sender
{
    if (self.tumblrButtonTappedBlock) {
        self.tumblrButtonTappedBlock();
    }
}

- (void)cameraRollButtonTapped:(id)sender
{
    if (self.cameraRollButtonTappedBlock) {
        UIWindow *window = [self window];
        UIView *flash = [[UIView alloc] initWithFrame:window.bounds];
        flash.backgroundColor = [UIColor whiteColor];
        [window addSubview:flash];
        [UIView animateWithDuration:0.1 delay:0.02 options:UIViewAnimationOptionCurveEaseOut animations:^{
            flash.alpha = 0.0;
        } completion:^(BOOL finished) {
            [flash removeFromSuperview];
        }];
        self.cameraRollButtonTappedBlock(sender);
    }
}

#pragma mark UITableViewCell

- (void)prepareForReuse
{
    [self.avatarView prepareForReuse];
    [self.buttonBar hideActiveButtonGroup];
    
    self.playbackButtonTappedBlock = nil;
    self.flagButtonTappedBlock = nil;
    self.deleteButtonTappedBlock = nil;
    self.starButton.commentID = nil;
    self.facebookButtonTappedBlock = nil;
    self.twitterButtonTappedBlock = nil;
    self.tumblrButtonTappedBlock = nil;
    self.cameraRollButtonTappedBlock = nil;
    self.avatarImageOrUserNameTappedBlock = nil;
    self.shouldShowDeleteButtonBlock = nil;
}

#pragma mark Accessors

- (void)setIsForUploadingState:(BOOL)isForUploadingState
{
    _isForUploadingState = isForUploadingState;

    [self updateForUploadingState];
}

- (void)setUserName:(NSString *)inUserName;
{
    self.userNameLabel.text = inUserName;
    [self setNeedsLayout];
}

- (NSString *)userName
{
    return self.userNameLabel.text;
}

- (void)setStarCount:(NSString *)inStarCount
{
    self.starCountLabel.text = inStarCount;
    [self layoutCountLabels];
}

- (void)layoutCountLabels {
    CGFloat starCountWidth = [self.starCountLabel.text sizeWithAttributes:@{NSFontAttributeName: self.starCountLabel.font}].width;
    self.starIconView.center = CGPointMake(CGRectGetMinX(self.starCountLabel.frame) + starCountWidth + roundf(CGRectGetWidth(self.starIconView.frame) / 2) + 5.0f, self.starCountLabel.center.y);
    
	CGFloat playbackCountWidth = [self.playbackCountLabel.text sizeWithAttributes:@{NSFontAttributeName: self.playbackCountLabel.font}].width;

    self.playbackCountLabel.frame = (CGRect){.origin = CGPointMake(CGRectGetMaxX(self.starIconView.frame) + 10.0f, CGRectGetMinY(self.starCountLabel.frame)), .size = CGSizeMake(playbackCountWidth, self.playbackCountLabel.frame.size.height)};

    self.playbackIconView.center = CGPointMake(CGRectGetMinX(self.playbackCountLabel.frame) + playbackCountWidth + roundf(CGRectGetWidth(self.playbackIconView.frame) / 2) + 5.0f, self.playbackCountLabel.center.y);
}

- (NSString *)starCount
{
    return self.starCountLabel.text;
}

- (void)setPlaybackCount:(NSString *)inPlaybackCount
{
    self.playbackCountLabel.text = inPlaybackCount;
    [self layoutCountLabels];
}

- (NSString *)playbackCount
{
    return self.playbackCountLabel.text;
}

#pragma mark -
#pragma mark UI State

- (void)updateForUploadingState
{
    if (_isForUploadingState) {
        self.starButton.enabled = NO;
        self.actionButton.enabled = NO;
        self.playbackButton.enabled = NO;
    } else {
        self.starButton.enabled = YES;
        self.actionButton.enabled = YES;
        self.playbackButton.enabled = YES;
    }
}

#pragma mark -
#pragma mark DQButtonBarDelegate

- (BOOL)buttonBar:(DQButtonBar *)buttonBar shouldDiscloseButtonGroupAtIndex:(NSUInteger)index
{
    return (index == 1);
}

- (NSArray *)buttonBar:(DQButtonBar *)buttonBar buttonGroupAtIndex:(NSUInteger)index
{
    if (index != 1)
    {
        return nil;
    }

    BOOL shouldShowDeleteButtonInsteadOfFlagButton = self.shouldShowDeleteButtonBlock && self.shouldShowDeleteButtonBlock();
    return @[shouldShowDeleteButtonInsteadOfFlagButton ? self.deleteButton : self.flagButton, self.cameraRollButton, self.facebookButton, self.twitterButton, self.tumblrButton];
}

- (void)buttonBarDidClose {
    self.playbackButton.layer.opacity = 1;
    self.starButton.layer.opacity = 1;
}

#pragma mark -

- (void)actionButtonPressed:(id)sender
{
    if (self.buttonBar.isDisclosingButtonGroup) {
        [self.buttonBar hideActiveButtonGroup];
    } else {
        [self.buttonBar discloseButtonGroupAtIndex:1];
         self.playbackButton.layer.opacity = 0.5;
         self.starButton.layer.opacity = 0.5;
    }
}

#pragma mark UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    // Divide the footer between the avatar and the info and controls
    CGRect avatarContainer;
    CGRect controlsContainer;
    CGRectDivide(bounds, &avatarContainer, &controlsContainer, DQGalleryCommentFooterViewAvatarFrameWidth + 10.0f, CGRectMinXEdge);
    avatarContainer = CGRectInset(avatarContainer, 10.0f, 10.0f);
    avatarContainer.size.width += 10.0f;
    self.avatarView.frame = avatarContainer;
    self.gradientImageView.frame = bounds;
    
    // Subdivide the container for info and controls
    CGRect drawingInfoRect;
    CGRect controlsRect;
    CGRectDivide(CGRectInset(controlsContainer, 10.0f, 10.0f), &drawingInfoRect, &controlsRect, roundf(CGRectGetWidth(controlsContainer) / 3.75), CGRectMinXEdge);
    
    // Layout labels
    CGRect usernameLabelRect;
    CGRect statsRect;
    CGRectDivide(drawingInfoRect, &usernameLabelRect, &statsRect, 30.0f, CGRectMinYEdge);
    CGSize userNameSize = [self.userNameLabel.text sizeWithAttributes:@{NSFontAttributeName: self.userNameLabel.font}];
    self.userNameLabel.frame = CGRectMake(usernameLabelRect.origin.x, usernameLabelRect.origin.y, userNameSize.width, userNameSize.height);
    
    CGRect starsInfoRect;
    CGRect playbackInfoRect;
    CGRectDivide(statsRect, &starsInfoRect, &playbackInfoRect, roundf(CGRectGetWidth(statsRect) / 2), CGRectMinXEdge);
    
    CGRect starsLabelRect;
    CGRect starsIconRect;
    CGRectDivide(starsInfoRect, &starsIconRect, &starsLabelRect, self.starIconView.image.size.width, CGRectMaxXEdge);
    starsIconRect.size = self.starIconView.image.size;
    self.starIconView.frame = starsIconRect;
    self.starCountLabel.frame = starsLabelRect;
    
    // Position the star icon just to the right of the text
    CGFloat starCountWidth = [self.starCountLabel.text sizeWithAttributes:@{NSFontAttributeName: self.starCountLabel.font}].width;
    self.starIconView.center = CGPointMake(CGRectGetMinX(self.starCountLabel.frame) + starCountWidth + roundf(CGRectGetWidth(self.starIconView.frame) / 2) + 5.0f, self.starCountLabel.center.y);
    
    CGRect playbackLabelRect;
    CGRect playbackIconRect;
    CGRectDivide(playbackInfoRect, &playbackIconRect, &playbackLabelRect, self.playbackIconView.image.size.width, CGRectMaxXEdge);
    playbackIconRect.size = self.playbackIconView.image.size;
    self.playbackIconView.frame = playbackIconRect;
    self.playbackCountLabel.frame = playbackLabelRect;
    
    // Position the playback icon just to the right of the text
    CGFloat playbackCountWidth = [self.playbackCountLabel.text sizeWithAttributes:@{NSFontAttributeName: self.playbackCountLabel.font}].width;
    self.playbackIconView.center = CGPointMake(CGRectGetMinX(self.playbackCountLabel.frame) + playbackCountWidth + roundf(CGRectGetWidth(self.playbackIconView.frame) / 2) + 5.0f, self.playbackCountLabel.center.y);
    
    // Move the playback count label and icon just to the right of the stars elements
    self.playbackCountLabel.frame = (CGRect){.origin = CGPointMake(CGRectGetMaxX(self.starIconView.frame) + 10.0f, CGRectGetMinY(self.starCountLabel.frame)), .size = CGSizeMake(playbackCountWidth, self.playbackCountLabel.frame.size.height)};
    self.playbackIconView.center = CGPointMake(CGRectGetMaxX(self.playbackCountLabel.frame) + 10.0f, self.playbackCountLabel.center.y);
    
    // Layout controls
    self.buttonBar.frame = controlsRect;
}

@end
