//
//  DQCollectionViewUploadCell.m
//  DrawQuest
//
//  Created by David Mauro on 10/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCollectionViewUploadCell.h"
#import "DQDataStoreController.h"
#import "DQButton.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

typedef NS_ENUM(NSUInteger, DQCollectionViewUploadCellState) {
    DQCollectionViewUploadCellStateFailed,
    DQCollectionViewUploadCellStateUploadingImage,
    DQCollectionViewUploadCellStatePostingComment,
    DQCollectionViewUploadCellStateUploadingPlaybackData,
    DQCollectionViewUploadCellStateFailedNew,
    DQCollectionViewUploadCellStateFailedUploadingImage,
    DQCollectionViewUploadCellStateFailedPostingComment,
    DQCollectionViewUploadCellStateFailedUploadingPlaybackData,
    DQCollectionViewUploadCellStateFailedWithInvalidFacebookToken,
    DQCollectionViewUploadCellStateFailedWithInvalidTwitterToken
};

@interface DQCollectionViewUploadCell ()

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIView *failViewWrapper;
@property (nonatomic, strong) DQButton *retryButton;
@property (nonatomic, strong) DQButton *cancelButton;
@property (nonatomic, strong) UILabel *errorMessageLabel;
@property (nonatomic, strong) UIView *buttonDivider;
@property (nonatomic, strong) NSString *commentUploadIdentifier;
@property (nonatomic, assign) DQCollectionViewUploadCellState state;

@end

@implementation DQCollectionViewUploadCell

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadProgressChangedNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        __weak typeof(self) weakSelf = self;

        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.layer.borderColor = [[UIColor dq_drawingThumbStrokeColor] CGColor];
        _imageView.layer.borderWidth = 0.5f;
        [self addSubview:_imageView];

        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.progressTintColor = self.tintColor;
        _progressView.clipsToBounds = YES;
        [self addSubview:_progressView];

        _failViewWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        _failViewWrapper.translatesAutoresizingMaskIntoConstraints = NO;
        _failViewWrapper.hidden = YES;
        [self addSubview:_failViewWrapper];

        _retryButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_retry"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _retryButton.translatesAutoresizingMaskIntoConstraints = NO;
        _retryButton.tappedBlock = ^(DQButton *button) {
            [weakSelf.progressView setProgress:0.0f animated:NO];
            if (weakSelf.retryButtonTappedBlock)
            {
                weakSelf.retryButtonTappedBlock(button);
            }
        };
        [_failViewWrapper addSubview:_retryButton];

        _cancelButton = [DQButton buttonWithImage:[[UIImage imageNamed:@"button_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        _cancelButton.tappedBlock = ^(DQButton *button) {
            if (weakSelf.cancelButtonTappedBlock)
            {
                weakSelf.cancelButtonTappedBlock(button);
            }
        };
        [_failViewWrapper addSubview:_cancelButton];

        _errorMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _errorMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _errorMessageLabel.font = [UIFont dq_gridCellErrorFont];
        _errorMessageLabel.textColor = [UIColor dq_modalPrimaryTextColor];
        _errorMessageLabel.numberOfLines = 4;
        _errorMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        [_failViewWrapper addSubview:_errorMessageLabel];

        _buttonDivider = [[UIView alloc] initWithFrame:CGRectZero];
        _buttonDivider.translatesAutoresizingMaskIntoConstraints = NO;
        _buttonDivider.backgroundColor = [UIColor dq_drawingThumbStrokeColor];
        [_failViewWrapper addSubview:_buttonDivider];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_imageView, _progressView, _failViewWrapper, _retryButton, _cancelButton, _errorMessageLabel, _buttonDivider);
        NSDictionary *metrics = @{@"buttonHeight": @(35), @"buttonWidth": @(43)};

        DQVisualConstraintsWithOptions(self, @"H:|[_imageView]-[_progressView]-|", NSLayoutFormatAlignAllCenterY);
        DQVisualConstraintsWithOptions(self, @"H:|[_imageView]-[_failViewWrapper]|", NSLayoutFormatAlignAllCenterY);
        DQVisualConstraints(self, @"V:|[_imageView]|");
        DQVisualConstraints(self, @"V:[_failViewWrapper(buttonHeight)]");
        DQVisualConstraints(self, @"V:[_progressView]");

        DQVisualConstraintsWithOptions(_failViewWrapper, @"H:|[_errorMessageLabel][_retryButton(buttonWidth)][_buttonDivider(1)][_cancelButton(buttonWidth)]|", NSLayoutFormatAlignAllCenterY);
        DQVisualConstraints(_failViewWrapper, @"V:|[_retryButton]|");
        DQVisualConstraints(_failViewWrapper, @"V:|[_cancelButton]|");
        DQVisualConstraints(_failViewWrapper, @"V:|[_buttonDivider]|");

        // 4 x 3 size for imageView
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_imageView attribute:NSLayoutAttributeHeight multiplier:4.0f/3.0f constant:0.0f]];
#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)prepareForReuse
{
    self.imageView.image = nil;
    self.retryButtonTappedBlock = nil;
    self.cancelButtonTappedBlock = nil;
    [self.progressView setProgress:0.0f animated:NO];
    self.progressView.hidden = NO;
    self.failViewWrapper.hidden = YES;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQCommentUploadProgressChangedNotification object:nil];
    [super prepareForReuse];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.progressView.progressTintColor = self.tintColor;
}

