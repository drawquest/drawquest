//
//  DQCommentPublishViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCommentPublishViewController.h"

// Additions
#import "STUtils.h"
#import "NSDictionary+DQAPIConveniences.h"

// Controllers
#import "DQFacebookController.h"
#import "DQTwitterController.h"

// Subclasses
#import "DQPadCommentPublishViewController.h"
#import "DQPhoneCommentPublishViewController.h"

const NSInteger DQPublishDefaultPersonalShareRewardValue = 3;

@interface DQCommentPublishViewController ()

@property (nonatomic, strong) NSMutableArray *shareFlags;
@property (nonatomic, readwrite, strong) NSDictionary *rewardsInfo;
@property (nonatomic, readwrite, strong) NSArray *rewardsDescriptions;
@property (nonatomic, readwrite, strong) NSArray *rewardsValues;
@property (nonatomic, strong) NSDictionary *rewardsDictionary;
@property (nonatomic, weak) DQFacebookController *facebookController;
@property (nonatomic, weak) DQTwitterController *twitterController;

@end

@implementation DQCommentPublishViewController

- (id)initWithPublishDataSource:(id<DQCommentPublishViewControllerDataSource>)publishDataSource publishDelegate:(id<DQCommentPublishViewControllerDelegate>)publishDelegate delegate:(id<DQViewControllerDelegate>)delegate rewardsDictionary:(NSDictionary *)rewardsDictionary facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController;
{
    if ([self class] == [DQCommentPublishViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadCommentPublishViewController alloc] initWithPublishDataSource:publishDataSource publishDelegate:publishDelegate delegate:delegate rewardsDictionary:rewardsDictionary facebookController:facebookController twitterController:twitterController];
        }
        else
        {
            self = [[DQPhoneCommentPublishViewController alloc] initWithPublishDataSource:publishDataSource publishDelegate:publishDelegate delegate:delegate rewardsDictionary:rewardsDictionary facebookController:facebookController twitterController:twitterController];
        }
    }
    else
    {
        self = [super initWithDelegate:delegate];
        if (self)
        {
            _publishDataSource = publishDataSource;
            _publishDelegate = publishDelegate;
            _rewardsDictionary = rewardsDictionary;
            _facebookController = facebookController;
            _twitterController = twitterController;
        }
    }
    return self;
}

- (UIView *)twitterSharingView
{
    return nil; // subclasses must override this
}

- (void)setSharingFB:(BOOL)sharingFB
{
    // Subclasses must override this
}

- (void)setSharingTW:(BOOL)sharingTW
{
    // Subclasses must override this
}

#pragma mark - Accessors

- (void)setRewardsInfo:(NSDictionary *)rewardsInfo
{
    [self view]; // ensure view is loaded
    @synchronized(_rewardsInfo)
    {
        _rewardsInfo = rewardsInfo;
        [self updateDisplayRewardsInfo];
    }

}

#pragma mark - Rewards

- (void)updateDisplayRewardsInfo
{
    if (!self.rewardsInfo)
    {
        return;
    }
    
    NSMutableArray *descriptions = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];

    NSArray *keys = [self.rewardsInfo sortedKeys];
    for (NSString *currentKey in keys)
    {
        NSString *description = [self.rewardsDictionary.dq_rewardsCopy valueForKey:currentKey];
        if (description)
        {
            NSNumber *rewardValue = [self.rewardsDictionary.dq_rewardsAmounts valueForKey:currentKey];
            if (rewardValue)
            {
                [descriptions addObject:description];
                [values addObject:rewardValue];
            }
        }
    }

    self.rewardsDescriptions = descriptions;
    self.rewardsValues = values;
}

- (void)submitPublishToFacebook:(BOOL)publishToFacebook publishToTwitter:(BOOL)publishToTwitter beginAuthorizingFacebookBlock:(dispatch_block_t)beginAuthorizingFacebookBlock endAuthorizingFacebookBlock:(dispatch_block_t)endAuthorizingFacebookBlock cancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    // Make sure we have authed with any requested services before posting.
    // Authorizations are done linearly and we will stop authing if any
    // cancel or fail.
    
    NSString *facebookAccessToken = publishToFacebook && [self.facebookController hasOpenFacebookSessionWithPermissions:@[@"email", @"publish_actions"]] ? [self.facebookController openFacebookSessionAccessToken] : nil;
    NSString *twitterAccessToken = publishToTwitter ? self.twitterController.twitterAccessToken : nil;
    NSString *twitterAccessTokenSecret = publishToTwitter ? self.twitterController.twitterAccessTokenSecret : nil;

    __weak typeof(self) weakSelf = self;
    
    void (^facebookAuthBlock)(dispatch_block_t) = ^(dispatch_block_t facebookCompletionBlock) {
        if (publishToFacebook && ! facebookAccessToken)
        {
            if (beginAuthorizingFacebookBlock)
            {
                beginAuthorizingFacebookBlock();
            }
            [weakSelf requestFacebookPublishAccessForFeature:@"publish-comment" cancellationBlock:^{
                if (endAuthorizingFacebookBlock)
                {
                    endAuthorizingFacebookBlock();
                }
                if (cancellationBlock)
                {
                    cancellationBlock();
                }
            } completionBlock:^(NSString *facebookToken) {
                if (endAuthorizingFacebookBlock)
                {
                    endAuthorizingFacebookBlock();
                }
                if (facebookCompletionBlock)
                {
                    facebookCompletionBlock();
                }
            } failureBlock:^(NSError *error) {
                if (endAuthorizingFacebookBlock)
                {
                    endAuthorizingFacebookBlock();
                }
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }];
        }
        else if (facebookCompletionBlock)
        {
            facebookCompletionBlock();
        }
    };

    void (^twitterAuthBlock)(dispatch_block_t) = ^(dispatch_block_t twitterCompletionBlock) {
        if (publishToTwitter && ! (twitterAccessToken && twitterAccessTokenSecret))
        {
            [weakSelf requestTwitterAccessInView:[weakSelf twitterSharingView] withCancellationBlock:cancellationBlock accountSelectedBlock:nil completionBlock:twitterCompletionBlock failureBlock:failureBlock];
        }
        else if (twitterCompletionBlock)
        {
            twitterCompletionBlock();
        }
    };

    facebookAuthBlock(^{
        twitterAuthBlock(completionBlock);
    });
}

@end
