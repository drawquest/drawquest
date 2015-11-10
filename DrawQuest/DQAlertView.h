//
//  DQAlertView.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQAlertView;

typedef void(^DQAlertViewCancellationBlock)(DQAlertView *alertView);
typedef void(^DQAlertViewCompletionBlock)(DQAlertView *alertView, NSInteger buttonIndex);

@interface DQAlertView : UIAlertView

@property (nonatomic, copy) DQAlertViewCancellationBlock dq_cancellationBlock;;
@property (nonatomic, copy) DQAlertViewCompletionBlock dq_completionBlock;

@end
