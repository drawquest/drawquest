//
//  DQReusableBannerView.h
//  DrawQuest
//
//  Created by David Mauro on 11/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQReusableBannerView : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *messageLabel;
@property (nonatomic, copy) void (^cellTappedBlock)(DQReusableBannerView *cell);

@end
