//
//  DQSocialNetworkMessageCell.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/24/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQSocialNetworkMessageCell;

@interface DQSocialNetworkMessageCell : UITableViewCell
@property (nonatomic, strong) NSURL *profileURL;
@property (nonatomic, copy) void (^messageChangedBlock)(NSString *text);
@property (nonatomic, readonly, copy) NSString *messageText;
@end
