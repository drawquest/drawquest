//
//  DQHomeHeaderView.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQHomeHeaderView.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "DQImageView.h"
#import "DQCircularMaskImageView.h"
#import "DQQuest.h"
#import "UIView+STAdditions.h"
#import "DQLocalizer.h"

static const CGRect kAvatarRect = { { 8.0f, 8.0f }, { 56.0f, 56.0f } };
static const CGRect kCopyRect = { { 81.0f, 13.0f }, { 320.0f, 20.0f } };
static const CGRect kUsernameRect = { { 81.0f, 33.0f }, { 320.0f, 20.0f } };

@interface DQHomeHeaderView ()

@property (strong, nonatomic) UIButton *drawButton;
@property (strong, nonatomic) UIButton *firstDrawButton;
@property (strong, nonatomic) UIButton *responsesButton;

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *coinsLabel;

@property (weak, nonatomic) UIView *sponsorView;
@property (weak, nonatomic) DQCircularMaskImageView *sponsorAvatarView;
@property (weak, nonatomic) UILabel *sponsorUsernameLabel;
@property (weak, nonatomic) UILabel *sponsorCopyLabel;

@property (weak, nonatomic) UIView *questView;
@property (weak, nonatomic) UIView *questDetailsView;
@property (strong, nonatomic) UIView *firstDividerView;
@property (strong, nonatomic) UIView *secoundDividerView;

@end

