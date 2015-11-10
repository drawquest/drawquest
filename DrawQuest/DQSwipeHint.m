//
//  DQSwipeHint.m
//  DrawQuest
//
//  Created by David Mauro on 10/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSwipeHint.h"

#import "UIView+STAdditions.h"

@interface DQSwipeHint ()

@property (nonatomic, strong) UILabel *swipeLabel;
@property (nonatomic, strong) UILabel *directionLabel;
@property (nonatomic, strong) UIView *animationView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIPushBehavior *pusher;
@property (nonatomic, strong) NSTimer *pushInterval;

@end

@implementation DQSwipeHint

- (id)initWithTextAttributes:(NSDictionary *)textAttributes
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        NSAttributedString *swipeString = [[NSAttributedString alloc] initWithString:DQLocalizedString(@"SLIDE", @"Prompt to drag with a finger to advance") attributes:textAttributes];
        _swipeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _swipeLabel.attributedText = swipeString;
        [self addSubview:_swipeLabel];
        [_swipeLabel sizeToFit];

        NSAttributedString *directionString = [[NSAttributedString alloc] initWithString:@"<" attributes:textAttributes];
        _directionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _directionLabel.attributedText = directionString;
        [_directionLabel sizeToFit];

        _animationView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _directionLabel.frameWidth * 5, _directionLabel.frameHeight)];
        [self addSubview:_animationView];
        [_animationView addSubview:_directionLabel];
        _directionLabel.frameMaxX = _animationView.frameMaxX;

        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:_animationView];

        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[_directionLabel]];
        gravity.gravityDirection = CGVectorMake(0.4f, 0.0f);
        [_animator addBehavior:gravity];

        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_directionLabel]];
        collision.translatesReferenceBoundsIntoBoundary = YES;
        [_animator addBehavior:collision];

        UIDynamicItemBehavior *directionLabelBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[_directionLabel]];
        directionLabelBehavior.elasticity = 0.3f;
        [_animator addBehavior:directionLabelBehavior];

        _pusher = [[UIPushBehavior alloc] initWithItems:@[_directionLabel] mode:UIPushBehaviorModeInstantaneous];
        _pusher.pushDirection = CGVectorMake(-0.015f, 0.0f);
        self.pusher.active = NO;
        [_animator addBehavior:_pusher];
    }
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.window)
    {
        NSLog(@"scheduling timer");
        [_pushInterval invalidate];
        _pushInterval = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(push:) userInfo:nil repeats:YES];
    }
    else
    {
        NSLog(@"invalidating timer");
        [_pushInterval invalidate];
        _pushInterval = nil;
    }
}

- (void)push:(id)sender
{
    self.pusher.active = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.swipeLabel.frameMaxX = self.boundsSize.width;
    self.animationView.frameMaxX = self.swipeLabel.frameX - 5.0f;
}

- (void)sizeToFit
{
    self.bounds = self.swipeLabel.bounds;
}


@end
