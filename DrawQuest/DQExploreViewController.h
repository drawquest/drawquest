//
//  DQExploreViewController.h
//  DrawQuest
//
//  Created by Dirk on 4/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@interface DQExploreViewController : DQViewController

@property (nonatomic, copy) void (^tappedCommentBlock)(DQExploreViewController *c, NSString *questID, NSString *commentID);
@property (nonatomic, copy) void (^displaySearchBlock)(DQExploreViewController *c);

@property (nonatomic, copy) NSString *forcedCommentID;

// designated initializer
- (id)initWithSearchEnabled:(BOOL)searchEnabled delegate:(id<DQViewControllerDelegate>)delegate;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithSearchEnabled:delegate:);
- (id)init MSDesignatedInitializer(initWithSearchEnabled:delegate:);

@end
