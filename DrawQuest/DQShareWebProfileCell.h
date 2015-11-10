//
//  DQShareWebProfileCell.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQShareWebProfileCell;

typedef void (^DQShareWebProfileCellSharingBlock)(DQShareWebProfileCell *cell, BOOL sharing);

@interface DQShareWebProfileCell : UITableViewCell
@property (nonatomic, getter = isSharing) BOOL sharing;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) DQShareWebProfileCellSharingBlock sharingBlock;

@end
