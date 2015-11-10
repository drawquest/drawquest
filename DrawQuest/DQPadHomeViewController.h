//
//  DQPadHomeViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQHomeViewController.h"
#import "DQNavigationBar.h"

@class DQPadHomeViewController;

@protocol DQPadHomeViewControllerDataSource <NSObject>

- (NSString *)firstRunQuestIDForPadHomeViewController:(DQPadHomeViewController *)vc;
- (NSString *)questOfTheDayIDForPadHomeViewController:(DQPadHomeViewController *)vc;
- (void)padHomeViewController:(DQPadHomeViewController *)vc takeQuestOfTheDayID:(NSString *)questOfTheDayID;

@end

@interface DQPadHomeViewController : DQHomeViewController

@property (nonatomic, weak) id<DQPadHomeViewControllerDataSource> dataSource;

@property (nonatomic, copy) void (^showEditorForQuestOfTheDayBlock)(DQHomeViewController *homeViewController, DQQuest *quest, BOOL isFirstQuest);
@property (nonatomic, copy) void (^showGalleryForQuestBlock)(DQHomeViewController *homeViewController, DQQuest *quest);
@property (nonatomic, copy) void (^showGalleryForQuestOfTheDayBlock)(DQHomeViewController *homeViewController, DQQuest *quest);
@property (nonatomic, copy) void (^showProfileForUserBlock) (DQHomeViewController *homeViewController, NSString *username);
@property (nonatomic, copy) void (^showShopBlock)(DQHomeViewController *c);

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate dataSource:(id<DQPadHomeViewControllerDataSource>)dataSource;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:dataSource:);

@end
