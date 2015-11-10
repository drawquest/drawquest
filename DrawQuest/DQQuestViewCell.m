//
//  DQQuestViewCell.m
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuestViewCell.h"

// Additions
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

// Views
#import "DQCircularMaskImageView.h"

// Additions
#import "DQViewMetricsConstants.h"

static const CGFloat kDQQuestViewCellHorizontalPadding = 15.0f;
static const CGFloat kDQQuestViewCellVerticalPadding = 7.0f;

@implementation DQQuestViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        _questTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _questTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_questTitleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _questTitleLabel.textColor = self.tintColor;
        _questTitleLabel.font = [UIFont dq_questCellTitleFont];
        _questTitleLabel.numberOfLines = 2;
        _questTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_questTitleLabel];
        
        _questTemplateImageView = [[DQImageView alloc] initWithFrame:CGRectZero];
        _questTemplateImageView.backgroundColor = [UIColor whiteColor];
        _questTemplateImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _questTemplateImageView.layer.borderWidth = 0.5f;
        _questTemplateImageView.layer.borderColor = [[UIColor dq_drawingThumbStrokeColor] CGColor];
        [self.contentView addSubview:_questTemplateImageView];

        // Layout
#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(_questTitleLabel, _questTemplateImageView);
        NSDictionary *metrics = @{@"priority": @(UILayoutPriorityDefaultHigh), @"seperatorPadding": @(12), @"paddingHorizontal": @(kDQQuestViewCellHorizontalPadding), @"paddingVertical": @(kDQQuestViewCellVerticalPadding), @"priority": @(UILayoutPriorityDefaultHigh), @"imageWidth": @(kDQFormPhoneThumbnailWidth), @"imageHeight": @(kDQFormPhoneThumbnailHeight)};

        DQVisualConstraintsWithOptions(self.contentView, @"H:|-paddingHorizontal@priority-[_questTemplateImageView(imageWidth@priority)]-paddingHorizontal@priority-[_questTitleLabel]-paddingHorizontal@priority-|", NSLayoutFormatAlignAllCenterY);
        DQVisualConstraints(self.contentView, @"V:|-paddingVertical-[_questTemplateImageView(imageHeight@priority)]");
        DQVisualConstraints(self.contentView, @"V:|-paddingVertical-[_questTitleLabel]");

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.questTitleLabel.text = nil;
    [self.questTemplateImageView prepareForReuse];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.questTitleLabel.textColor = self.tintColor;
}

- (void)layoutSubviews
{
    [self.questTitleLabel sizeToFit];

    [super layoutSubviews];
}

@end
