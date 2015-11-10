//
//  DQPublishRewardsViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPublishRewardsViewController.h"

// Controllers
#import "DQPublicServiceController.h"

// Views
#import "DQButton.h"
#import "DQCoinsLabel.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQPublishRewardsViewController ()

//@property (nonatomic, weak) DQButton *skipButton;
@property (nonatomic, weak) UIView *headerView;
@property (nonatomic, weak) UIView *rewardViewsWrapper;
@property (nonatomic, weak) DQPublishStreakView *streakView;
@property (nonatomic, strong) NSArray *rewardViews;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) NSInteger totalEarned;
@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, assign) BOOL receivedCoins;

@end

@implementation DQPublishRewardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *rewardViewsWrapper = [[UIView alloc] initWithFrame:CGRectZero];
    rewardViewsWrapper.hidden = YES;
    [self.view addSubview:rewardViewsWrapper];
    self.rewardViewsWrapper = rewardViewsWrapper;

    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 121.0f)];
    headerView.hidden = YES;
    [self.view addSubview:headerView];
    self.headerView = headerView;

    /*
    DQButton *skipButton = [DQButton buttonWithType:UIButtonTypeCustom];
    [skipButton setTitle:DQLocalizedString(@"Skip", @"Option to continue without completing the current step") forState:UIControlStateNormal];
    skipButton.layer.cornerRadius = 2.0f;
    skipButton.backgroundColor = [UIColor dq_phoneRewardsGray];
    skipButton.titleLabel.font = [UIFont dq_phoneRewardsFont];
    skipButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 15.0f, 4.0f, 15.0f);
    __weak typeof(self) weakSelf = self;
    skipButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.dismissBlock)
        {
            weakSelf.dismissBlock(weakSelf);
        }
    };
    [self.view addSubview:skipButton];
    self.skipButton = skipButton;
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ( ! self.rewardViews)
    {
        self.rewardViews = @[];

        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestPostingRewardsForQuestID:self.questID shareFlags:self.shareFlags withCompletionBlock:^(DQHTTPRequest *request, id JSONObject) {
            if (request && [JSONObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSInteger daysUntilStreak = responseDictionary.dq_nextStreakDaysUntil;
                NSInteger goalStreakDays = responseDictionary.dq_nextStreakGoal;

                NSMutableArray *rewardViews = [[NSMutableArray alloc] init];
                NSDictionary *rewardsInfo = JSONObject;
                NSArray *keys = [rewardsInfo sortedKeys];
                for (NSString *currentKey in keys)
                {
                    NSString *description = [weakSelf.rewardsDictionary.dq_rewardsPhoneCopy valueForKey:currentKey];
                    if (description)
                    {
                        NSNumber *rewardValue = [weakSelf.rewardsDictionary.dq_rewardsAmounts valueForKey:currentKey];
                        if (rewardValue)
                        {
                            self.totalEarned += [rewardValue integerValue];
                            self.receivedCoins = YES;
                            DQPublishRewardView *rewardView = [[DQPublishRewardView alloc] initWithFrame:CGRectZero];
                            rewardView.rewardLabel.text = description;
                            rewardView.amountLabel.text = [NSString stringWithFormat:@"+%@", rewardValue];

                            // Change the reward color based on type
                            if ([currentKey isEqualToString:DQAPIValueRewardTypeSignup] || [currentKey isEqualToString:DQAPIValueRewardTypeQuestOfTheDay] || [currentKey isEqualToString:DQAPIValueRewardTypeArchivedQuest])
                            {
                                rewardView.backgroundColor = [UIColor dq_homeTabColor];
                            }
                            else if ([currentKey isEqualToString:DQAPIValueRewardTypePersonalFacebookShare] || [currentKey isEqualToString:DQAPIValueRewardTypePersonalTwitterShare])
                            {
                                rewardView.backgroundColor = [UIColor dq_profileTabColor];
                            }
                            else if ([currentKey isEqualToString:DQAPIValueRewardTypeStreak3] || [currentKey isEqualToString:DQAPIValueRewardTypeStreak10] || [currentKey isEqualToString:DQAPIValueRewardTypeStreak100])
                            {
                                rewardView.backgroundColor = [UIColor dq_drawTabColor];
                            }
                            [rewardViews addObject:rewardView];
                            [weakSelf.rewardViewsWrapper addSubview:rewardView];
                        }
                    }
                }
                // Streak reward view
                if (daysUntilStreak > 0)
                {
                    DQPublishStreakView *streakView = [[DQPublishStreakView alloc] initWithFrame:CGRectZero];
                    if (daysUntilStreak == 1)
                    {
                        streakView.streakLabel.text = [NSString stringWithFormat:DQLocalizedString(@"%ld more day 'til next Streak Bonus", @"Label indicating the number of days until the user receives another streak bonus, singular"), (long)daysUntilStreak];
                    }
                    else
                    {
                        streakView.streakLabel.text = [NSString stringWithFormat:DQLocalizedString(@"%ld more days 'til next Streak Bonus", @"Label indicating the number of days until the user receives another streak bonus, plural"), (long)daysUntilStreak];
                    }
                    // Set the progress to what it previously was so we can later animate it into the new position
                    weakSelf.progress = (goalStreakDays - daysUntilStreak)/(goalStreakDays * 1.0f);
                    [rewardViews addObject:streakView];
                    [weakSelf.rewardViewsWrapper addSubview:streakView];
                    self.streakView = streakView;
                }
                
                weakSelf.rewardViews = [NSArray arrayWithArray:rewardViews];
                
                [weakSelf ready];
            }
            else
            {
                // If the API fails just show the pig
                [weakSelf ready];
            }
        } failureBlock:^(DQHTTPRequest *request, NSError *error) {
            [weakSelf ready];
        }];
    }
}

/*
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self.skipButton sizeToFit];
    self.skipButton.frameCenterX = self.view.frameCenterX;
    self.skipButton.frameMaxY = self.view.frameMaxY - self.view.frameHeight/10;
}
 */

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.isReady = NO;
        self.rewardViews = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark -

