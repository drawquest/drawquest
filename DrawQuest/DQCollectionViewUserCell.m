//
//  DQCollectionViewUserCell.m
//  DrawQuest
//
//  Created by David Mauro on 10/21/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQCollectionViewUserCell.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "UIFont+DQAdditions.h"
#import "DQViewMetricsConstants.h"

// Views
#import "DQPhoneFollowButton.h"

@interface DQCollectionViewUserCell ()

@property (nonatomic, strong) UIImageView *disclosureImageView;
@property (nonatomic, strong) UIView *fakeDivider;
@property (nonatomic, strong) DQPhoneFollowButton *followButton;

@end

@implementation DQCollectionViewUserCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kDQFormPhoneGalleryAvatarSize, kDQFormPhoneGalleryAvatarSize)];
        [self.contentView addSubview:_avatarImageView];

        _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.numberOfLines = 1;
        _usernameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _usernameLabel.textColor = self.tintColor;
        _usernameLabel.font = [UIFont dq_reactionCellUsernameFont];
        [self.contentView addSubview:_usernameLabel];

        _followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectZero];
        _followButton.boundsSize = CGSizeMake(51.0, 29.0);
        _followButton.hidden = YES;
        [self.contentView addSubview:_followButton];

        _disclosureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_phone"]];
        [self.contentView addSubview:_disclosureImageView];

        _fakeDivider = [[UIView alloc] initWithFrame:CGRectZero];
        _fakeDivider.backgroundColor = [UIColor dq_phoneTableSeperatorColor];
        [self.contentView addSubview:_fakeDivider];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [self.contentView addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)prepareForReuse
{
    self.followButton.username = nil;
    self.followButton.hidden = YES;
    self.disclosureImageView.hidden = NO;
    [super prepareForReuse];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.usernameLabel.textColor = self.tintColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat padding = 15.0f;

    self.avatarImageView.frameX = padding;
    self.avatarImageView.frameCenterY = self.contentView.frameCenterY;

    self.disclosureImageView.frameMaxX = self.contentView.frameMaxX - padding;
    self.disclosureImageView.frameCenterY = self.contentView.frameCenterY;

    self.followButton.frameMaxX = self.contentView.frameMaxX - padding;
    self.followButton.frameCenterY = self.contentView.frameCenterY;

    [self.usernameLabel sizeToFit];
    self.usernameLabel.frameX = self.avatarImageView.frameMaxX + padding;
    self.usernameLabel.frameWidth = self.contentView.frameWidth - self.avatarImageView.frameWidth - self.disclosureImageView.frameWidth - padding  * 2;
    self.usernameLabel.frameCenterY = self.contentView.frameCenterY;

    self.fakeDivider.frameX = padding;
    self.fakeDivider.frameWidth = self.contentView.frameWidth - padding;
    self.fakeDivider.frameMaxY = self.contentView.frameMaxY;
    self.fakeDivider.frameHeight = 0.5f;
}

- (void)tapped:(id)sender
{
    if (self.cellTappedBlock)
    {
        self.cellTappedBlock();
    }
}

- (void)displayFollowButtonForUsername:(NSString *)username
{
    self.followButton.username = username;
    self.followButton.hidden = NO;
    self.disclosureImageView.hidden = YES;
}

@end
