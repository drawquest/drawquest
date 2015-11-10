//
//  DQActivityController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-24.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"

@class DQActivityController;
@class DQActivityDataStoreController;

@protocol DQActivityControllerDelegate <DQControllerDelegate>

- (DQActivityDataStoreController *)newActivityDataStoreControllerForActivityController:(DQActivityController *)c;

- (void)activityController:(DQActivityController *)c didLoadActivities:(NSArray *)activities;
- (void)activityController:(DQActivityController *)c didUpdateActivities:(NSArray *)activities;
- (void)activityController:(DQActivityController *)c didScrollActivities:(NSArray *)activities;

- (void)activityController:(DQActivityController *)c loadFailedWithError:(NSError *)error;
- (void)activityController:(DQActivityController *)c updateFailedWithError:(NSError *)error;
- (void)activityController:(DQActivityController *)c scrollFailedWithError:(NSError *)error;

@end

@interface DQActivityController : DQController

@property (nonatomic, weak) id<DQActivityControllerDelegate>delegate;

- (id)initWithDelegate:(id<DQActivityControllerDelegate>)delegate;

- (void)reset;

- (NSUInteger)numberOfUnreadActivityItems;
- (void)markAllActivityItemsRead;
- (void)load;
- (void)update;
- (void)scroll;

@end
