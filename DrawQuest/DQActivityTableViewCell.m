//
//  DQActivityTableViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/15/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQActivityTableViewCell.h"
#import "DQActivityItem.h"
#import "STUtils.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

#import "DQPadActivityTableViewCell.h"
#import "DQPhoneActivityTableViewCell.h"
#import "DQCircularMaskImageView.h"
#import "DQPhoneFollowButton.h"

@interface DQActivityTableViewCell()

@end

@implementation DQActivityTableViewCell

- (void)prepareForReuse
{
    self.usernameLabel.hidden = NO;
    self.activityLabel.hidden = NO;
    self.timestampView.hidden = NO;
    self.avatarImageView.hidden = NO;
    self.drawingImageView.hidden = NO;

    // Clear the images
    [self.avatarImageView prepareForReuse];
    [self.drawingImageView prepareForReuse];
    [self.avatarImageView removeGestureRecognizer:self.avatarImageViewTapGestureRecognizer];
    self.avatarImageViewTapGestureRecognizer = nil;
    [self.usernameLabel removeGestureRecognizer:self.usernameLabelTapGestureRecognizer];
    self.usernameLabelTapGestureRecognizer = nil;
    self.avatarOrUserNameTappedBlock = nil;
    [self.followButton removeFromSuperview];
    self.followButton = nil;
    [super prepareForReuse];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ([self class] == [DQActivityTableViewCell class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadActivityTableViewCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
        }
        else
        {
            self = [[DQPhoneActivityTableViewCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
        }
    }
    else
    {
        self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
        if (self)
        {
            _activityLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _activityLabel.numberOfLines = 0;
            [self.contentView addSubview:_activityLabel];

            _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _usernameLabel.userInteractionEnabled = YES;
            [self.contentView addSubview:_usernameLabel];

            _timestampView = [[DQTimestampView alloc] initWithFrame:CGRectZero];
            [self.contentView addSubview:_timestampView];

            _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
            [self.contentView addSubview:_avatarImageView];

            _drawingImageView = [[DQImageView alloc] initWithFrame:CGRectZero];
            [self.contentView addSubview:_drawingImageView];
        }
    }
    return self;
}

- (NSString *)activityLabelTextForActivityItem:(DQActivityItem *)inActivityItem withText:(NSString *)additionalText
{
    return [NSString stringWithFormat:@"%@ %@.", inActivityItem.creatorUserName, additionalText];
}

- (void)_ai:(DQActivityItem *)inActivityItem did:(NSString *)additionalText
{
    self.usernameLabel.text = inActivityItem.creatorUserName;
    self.activityLabel.text = additionalText;
}

- (void)initializeStarActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"starred your drawing", @"Preceeded by a username indicating that they have starred your drawing")];
}

- (void)initializeRemixActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"remixed your drawing", @"Preceeded by a username indicating that they have remixed your drawing")];
}

- (void)initializePlaybackActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"played your drawing", @"Preceeded by a username indicating that they have played your drawing")];
}

- (void)initializePostActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"posted a drawing", @"Preceeded by a username indicating that they have posted a drawing of their own")];
}

- (void)initializeFollowActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"started following you", @"Preceeded by a username indicating that they have started following you")];
    self.drawingImageView.hidden = YES;
    if (self.followButton)
    {
        [self.followButton removeFromSuperview];
        self.followButton = nil;
    }
    self.followButton = [[DQPhoneFollowButton alloc] initWithFrame:CGRectZero];
    self.followButton.username = ai.creatorUserName;
    [self.contentView addSubview:self.followButton];
}

- (void)initializeFacebookFriendJoinedActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"joined DrawQuest", @"Preceeded by a username indicating that they have just joined DrawQuest")];
    self.drawingImageView.hidden = YES;
}

- (void)initializeTwitterFriendJoinedActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"joined DrawQuest", @"Preceeded by a username indicating that they have just joined DrawQuest")];
    self.drawingImageView.hidden = YES;
}

