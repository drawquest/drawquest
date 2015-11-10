//
//  DQSocialNetworkButtonHeaderView.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-04.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQSocialNetworkButtonHeaderView;

typedef void (^DQSocialNetworkButtonValueChangedBlock)(DQSocialNetworkButtonHeaderView *c, BOOL facebook, BOOL twitter);

@interface DQSocialNetworkButtonHeaderView : UITableViewCell
@property (nonatomic, copy) NSString *title;
@property (nonatomic) BOOL facebookSharing;
@property (nonatomic) BOOL twitterSharing;
@property (nonatomic, copy) DQSocialNetworkButtonValueChangedBlock valueChangedBlock;
@property (nonatomic, readonly, weak) UIButton *facebookButton;
@property (nonatomic, readonly, weak) UIButton *twitterButton;

@end
