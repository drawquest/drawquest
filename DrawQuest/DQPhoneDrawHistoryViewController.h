//
//  DQPhoneDrawHistoryViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQQuest.h"

@interface DQPhoneDrawHistoryViewController : DQViewController

@property (nonatomic, copy) void (^showGalleryForQuestBlock)(DQQuest *quest);

- (void)refresh;
- (void)resetView;

@end
