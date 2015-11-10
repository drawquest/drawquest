//
//  DQBlockActionTarget.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-14.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQBlockActionTarget.h"

void * const kDQBlockActionTargetTargetKey = (void *)&kDQBlockActionTargetTargetKey;

@implementation DQBlockActionTarget

@dynamic actionSelector;

- (instancetype)initWithSenderBlock:(DQBlockActionTargetSenderBlock)senderBlock
{
    self = [super init];
    {
        _senderBlock = [senderBlock copy];
    }
    return self;
}

- (void)action:(id)sender
{
    if (self.senderBlock)
    {
        self.senderBlock(sender);
    }
}

- (SEL)actionSelector
{
    return @selector(action:);
}

@end
