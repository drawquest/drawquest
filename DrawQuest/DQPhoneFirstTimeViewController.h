//
//  DQPhoneFirstTimeViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQPhoneFirstTimeViewController : UIViewController

@property (nonatomic, copy) void (^showAuthBlock)(DQPhoneFirstTimeViewController *vc);
@property (nonatomic, copy) void (^showFirstQuestBlock)(DQPhoneFirstTimeViewController *vc);
@property (nonatomic, copy) void (^showHomeBlock)(DQPhoneFirstTimeViewController *vc);
@property (nonatomic, copy) void (^enablePushBlock)(DQPhoneFirstTimeViewController *vc);

@end
