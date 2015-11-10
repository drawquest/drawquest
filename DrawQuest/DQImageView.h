//
//  DQImageView.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/12/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQImageView : UIView

//@property (nonatomic, copy) NSString *imageURL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIImage *frameImage;
@property (nonatomic, strong) UIImageView *internalImageView;
@property (nonatomic, strong) UIView *accessoryView;
@property (nonatomic, copy) CGPoint (^accessoryViewCenterBlock)(CGRect bounds);

@property (nonatomic) CGFloat cornerRadius;

- (void)setImageURL:(NSString *)imageURL;

- (void)setImageWithURL:(NSString *)imageURL
       placeholderImage:(UIImage *)placeholder
        completionBlock:(dispatch_block_t)completionBlock
           failureBlock:(void (^)(NSError *error))failureBlock;

- (void)prepareForReuse;

@end
