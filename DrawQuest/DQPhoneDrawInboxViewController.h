//
//  DQPhoneDrawInboxViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/23/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQQuest.h"

extern NSString *const DQDrawInboxViewControllerClearBadgeNotification;

@interface DQPhoneDrawInboxViewController : DQViewController

@property (nonatomic, assign) BOOL shouldSendClearBadgeNotification;

@property (nonatomic, copy) void (^showEditorForQuestBlock)(DQQuest *quest);
@property (nonatomic, copy) void (^showGalleryForQuestBlock)(DQQuest *quest);
@property (nonatomic, copy) void (^requestPublishQuestBlock)(DQPhoneDrawInboxViewController *vc);
@property (nonatomic, copy) void (^didDismissQuestBlock)(DQPhoneDrawInboxViewController *vc);

- (void)resetView;

@end
