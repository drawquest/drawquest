//
//  DQPhoneUserTableViewCell.h
//  DrawQuest
//
//  Created by David Mauro on 11/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTableViewCell.h"

#import "DQCircularMaskImageView.h"

@interface DQPhoneUserTableViewCell : DQTableViewCell

@property (nonatomic, strong) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, copy) void (^cellTappedBlock)(DQPhoneUserTableViewCell *cell);

- (void)displayFollowButtonForUsername:(NSString *)username;

@end
