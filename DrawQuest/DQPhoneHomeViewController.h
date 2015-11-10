//
//  DQPhoneHomeViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQHomeViewController.h"

extern NSString *const DQPhoneHomeViewControllerClearBadgeNotification;

@interface DQPhoneHomeViewController : DQHomeViewController

@property (nonatomic, assign) NSInteger oneUseDefaultSegmentIndex;
@property (nonatomic, assign) BOOL shouldSendClearBadgeNotification;
@property (nonatomic, copy) void (^presentAddFriendsBlock)(DQPhoneHomeViewController *vc);
@property (nonatomic, copy) BOOL (^shouldPresentAddFriendsBlock)(DQPhoneHomeViewController *vc);
@property (nonatomic, copy) void (^commentViewedBlock)(DQPhoneHomeViewController *homeViewController, NSString *commentID);

@end
