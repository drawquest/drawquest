//
//  DQPublishAuthViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-27.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPublishAuthViewController.h"

// View Controllers
#import "DQPadPublishAuthViewController.h"
#import "DQPhonePublishAuthViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"
#import "DQViewMetricsConstants.h"

@implementation DQPublishAuthViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    if ([self class] == [DQPublishAuthViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadPublishAuthViewController alloc] initWithDelegate:delegate];
        }
        else
        {
            self = [[DQPhonePublishAuthViewController alloc] initWithDelegate:delegate];
        }
    }
    else
    {
        self = [super initWithDelegate:delegate];
        if (self)
        {
        }
    }
    return self;
}

#pragma mark - Actions

- (void)facebook:(id)sender
{
    if (self.facebookBlock)
    {
        self.facebookBlock(self);
    }
}

- (void)twitter:(id)sender
{
    if (self.twitterBlock)
    {
        self.twitterBlock(self, sender);
    }
}

- (void)email:(id)sender
{
    if (self.drawQuestBlock)
    {
        self.drawQuestBlock(self);
    }
}

- (void)loginButtonTouchUpInside:(id)sender
{
    if (self.signInBlock)
    {
        self.signInBlock(self);
    }
}

@end