- (UIView *)makeSparklyPig
{
    UIView *pig = [[UIView alloc] initWithFrame:CGRectZero];

    UIImageView *sparkles1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_coinReward_sparkle_bundle2"]];
    [pig addSubview:sparkles1];

    UIImageView *sparkles2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_coinReward_sparkle_bundle3"]];
    [pig addSubview:sparkles2];

    UIImageView *sparkles3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_coinReward_sparkle_bundle4"]];
    [pig addSubview:sparkles3];

    UIImageView *pigAndCoins = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_coinReward_pig_and_coins"]];
    [pig addSubview:pigAndCoins];

    pig.bounds = pigAndCoins.bounds;

    [UIView animateWithDuration:0.8f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        sparkles1.alpha = 0.1f;
    } completion:nil];

    [UIView animateWithDuration:0.5f delay:0.2f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        sparkles2.alpha = 0.2f;
    } completion:nil];

    [UIView animateWithDuration:0.3f delay:0.1f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        sparkles3.alpha = 0.5f;
    } completion:nil];

    return pig;
}

- (UIView *)makeRollyPig
{
    UIView *pig = [[UIView alloc] initWithFrame:CGRectZero];

    UIImageView *mud = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_coinReward_mud_puddle"]];
    [pig addSubview:mud];

    UIImageView *pigBody = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_pig_roll_body"]];
    [pig addSubview:pigBody];

    UIImageView *pigHead = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tour2_pig_roll_head"]];
    [pig addSubview:pigHead];

    pig.bounds = pigBody.bounds;
    pig.frameHeight += 10.0f;
    pigHead.center = pig.boundsCenter;
    mud.frameCenterX = pig.boundsCenterX;
    mud.frameMaxY = pig.frameHeight;

    pigBody.transform = CGAffineTransformMakeRotation(-0.5f);
    pigHead.transform = CGAffineTransformMakeRotation(-0.85f);

    [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        pigBody.transform = CGAffineTransformMakeRotation(0.5f);
        pigHead.transform = CGAffineTransformMakeRotation(0.85f);
    } completion:nil];

    return pig;
}

