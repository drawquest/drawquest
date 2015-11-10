//
//  DQFlowLayoutAttributes.m
//  DrawQuest
//
//  Created by Dirk on 3/25/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQFlowLayoutAttributes.h"

@implementation DQFlowLayoutAttributes

- (id)copyWithZone:(NSZone *)zone
{
    DQFlowLayoutAttributes *theCopy = [super copyWithZone:zone];
    theCopy.dimmed = self.dimmed;
    return theCopy;
}

@end
