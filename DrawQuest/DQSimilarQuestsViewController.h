//
//  DQSimilarQuestsViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQSimilarQuestsViewController : DQViewController

@property (nonatomic, weak) UITextField *titleField;
@property (nonatomic, copy) void (^returnTappedOnTitleFieldBlock)(DQSimilarQuestsViewController *vc);

@end