@implementation DQHomeHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = [UIColor whiteColor];
    
    //Left side
    UIView *questView = [[UIView alloc] initWithFrame:CGRectMake(18, 18, 532.0f, 306.0f)];
    questView.backgroundColor = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
    [self addSubview:questView];
    self.questView = questView;
    
    UIView *questDetailsView = [[UIView alloc] initWithFrame:CGRectMake(0, 252.0f, 532.0f, 54.0f)];
    [self.questView addSubview:questDetailsView];
    self.questDetailsView = questDetailsView;
    
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15];
    _titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:_titleLabel];

    _questLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _questLabel.backgroundColor = [UIColor clearColor];
    _questLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:25];
    _questLabel.textColor = [UIColor whiteColor];
    _questLabel.numberOfLines = 3;
    _questLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_questLabel];

    _coinsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _coinsLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_coinsLabel];

    _imageView = [[DQImageView alloc] initWithFrame:CGRectZero];
    [[_imageView layer] setBorderWidth:1.0f];
    [[_imageView layer] setBorderColor:[[UIColor colorWithRed:(232/255.0) green:(232/255.0) blue:(232/255.0) alpha:1.0] CGColor]];
    [self addSubview:_imageView];

    //Action buttons on today's quest
    _firstDividerView = [[UIView alloc] initWithFrame:CGRectMake(410, 271.0f, 1, 34)];
    _firstDividerView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self addSubview:_firstDividerView];
    
    _responsesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _responsesButton.frame = CGRectMake(CGRectGetMaxX(_firstDividerView.frame), 271.0f, 67.0f, 34.0f);
    [_responsesButton setImage:[[UIImage imageNamed:@"button_gallery"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_responsesButton setTintColor:[UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1]];
    [self addSubview:_responsesButton];
    
    _secoundDividerView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_responsesButton.frame), 271.0f, 1, 34)];
    _secoundDividerView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self addSubview:_secoundDividerView];
    
    _drawButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _drawButton.frame = CGRectMake(CGRectGetMaxX(_secoundDividerView.frame), 271.0f, 67.0f, 34.0f);
    [_drawButton setImage:[[UIImage imageNamed:@"button_draw_pencil"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_drawButton setTintColor:[UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1]];
    [self addSubview:_drawButton];

    //Right side
    [_drawButton addTarget:self action:@selector(drawButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_responsesButton addTarget:self action:@selector(responsesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_firstDrawButton addTarget:self action:@selector(drawButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
    [_imageView addGestureRecognizer:tapRecognizer];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
    [_imageView addGestureRecognizer:swipeRecognizer];

    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentBounds = CGRectInset(self.bounds, 25.0f, 25.0f);
    CGRect leftBox;
    CGRect rightBox;
    CGRectDivide(contentBounds, &rightBox, &leftBox, 408.0f, CGRectMaxXEdge);

    rightBox.size.height = 306.0f;
    rightBox.size.width = 435.0f;
    rightBox.origin.x = CGRectGetMaxX(self.questView.frame) + 20;
    rightBox.origin.y = 18;

    self.imageView.frame = rightBox;
    
    CGRect titleBox;
    CGRect bottomLeftBox;
    CGRectDivide(leftBox, &titleBox, &bottomLeftBox, 30.0f, CGRectMinYEdge);


    bottomLeftBox = CGRectInset(bottomLeftBox, 0.0f, 20.0f);
    CGRect questBox;
    CGRect buttonsBox;
    CGRectDivide(bottomLeftBox, &questBox, &buttonsBox, 170.0f, CGRectMinYEdge);

    questBox.size.width -= 84.0f;
    questBox.origin.x += 13.0f;
    questBox.origin.y -= 20.0f;

    self.questLabel.frame = CGRectInset(questBox, 5.0f, 0.0f);

    BOOL isUsingNonEnglishLocalization = ![[DQLocalization displayedLanguage] isEqualToString:@"en"];

    //James' chaos, did this her as hasUserEverLoggedIn is set correct in init
    if (!self.hasUserEverLoggedIn) { //yeah yeah next two blocks should be swapped order so not do if !self.hasUserEverLoggedIn
        
        //Specific to first time
        UILabel *firstQuestLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 2, 0, 0)];
        firstQuestLabel.text = DQLocalizedString(@"My First Quest", @"Label for the user's first Quest");
        firstQuestLabel.textColor = [UIColor whiteColor];
        firstQuestLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20.0f];
        [firstQuestLabel sizeToFit];
        [self.questView addSubview:firstQuestLabel];
        
        //First time draw this quest button
        _firstDrawButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 532.0f, 54.0f)];
        _firstDrawButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_firstDrawButton setTitle:DQLocalizedString(@"Draw This Quest", @"Label for option to draw a particular Quest") forState:UIControlStateNormal];
        [_firstDrawButton setImage:[UIImage imageNamed:@"button_draw_pencil"] forState:UIControlStateNormal];
        _firstDrawButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
        _firstDrawButton.titleLabel.textColor = [UIColor whiteColor];
        _firstDrawButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _firstDrawButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:25.0f];
        _firstDrawButton.backgroundColor = [UIColor colorWithRed:(85/255.0) green:(200/255.0) blue:(160/255.0) alpha:1];
        [_firstDrawButton addTarget:self action:@selector(drawButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.questDetailsView addSubview:_firstDrawButton];
        
        //First time coins label
        UILabel *coinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 170, 532.0f, 50)];
        coinsLabel.textAlignment = NSTextAlignmentCenter;
        coinsLabel.text = DQLocalizedString(@"Earn      25 Coins", @"Label indicating the user can earn 25 coins with fixed white space");
        coinsLabel.textColor = [UIColor whiteColor];
        coinsLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20.0f];
        [coinsLabel sizeToFit];
        coinsLabel.frameCenterX = self.questView.boundsCenterX;
        [self.questView addSubview:coinsLabel];
        
        UIImageView *coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rewards_coin_medium"]];
        // Hack to place the image differently for non-English
        if (isUsingNonEnglishLocalization)
        {
            coinImageView.frame = CGRectMake(coinsLabel.frameX - 25, 0, 22, 22);
        }
        else
        {
            coinImageView.frame = CGRectMake(238, 0, 22, 22);
        }
        coinImageView.frameCenterY = coinsLabel.frameCenterY;
        coinImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.questView addSubview:coinImageView];
        
    } else {
        //Today's quest
        UILabel *firstQuestLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 2, 0, 0)];
        firstQuestLabel.text = DQLocalizedString(@"Today's Quest", @"Label for the Quest of the Day");
        firstQuestLabel.textColor = [UIColor whiteColor];
        firstQuestLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20.0f];
        [firstQuestLabel sizeToFit];
        [self.questView addSubview:firstQuestLabel];
        
        //Coins earned label
        UILabel *coinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, 522.0f, 50)];
        coinsLabel.textAlignment = NSTextAlignmentRight;
        coinsLabel.text = DQLocalizedString(@"Earn      5 Coins", @"Label indicating the user can earn 5 coins with fixed white space");
        coinsLabel.textColor = [UIColor whiteColor];
        coinsLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20.0f];
        [self.questView addSubview:coinsLabel];
        [coinsLabel sizeToFit];
        coinsLabel.frameMaxX = self.questView.frameWidth - 10.0f;
        
        UIImageView *coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rewards_coin_medium"]];
        if (isUsingNonEnglishLocalization)
        {
            coinImageView.frame = CGRectMake(coinsLabel.frameX - 25, 0, 22, 22);
        }
        else
        {
            coinImageView.frame = CGRectMake(425, 0, 22, 22);
        }
        coinImageView.frameCenterY = coinsLabel.frameCenterY;
        coinImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.questView addSubview:coinImageView];
        
        
        //Quest details
        _questDetailsView.backgroundColor = [UIColor whiteColor];
        _questDetailsView.frame = CGRectMake(0, 233, 532.0f, 73.0f);
        _questDetailsView.layer.borderColor = [UIColor colorWithRed:(235/255.0) green:(235/255.0) blue:(235/255.0) alpha:1].CGColor;
        _questDetailsView.layer.borderWidth = 1;

        UITapGestureRecognizer *sponsorTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sponsorViewTapped:)];
        [_questDetailsView addGestureRecognizer:sponsorTapRecognizer];
        
        DQCircularMaskImageView *sponsorAvatarView = [[DQCircularMaskImageView alloc] initWithFrame:kAvatarRect];
        [sponsorAvatarView setBackgroundColor:[UIColor clearColor]];
        [_questDetailsView addSubview:sponsorAvatarView];
        _sponsorAvatarView = sponsorAvatarView;
        
        UILabel *sponsorCopyLabel = [[UILabel alloc] initWithFrame:kCopyRect];
        [sponsorCopyLabel setBackgroundColor:[UIColor clearColor]];
        [sponsorCopyLabel setTextColor:[UIColor colorWithRed:(134/255.0) green:(134/255.0) blue:(134/255.0) alpha:1]];
        sponsorCopyLabel.font = [UIFont systemFontOfSize:13.0];
        [_questDetailsView addSubview:sponsorCopyLabel];
        _sponsorCopyLabel = sponsorCopyLabel;
        
        UILabel *sponsorUsernameLabel = [[UILabel alloc] initWithFrame:kUsernameRect];
        [sponsorUsernameLabel setBackgroundColor:[UIColor clearColor]];
        [sponsorUsernameLabel setTextColor:[UIColor colorWithRed:(82/255.0) green:(226/255.0) blue:(178/255.0) alpha:1]];
        sponsorUsernameLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15.0];
        [_questDetailsView addSubview:sponsorUsernameLabel];
        _sponsorUsernameLabel = sponsorUsernameLabel;
        
    }
    
    if (self.hasUserEverLoggedIn) {
        
        self.firstDrawButton.hidden = YES;
        self.drawButton.hidden = NO;
        self.responsesButton.hidden = NO;
    } else {
        self.drawButton.hidden = YES;
        self.responsesButton.hidden = YES;
        _firstDividerView.hidden = YES;
        _secoundDividerView.hidden = YES;
    }
}

