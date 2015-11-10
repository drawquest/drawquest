//
//  DQGridSectionFooter.m
//  DrawQuest
//
//  Created by Dirk on 4/8/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGridSectionFooter.h"

#import "UIView+STAdditions.h"

static const CGFloat kDQActivtyIndicatorRightPadding = 5.0f;
static const CGFloat kDQTopPadding = 20.0f;

@interface DQGridSectionFooter()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UILabel *loadingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak) UIView *visualBuffer;

@end

@implementation DQGridSectionFooter

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Won't show until we update the state
        self.hidden = YES;

        self.backgroundColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1];
        
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [loadingLabel setBackgroundColor:[UIColor clearColor]];
        [loadingLabel setText:DQLocalizedString(@"Loading More", @"More items are loading in from the server indicator label")];
        [loadingLabel setTextColor:[UIColor whiteColor]];
        [loadingLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:20.0]];
        [self addSubview:loadingLabel];
        _loadingLabel = loadingLabel;
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:activityIndicatorView];
        _activityIndicatorView = activityIndicatorView;

        UIView *visualBuffer = [[UIView alloc] initWithFrame:CGRectZero];
        visualBuffer.frameHeight = 768.0f;
        visualBuffer.backgroundColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1];
        [self addSubview:visualBuffer];
        self.visualBuffer = visualBuffer;

    }
    return self;
}

- (void)setSectionState:(DQGridSectionFooterState)state
{
    _sectionState = state;
    
    switch (state) {
        case DQGridSectionFooterStateLoaded:
            self.hidden = YES;
            [self.activityIndicatorView stopAnimating];
            self.loadingLabel.text = @"";
            break;
        case DQGridSectionFooterStateLoading:
            self.hidden = NO;
            [self.activityIndicatorView startAnimating];
            self.loadingLabel.text = DQLocalizedString(@"Loading", @"The user must wait as a request is currently being made.");
            break;
        case DQGridSectionFooterStateLoadFailed:
            self.hidden = NO;
            [self.activityIndicatorView stopAnimating];
            self.loadingLabel.text = DQLocalizedString(@"Load More", @"Button title indicating the user can tap to load in more items");
            break;
        default:
            break;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    CGSize loadingLabelSize = [self.loadingLabel.text boundingRectWithSize:self.bounds.size options:0 attributes:@{NSFontAttributeName: self.loadingLabel.font, NSParagraphStyleAttributeName: paragraphStyle} context:nil].size;
    CGFloat labelAndActivityWidth = loadingLabelSize.width + kDQActivtyIndicatorRightPadding + self.activityIndicatorView.bounds.size.width;
    CGFloat leftPadding = (self.bounds.size.width - labelAndActivityWidth)/2.0f;
    
    [self.activityIndicatorView setFrame:(CGRect) { leftPadding, kDQTopPadding, self.activityIndicatorView.bounds.size.width, self.activityIndicatorView.bounds.size.height }];
    [self.loadingLabel setFrame:(CGRect) { CGRectGetMaxX(self.activityIndicatorView.frame) + kDQActivtyIndicatorRightPadding, kDQTopPadding, loadingLabelSize.width, self.activityIndicatorView.bounds.size.height }];

    self.visualBuffer.frameWidth = self.frameWidth;
    self.visualBuffer.frameY = self.frameHeight;
}

@end