- (void)setupAnimatedViews
{
    CGFloat horizontalInset = 7.0f;
    CGFloat headerMarginBottom = 14.0f;
    CGFloat rewardViewPadding = 12.0f;

    if (self.receivedCoins)
    {
        UIView *pig = [self makeSparklyPig];
        [self.headerView addSubview:pig];

        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        headerLabel.textAlignment = NSTextAlignmentRight;
        headerLabel.text = DQLocalizedString(@"Total coins:", @"Total coins a user has collected tally prefix");
        headerLabel.textColor = [UIColor dq_coinTextColor];
        headerLabel.font = [UIFont dq_phoneRewardsLargeFont];
        headerLabel.adjustsFontSizeToFitWidth = YES;
        headerLabel.minimumScaleFactor = 0.5f;
        [self.headerView addSubview:headerLabel];

        UILabel *coinsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        coinsLabel.text = [NSString stringWithFormat:@"%ld", [self.loggedInAccount.coinCount integerValue] + self.totalEarned];
        coinsLabel.textColor = [UIColor whiteColor];
        coinsLabel.font = [UIFont dq_phoneRewardsLargeCoinsFont];
        [self.headerView addSubview:coinsLabel];

        UIImageView *coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rewards_coin_large"]];
        [self.headerView addSubview:coinImageView];

        // Layout
        pig.frameX = 3.0f;
        pig.frameMaxY = self.headerView.boundsSize.height + 4.0f;

        [coinsLabel sizeToFit];
        coinsLabel.frameMaxX = self.headerView.boundsSize.width - 9.0f;
        coinsLabel.frameMaxY = self.headerView.boundsSize.height;

        coinImageView.frameMaxX = coinsLabel.frameX - 2.0f;
        coinImageView.frameCenterY = coinsLabel.frameCenterY;

        [headerLabel sizeToFit];
        headerLabel.frameWidth = 110.0f;
        headerLabel.frameMaxX = coinsLabel.frameMaxX;
        headerLabel.frameMaxY = coinsLabel.frameY - 8.0f;
    }
    else
    {
        self.headerView.frameHeight = 235.0f;

        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        headerLabel.numberOfLines = 0;
        headerLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        headerLabel.text = DQLocalizedString(@"Nice drawing! You're on a roll today!", @"Message congratulating the user on completing another drawing for the day");
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [UIFont dq_phoneRewardsLargeFont];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        [self.headerView addSubview:headerLabel];

        headerLabel.frameWidth = 170.0f;
        [headerLabel sizeToFit];
        headerLabel.frameCenterX = self.headerView.boundsCenterX;
        headerLabel.frameMaxY = self.headerView.frameHeight;

        UIView *pig = [self makeRollyPig];
        [self.headerView addSubview:pig];

        pig.frameCenterX = self.headerView.boundsCenterX;
        pig.frameMaxY = headerLabel.frameY - 20.0f;
    }

    // Rewards cells
    self.rewardViewsWrapper.frameWidth = self.view.frameWidth - horizontalInset * 2;
    UIView *lastView = nil;
    for (UIView *rewardView in self.rewardViews)
    {
        [rewardView sizeToFit];
        if (lastView)
        {
            rewardView.frameY = lastView.frameMaxY + rewardViewPadding;
        }
        lastView = rewardView;
    }
    self.rewardViewsWrapper.frameHeight = lastView.frameMaxY;
    self.rewardViewsWrapper.frameCenterX = self.view.boundsCenterX;

    // Center everything vertically, weighted towards the top
    CGFloat height = self.headerView.frameHeight + headerMarginBottom + self.rewardViewsWrapper.frameHeight;
    CGFloat topPadding = (self.view.frameHeight - height)/2.5;
    self.headerView.frameY = topPadding;
    self.rewardViewsWrapper.frameY = self.headerView.frameMaxY + headerMarginBottom;
}

- (void)ready
{
    // Must be called twice before it executes
    if (self.isReady)
    {
        [self setupAnimatedViews];

        // Move offscreen and unhide
        CGFloat headerViewOffscreenOffset = self.headerView.frameMaxY;
        CGFloat rewardViewsOffscreenOffset = self.view.frameHeight - self.rewardViewsWrapper.frameY;
        self.headerView.frameY -= headerViewOffscreenOffset;
        for (UIView *view in self.rewardViews)
        {
            view.frameY += rewardViewsOffscreenOffset;
        }
        self.rewardViewsWrapper.hidden = NO;
        self.headerView.hidden = NO;

        __weak typeof(self) weakSelf = self;
        dispatch_block_t animationsCompleteBlock = ^{
            // DONE START TIMER TO DISMISS
            double delayInSeconds = 2.2f + 0.3f * [weakSelf.rewardViews count];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (weakSelf.dismissBlock)
                {
                    weakSelf.dismissBlock(weakSelf);
                }
            });
        };

        // Animate header, then cascade reward views
        [UIView animateWithDuration:0.65f delay:0.0f usingSpringWithDamping:0.45f initialSpringVelocity:0.1f options:0 animations:^{
            self.headerView.frameY += headerViewOffscreenOffset;
        } completion:^(BOOL finished) {
            if ([self.rewardViews count])
            {
                [self.rewardViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [UIView animateWithDuration:1.0f delay:0.55f * idx usingSpringWithDamping:0.41f initialSpringVelocity:0.01f options:0 animations:^{
                        view.frameY -= rewardViewsOffscreenOffset;
                    } completion:^(BOOL finished) {
                        if (view == self.streakView)
                        {
                            [self.streakView.progressView setProgress:self.progress animated:YES];
                        }
                        if (idx == [self.rewardViews count] - 1)
                        {
                            animationsCompleteBlock();
                        }
                    }];
                }];
            }
            else
            {
                animationsCompleteBlock();
            }
        }];

    }
    self.isReady = YES;
}