- (void)initializeWelcomeActivityItem:(DQActivityItem *)inActivityItem
{
    self.usernameLabel.text = @"";
    self.activityLabel.text = DQLocalizedString(@"Welcome to DrawQuest!", @"Activity item welcoming new users");
    self.drawingImageView.hidden = YES;
    self.avatarImageView.image = [UIImage imageNamed:@"questbot_small"];
}

- (void)initializeFeaturedInExploreActivityItem:(DQActivityItem *)inActivityItem
{
    self.usernameLabel.text = @"";
    self.activityLabel.text = DQLocalizedString(@"Your drawing was featured on Explore!", @"Activity item notifying users of an explore feature");
}

- (void)initializeNewColorsActivityItem:(DQActivityItem *)inActivityItem
{
    self.usernameLabel.text = @"";
    self.activityLabel.text = DQLocalizedString(@"New colors available!", @"Activity item notifying users new colors are available in the shop");
    self.drawingImageView.hidden = YES;
}

- (void)initializeNewUGQActivityItem:(DQActivityItem *)ai
{
    [self _ai:ai did:DQLocalizedString(@"created a Quest", @"Preceeded by a username indicating that they have created a Quest")];
}

- (void)initializeOtherOrUnknownActivityItem:(DQActivityItem *)inActivityItem
{
    self.usernameLabel.text = @"";
    // FIXME: This text should come from the activityItem
    self.activityLabel.text = DQLocalizedString(@"Please update DrawQuest to view this.", @"Activity item request that the user update to a newer version of the app");;
    self.drawingImageView.hidden = YES;
}

- (void)initializeWithActivityItem:(DQActivityItem *)inActivityItem
{
    self.timestampView.timestamp = inActivityItem.timestamp;

    switch (inActivityItem.activityType)
    {
        case DQActivityItemTypeStar: [self initializeStarActivityItem:inActivityItem]; break;
        case DQActivityItemTypeRemix: [self initializeRemixActivityItem:inActivityItem]; break;
        case DQActivityItemTypePlayback: [self initializePlaybackActivityItem:inActivityItem]; break;
        case DQActivityItemTypePost: [self initializePostActivityItem:inActivityItem]; break;
        case DQActivityItemTypeFollow: [self initializeFollowActivityItem:inActivityItem]; break;
        case DQActivityItemTypeFacebookFriendJoined: [self initializeFacebookFriendJoinedActivityItem:inActivityItem]; break;
        case DQActivityItemTypeTwitterFriendJoined: [self initializeTwitterFriendJoinedActivityItem:inActivityItem]; break;
        case DQActivityItemTypeWelcome: [self initializeWelcomeActivityItem:inActivityItem]; break;
        case DQActivityItemTypeFeaturedInExplore: [self initializeFeaturedInExploreActivityItem:inActivityItem]; break;
        case DQActivityItemTypeNewColors: [self initializeNewColorsActivityItem:inActivityItem]; break;
        case DQActivityItemTypeUGQ: [self initializeNewUGQActivityItem:inActivityItem]; break;
        case DQActivityItemTypeUnknown:
        default:
            [self initializeOtherOrUnknownActivityItem:inActivityItem];
            break;
    }

    if (!self.avatarImageView.image)
    {
        self.avatarImageView.imageURL = inActivityItem.avatarURL;
    }
    self.drawingImageView.imageURL = inActivityItem.thumbnailURL;

    // Make the avatar and username tappable
    if (inActivityItem.creatorUserID && inActivityItem.creatorUserName && inActivityItem.activityType != DQActivityItemTypeFollow && inActivityItem.activityType != DQActivityItemTypeFacebookFriendJoined && inActivityItem.activityType != DQActivityItemTypeTwitterFriendJoined)
    {
        self.avatarImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageOrUserNameTapped:)];
        [self.avatarImageView addGestureRecognizer:self.avatarImageViewTapGestureRecognizer];
        self.usernameLabelTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageOrUserNameTapped:)];
        [self.usernameLabel addGestureRecognizer:self.usernameLabelTapGestureRecognizer];
    }
}

- (void)avatarImageOrUserNameTapped:(UITapGestureRecognizer *)sender
{
    if (self.avatarOrUserNameTappedBlock)
    {
        self.avatarOrUserNameTappedBlock();
    }
}

@end
