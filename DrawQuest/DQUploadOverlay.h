//
//  DQUploadOverlay.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/26/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DQUploadOverlayState) {
    DQUploadOverlayStateFailed,
    DQUploadOverlayStateUploadingImage,
    DQUploadOverlayStatePostingComment,
    DQUploadOverlayStateUploadingPlaybackData,
    DQUploadOverlayStateFailedNew,
    DQUploadOverlayStateFailedUploadingImage,
    DQUploadOverlayStateFailedPostingComment,
    DQUploadOverlayStateFailedUploadingPlaybackData,
    DQUploadOverlayStateFailedWithInvalidFacebookToken,
    DQUploadOverlayStateFailedWithInvalidTwitterToken
};

@interface DQUploadOverlay : UIView

@property (nonatomic, assign) DQUploadOverlayState state;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIButton *retryButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UILabel *statusLabel;

@end
