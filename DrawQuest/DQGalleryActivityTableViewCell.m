//
//  DQGalleryActivityTableViewCell.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQGalleryActivityTableViewCell.h"
#import "DQTimestampView.h"
#import "DQCircularMaskImageView.h"
#import "STUtils.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

CGFloat DQGalleryActivityTableViewCellSideInset = 0.0;

CGFloat DQGalleryActivityTableViewCellContentPadding = 0.0;
CGFloat DQGalleryActivityTableViewCellLabelPadding = 0.0;

CGFloat DQGalleryActivityTableViewCellAvatarWidth = 60.0;
CGFloat DQGalleryActivityTableViewCellAvatarHeight = 50.0;

CGFloat DQGalleryActivityTableViewCellActivityTypeIconWidth = 35.0;
CGFloat DQGalleryActivityTableViewCellActivityTypeIconHeight = 35.0;

CGFloat DQGalleryActivityTableViewCellDisclosureArrowWidth = 10.0;
CGFloat DQGalleryActivityTableViewCellDisclosureArrowHeight = 14.0;

CGFloat DQGalleryActivityTableViewCellBorderStrokeWidth = 1.0;


@interface DQGalleryActivityTableViewCellBorderView : UIView

@property (nonatomic, strong) UIBezierPath *borderPath;

@end


@interface DQGalleryActivityTableViewCell ()

@property (nonatomic, strong) DQGalleryActivityTableViewCellBorderView *borderView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) DQTimestampView *timestampView;
@property (nonatomic, strong) UIImageView *activityTypeIcon;
@property (nonatomic, strong) UIImageView *disclosureArrowIcon;
@property (nonatomic, weak) UIView *borderLeft;
@property (nonatomic, weak) UIView *borderRight;
@property (nonatomic, weak) UIView *borderBottom;

@end


@implementation DQGalleryActivityTableViewCell

@synthesize borderView;
@synthesize avatarView;
@synthesize nameLabel;
@synthesize activityTypeLabel;
@synthesize activityTypeIcon;
@synthesize disclosureArrowIcon;
@synthesize activityType;

#pragma mark Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundView = nil;
        self.backgroundColor = [UIColor clearColor];
        
        // Set up the border view
        self.borderView = [[DQGalleryActivityTableViewCellBorderView alloc]
                            initWithFrame:CGRectZero];
        
        [self.contentView addSubview:self.borderView];
    
        // Set up the avatar view
        self.avatarView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.avatarView];
        
        // Set up the activity type icon
        self.activityTypeIcon = [[UIImageView alloc] initWithFrame:CGRectZero];        
        [self.contentView addSubview:self.activityTypeIcon];
        
        // Set up the name label
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.font = [UIFont dq_activityItemUserNameFont];
        self.nameLabel.textColor = [UIColor colorWithRed:(97/255.0) green:(228/255.0) blue:(182/255.0) alpha:1];
        [self.contentView addSubview:self.nameLabel];
        
        // Set up the activity label
        self.activityTypeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.activityTypeLabel.font = [UIFont dq_activityItemActivityTypeFont];
        self.activityTypeLabel.textColor = [UIColor dq_activityItemActivityTypeFontColor];
        [self.contentView addSubview:self.activityTypeLabel];

        self.timestampView = [[DQTimestampView alloc] initWithFrame:CGRectZero];
        self.timestampView.tintColor = [UIColor dq_timestampColor];
        [self.contentView addSubview:self.timestampView];
        
        self.activityType = DQActivityItemTypeOther;
        
        self.forCurrentUser = NO;

        UIView *borderLeft = [[UIView alloc] initWithFrame:CGRectZero];
        borderLeft.backgroundColor = [UIColor colorWithRed:(218/255.0) green:(218/255.0) blue:(218/255.0) alpha:1];
        [self.contentView addSubview:borderLeft];
        self.borderLeft = borderLeft;

        UIView *borderRight = [[UIView alloc] initWithFrame:CGRectZero];
        borderRight.backgroundColor = [UIColor colorWithRed:(218/255.0) green:(218/255.0) blue:(218/255.0) alpha:1];
        [self.contentView addSubview:borderRight];
        self.borderRight = borderRight;

        UIView *borderBottom = [[UIView alloc] initWithFrame:CGRectZero];
        borderBottom.backgroundColor = [UIColor colorWithRed:(218/255.0) green:(218/255.0) blue:(218/255.0) alpha:1];
        [self.contentView addSubview:borderBottom];
        self.borderBottom = borderBottom;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.avatarView prepareForReuse];
    
    self.activityTypeLabel.text = nil;
    self.forCurrentUser = NO;
}


- (void)initializeWithReactionInfo:(NSDictionary *)reactionInfo
{
    [self.avatarView setImageWithURL:reactionInfo.dq_userInfo.dq_galleryUserAvatarURL placeholderImage:nil completionBlock:nil failureBlock:nil];
    self.activityType = reactionInfo.dq_reactionActivityType;
    self.userName = reactionInfo.dq_userInfo.dq_userName;
    self.timestampView.timestamp = reactionInfo.dq_timestamp;
}

