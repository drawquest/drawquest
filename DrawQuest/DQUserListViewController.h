//
//  DQUserListViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/31/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"

typedef enum {
    DQUserListTypeFollowers,
    DQUserListTypeFollowing
} DQUserListType;

@interface DQUserListViewController : DQViewController

@property (nonatomic, copy) void (^displayProfileBlock)(DQUserListViewController *c, NSString *userName);

// designated initializer
- (id)initWithUserName:(NSString *)inUserName userListType:(DQUserListType)type delegate:(id<DQViewControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithUserName:userListType:delegate:);

@end
