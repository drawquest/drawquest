//
//  DQPhoneCommentPublishViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-16.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneCommentPublishViewController.h"

// Views
#import "DQButton.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@interface DQPhoneCommentPublishViewController () <DQPublishShareOptionsViewDelegate>

@property (nonatomic, strong) DQPublishShareOptionsView *sharingView;
@property (nonatomic, weak) UIView *headerView;
@property (nonatomic, weak) UIImageView *previewImageView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) DQButton *submitButton;

@end

@implementation DQPhoneCommentPublishViewController

- (id)initWithPublishDataSource:(id<DQCommentPublishViewControllerDataSource>)publishDataSource publishDelegate:(id<DQCommentPublishViewControllerDelegate>)publishDelegate delegate:(id<DQViewControllerDelegate>)delegate rewardsDictionary:(NSDictionary *)rewardsDictionary facebookController:(DQFacebookController *)facebookController twitterController:(DQTwitterController *)twitterController
{
    self = [super initWithPublishDataSource:publishDataSource publishDelegate:publishDelegate delegate:delegate rewardsDictionary:rewardsDictionary facebookController:facebookController twitterController:twitterController];
    if (self)
    {
        _sharingView = [[DQPublishShareOptionsView alloc] initWithFrame:CGRectZero shareOptions:@[@(DQPublishShareOptionsViewTypeFacebook), @(DQPublishShareOptionsViewTypeTwitter), @(DQPublishShareOptionsViewTypeEmail), @(DQPublishShareOptionsViewTypeTextMessage)] delegate:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:headerView];
    self.headerView = headerView;

    UIImageView *previewImageView = [[UIImageView alloc] initWithImage:self.previewImage];
    previewImageView.layer.borderColor = [[UIColor dq_drawingThumbStrokeColor] CGColor];
    previewImageView.layer.borderWidth = 1.0f;
    previewImageView.frame = CGRectMake(0.0f, 0.0f, 96.0f, 72.0f);
    [headerView addSubview:previewImageView];
    self.previewImageView = previewImageView;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.font = [UIFont dq_questCreationTitleFont];
    titleLabel.textColor = [UIColor dq_phoneGrayTextColor];
    titleLabel.numberOfLines = 3;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.text = self.questTitle;
    [headerView addSubview:titleLabel];
    self.titleLabel = titleLabel;

    DQButton *submitButton = [DQButton buttonWithType:UIButtonTypeCustom];
    submitButton.tintColorForBackground = YES;
    submitButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
    [submitButton setTitle:DQLocalizedString(@"Post to DrawQuest", @"Upload the completed drawing to DrawQuest button title") forState:UIControlStateNormal];
    submitButton.layer.cornerRadius = 4.0f;
    [submitButton sizeToFit];
    submitButton.frameWidth = kDQFormPhoneCTAButtonWidth;
    __weak typeof(self) weakSelf = self;
    submitButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.submitButtonTappedBlock)
        {
            weakSelf.submitButtonTappedBlock(weakSelf, button);
        }
    };
    [self.view addSubview:submitButton];
    self.submitButton = submitButton;

    [self.view addSubview:self.sharingView];
}

- (void)viewDidLayoutSubviews
{
    // FIXME: Finalize these metrics
    CGFloat headerHoriInset = 15.0f;
    CGFloat headerVertInset = 10.0f;
    self.headerView.frame = CGRectMake(0.0f, 0.0f, self.view.frameWidth, self.previewImageView.frameHeight + headerVertInset * 2);
    self.headerView.frame = CGRectInset(self.headerView.frame, headerHoriInset, headerVertInset);

    CGFloat templateMarginRight = 22.0f;
    self.titleLabel.frameWidth = self.headerView.frameWidth - self.previewImageView.frameWidth - templateMarginRight;
    self.titleLabel.frameX = self.previewImageView.frameMaxX + templateMarginRight;
    [self.titleLabel sizeToFit];
    self.titleLabel.frameCenterY = self.previewImageView.frameCenterY;

    self.sharingView.frameWidth = self.view.frameWidth - headerHoriInset;
    self.sharingView.frameX = headerHoriInset;
    self.sharingView.frameHeight = [self.sharingView desiredHeight];
    self.sharingView.frameY = self.headerView.frameMaxY + headerVertInset;

    self.submitButton.frameCenterX = self.view.center.x;
    self.submitButton.frameY = self.sharingView.frameMaxY + 30.0f;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark -

- (void)setPreviewImage:(UIImage *)previewImage
{
    _previewImage = previewImage;
    self.previewImageView.image = previewImage;
}

- (void)setSharingFB:(BOOL)sharingFB
{
    [self.sharingView shareOption:DQPublishShareOptionsViewTypeFacebook highlight:sharingFB];
}

- (void)setSharingTW:(BOOL)sharingTW
{
    [self.sharingView shareOption:DQPublishShareOptionsViewTypeTwitter highlight:sharingTW];
}

- (UIView *)twitterSharingView {
    return self.sharingView;
}

#pragma mark - DQPublishShareOptionsViewDelegate Methods

- (void)publishShareOptionsView:(DQPublishShareOptionsView *)view didSelectShareOption:(DQPublishShareOptionsViewType)shareType
{
    [self.publishDelegate publishViewController:self didSelectShareOption:shareType fromShareOptionsView:view];
}

@end
