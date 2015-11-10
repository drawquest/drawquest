//
//  DQAlertView.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAlertView.h"

@implementation DQAlertView

- (void)setDq_cancellationBlock:(DQAlertViewCancellationBlock)dq_cancellationBlock
{
    self.delegate = (dq_cancellationBlock || self.dq_completionBlock) ? self : nil;
    _dq_cancellationBlock = [dq_cancellationBlock copy];
}

- (void)setDq_completionBlock:(DQAlertViewCompletionBlock)dq_completionBlock
{
    self.delegate = (dq_completionBlock || self.dq_cancellationBlock) ? self : nil;
    _dq_completionBlock = [dq_completionBlock copy];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView == self) && self.dq_completionBlock)
    {
        self.dq_completionBlock(self, buttonIndex);
        self.dq_completionBlock = nil;
        self.dq_completionBlock = nil;
    }
}

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(UIAlertView *)alertView
{
    if ((alertView == self) && self.dq_cancellationBlock)
    {
        self.dq_cancellationBlock(self);
        self.dq_cancellationBlock = nil;
        self.dq_completionBlock = nil;
    }
}

@end
