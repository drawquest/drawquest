//
//  DQPublishAuthViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-27.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@class DQPublishAuthViewController;

typedef void(^DQPublishAuthViewControllerBlock)(DQPublishAuthViewController *c);
typedef void(^DQPublishAuthViewControllerTwitterBlock)(DQPublishAuthViewController *c, UIView *sender);

@interface DQPublishAuthViewController : DQViewController

@property (nonatomic, copy) DQPublishAuthViewControllerBlock cancelBlock;
@property (nonatomic, copy) DQPublishAuthViewControllerBlock facebookBlock;
@property (nonatomic, copy) DQPublishAuthViewControllerTwitterBlock twitterBlock;
@property (nonatomic, copy) DQPublishAuthViewControllerBlock drawQuestBlock;
@property (nonatomic, copy) DQPublishAuthViewControllerBlock signInBlock;

- (void)loginButtonTouchUpInside:(id)sender;

@end
