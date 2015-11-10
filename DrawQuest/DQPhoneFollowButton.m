//
//  DQPhoneFollowButton.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneFollowButton.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "DQFollowConstants.h"

@interface DQPhoneFollowButton ()

@property (nonatomic, assign) DQFollowState followState;

@end

@implementation DQPhoneFollowButton

- (void)dealloc
{
    if (_username)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:DQFollowStateChangedNotification
                                                      object:nil];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _followState = DQFollowStateIndeterminate;
        self.layer.cornerRadius = 5.0f;
        self.backgroundColor = [UIColor dq_activityFollowButtonNotFollowingColor];
        self.tintColorForBackground = NO;
        [self addTarget:self action:@selector(followButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    }
    return self;
}

- (void)prepareForReuse
{
    self.username = nil;
}

- (void)followButtonTapped:(DQPhoneFollowButton *)sender
{
    if ([self.username length])
    {
        DQFollowState nextState = (self.followState == DQFollowStateFollowing ?
                                   DQFollowStateNotFollowing :
                                   DQFollowStateFollowing);
        self.followState = nextState;
        DQRequestSetFollowState(self.username, nextState);
    }
}

- (void)setUsername:(NSString *)username
{
    if (!(_username ? [_username isEqualToString:username] : !username))
    {
        self.followState = DQFollowStateIndeterminate;
        // NSLog(@"button %p username changing from %@ to %@", self, _username, username);
        if (_username)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:DQFollowStateChangedNotification
                                                          object:nil];
        }
        _username = [username copy];
        if (_username)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(followStateChanged:)
                                                         name:DQFollowStateChangedNotification
                                                       object:nil];
        }
        if ([_username length])
        {
            __weak typeof(self) weakSelf = self;
            DQRequestFollowState(_username, ^(NSString *username, DQFollowState state) {
                typeof(self) _self = weakSelf;
                if (_self && [username length] && [username isEqualToString:_self.username])
                {
                    _self.followState = state;
                }
            });
        }
    }
}

- (void)followStateChanged:(NSNotification *)notification
{
    if (_username)
    {
        NSString *username = [notification object];
        if (username)
        {
            if ([_username isEqualToString:username])
            {
                DQFollowState state = [[notification userInfo][DQFollowStateNotificationStateUserInfoKey] integerValue];
                // NSLog(@"button %p for %@ changed state to: %ld", self, self.username, (long)state);
                self.followState = state;
            }
        }
        else
        {
            NSDictionary *states = [notification userInfo][DQFollowStateNotificationManyStatesUserInfoKey];
            NSNumber *stateNumber = states[_username];
            if (stateNumber)
            {
                DQFollowState state = [stateNumber integerValue];
                // NSLog(@"button %p for %@ changed state to: %ld", self, self.username, (long)state);
                self.followState = state;
            }
        }
    }
}

- (void)setFollowState:(DQFollowState)followState
{
    if (_followState != followState)
    {
        _followState = followState;
        self.tintColorForBackground = followState == DQFollowStateFollowing;
        if (followState == DQFollowStateFollowing)
        {
            // NSLog(@"button %p for %@ setting following image", self, self.username);
            [self setImage:[UIImage imageNamed:@"activity_following"] forState:UIControlStateNormal];
        }
        else
        {
            // NSLog(@"button %p for %@ setting not-following image", self, self.username);
            [self setImage:[UIImage imageNamed:@"activity_follow"] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor dq_activityFollowButtonNotFollowingColor];
        }
    }
}

@end
