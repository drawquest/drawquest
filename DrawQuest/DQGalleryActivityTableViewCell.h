//
//  DQGalleryActivityTableViewCell.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQActivityItem.h"

@class DQCircularMaskImageView;

@interface DQGalleryActivityTableViewCell : UITableViewCell

@property (nonatomic, assign) DQActivityItemType activityType;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) UILabel *activityTypeLabel;
@property (nonatomic, strong) DQCircularMaskImageView *avatarView;
@property (nonatomic, assign, getter = isForCurrentUser) BOOL forCurrentUser;

- (void)initializeWithReactionInfo:(NSDictionary *)inReactionInfo;

@end
