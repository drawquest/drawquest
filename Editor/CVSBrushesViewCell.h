//
//  CVSBrushesViewCell.h
//  DrawQuest
//
//  Created by David Mauro on 9/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVSBrushView.h"

@interface CVSBrushesViewCell : UICollectionViewCell

@property (nonatomic, weak) CVSBrushView *brushView;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) BOOL popped;

- (void)setPoppedUnanimated:(BOOL)popped;

@end
