//
//  DQPadProfileHeaderView.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadProfileHeaderView.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

// Views
#import "DQImageView.h"
#import "DQProfileInfoView.h"
#import "DQPhoneFollowButton.h"

@implementation DQPadProfileHeaderView
{
    CGRect _contentBounds;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = [UIColor whiteColor];

    _contentBounds = CGRectInset(self.bounds, 15.0f, 15.0f);
    
    //User info
    _userImageView = [[DQImageView alloc] initWithFrame:CGRectZero];
    _userImageView.cornerRadius = 150.0;
    [self addSubview:_userImageView];
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:30.0];
    _nameLabel.textColor = [UIColor colorWithRed:(253/255.0) green:(124/255.0) blue:(149/255.0) alpha:1];
    [self addSubview:_nameLabel];
    
    _bio = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 310.0f, 85.0f)];

    _bioLabel = [[UILabel alloc] initWithFrame:_bio.bounds];
    _bioLabel.backgroundColor = [UIColor clearColor];
    _bioLabel.textColor = [UIColor colorWithRed:(173/255.0) green:(173/255.0) blue:(173/255.0) alpha:1];
    _bioLabel.font = [UIFont systemFontOfSize:15];
    _bioLabel.textAlignment = NSTextAlignmentLeft;
    _bioLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _bioLabel.numberOfLines = 4;
    _bioLabel.userInteractionEnabled = YES;
    [_bio addSubview:_bioLabel];
    
    [self addSubview:_bio];

    
    //Coins coins coins
    UIView *coinDividerView = [[UIView alloc] initWithFrame:CGRectMake(650, 56, 1, 156)];
    coinDividerView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self addSubview:coinDividerView];
    
    _coinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_coin"]];
    _coinImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coinImageView.frame = CGRectMake(CGRectGetMaxX(coinDividerView.frame) + 140, 100, 40, 40);
    [self addSubview:_coinImageView];
    
    _coinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_coinImageView.frame) + 5, 100, 188, 40)];
    _coinsLabel.font = [UIFont fontWithName:@"Vanilla" size:40.0];
    _coinsLabel.textColor = [UIColor colorWithRed:(252/255.0) green:(209/255.0) blue:(107/255.0) alpha:1];
    _coinsLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *coinsTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(coinsLabelTapped:)];
    [_coinsLabel addGestureRecognizer:coinsTapRecognizer];
    [self addSubview:_coinsLabel];
    
    //Lower divivders
    UIView *horDividerView = [[UIView alloc] initWithFrame:CGRectMake(22, 245, 1002, 1)];
    horDividerView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self addSubview:horDividerView];
    
    UIView *leftDividerView = [[UIView alloc] initWithFrame:CGRectMake(342, 261, 1, 62)];
    leftDividerView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self addSubview:leftDividerView];
    
    UIView *rightDividerView = [[UIView alloc] initWithFrame:CGRectMake(684, 261, 1, 62)];
    rightDividerView.backgroundColor = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(238/255.0) alpha:1];
    [self addSubview:rightDividerView];
    
    //Drawings, followers, following buttons
    _drawingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    _drawingsButton.frame = CGRectMake(22, 253, 320, 76);
    [_drawingsButton setTitleColor:[UIColor colorWithRed:(253/255.0) green:(130/255.0) blue:(153/255.0) alpha:1] forState:UIControlStateNormal];
    _drawingsButton.titleLabel.numberOfLines = 2;
    _drawingsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _drawingsButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20];
    [self addSubview:_drawingsButton];
    
    _followersButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _followersButton.frame = CGRectMake(343, 253, 320, 76);
    [_followersButton setTitleColor:[UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1] forState:UIControlStateNormal];
    _followersButton.titleLabel.numberOfLines = 2;
    _followersButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _followersButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20];
    [self addSubview:_followersButton];
    
    _followingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _followingButton.frame = CGRectMake(685, 253, 320, 76);
    [_followingButton setTitleColor:[UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1] forState:UIControlStateNormal];
    _followingButton.titleLabel.numberOfLines = 2;
    _followingButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _followingButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20];
    [self addSubview:_followingButton];
    
    
    //Social Networks Icons
    _socialButtonsView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:_socialButtonsView];
    
    //Follow/unfollow on other user's profiles
    _followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectMake(703, 115, 260, 44)];
    _followButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:25];
    _followButton.tintColor = [UIColor colorWithRed:(253/255.0) green:(124/255.0) blue:(149/255.0) alpha:1];
    [self addSubview:_followButton];

    [self initializeForUserState];

    return self;
}

- (void)initializeForUserState
{
    _followButton.hidden = self.isForLoggedInUser;
    _coinImageView.hidden = !self.isForLoggedInUser;
    _coinsLabel.hidden = !self.isForLoggedInUser;
}

#pragma mark -

- (void)coinsLabelTapped:(id)sender
{
    if (self.showShopBlock)
    {
        self.showShopBlock(self);
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setIsForLoggedInUser:(BOOL)isForLoggedInUser
{
    _isForLoggedInUser = isForLoggedInUser;

    [self initializeForUserState];

    [self setNeedsDisplay];
}

- (void)setBioText:(NSString *)inBioText
{
    self.bioLabel.text = inBioText;
    self.bioLabel.frameWidth = self.bio.frameWidth;
    [self.bioLabel sizeToFit];

    [self setNeedsDisplay];
}

- (NSString *)bioText
{
    return self.bioLabel.text;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews
{
    CGRect userImageRect;
    userImageRect.size.height = 217.0f;
    userImageRect.size.width = 217.0f;
    userImageRect.origin.x = 21.0f;
    userImageRect.origin.y = 22.0f;
    
    self.userImageView.frame = userImageRect;

    [self.nameLabel sizeToFit];
    self.nameLabel.frame = CGRectMake(285, 64, 388.0f, self.nameLabel.frameHeight);
    self.bio.frameOrigin = CGPointMake(CGRectGetMinX(self.nameLabel.frame), CGRectGetMaxY(self.nameLabel.frame) + 10);
    self.socialButtonsView.frame = CGRectMake(_bio.frame.origin.x, 195, 235, 32);
}

@end
