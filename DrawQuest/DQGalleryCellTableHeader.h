//
//  DQGalleryCellTableHeader.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQGalleryCommentFooterView;
@class DQComment;
@class DQCommentUpload;
@class DQUploadOverlay;
@class DQImageView;
@class DQStarButton;
@class DQCircularMaskImageView;

@interface DQGalleryCellTableHeader : UIView

@property (nonatomic, strong, readonly) DQCircularMaskImageView *avatarView;
@property (nonatomic, strong, readonly) DQImageView *drawingView;
@property (nonatomic, strong, readonly) DQGalleryCommentFooterView *footerView;
@property (nonatomic, strong) DQUploadOverlay *uploadOverlay;
@property (nonatomic, assign, getter = isDimmed) BOOL dimmed;
@property (nonatomic, strong, readonly) NSString *commentID;
@property (nonatomic, strong) NSString *commentUploadIdentifier;
@property (nonatomic, copy) void (^tappedRetryUploadButtonBlock)(UIButton *sender);
@property (nonatomic, copy) void (^tappedCancelUploadButtonBlock)(UIButton *sender);

- (void)initializeWithComment:(DQComment *)inComment;
- (void)initializeWithCommentUpload:(DQCommentUpload *)inCommentUpload loggedInUsername:(NSString *)loggedInUsername loggedInAvatarURL:(NSString *)loggedInAvatarURL;
- (void)prepareForReuse;
@end


@interface DQGalleryCommentFooterView : UIView

@property (nonatomic, strong, readonly) DQCircularMaskImageView *avatarView;
@property (nonatomic, strong, readonly) UILabel *userNameLabel;
@property (nonatomic, strong) DQStarButton *starButton;

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *starCount;
@property (nonatomic, strong) NSString *playbackCount;
@property (nonatomic, copy) dispatch_block_t playbackButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t flagButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t deleteButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t starButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t facebookButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t twitterButtonTappedBlock;
@property (nonatomic, copy) dispatch_block_t tumblrButtonTappedBlock;
@property (nonatomic, copy) void (^cameraRollButtonTappedBlock)(UIView *view);
@property (nonatomic, copy) dispatch_block_t avatarImageOrUserNameTappedBlock;
@property (nonatomic, copy) BOOL (^shouldShowDeleteButtonBlock)(void);
@property (nonatomic, copy) BOOL (^shouldShowCameraButtonBlock)(void);

- (void)prepareForReuse;

@end