- (void)drawRect:(CGRect)rect
{
    CGRect outerRect = CGRectInset(self.bounds, 25.0f, 15.0f);
    outerRect.size.height -= 20.0f;

    CGRect contentBounds = CGRectInset(self.bounds, 25.0f, 25.0f);
    CGRect leftBox;
    CGRect rightBox;
    CGRectDivide(contentBounds, &leftBox, &rightBox, 500.0f, CGRectMinXEdge);

    leftBox.size.height = 306.0f;
    leftBox.origin.x += 23.0f;
    leftBox.origin.y += 11.0f;

}

- (void)configureWithQuest:(DQQuest *)quest
{
    NSString *username = quest.attributionUsername ?: quest.authorUsername;
    NSString *avatarURL = quest.attributionAvatarUrl ?: quest.authorAvatarUrl;
    NSString *label = quest.attributionCopy;

    [self.sponsorAvatarView setImageWithURL:avatarURL placeholderImage:nil completionBlock:nil failureBlock:nil];
    [self.sponsorUsernameLabel setText:username];
    [self.sponsorCopyLabel setText:label];
    [self.sponsorView setHidden:NO];
}

- (void)drawButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(homeHeaderViewDrawButtonTapped:)]) {
        [self.delegate homeHeaderViewDrawButtonTapped:self];
    }
}

- (void)responsesButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(homeHeaderViewResponsesButtonTapped:)]) {
        [self.delegate homeHeaderViewResponsesButtonTapped:self];
    }
}

- (void)imageViewTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(homeHeaderViewImageViewTapped:)]) {
        [self.delegate homeHeaderViewImageViewTapped:self];
    }
}

- (void)sponsorViewTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(homeHeaderViewSponsorTapped:)]) {
        [self.delegate homeHeaderViewSponsorTapped:self];
    }
}

- (BOOL)hasUserEverLoggedIn
{
    return [self.delegate homeHeaderViewHasUserEverLoggedIn];
}

@end
