//
//  DQPhoneDrawAllViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/7/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQQuest.h"

@interface DQPhoneDrawAllViewController : DQViewController

@property (nonatomic, copy) void (^showGalleryForQuestBlock)(DQQuest *quest);

- (void)resetView;

@end