#pragma mark - Public

- (void)initializeWithCommentUpload:(DQCommentUpload *)inCommentUpload
{
    self.commentUploadIdentifier = inCommentUpload.identifier;
    self.imageView.image = inCommentUpload.image;
    [self setProgress:([inCommentUpload.uploadProgress floatValue] / 100.0f) animated:NO];
    [self setStateForCommentUploadStatus:inCommentUpload.status];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStatusChanged:) name:DQCommentUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:DQCommentUploadProgressChangedNotification object:nil];
}

#pragma mark -

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    self.failViewWrapper.hidden = YES;
    self.progressView.hidden = NO;
    [self.progressView setProgress:progress animated:animated];
}

- (BOOL)isUploading
{
    DQCollectionViewUploadCellState s = self.state;
    return ((s == DQCollectionViewUploadCellStateUploadingImage) ||
            (s == DQCollectionViewUploadCellStatePostingComment) ||
            (s == DQCollectionViewUploadCellStateUploadingPlaybackData));
}

- (void)setStateForCommentUploadStatus:(DQCommentUploadStatus)status
{
    DQCollectionViewUploadCellState result = DQCollectionViewUploadCellStateFailed;
    switch (status)
    {
        case DQCommentUploadStatusUploadingImage:
            result = DQCollectionViewUploadCellStateUploadingImage;
            break;
        case DQCommentUploadStatusPostingComment:
            result = DQCollectionViewUploadCellStatePostingComment;
            break;
        case DQCommentUploadStatusUploadingPlaybackData:
            result = DQCollectionViewUploadCellStateUploadingPlaybackData;
            break;
        case DQCommentUploadStatusFailedNew:
            result = DQCollectionViewUploadCellStateFailedNew;
            break;
        case DQCommentUploadStatusFailedUploadingImage:
            result = DQCollectionViewUploadCellStateFailedUploadingImage;
            break;
        case DQCommentUploadStatusFailedPostingComment:
            result = DQCollectionViewUploadCellStateFailedPostingComment;
            break;
        case DQCommentUploadStatusFailedUploadingPlaybackData:
            result = DQCollectionViewUploadCellStateFailedUploadingPlaybackData;
            break;
        case DQCommentUploadStatusFailedWithInvalidFacebookToken:
            result = DQCollectionViewUploadCellStateFailedWithInvalidFacebookToken;
            break;
        case DQCommentUploadStatusFailedWithInvalidTwitterToken:
            result = DQCollectionViewUploadCellStateFailedWithInvalidTwitterToken;
            break;
        default:
            break;
    }
    self.state = result;
    [self configureInterfaceForCurrentState];
}

- (void)configureInterfaceForCurrentState
{
    BOOL uploading = [self isUploading];
    self.failViewWrapper.hidden = uploading;
    self.progressView.hidden = !uploading;
    NSString *text = nil;
    switch (self.state)
    {
        case DQCollectionViewUploadCellStateUploadingImage:
            text = DQLocalizedString(@"Posting Image...", @"User should wait as the image is uploading");
            break;
        case DQCollectionViewUploadCellStatePostingComment:
            text = DQLocalizedString(@"Posting to Quest...", @"User should wait as the comment is uploading");
            break;
        case DQCollectionViewUploadCellStateUploadingPlaybackData:
            text = DQLocalizedString(@"Posting Playback Data...", @"User should wait as the playback data is uploading");
            break;
        case DQCollectionViewUploadCellStateFailedUploadingImage:
            text = DQLocalizedString(@"Posting Image Failed.\nTry Again?", @"Image upload failed message");
            break;
        case DQCollectionViewUploadCellStateFailedPostingComment:
            text = DQLocalizedString(@"Posting to Quest Failed.\nTry Again?", @"Comment upload failed message");
            break;
        case DQCollectionViewUploadCellStateFailedUploadingPlaybackData:
            text = DQLocalizedString(@"Posting Playback Data Failed.\nTry Again?", @"Playback data upload failed message");
            break;
        case DQCollectionViewUploadCellStateFailedWithInvalidFacebookToken:
            text = DQLocalizedString(@"Posting to Facebook Failed.\nTry Again?", @"Upload to Facebook failed message");
            break;
        case DQCollectionViewUploadCellStateFailedWithInvalidTwitterToken:
            text = DQLocalizedString(@"Posting to Twitter Failed.\nTry Again?", @"Upload to Twitter failed message");
            break;
        default:
            text = DQLocalizedString(@"Upload Failed. Try Again?", @"Upload failed message");
            break;
    }
    self.errorMessageLabel.text = text;
    [self setNeedsLayout];
}

#pragma mark - Actions

- (void)updateProgress:(NSNotification *)notification
{
    DQCommentUpload *commentUpload = [[notification userInfo] objectForKey:DQCommentUploadObjectNotificationKey];
    if (commentUpload && [self.commentUploadIdentifier isEqualToString:commentUpload.identifier]) {
        [self setProgress:(commentUpload.uploadProgress ? [commentUpload.uploadProgress floatValue] / 100.0f : 0.0) animated:YES];
    }
}

- (void)uploadStatusChanged:(NSNotification *)inNotification
{
    DQCommentUpload *commentUpload = [inNotification object];
    if (commentUpload && [self.commentUploadIdentifier isEqualToString:commentUpload.identifier]) {
        [self setStateForCommentUploadStatus:commentUpload.status];
    }
}

@end
