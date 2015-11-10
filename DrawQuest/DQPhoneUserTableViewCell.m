//
//  DQPhoneUserTableViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 11/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneUserTableViewCell.h"

#import "DQPhoneFollowButton.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@interface DQPhoneUserTableViewCell ()

@property (nonatomic, strong) UIImageView *disclosureImageView;
@property (nonatomic, strong) DQPhoneFollowButton *followButton;

@end

@implementation DQPhoneUserTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor dq_phoneBackgroundColor];

        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kDQFormPhoneGalleryAvatarSize, kDQFormPhoneGalleryAvatarSize)];
        [self.contentView addSubview:_avatarImageView];

        self.textLabel.numberOfLines = 1;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.textLabel.textColor = self.tintColor;
        self.textLabel.font = [UIFont dq_reactionCellUsernameFont];

        _followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectZero];
        _followButton.boundsSize = CGSizeMake(51.0, 29.0);
        _followButton.hidden = YES;
        [self.contentView addSubview:_followButton];

        _disclosureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_phone"]];
        [self.contentView addSubview:_disclosureImageView];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self.contentView addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat padding = 12.0f;

    self.avatarImageView.frameX = padding;
    self.avatarImageView.frameCenterY = self.contentView.frameCenterY;

    self.disclosureImageView.frameMaxX = self.contentView.frameMaxX - 35.0;
    self.disclosureImageView.frameCenterY = self.contentView.frameCenterY;

    self.followButton.frameMaxX = self.contentView.frameMaxX - padding;
    self.followButton.frameCenterY = self.contentView.frameCenterY;

    [self.textLabel sizeToFit];
    self.textLabel.frameX = self.avatarImageView.frameMaxX + padding;
    self.textLabel.frameWidth = self.contentView.frameWidth - self.avatarImageView.frameWidth - self.disclosureImageView.frameWidth - padding  * 2;
    self.textLabel.frameCenterY = self.contentView.frameCenterY;
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

    self.textLabel.textColor = self.tintColor;
}

- (void)cellTapped:(id)sender
{
    if (self.cellTappedBlock)
    {
        self.cellTappedBlock(self);
    }
}

- (void)displayFollowButtonForUsername:(NSString *)username
{
    self.followButton.username = username;
    self.followButton.hidden = NO;
    self.disclosureImageView.hidden = YES;
}

@end
