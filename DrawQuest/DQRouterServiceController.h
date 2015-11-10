//
//  DQRouterServiceController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 1/9/2014.
//  Copyright (c) 2014 Canvas. All rights reserved.
//

#import "DQAbstractServiceController.h"

@interface DQRouterServiceController : DQAbstractServiceController

- (void)requestConfiguration:(dispatch_block_t)completionBlock;

@end
