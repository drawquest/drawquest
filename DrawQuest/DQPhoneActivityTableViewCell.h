//
//  DQPhoneActivityTableViewCell.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-10-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQActivityTableViewCell.h"
#import "DQActivityItem.h"

extern NSString *const DQPhoneActivityTableViewCellMarkAsReadNotification;

@class DQButton;

@interface DQPhoneActivityTableViewCell : DQActivityTableViewCell

@property (nonatomic, assign) DQActivityItemType activityType;
@property (nonatomic, assign) BOOL isUnread;

@end
