//
//  DQColorDetailsViewController.h
//  DrawQuest
//
//  Created by David Mauro on 7/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQButton.h"

@interface DQColorDetailsViewController : UIViewController

@property (nonatomic, strong) NSNumber *cost;
@property (nonatomic, copy) NSString *colorName;
@property (nonatomic, copy) void (^purchaseButtonTappedBlock)(DQButton *button);

- (void)setColor:(UIColor *)color isPurchased:(BOOL)isPurchased;

@end
