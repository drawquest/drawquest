//
//  DQActionSheet.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-08-15.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQActionSheet.h"

@implementation DQActionSheet

- (void)setDq_cancellationBlock:(DQActionSheetCancellationBlock)dq_cancellationBlock
{
    self.delegate = (dq_cancellationBlock || self.dq_completionBlock) ? self : nil;
    _dq_cancellationBlock = [dq_cancellationBlock copy];
}

- (void)setDq_completionBlock:(DQActionSheetCompletionBlock)dq_completionBlock
{
    self.delegate = (dq_completionBlock || self.dq_cancellationBlock) ? self : nil;
    _dq_completionBlock = [dq_completionBlock copy];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self)
    {
        if (buttonIndex == actionSheet.cancelButtonIndex)
        {
            if (self.dq_cancellationBlock)
            {
                self.dq_cancellationBlock(self);
                self.dq_completionBlock = nil;
                self.dq_completionBlock = nil;
            }
        }
        else if (self.dq_completionBlock)
        {
            self.dq_completionBlock(self, buttonIndex);
            self.dq_completionBlock = nil;
            self.dq_completionBlock = nil;
        }
    }
}

@end
