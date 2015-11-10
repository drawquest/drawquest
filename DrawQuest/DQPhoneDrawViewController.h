//
//  DQPhoneDrawViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQPhoneDrawInboxViewController.h"
#import "DQPhoneDrawHistoryViewController.h"
#import "DQPhoneDrawAllViewController.h"

@interface DQPhoneDrawViewController : DQViewController

@property (nonatomic, readonly, strong) DQPhoneDrawInboxViewController *inboxViewController;

@property (nonatomic, copy) DQPhoneDrawInboxViewController *(^makeInboxViewControllerBlock)(DQPhoneDrawViewController *vc);
@property (nonatomic, copy) DQPhoneDrawHistoryViewController *(^makeHistoryViewControllerBlock)(DQPhoneDrawViewController *vc);
@property (nonatomic, copy) DQPhoneDrawAllViewController *(^makeAllViewControllerBlock)(DQPhoneDrawViewController *vc);
@property (nonatomic, copy) void (^showEditorForQuestBlock)(UIViewController *vc, DQQuest *quest, NSString *source);
@property (nonatomic, copy) void (^showGalleryForQuestBlock)(UIViewController *vc, DQQuest *quest, NSString *source);

- (void)showQuestOfTheDay;

@end
