//
//  DQCommentViewTracker.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"

@interface DQCommentViewTracker : DQController

@property (nonatomic, strong) NSNumber *uploadInterval;

- (void)start;
- (void)stop;
- (void)trackViewOfCommentWithServerID:(NSString *)serverID;

@end
