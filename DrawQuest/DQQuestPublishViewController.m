//
//  DQQuestPublishViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestPublishViewController.h"

// Views
#import "DQButton.h"
#import "DQView.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@interface DQQuestPublishViewController () <DQPublishShareOptionsViewDelegate>

@property (nonatomic, strong) DQPublishShareOptionsView *sharingView;
@property (nonatomic, weak) UIView *headerView;
@property (nonatomic, weak) UIView *templateView;
@property (nonatomic, weak) UIImageView *templateImageView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) DQButton *submitButton;
@property (nonatomic, weak) UILabel *templateLabel;

@end

@implementation DQQuestPublishViewController

- (id)initWithPublishDelegate:(id<DQQuestPublishViewControllerDelegate>)publishDelegate delegate:(id<DQViewControllerDelegate>)delegate
{
    self  = [super initWithDelegate:delegate];
    if (self)
    {
        _publishDelegate = publishDelegate;
        _sharingView = [[DQPublishShareOptionsView alloc] initWithFrame:CGRectZero shareOptions:@[@(DQPublishShareOptionsViewTypeFacebook), @(DQPublishShareOptionsViewTypeTwitter), @(DQPublishShareOptionsViewTypeEmail), @(DQPublishShareOptionsViewTypeTextMessage)] delegate:self];
    }
    return self;
}

- (void)loadView
{
    __weak typeof(self) weakSelf = self;
    DQView *view = [[DQView alloc] initWithFrame:CGRectZero];
    view.dq_tintColorDidChangeBlock = ^(DQView *view) {
        weakSelf.templateLabel.textColor  = view.tintColor;
    };
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:headerView];
    self.headerView = headerView;

    UIImageView *templateImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"default_template_draw"]];
    templateImageView.frame = CGRectMake(0.0f, 0.0f, kDQFormPhoneThumbnailWidth, kDQFormPhoneThumbnailHeight);
    UIView *templateView = [[UIView alloc] initWithFrame:templateImageView.bounds];
    UILabel *templateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    templateLabel.frameWidth = templateView.frameWidth - 20.0f;
    templateLabel.text = DQLocalizedString(@"Draw a Template", @"Prompt to draw a Quest template");
    templateLabel.numberOfLines = 3;
    templateLabel.adjustsFontSizeToFitWidth = YES;
    templateLabel.minimumScaleFactor = 0.5f;
    templateLabel.textAlignment = NSTextAlignmentCenter;
    templateLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:16.0];
    templateLabel.textColor = self.view.tintColor;
    [templateLabel sizeToFit];
    templateLabel.center = templateView.boundsCenter;
    [templateView addSubview:templateImageView];
    [templateView addSubview:templateLabel];
    templateView.layer.borderWidth = 0.5f;
    templateView.layer.borderColor = [[UIColor dq_drawingThumbStrokeColor] CGColor];
    templateView.userInteractionEnabled = YES;
    UITapGestureRecognizer *templateTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(templateViewTapped:)];
    [templateView addGestureRecognizer:templateTapRecognizer];
    [headerView addSubview:templateView];
    self.templateView = templateView;
    self.templateImageView = templateImageView;
    self.templateLabel = templateLabel;

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
    self.headerView.frame = CGRectMake(0.0f, 0.0f, self.view.frameWidth, self.templateView.frameHeight + headerVertInset * 2);
    self.headerView.frame = CGRectInset(self.headerView.frame, headerHoriInset, headerVertInset);

    CGFloat templateMarginRight = 22.0f;
    self.titleLabel.frameWidth = self.headerView.frameWidth - self.templateView.frameWidth - templateMarginRight;
    self.titleLabel.frameX = self.templateView.frameMaxX + templateMarginRight;
    [self.titleLabel sizeToFit];
    self.titleLabel.frameCenterY = self.templateView.frameCenterY;

    self.sharingView.frameWidth = self.view.frameWidth - headerHoriInset;
    self.sharingView.frameX = headerHoriInset;
    self.sharingView.frameHeight = [self.sharingView desiredHeight];
    self.sharingView.frameY = self.headerView.frameMaxY + headerVertInset;

    self.submitButton.frameCenterX = self.view.center.x;
    self.submitButton.frameY = self.sharingView.frameMaxY + 30.0f;
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [self.sharingView removeFromSuperview];
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)setTemplateImage:(UIImage *)templateImage
{
    [self view]; // ensure view is loaded
    self.templateImageView.image = templateImage ?: [UIImage imageNamed:@"default_template_draw"];
    self.templateLabel.hidden = (templateImage != nil);
}

- (void)setQuestTitle:(NSString *)questTitle
{
    [self view]; // ensure view is loaded
    _questTitle = questTitle;
    self.titleLabel.text = questTitle;
}

- (void)setSharingFB:(BOOL)sharingFB
{
    [self view]; // ensure view is loaded
    [self.sharingView shareOption:DQPublishShareOptionsViewTypeFacebook highlight:sharingFB];
}

- (void)setSharingTW:(BOOL)sharingTW
{
    [self view]; // ensure view is loaded
    [self.sharingView shareOption:DQPublishShareOptionsViewTypeTwitter highlight:sharingTW];
}

- (UIView *)twitterSharingView
{
    [self view]; // ensure view is loaded
    // FIXME: this isn't correct but it really doesn't matter for iPhone anyway
    return self.sharingView;
}

#pragma mark - Actions

- (void)templateViewTapped:(id)sender
{
    if (self.drawTemplateBlock)
    {
        self.drawTemplateBlock(self);
    }
}

#pragma mark - DQPublishShareOptionsViewDelegate Methods

- (void)publishShareOptionsView:(DQPublishShareOptionsView *)view didSelectShareOption:(DQPublishShareOptionsViewType)shareType
{
    [self.publishDelegate publishViewController:self didSelectShareOption:shareType fromShareOptionsView:view];
}

@end
