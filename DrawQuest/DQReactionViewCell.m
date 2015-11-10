//
//  DQReactionViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 9/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQReactionViewCell.h"
#import "DQTimestampView.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

static const CGFloat kDQReactionViewCellPadding = 10.0f;
static NSArray *reactionDescriptionStrings;
static NSArray *reactionAccessoryImageNames;

@interface DQReactionViewCell ()

@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) DQTimestampView *timestampView;
@property (nonatomic, strong) NSArray *reactionAccessoryImageViews;

@end

@implementation DQReactionViewCell

+ (void)initialize
{
    reactionDescriptionStrings = @[
                                   DQLocalizedString(@"starred this drawing", @"User has starred current drawing suffix"),
                                   DQLocalizedString(@"played this drawing", @"User has played current drawing suffix")
                                   ];
    reactionAccessoryImageNames = @[
                                   @"activity_star",
                                   @"activity_play"
                                   ];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor dq_phoneBackgroundColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        _avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_avatarImageView];

        _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.textColor = self.tintColor;
        _usernameLabel.font = [UIFont dq_reactionCellUsernameFont];
        [self.contentView addSubview:_usernameLabel];

        _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _descriptionLabel.adjustsFontSizeToFitWidth = YES;
        _descriptionLabel.minimumScaleFactor = 0.5f;
        _descriptionLabel.textColor = [UIColor dq_modalPrimaryTextColor];
        _descriptionLabel.font = [UIFont dq_reactionCellDescriptionFont];
        [self.contentView addSubview:_descriptionLabel];

        _timestampView = [[DQTimestampView alloc] initWithFrame:CGRectZero];
        _timestampView.translatesAutoresizingMaskIntoConstraints = NO;
        _timestampView.tintColor = [UIColor dq_timestampColor];
        [self.contentView addSubview:_timestampView];

        NSMutableArray *reactionAccessoryImageViews = [NSMutableArray array];
        for (int i = 0; i < DQReactionViewCellTypeCount; i++)
        {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:reactionAccessoryImageNames[i]]];
            UIView *imageWrapper = [[UIView alloc] initWithFrame:imageView.bounds];
            imageWrapper.frameWidth += 2;
            [imageWrapper addSubview:imageView];
            [reactionAccessoryImageViews addObject:imageWrapper];
        }
        _reactionAccessoryImageViews = reactionAccessoryImageViews;

        // Layout
#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_avatarImageView, _usernameLabel, _descriptionLabel, _timestampView);
        NSDictionary *metrics = @{@"padding": @(kDQReactionViewCellPadding), @"leftPadding": @(15), @"fontPadding": @(kDQReactionViewCellPadding - 4), @"avatarSize": @(kDQFormPhoneGalleryAvatarSize), @"avatarRightMargin": @(15)};

        DQVisualConstraints(self, @"H:|-leftPadding-[_avatarImageView(avatarSize)]");
        DQVisualConstraints(self, @"H:[_avatarImageView]-avatarRightMargin-[_usernameLabel]");
        DQVisualConstraints(self, @"H:[_avatarImageView]-avatarRightMargin-[_descriptionLabel]");
        DQVisualConstraints(self, @"H:[_avatarImageView]-avatarRightMargin-[_timestampView]");
        DQVisualConstraints(self, @"V:|-padding-[_avatarImageView(avatarSize)]");
        DQVisualConstraints(self, @"V:|-fontPadding-[_usernameLabel][_descriptionLabel]-2-[_timestampView]");

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.usernameLabel.textColor = self.tintColor;
}

#pragma mark - Accessors

- (void)setTimestamp:(NSDate *)timestamp
{
    self.timestampView.timestamp = timestamp;
}

- (NSDate *)timestamp
{
    return self.timestampView.timestamp;
}

- (void)setReactionType:(DQReactionViewCellType)reactionType
{
    if (reactionType != DQReactionViewCellTypeNotFound)
    {
        _reactionType = reactionType;
        self.accessoryView = [self.reactionAccessoryImageViews objectAtIndex:reactionType];
        self.descriptionLabel.text = [reactionDescriptionStrings objectAtIndex:reactionType];
    }
}

@end
