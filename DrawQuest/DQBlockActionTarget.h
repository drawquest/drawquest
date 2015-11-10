//
//  DQBlockActionTarget.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-14.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void * const kDQBlockActionTargetTargetKey;

typedef void(^DQBlockActionTargetSenderBlock)(id sender);

@interface DQBlockActionTarget : NSObject

@property (nonatomic, copy) DQBlockActionTargetSenderBlock senderBlock;
@property (nonatomic, readonly, assign) SEL actionSelector;

- (instancetype)initWithSenderBlock:(DQBlockActionTargetSenderBlock)senderBlock;

@end
