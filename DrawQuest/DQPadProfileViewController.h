//
//  DQPadProfileViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQProfileViewController.h"

@class DQComment;

@interface DQPadProfileViewController : DQProfileViewController

@property (nonatomic, copy) void (^displayFollowersBlock)(DQProfileViewController *profileViewController);
@property (nonatomic, copy) void (^displayFollowingBlock)(DQProfileViewController *profileViewController);
@property (nonatomic, copy) void (^displayGalleryForCommentBlock)(DQProfileViewController *profileViewController, DQComment *comment);
@property (nonatomic, copy) void (^displaySettingsBlock)(DQProfileViewController *profileViewController);
@property (nonatomic, copy) void (^inviteFriendsBlock)(UIViewController *presentingViewController);
@property (nonatomic, copy) void (^shopBlock)(DQProfileViewController *profileViewController);


@end