@end

#pragma mark -
#pragma mark - Reward Views

static const CGFloat kDQPublishRewardViewInsetHori = 10.0f;
static const CGFloat kDQPublishRewardViewInsetVert = 16.0f;

@interface DQPublishRewardView ()

@property (nonatomic, strong) UIImageView *coinImageView;

@end

@implementation DQPublishRewardView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.cornerRadius = 4.0f;

        _rewardLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _rewardLabel.font = [UIFont dq_phoneRewardsFont];
        _rewardLabel.textColor = [UIColor whiteColor];
        _rewardLabel.numberOfLines = 1;
        _rewardLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _rewardLabel.adjustsFontSizeToFitWidth = YES;
        _rewardLabel.minimumScaleFactor = 0.5f;
        [self addSubview:_rewardLabel];

        _amountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _amountLabel.font = [UIFont dq_coinsFont];
        _amountLabel.textColor = [UIColor whiteColor];
        _amountLabel.numberOfLines = 1;
        [self addSubview:_amountLabel];

        _coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rewards_coin_medium"]];
        [self addSubview:_coinImageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.coinImageView.frameMaxX = self.frameMaxX - 6.0f;
    self.coinImageView.frameCenterY = self.boundsCenterY;

    [self.amountLabel sizeToFit];
    self.amountLabel.frameMaxX = self.coinImageView.frameX;
    self.amountLabel.frameCenterY = self.boundsCenterY;

    [self.rewardLabel sizeToFit];
    self.rewardLabel.frameX = kDQPublishRewardViewInsetHori;
    self.rewardLabel.frameWidth = self.amountLabel.frameX - kDQPublishRewardViewInsetHori - 10.0f;
    self.rewardLabel.frameCenterY = self.boundsCenterY;
}

- (void)sizeToFit
{
    CGSize size = [self.rewardLabel.text sizeWithAttributes:@{NSFontAttributeName: self.rewardLabel.font}];
    self.frameHeight = size.height + kDQPublishRewardViewInsetVert * 2;
    self.frameWidth = self.superview.frameWidth;
}

@end

@implementation DQPublishStreakView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor dq_phoneRewardsGray];
        self.layer.cornerRadius = 4.0f;

        _streakLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _streakLabel.frameWidth = 310.0f - kDQPublishRewardViewInsetHori * 2;
        _streakLabel.frameHeight = 20.0f;
        _streakLabel.font = [UIFont dq_phoneRewardsFont];
        _streakLabel.textColor = [UIColor whiteColor];
        _streakLabel.numberOfLines = 1;
        _streakLabel.adjustsFontSizeToFitWidth = YES;
        _streakLabel.minimumScaleFactor = 0.5f;
        [self addSubview:_streakLabel];

        _progressView = [[DQProgressView alloc] initWithFrame:CGRectZero];
        _progressView.frameHeight = 24.0f;
        _progressView.cornerRadius = 12.0f;
        _progressView.progressColor = [UIColor dq_activityTabColor];
        _progressView.trackColor = [UIColor dq_colorWithRed:90 green:90 blue:90];
        [self addSubview:_progressView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.streakLabel.frameCenterX = self.boundsCenterX;
    self.streakLabel.frameY = 10.0f;

    self.progressView.frameX = kDQPublishRewardViewInsetHori;
    self.progressView.frameWidth = self.frameWidth - kDQPublishRewardViewInsetHori * 2;
    self.progressView.frameY = self.streakLabel.frameMaxY + 10.0f;
}

- (void)sizeToFit
{
    CGSize labelSize = [self.streakLabel.text sizeWithAttributes:@{NSFontAttributeName: self.streakLabel.font}];
    self.frameHeight = labelSize.height + self.progressView.frameHeight + kDQPublishRewardViewInsetVert + 20.0f;
    self.frameWidth = self.superview.frameWidth;
}

@end
