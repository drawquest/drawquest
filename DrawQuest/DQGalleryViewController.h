//
//  DQGalleryViewController.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/3/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"

@class DQHTTPRequest;

@class DQModelObject;
@class DQQuest;
@class DQComment;
@class DQCommentUpload;
@class DQPlaybackDataManager;
@class DQSharingController;

typedef enum {
    DQGalleryStateStart,
    DQGalleryStateCommentUploadsLoaded,
    DQGalleryStateViewLoaded,
    DQGalleryStateDisplayingLoadingView,
    DQGalleryStateDisplayingRetryView,
    DQGalleryStateDisplayingNotFoundErrorView,
    DQGalleryStateDisplayingSparseView,
    DQGalleryStateDisplayingGalleryWithCommentUploads,

    DQGalleryStatePublishingStart,
    DQGalleryStatePublishingCommentUploadsLoaded,
    DQGalleryStatePublishingViewLoaded,
    DQGalleryStatePublishingDisplayingCommentUploads,
    DQGalleryStatePublishingDisplayingCommentUploadsLoadingGallery
} DQGalleryState;

typedef enum {
    DQGalleryTransitionLoadCommentUploads,
    DQGalleryTransitionLoadView,
    DQGalleryTransitionLoadGallery,
    DQGalleryTransitionLoadGallerySucceeded,
    DQGalleryTransitionLoadGalleryNotFound,
    DQGalleryTransitionLoadGalleryFailed,
    DQGalleryTransitionUnloadView
} DQGalleryTransition;

@interface DQGalleryViewController : DQViewController

@property (nonatomic, readonly, copy) NSString *questID;
@property (nonatomic, readwrite, copy) NSString *focusedCommentID;
@property (nonatomic, strong) DQPlaybackDataManager *playbackDataManager;
@property (nonatomic, readonly, copy) NSString *source;

@property (nonatomic, weak) UIView *loadingView;

@property (nonatomic, copy) void (^galleryViewControllerFirstTimeViewDidAppearBlock)(DQGalleryViewController *galleryViewController);
@property (nonatomic, copy) void (^displayProfileForUserNameBlock)(DQGalleryViewController *galleryViewController, NSString *userName);
@property (nonatomic, copy) void (^saveToCameraRollBlock)(DQGalleryViewController *galleryViewController, DQComment *comment, UIView *view);
@property (nonatomic, copy) void (^displayPlaybackBlock)(DQGalleryViewController *galleryViewController, DQQuest *quest, DQComment *comment);
@property (nonatomic, copy) void (^commentViewedBlock)(DQGalleryViewController *galleryViewController, NSString *commentID);
@property (nonatomic, copy) void (^inviteToQuestBlock)(DQGalleryViewController *galleryViewController, DQQuest *quest);
@property (nonatomic, copy) void (^showEditorBlock)(DQGalleryViewController *galleryViewController, DQQuest *quest);
@property (nonatomic, copy) DQSharingController *(^makeSharingControllerBlock)(DQGalleryViewController *galleryViewController);

// Initialization

// designated initializer
- (id)initWithQuestID:(NSString *)inQuestID focusedCommentID:(NSString *)inScrolledCommentID source:(NSString *)source publishing:(BOOL)isPublishing newPlaybackDataManager:(DQPlaybackDataManager *)newPlaybackDataManager delegate:(id<DQViewControllerDelegate>)delegate;

- (id)init MSDesignatedInitializer(initWithQuestID:focusedCommentID:source:publishing:newPlaybackDataManager:delegate:);

- (NSDictionary *)viewEventLoggingParameters;
- (NSDictionary *)eventLoggingParameters;

- (void)showError:(NSError *)inError;
- (void)showErrorWithTitle:(NSString *)inTitle andDescription:(NSString *)inDescription;

- (void)commentFlagged:(NSNotification *)notification;
- (void)commentDeleted:(NSNotification *)notification;
- (void)commentPlayed:(NSNotification *)notification;
- (void)commentUploadCompleted:(NSNotification *)notification;

#pragma mark - Actions

- (void)flagButtonTappedForComment:(DQComment *)comment;
- (void)deleteButtonTappedForComment:(DQComment *)comment;
- (void)cameraRollButtonTappedForComment:(DQComment *)comment fromView:(UIView *)view;
- (void)displayProfileForUserWithUsername:(NSString *)username fromGalleryObject:(DQModelObject *)galleryObject;

@end