#pragma mark Accessors

- (void)setActivityType:(DQActivityItemType)inActivityType
{
    activityType = inActivityType;
    
    UIImage *iconImage = nil;

    switch (inActivityType) {
        case DQActivityItemTypePlayback:
            iconImage = [UIImage imageNamed:@"activity_play"];
            break;
        case DQActivityItemTypeStar:
            iconImage = [UIImage imageNamed:@"activity_star"];
            break;
        default:
            break;
    }
    
    self.activityTypeIcon.image = iconImage;
    self.activityTypeLabel.text = [self activityLabelTextForActivityType:inActivityType];
    
    [self setNeedsDisplay];
}

- (NSString *)activityLabelTextForActivityType:(DQActivityItemType)inActivityType
{
    NSString *actionString = @"";

    switch (inActivityType) {
        case DQActivityItemTypeStar:
            actionString = (self.isForCurrentUser) ? DQLocalizedString(@"starred your drawing", @"Preceeded by a username indicating that they have starred your drawing") : DQLocalizedString(@"starred this drawing", @"User has starred current drawing suffix");
            break;
        case DQActivityItemTypePlayback:
            actionString =  (self.isForCurrentUser) ? DQLocalizedString(@"played your drawing", @"Preceeded by a username indicating that they have played your drawing") : DQLocalizedString(@"played this drawing", @"User has played current drawing suffix");
            break;
        default:
            break;
    }
    
    return actionString;
}


- (void)setUserName:(NSString *)inUserName
{
    self.nameLabel.text = inUserName;
    
    [self setNeedsLayout];
}

- (NSString *)userName
{
    return self.nameLabel.text;
}

#pragma mark UITableViewCell

/*- (void)setSelected:(BOOL)selected animated:(BOOL)animated
 {
     [super setSelected:selected animated:animated];
 
     // Configure the view for the selected state
}*/

#pragma mark UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect insetRect = CGRectInset(self.contentView.frame, DQGalleryActivityTableViewCellSideInset * 2, 0.0);
    CGRect insideRect = CGRectInset(insetRect, DQGalleryActivityTableViewCellBorderStrokeWidth, 0.0);
    insideRect.size.height -= DQGalleryActivityTableViewCellBorderStrokeWidth;
        
    self.borderView.frame = insetRect;
    
    CGFloat doublePadding = (DQGalleryActivityTableViewCellContentPadding * 2.0);
    
    self.avatarView.frame = CGRectMake(17, 15, 40, 40);
    self.activityTypeIcon.frame = CGRectMake(600, 23, 0.0f, 0.0f);
    [self.activityTypeIcon sizeToFit];
    
    // Lay out the name label
    [self.nameLabel sizeToFit];
    self.nameLabel.frame = CGRectMake(66, 12, self.nameLabel.frameWidth, self.nameLabel.frameHeight);

    // Lay out the activity type label
    [self.activityTypeLabel sizeToFit];
    self.activityTypeLabel.frame = CGRectMake(66, CGRectGetMaxY(self.nameLabel.frame) + 2, self.activityTypeLabel.frameWidth, self.activityTypeLabel.frameHeight);

    [self.timestampView sizeToFit];
    self.timestampView.frameX = CGRectGetMinX(self.nameLabel.frame);
    self.timestampView.frameY = CGRectGetMaxY(self.activityTypeLabel.frame) + 4.0f;
    
    // Lay out the disclosure arrow
    CGRect disclosureArrowFrame = [self centeredSubRectOfSize:CGSizeMake(DQGalleryActivityTableViewCellDisclosureArrowWidth, DQGalleryActivityTableViewCellDisclosureArrowHeight) insideRect:CGRectMake(CGRectGetMaxX(insideRect) - (DQGalleryActivityTableViewCellDisclosureArrowWidth + doublePadding), insideRect.origin.y, DQGalleryActivityTableViewCellDisclosureArrowWidth + doublePadding, insideRect.size.height)];
    
    self.disclosureArrowIcon.frame = disclosureArrowFrame;
    
    
    //Hack for line under each cell
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(17, CGRectGetMaxY(self.frame) - 3, 623, 1)];
    lineView.backgroundColor = [UIColor colorWithRed:(195/255.0) green:(195/255.0) blue:(195/255.0) alpha:1];
    [self addSubview:lineView];

    self.borderLeft.frameWidth = 1.0f;
    self.borderLeft.frameHeight = self.contentView.frameHeight;

    self.borderRight.frameWidth = 1.0f;
    self.borderRight.frameHeight = self.contentView.frameHeight;
    self.borderRight.frameMaxX = self.contentView.frameWidth;

    self.borderBottom.frameWidth = self.contentView.frameWidth;
    self.borderBottom.frameHeight = 1.0f;
    self.borderBottom.frameMaxY = self.contentView.frameHeight;
}

@end


@implementation DQGalleryActivityTableViewCellBorderView

- (id)initWithFrame:(CGRect)inFrame
{
    self = [super initWithFrame:inFrame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

@end
