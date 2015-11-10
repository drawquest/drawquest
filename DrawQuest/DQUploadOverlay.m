//
//  DQUploadOverlay.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/26/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQUploadOverlay.h"

#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQUploadOverlay()

@property (strong, nonatomic) UILabel *uploadingLabel;
@property (strong, nonatomic) UIView *backgroundView;

@end

@implementation DQUploadOverlay

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];

    _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 403.0f, 159.0f)];
    _backgroundView.layer.cornerRadius = 10.0f;
    _backgroundView.backgroundColor = [UIColor dq_greenColor];
    [self addSubview:_backgroundView];

    _uploadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _uploadingLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:24.0f];
    _uploadingLabel.textColor = [UIColor whiteColor];
    _uploadingLabel.text = DQLocalizedString(@"Uploading", @"Data is uploading to server indicator label");
    [_uploadingLabel sizeToFit];
    [self.backgroundView addSubview:_uploadingLabel];
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
    _progressView.trackTintColor = [UIColor whiteColor];
    _progressView.progressTintColor = [UIColor dq_blueColor];
    [self.backgroundView  addSubview:_progressView];
    
    _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_retryButton setImage:[UIImage imageNamed:@"button_refresh_light"] forState:UIControlStateNormal];
    _retryButton.frame = (CGRect){.size = [_retryButton imageForState:UIControlStateNormal].size};
    [self.backgroundView  addSubview:_retryButton];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setImage:[UIImage imageNamed:@"button_icon_close"] forState:UIControlStateNormal];
    _cancelButton.frame = (CGRect){.size = [_cancelButton imageForState:UIControlStateNormal].size};
    [self.backgroundView  addSubview:_cancelButton];
    
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.numberOfLines = 0;
    _statusLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    _statusLabel.minimumScaleFactor = 8.0/14.0;
    _statusLabel.adjustsFontSizeToFitWidth = YES;
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.text = DQLocalizedString(@"Upload Failed. Try Again?", @"Upload failed message");
    [self.backgroundView addSubview:_statusLabel];
    
    _state = DQUploadOverlayStateFailed;
    [self configureInterfaceForCurrentState];
    
    return self;
}

#pragma mark - Accessors

- (void)setState:(DQUploadOverlayState)state
{
    _state = state;
    [self configureInterfaceForCurrentState];
}

#pragma mark - Configuration

- (BOOL)isUploading
{
    DQUploadOverlayState s = self.state;
    return ((s == DQUploadOverlayStateUploadingImage) ||
            (s == DQUploadOverlayStatePostingComment) ||
            (s == DQUploadOverlayStateUploadingPlaybackData));
}

- (void)configureInterfaceForCurrentState
{
    BOOL uploading = [self isUploading];
    self.retryButton.hidden = uploading;
    self.cancelButton.hidden = uploading;
    self.progressView.hidden = !uploading;
    NSString *text = nil;
    switch (self.state)
    {
        case DQUploadOverlayStateUploadingImage:
            text = DQLocalizedString(@"Posting Image...", @"User should wait as the image is uploading");
            break;
        case DQUploadOverlayStatePostingComment:
            text = DQLocalizedString(@"Posting to Quest...", @"User should wait as the comment is uploading");
            break;
        case DQUploadOverlayStateUploadingPlaybackData:
            text = DQLocalizedString(@"Posting Playback Data...", @"User should wait as the playback data is uploading");
            break;
        case DQUploadOverlayStateFailedUploadingImage:
            text = DQLocalizedString(@"Posting Image Failed.\nTry Again?", @"Image upload failed message");
            break;
        case DQUploadOverlayStateFailedPostingComment:
            text = DQLocalizedString(@"Posting to Quest Failed.\nTry Again?", @"Comment upload failed message");
            break;
        case DQUploadOverlayStateFailedUploadingPlaybackData:
            text = DQLocalizedString(@"Posting Playback Data Failed.\nTry Again?", @"Playback data upload failed message");
            break;
        case DQUploadOverlayStateFailedWithInvalidFacebookToken:
            text = DQLocalizedString(@"Posting to Facebook Failed.\nTry Again?", @"Upload to Facebook failed message");
            break;
        case DQUploadOverlayStateFailedWithInvalidTwitterToken:
            text = DQLocalizedString(@"Posting to Twitter Failed.\nTry Again?", @"Upload to Twitter failed message");
            break;
        default:
            text = DQLocalizedString(@"Upload Failed. Try Again?", @"Upload failed message");
            break;
    }
    self.statusLabel.text = text;
    [self setNeedsLayout];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    self.backgroundView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    CGRect contentBounds = self.backgroundView.bounds;

    [self.uploadingLabel sizeToFit];
    self.uploadingLabel.center = CGPointMake(CGRectGetMidX(contentBounds), CGRectGetMinY(contentBounds) + self.uploadingLabel.frame.size.height + 10.0f);
    
    self.progressView.frame = (CGRect){.size = CGSizeMake(200.0f, 20.0f)};
    self.progressView.center = CGPointMake(CGRectGetMidX(contentBounds), CGRectGetMaxY(self.uploadingLabel.frame) + 25.0f);
    
    self.cancelButton.center = CGPointMake(CGRectGetMaxX(contentBounds) - (CGRectGetWidth(self.cancelButton.frame) + 40.0f), self.progressView.center.y);
    self.retryButton.center = CGPointMake(CGRectGetMinX(self.cancelButton.frame) - (roundf(CGRectGetWidth(self.cancelButton.frame) / 2) + 5.0f), self.cancelButton.center.y);

    BOOL uploading = [self isUploading];
    if (uploading)
    {
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        self.statusLabel.boundsSize = CGSizeMake(250.0f, 18.0f);
        self.statusLabel.frameCenterX = self.statusLabel.superview.boundsCenterX;
        self.statusLabel.frameY = self.progressView.frameMaxY + 8.0f;
    }
    else
    {
        self.statusLabel.textAlignment = NSTextAlignmentLeft;
        self.statusLabel.boundsSize = CGSizeMake(250.0f, 40.0f);
        self.statusLabel.frameX = 40.0f;
        self.statusLabel.frameCenterY = self.cancelButton.frameCenterY;
    }
}

@end
