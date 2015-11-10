//
//  DQTableViewCell.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-02.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQTableViewCell : UITableViewCell

@property (nonatomic, copy) void (^dq_tintColorDidChangeBlock)(DQTableViewCell *cell);

@end
