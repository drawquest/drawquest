//
//  DQQuestPublishViewController.h
//  DrawQuest
//
//  Created by David Mauro on 10/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

// Views
#import "DQPublishShareOptionsView.h"

@class DQQuestPublishViewController;

@protocol DQQuestPublishViewControllerDelegate <NSObject>

- (void)publishViewController:(DQQuestPublishViewController *)publishViewController didSelectShareOption:(DQPublishShareOptionsViewType)shareType fromShareOptionsView:(DQPublishShareOptionsView *)view;

@end

@interface DQQuestPublishViewController : DQViewController

@property (nonatomic, strong) UIImage *templateImage;
@property (nonatomic, weak) id<DQQuestPublishViewControllerDelegate> publishDelegate;
@property (nonatomic, copy) NSString *questTitle;
@property (nonatomic, copy) void (^drawTemplateBlock)(DQQuestPublishViewController *vc);
@property (nonatomic, copy) void (^submitButtonTappedBlock)(DQQuestPublishViewController *vc, DQButton *button);

// Designated Initializer
- (id)initWithPublishDelegate:(id<DQQuestPublishViewControllerDelegate>)publishDelegate delegate:(id<DQViewControllerDelegate>)delegate;
// Overridden initializers
- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithPublishDelegate:delegate:);

- (UIView *)twitterSharingView;
- (void)setSharingFB:(BOOL)sharingFB;
- (void)setSharingTW:(BOOL)sharingTW;

@end
