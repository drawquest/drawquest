//
//  DQCommentPublishViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"

// Views
#import "DQPublishShareOptionsView.h"

extern const NSInteger DQPublishDefaultPersonalShareRewardValue;

@class DQCommentPublishViewController;

@protocol DQCommentPublishViewControllerDataSource <NSObject>

- (BOOL)isSharingWithFacebookForCommentPublishViewController:(DQCommentPublishViewController *)pvc;
- (void)commentPublishViewController:(DQCommentPublishViewController *)pvc setSharingWithFacebook:(BOOL)sharingWithFacebook;

- (BOOL)isSharingWithTwitterForCommentPublishViewController:(DQCommentPublishViewController *)pvc;
- (void)commentPublishViewController:(DQCommentPublishViewController *)pvc setSharingWithTwitter:(BOOL)sharingWithTwitter;

@end

@protocol DQCommentPublishViewControllerDelegate <NSObject>

- (void)refreshRewardsInfoForCommentPublishViewController:(DQCommentPublishViewController *)pvc;
- (void)publishViewController:(DQCommentPublishViewController *)publishViewController didSelectShareOption:(DQPublishShareOptionsViewType)shareType fromShareOptionsView:(DQPublishShareOptionsView *)view;

@end

@class DQFacebookController;
@class DQTwitterController;

@interface DQCommentPublishViewController : DQViewController

@property (nonatomic, weak) id<DQCommentPublishViewControllerDataSource> publishDataSource;
@property (nonatomic, weak) id<DQCommentPublishViewControllerDelegate> publishDelegate;
@property (nonatomic, readonly, strong) NSDictionary *rewardsInfo;
@property (nonatomic, readonly, strong) NSArray *rewardsDescriptions;
@property (nonatomic, readonly, strong) NSArray *rewardsValues;
@property (nonatomic, copy) void (^submitButtonTappedBlock)(DQCommentPublishViewController *vc, DQButton *button);

// designated initializer
- (id)initWithPublishDataSource:(id<DQCommentPublishViewControllerDataSource>)publishDataSource publishDelegate:(id<DQCommentPublishViewControllerDelegate>)publishDelegate delegate:(id<DQViewControllerDelegate>)delegate rewardsDictionary:(NSDictionary *)rewardsDictionary facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithPublishDataSource:publishDelegate:delegate:rewardsDictionary:facebookController:twitterController:);

- (void)setRewardsInfo:(NSDictionary *)rewardsInfo;

- (void)submitPublishToFacebook:(BOOL)publishToFacebook publishToTwitter:(BOOL)publishToTwitter beginAuthorizingFacebookBlock:(dispatch_block_t)beginAuthorizingFacebookBlock endAuthorizingFacebookBlock:(dispatch_block_t)endAuthorizingFacebookBlock cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock;

// methods that subclasses can call
- (void)updateDisplayRewardsInfo;

// methods that subclasses must override
- (UIView *)twitterSharingView;
- (void)setSharingFB:(BOOL)sharingFB;
- (void)setSharingTW:(BOOL)sharingTW;

@end
