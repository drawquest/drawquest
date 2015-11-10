//
//  DQPhoneFirstTimeViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneFirstTimeViewController.h"

#import "DQTourPageView.h"
#import "DQButton.h"
#import "DQSwipeHint.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQPhoneFirstTimeViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *tourPageViews;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIPageControl *pageControl;
@property (nonatomic, weak) DQSwipeHint *swipeHint;

@end

@implementation DQPhoneFirstTimeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;

    DQTourPageView *tourDailyView = [[DQTourPageView alloc] initWithGradientImage:[UIImage imageNamed:@"tour_blue_blur"] foregroundImage:[UIImage imageNamed:@"tour_tools_grouped"] message:DQLocalizedString(@"Draw, every day.\n\n ", @"Instructions explaining that users can draw something every day") displayExtraOptions:NO button:nil];
    DQTourPageView *tourCoinsView = [[DQTourPageView alloc] initWithGradientImage:[UIImage imageNamed:@"tour_green_blur"] foregroundImage:[UIImage imageNamed:@"tour_pig_grouped"] message:DQLocalizedString(@"Earn coins by drawing Quests. Spend coins to get more colors.", @"Instructions explaining the coin economy") displayExtraOptions:NO button:nil];
    DQTourPageView *tourFriendsView = [[DQTourPageView alloc] initWithGradientImage:[UIImage imageNamed:@"tour_pink_blur"] foregroundImage:[UIImage imageNamed:@"tour_avatar_stars_grouped"] message:DQLocalizedString(@"Follow friends and other Questers. Star and play drawings you like.", @"Instructions explaining how following, starring and playing all work") displayExtraOptions:NO button:nil];
    /*
    DQTourPageView *tourPushView = [[DQTourPageView alloc] initWithGradientImage:[UIImage imageNamed:@"tour_purple_blur"] foregroundImage:[UIImage imageNamed:@"tour_questBot"] message:DQLocalizedString(@"Push notifications remind you when there's a new Quest to draw.", @"Instructions explaining why you should say allow push notifications") displayExtraOptions:NO button:nil];
    tourPushView.wideText = YES;
     */
    DQButton *drawButton = [DQButton buttonWithImage:[UIImage imageNamed:@"tour_icon_draw"]];
    drawButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    drawButton.titleLabel.minimumScaleFactor = 0.5f;
    [drawButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [drawButton setTitle:DQLocalizedString(@"Give him a smile!", @"Quest title instructing users to draw the smiley face a smile") forState:UIControlStateNormal];
    drawButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 8.0f);
    drawButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
    drawButton.titleLabel.font = [UIFont dq_tourMessagesFont];
    drawButton.frame = CGRectMake(0.0f, 0.0f, 320.0f, 40.0f);
    drawButton.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.15f];
    __weak typeof(self) weakSelf = self;
    drawButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.showFirstQuestBlock)
        {
            weakSelf.showFirstQuestBlock(weakSelf);
        }
    };
    DQTourPageView *tourDrawView = [[DQTourPageView alloc] initWithGradientImage:nil foregroundImage:[UIImage imageNamed:@"tour_smile_Quest"] message:DQLocalizedString(@"Ready for your first Quest?", @"Message asking if users are ready to complete their first drawing") displayExtraOptions:YES button:drawButton];
    tourDrawView.wideText = YES;
    tourDrawView.asksForPushPermissions = YES;
    tourDrawView.drawLaterButtonTappedBlock = ^{
        if (weakSelf.showHomeBlock)
        {
            weakSelf.showHomeBlock(weakSelf);
        }
    };
    tourDrawView.signInButtonTappedBlock = ^{
        if (weakSelf.showAuthBlock)
        {
            weakSelf.showAuthBlock(weakSelf);
        }
    };
    tourDrawView.imageTappedBlock = ^{
        if (weakSelf.showFirstQuestBlock)
        {
            weakSelf.showFirstQuestBlock(weakSelf);
        }
    };
    tourDailyView.backgroundColor = [UIColor dq_blueColor];
    tourCoinsView.backgroundColor = [UIColor dq_greenColor];
    tourFriendsView.backgroundColor = [UIColor dq_pinkColor];
    //tourPushView.backgroundColor = [UIColor dq_purpleColor];
    tourDrawView.backgroundColor = [UIColor dq_greenColor];
    [scrollView addSubview:tourDailyView];
    [scrollView addSubview:tourCoinsView];
    [scrollView addSubview:tourFriendsView];
    //[scrollView addSubview:tourPushView];
    [scrollView addSubview:tourDrawView];
    self.tourPageViews = @[tourDailyView, tourCoinsView, tourFriendsView, tourDrawView];

    DQSwipeHint *swipeHint = [[DQSwipeHint alloc] initWithTextAttributes:@{NSFontAttributeName: [UIFont dq_tourSwipeHintFont], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [self.view addSubview:swipeHint];
    [swipeHint sizeToFit];
    self.swipeHint = swipeHint;

    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
    pageControl.numberOfPages = [self.tourPageViews count];
    pageControl.currentPage = 0;
    pageControl.userInteractionEnabled = NO;
    pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
    [self.view addSubview:pageControl];
    self.pageControl = pageControl;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGRect scrollContentFrame = self.view.bounds;
    scrollContentFrame.size.width *= [self.tourPageViews count];
    self.scrollView.frame = self.view.bounds;
    self.scrollView.contentSize = scrollContentFrame.size;

    CGRect currentPageRect;
    for (DQTourPageView *tourView in self.tourPageViews)
    {
        CGRectDivide(scrollContentFrame, &currentPageRect, &scrollContentFrame, self.view.boundsSize.width, CGRectMinXEdge);
        tourView.frame = currentPageRect;
    }

    [self.pageControl sizeToFit];
    self.pageControl.frameMaxY = self.view.frameMaxY - self.view.frameHeight * 0.15;

    [self.swipeHint sizeToFit];
    self.swipeHint.frameMaxY = self.pageControl.frameY - self.view.frameHeight * 0.05;
    self.swipeHint.frameCenterX = self.view.boundsCenterX;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.tourPageViews = nil;
        self.scrollView = nil;
        self.pageControl = nil;
        self.swipeHint = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger currentPage = round(scrollView.contentOffset.x / CGRectGetWidth(self.view.bounds));
    self.pageControl.currentPage = currentPage;
    if (currentPage != 0)
    {
        [self.swipeHint removeFromSuperview];
        self.swipeHint = nil;
    }

    DQTourPageView *view = [self.tourPageViews objectAtIndex:currentPage];
    if (view.asksForPushPermissions)
    {
        if (self.enablePushBlock)
        {
            self.enablePushBlock(self);
        }
    }
}


@end
