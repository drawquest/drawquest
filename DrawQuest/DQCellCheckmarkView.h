//
//  DQCellCheckmarkView.h
//  DrawQuest
//
//  Created by David Mauro on 6/14/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQCellCheckmarkView;

typedef void (^DQCellCheckmarkViewBlock)(DQCellCheckmarkView *checkmarkView);

@interface DQCellCheckmarkView : UIView

@property (nonatomic, copy) DQCellCheckmarkViewBlock tappedBlock;

// designated initializer
- (id)initWithLabelText:(NSString *)labelText;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithLabelText:);
- (id)init MSDesignatedInitializer(initWithLabelText:);

@end
