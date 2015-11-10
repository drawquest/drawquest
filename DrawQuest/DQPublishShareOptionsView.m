//
//  DQPublishShareOptionsView.m
//  DrawQuest
//
//  Created by David Mauro on 10/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPublishShareOptionsView.h"
#import "DQButton.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"

static NSArray *DQPublishShareOptionsTitles;
static NSArray *DQPublishShareOptionsImageNames;

@interface DQPublishShareOptionsView ()

@property (nonatomic, strong) UIView *buttonsWrapper;
@property (nonatomic, weak) id<DQPublishShareOptionsViewDelegate> delegate;

@end

@implementation DQPublishShareOptionsView

+ (void)initialize
{
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *imageNames = [NSMutableArray array];

    titles[DQPublishShareOptionsViewTypeFacebook] = DQLocalizedString(@"Facebook", @"Facebook");
    imageNames[DQPublishShareOptionsViewTypeFacebook] = @"share_icon_facebook";

    titles[DQPublishShareOptionsViewTypeTwitter] = DQLocalizedString(@"Twitter", @"Twitter");
    imageNames[DQPublishShareOptionsViewTypeTwitter] = @"share_icon_twitter";

    titles[DQPublishShareOptionsViewTypeEmail] = DQLocalizedString(@"Mail", @"Label for option to share using the Apple Mail app");
    imageNames[DQPublishShareOptionsViewTypeEmail] = @"share_icon_mail";

    titles[DQPublishShareOptionsViewTypeTextMessage] = DQLocalizedString(@"Message", @"Label for option to share using the Apple Messages app");
    imageNames[DQPublishShareOptionsViewTypeTextMessage] = @"share_icon_text";

    titles[DQPublishShareOptionsViewTypeCameraRoll] = DQLocalizedString(@"Camera Roll", @"Label for option to save to Apple Photos app");
    imageNames[DQPublishShareOptionsViewTypeCameraRoll] = @"share_icon_cameraRoll";

    titles[DQPublishShareOptionsViewTypeTumblr] = DQLocalizedString(@"Tumblr", @"Tumblr");
    imageNames[DQPublishShareOptionsViewTypeTumblr] = @"share_icon_tumblr";

    titles[DQPublishShareOptionsViewTypeFlickr] = DQLocalizedString(@"Flickr", @"Flickr");
    imageNames[DQPublishShareOptionsViewTypeFlickr] = @"share_icon_flickr";

    titles[DQPublishShareOptionsViewTypeInstagram] = DQLocalizedString(@"Instagram", @"Instagram");
    imageNames[DQPublishShareOptionsViewTypeInstagram] = @"share_icon_instagram";

    DQPublishShareOptionsTitles = [NSArray arrayWithArray:titles];
    DQPublishShareOptionsImageNames = [NSArray arrayWithArray:imageNames];
}

