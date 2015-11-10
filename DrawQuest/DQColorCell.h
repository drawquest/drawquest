//
//  DQColorCell.h
//  DrawQuest
//
//  Created by David Mauro on 7/24/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQColorCell : UICollectionViewCell

- (void)setColor:(UIColor *)inColor isNew:(BOOL)isNew isPurchased:(BOOL)isPurchased;

@end
