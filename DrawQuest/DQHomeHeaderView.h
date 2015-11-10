//
//  DQHomeHeaderView.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQImageView;
@class DQQuest;
@class DQHomeHeaderView;

@protocol DQHomeHeaderViewDelegate <NSObject>
- (void)homeHeaderViewDrawButtonTapped:(DQHomeHeaderView *)view;
- (void)homeHeaderViewResponsesButtonTapped:(DQHomeHeaderView *)view;
- (void)homeHeaderViewImageViewTapped:(DQHomeHeaderView *)view;
- (void)homeHeaderViewSponsorTapped:(DQHomeHeaderView *)view;
- (BOOL)homeHeaderViewHasUserEverLoggedIn;
@end


@interface DQHomeHeaderView : UIView
@property (strong, nonatomic) UILabel *questLabel;
@property (strong, nonatomic) DQImageView *imageView;
@property (nonatomic, weak) id<DQHomeHeaderViewDelegate> delegate;
- (void)configureWithQuest:(DQQuest *)quest;
@end
