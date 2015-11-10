//
//  DQActionSheet.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-08-15.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQActionSheet;

typedef void(^DQActionSheetCancellationBlock)(DQActionSheet *actionSheet);
typedef void(^DQActionSheetCompletionBlock)(DQActionSheet *actionSheet, NSInteger buttonIndex);

@interface DQActionSheet : UIActionSheet <UIActionSheetDelegate>

@property (nonatomic, copy) DQActionSheetCancellationBlock dq_cancellationBlock;;
@property (nonatomic, copy) DQActionSheetCompletionBlock dq_completionBlock;

@end
