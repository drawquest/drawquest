//
//  DQEmailSharingViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQEmailSharingViewController : UITableViewController

@property (nonatomic, strong, readonly) NSArray *emailList;

- (id)initWithEmailList:(NSArray *)emailList;
- (id)initWithStyle:(UITableViewStyle)style MSDesignatedInitializer(initWithEmailList:);

@end
