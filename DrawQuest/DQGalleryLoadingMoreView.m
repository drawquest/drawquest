//
//  DQGalleryLoadingMoreView.m
//  DrawQuest
//
//  Created by Dirk on 3/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGalleryLoadingMoreView.h"

static const CGFloat kActivtyIndicatorRightPadding = 5.0f;
static const CGFloat kActivtyIndicatorLeftPadding = 5.0f;

@interface DQGalleryLoadingMoreView()

@property (nonatomic, weak) UILabel *loadingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation DQGalleryLoadingMoreView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [loadingLabel setBackgroundColor:[UIColor clearColor]];
        [loadingLabel setText:DQLocalizedString(@"Loading More", @"More items are loading in from the server indicator label")];
        [loadingLabel setTextColor:[UIColor lightGrayColor]];
        [loadingLabel setHidden:YES];
        [self addSubview:loadingLabel];
        _loadingLabel = loadingLabel;
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:activityIndicatorView];
        _activityIndicatorView = activityIndicatorView;
        
        UIButton *loadMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [loadMoreButton setFrame:CGRectMake(0.0f, 0.0f, 226.0f, 224.0f)];
        [loadMoreButton setImage:[UIImage imageNamed:@"button_load_more"] forState:UIControlStateNormal];
        [loadMoreButton setImage:[UIImage imageNamed:@"button_load_more_hit"] forState:UIControlStateHighlighted];
        [loadMoreButton setHidden:YES];
        [self addSubview:loadMoreButton];
        _loadMoreButton = loadMoreButton;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.activityIndicatorView setCenter:CGPointMake(CGRectGetMidX(self.activityIndicatorView.bounds) +kActivtyIndicatorLeftPadding, CGRectGetMidY(self.bounds))];
    [self.loadingLabel setFrame:CGRectMake(CGRectGetMaxX(self.activityIndicatorView.frame) + kActivtyIndicatorRightPadding, CGRectGetMinY(self.activityIndicatorView.frame), self.bounds.size.width - (self.activityIndicatorView.bounds.size.width + kActivtyIndicatorRightPadding), self.activityIndicatorView.bounds.size.height)];
    [self.loadMoreButton setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
}

- (void)setGalleryState:(DQGalleryLoadingMoreViewState)galleryState
{
    _galleryState = galleryState;
    
    if (galleryState == DQGalleryLoadingMoreViewStateLoading) {
        [self.loadingLabel setHidden:NO];
        [self.activityIndicatorView startAnimating];
        [self.loadMoreButton setHidden:YES];
    } else {
        [self.loadingLabel setHidden:YES];
        [self.activityIndicatorView stopAnimating];
        [self.loadMoreButton setHidden:galleryState != DQGalleryLoadingMoreViewStateLoadFailed];
    }
}

- (void)setSectionType:(NSString *)type
{
    _sectionType = [type copy];
    
    if ([type isEqualToString:UICollectionElementKindSectionFooter]) {
        [self.loadMoreButton setImage:[UIImage imageNamed:@"button_load_more"] forState:UIControlStateNormal];
        [self.loadMoreButton setImage:[UIImage imageNamed:@"button_load_more_hit"] forState:UIControlStateHighlighted];
    } else if ([type isEqualToString:UICollectionElementKindSectionHeader]) {
        [self.loadMoreButton setImage:[UIImage imageNamed:@"button_load_more_left"] forState:UIControlStateNormal];
        [self.loadMoreButton setImage:[UIImage imageNamed:@"button_load_more_left_hit"] forState:UIControlStateHighlighted];
    }
}

- (void)setLoadMoreButtonTappedBlock:(DQGalleryLoadingMoreViewBlock)tappedBlock
{
    if (_loadMoreButtonTappedBlock)
    {
        [self.loadMoreButton removeTarget:self action:@selector(loadMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    _loadMoreButtonTappedBlock = [tappedBlock copy];
    if (_loadMoreButtonTappedBlock)
    {
        [self.loadMoreButton addTarget:self action:@selector(loadMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)loadMoreButtonTapped:(id)sender
{
    if (self.loadMoreButtonTappedBlock)
    {
        self.loadMoreButtonTappedBlock(self);
    }
}

@end

