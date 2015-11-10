//
//  DQPadFriendListCell.m
//  DrawQuest
//
//  Created by David Mauro on 6/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadFriendListCell.h"
#import "DQCircularMaskImageView.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

@interface DQPadFriendListCell ()

@property (nonatomic, strong) DQCircularMaskImageView *avatarView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *dqUsernameLabel;

@end

@implementation DQPadFriendListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _avatarView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
        [self.contentView addSubview:_avatarView];

        _displayNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _displayNameLabel.font = [UIFont dq_modalTableCellFont];
        _displayNameLabel.textColor = [UIColor dq_modalPrimaryTextColor];
        _displayNameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_displayNameLabel];

        _dqUsernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _dqUsernameLabel.font = [UIFont dq_modalTableCellDetailFont];
        _dqUsernameLabel.textColor = [UIColor dq_modalTableHeaderTextColor];
        _dqUsernameLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.avatarView prepareForReuse];
    self.displayNameLabel.text = nil;
    self.dqUsernameLabel.text = nil;
}

# pragma mark - Setters

- (void)setAvatarImageURL:(NSString *)imageURL
{
    [self.avatarView setImageWithURL:imageURL placeholderImage:nil completionBlock:nil failureBlock:nil];
}

- (void)setDisplayName:(NSString *)displayName
{
    self.displayNameLabel.text = displayName;
}

- (void)setDrawQuestUsername:(NSString *)dqUsername
{
    if ([dqUsername length])
    {
        dqUsername = [NSString stringWithFormat:@"%@ on DrawQuest", dqUsername];
        [self.contentView addSubview:self.dqUsernameLabel];
    }
    else
    {
        [self.dqUsernameLabel removeFromSuperview];
    }
    self.dqUsernameLabel.text = dqUsername;
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect contentBounds = CGRectInset(self.contentView.bounds, 10.0f, 10.0f);
    CGRect leftRect;
    CGRect centerRect;
    CGRectDivide(contentBounds, &leftRect, &centerRect, CGRectGetWidth(self.avatarView.frame) + 10.0f, CGRectMinXEdge);

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = self.displayNameLabel.lineBreakMode;
    CGSize constrainSize = CGSizeMake(CGRectGetWidth(centerRect), CGRectGetHeight(centerRect));
    CGSize expectedDisplayNameLabelSize = [self.displayNameLabel.text boundingRectWithSize:constrainSize options:0 attributes:@{NSFontAttributeName: self.displayNameLabel.font, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;

    paragraphStyle.lineBreakMode = self.dqUsernameLabel.lineBreakMode;
    constrainSize = CGSizeMake(CGRectGetWidth(centerRect), CGRectGetHeight(centerRect));
    CGSize expectedDQUsernameLabelSize = [self.dqUsernameLabel.text boundingRectWithSize:constrainSize options:0 attributes:@{NSFontAttributeName: self.displayNameLabel.font, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;

    self.avatarView.frame = CGRectMake(CGRectGetMinX(leftRect),
                                       CGRectGetMinY(leftRect) + (int)((CGRectGetHeight(leftRect) - CGRectGetHeight(self.avatarView.frame))/2),
                                       CGRectGetWidth(self.avatarView.frame),
                                       CGRectGetHeight(self.avatarView.frame));

    CGRect dqUsernameRect = CGRectZero;
    CGFloat lineHeight = 0.0f;
    if (self.dqUsernameLabel.text != nil)
    {
        lineHeight = 10.0f;
        self.dqUsernameLabel.frame = CGRectMake(CGRectGetMinX(centerRect),
                                    CGRectGetMinY(centerRect) + (int)((CGRectGetHeight(centerRect) - expectedDQUsernameLabelSize.height - lineHeight - expectedDisplayNameLabelSize.height)/2 + lineHeight + expectedDisplayNameLabelSize.height),
                                    CGRectGetWidth(centerRect),
                                    expectedDQUsernameLabelSize.height);
    }
    
    self.displayNameLabel.frame = CGRectMake(CGRectGetMinX(centerRect),
                                             CGRectGetMinY(centerRect) + (int)((CGRectGetHeight(centerRect) - CGRectGetHeight(dqUsernameRect) - lineHeight - expectedDisplayNameLabelSize.height)/2),
                                             CGRectGetWidth(centerRect),
                                             expectedDisplayNameLabelSize.height);
}

@end