- (id)initWithFrame:(CGRect)frame shareOptions:(NSArray *)shareOptions delegate:(id<DQPublishShareOptionsViewDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor dq_phoneDivider];

        _delegate = delegate;
        _buttonsWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_buttonsWrapper];

        for (NSNumber *shareOptionNumber in shareOptions)
        {
            DQPublishShareOptionsViewType shareOption = [shareOptionNumber integerValue];
            NSString *title = [DQPublishShareOptionsTitles objectAtIndex:shareOption];
            UIImage *image = [[UIImage imageNamed:[DQPublishShareOptionsImageNames objectAtIndex:shareOption]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

            DQButton *shareButton = [DQButton buttonWithImage:image];
            shareButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            shareButton.titleLabel.minimumScaleFactor = 0.5f;
            shareButton.titleLabel.font = [UIFont dq_shareTitleFont];
            [shareButton setTitle:title forState:UIControlStateNormal];
            shareButton.tintColorForTitle = YES;
            shareButton.backgroundColor = [UIColor dq_phoneBackgroundColor];
            shareButton.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            [shareButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            shareButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 5.0f);
            shareButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 0.0f);

            __weak typeof(self) weakSelf = self;
            shareButton.tappedBlock = ^(DQButton *button) {
                [weakSelf.delegate publishShareOptionsView:weakSelf didSelectShareOption:shareOption];
            };
            shareButton.tag = [self tagForShareOption:shareOption];
            [_buttonsWrapper addSubview:shareButton];
        }
        // Create empty button if we have an odd number
        if ([shareOptions count]%2 == 1)
        {
            UIView *empty = [[UIView alloc] initWithFrame:CGRectZero];
            empty.backgroundColor = [UIColor dq_phoneBackgroundColor];
            [_buttonsWrapper addSubview:empty];
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.buttonsWrapper.frame = self.bounds;

    CGRect bounds = self.bounds;
    NSUInteger count = [self.buttonsWrapper.subviews count];
    NSUInteger viewsPerRow = 2;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;

    int subviewIndex = 0;
    for (int row = 0; row < count/viewsPerRow; row++)
    {
        CGRect rowRect;
        CGRectDivide(bounds, &rowRect, &bounds, height/(count/viewsPerRow), CGRectMinYEdge);

        for (int column = 0; column < viewsPerRow; column++)
        {
            CGRect columnRect;
            // The right column is 20points wider for visual balance
            CGFloat modifier = (column%2 == 1) ? 10.0f : -10.f;
            CGRectDivide(rowRect, &columnRect, &rowRect, width/viewsPerRow + modifier, CGRectMinXEdge);

            // Inset to create borders
            CGFloat topInset = 1.0f;
            CGFloat bottomInset = (row == count/viewsPerRow - 1) ? 1.0f : 0.0f;
            CGFloat leftInset = (column == 0) ? 0.0f : 1.0f;
            CGFloat rightInset = 0.0f;
            UIEdgeInsets cellInsets = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);
            CGRect cellRect = UIEdgeInsetsInsetRect(columnRect, cellInsets);
            [[self.buttonsWrapper.subviews objectAtIndex:subviewIndex] setFrame:cellRect];

            subviewIndex++;
        }
    }
}

#pragma mark -

- (NSInteger)tagForShareOption:(DQPublishShareOptionsViewType)shareType
{
    return shareType + 1;
}

- (DQButton *)buttonWithShareType:(DQPublishShareOptionsViewType)shareType
{
    return (DQButton *)[self.buttonsWrapper viewWithTag:[self tagForShareOption:shareType]];
}

#pragma mark - Public

- (BOOL)shareTypeIsHighlighted:(DQPublishShareOptionsViewType)shareType
{
    UIButton *shareButton = [self buttonWithShareType:shareType];
    return shareButton.selected;
}

- (void)shareOption:(DQPublishShareOptionsViewType)shareType highlight:(BOOL)highlight
{
    UIButton *shareButton = [self buttonWithShareType:shareType];
    shareButton.tintAdjustmentMode = highlight ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;
    shareButton.selected = highlight;
}

- (void)showActivityForShareOption:(DQPublishShareOptionsViewType)shareType isActive:(BOOL)isActive
{
    DQButton *shareButton = [self buttonWithShareType:shareType];
    if (isActive)
    {
        [shareButton disableWithActivityIndicator];
    }
    else
    {
        [shareButton enableAndRemoveActivityIndicator];
    }
}

- (void)flashSuccessForShareOption:(DQPublishShareOptionsViewType)shareType
{
    DQButton *successView = [[DQButton alloc] initWithFrame:CGRectZero];
    successView.userInteractionEnabled = NO;
    successView.titleLabel.font = [UIFont dq_shareTitleFont];
    [successView setImage:[[UIImage imageNamed:@"share_success_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [successView setTitle:DQLocalizedString(@"Success", @"Successful request indicator label") forState:UIControlStateNormal];
    successView.tintColorForTitle = YES;
    successView.backgroundColor = [UIColor dq_phoneBackgroundColor];
    [successView setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    successView.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
    successView.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 0.0f);

    UIButton *shareButton = [self buttonWithShareType:shareType];
    successView.frame = shareButton.frame;
    successView.alpha = 0.0f;
    [self addSubview:successView];

    [UIView animateWithDuration:0.25f animations:^{
        successView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.6f delay:0.6f options:0 animations:^{
            successView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [successView removeFromSuperview];
        }];
    }];
}

- (CGFloat)desiredHeight
{
    return 50.0f * [[self.buttonsWrapper subviews] count]/2;
}

@end
