//
//  DQStarButton.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQStarButton.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQStarButton ()

@property (nonatomic, strong) UIImage *notStarredImage;
@property (nonatomic, strong) UIImage *starredImage;

@end

@implementation DQStarButton
{
    UIImageRenderingMode _notStarredImageRenderingMode;
    CGSize _starButtonIntrinsicContentSize;
}

- (void)dealloc
{
    if (_commentID)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:DQStarStateChangedNotification
                                                      object:nil];
    }
}

- (id)init
{
    self = [self initWithNotStarredImage:nil starredImage:nil size:CGSizeZero];
    if (self)
    {
    }
    return self;
}

// designated initializer
- (id)initWithNotStarredImage:(UIImage *)notStarredImage starredImage:(UIImage *)starredImage size:(CGSize)size
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _starState = DQStarStateIndeterminate;
        _notStarredImageRenderingMode = notStarredImage ? UIImageRenderingModeAlwaysOriginal : UIImageRenderingModeAlwaysTemplate;
        _notStarredImage = notStarredImage ?: [UIImage imageNamed:@"button_star_hit"];
        _starredImage = starredImage ?: [UIImage imageNamed:@"button_star_hit"];
        // in the default case, use the image size (phone)
        // on iPad where custom images are specified, the button size doesn't equal the image size
        _starButtonIntrinsicContentSize = notStarredImage ? size : notStarredImage.size;
        self.boundsSize = _starButtonIntrinsicContentSize;
        if (!notStarredImage)
        {
            self.tintColor = [UIColor dq_phoneButtonOffColor];
        }
        [self addTarget:self action:@selector(starButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return _starButtonIntrinsicContentSize;
}

- (void)prepareForReuse
{
    self.commentID = nil;
}

- (void)star
{
    if (self.starState == DQStarStateNotStarred)
    {
        [self starButtonTapped];
    }
}

- (void)starButtonTapped
{
    if ([self.commentID length])
    {
        DQStarState nextState = (self.starState == DQStarStateStarred ?
                                 DQStarStateNotStarred :
                                 DQStarStateStarred);
        self.starState = nextState;
        DQRequestSetStarState(self.commentID, nextState, self.eventLoggingParameters);
        
    }
}

- (void)setCommentID:(NSString *)commentID
{
    if (!(_commentID ? [_commentID isEqualToString:commentID] : !commentID))
    {
        self.starState = DQStarStateIndeterminate;
        // NSLog(@"button %p commentID changing from %@ to %@", self, _commentID, commentID);
        if (_commentID)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:DQStarStateChangedNotification
                                                          object:nil];
        }
        _commentID = [commentID copy];
        if (_commentID)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(starStateChanged:)
                                                         name:DQStarStateChangedNotification
                                                       object:nil];
        }
        if ([_commentID length])
        {
            __weak typeof(self) weakSelf = self;
            DQRequestStarState(_commentID, ^(NSString *commentID, DQStarState state) {
                typeof(self) _self = weakSelf;
                if (_self && [commentID length] && [commentID isEqualToString:_self.commentID])
                {
                    _self.starState = state;
                }
            });
        }
    }
}

- (void)starStateChanged:(NSNotification *)notification
{
    if (_commentID)
    {
        NSString *commentID = [notification object];
        if (commentID)
        {
            if ([_commentID isEqualToString:commentID])
            {
                DQStarState state = [[notification userInfo][DQStarStateNotificationStateUserInfoKey] integerValue];
                // NSLog(@"button %p for %@ changed state to: %ld", self, self.commentID, (long)state);
                self.starState = state;
            }
        }
    }
}

- (void)setStarState:(DQStarState)starState
{
    if (_starState != starState)
    {
        _starState = starState;
        if (starState == DQStarStateStarred)
        {
            // NSLog(@"button %p for %@ setting starred image", self, self.commentID);
            [self setImage:[self.starredImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }
        else
        {
            // NSLog(@"button %p for %@ setting not-starred image", self, self.commentID);
            [self setImage:[self.notStarredImage imageWithRenderingMode:_notStarredImageRenderingMode] forState:UIControlStateNormal];
        }
    }
    
    [self.delegate starButtonValueChanged];
}

@end
