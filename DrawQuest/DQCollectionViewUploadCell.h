//
//  DQCollectionViewUploadCell.h
//  DrawQuest
//
//  Created by David Mauro on 10/1/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQCommentUpload.h"

@interface DQCollectionViewUploadCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) void (^retryButtonTappedBlock)(UIButton *sender);
@property (nonatomic, copy) void (^cancelButtonTappedBlock)(UIButton *sender);

- (void)initializeWithCommentUpload:(DQCommentUpload *)inCommentUpload;

@end
