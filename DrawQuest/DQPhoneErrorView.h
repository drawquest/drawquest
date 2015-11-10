//
//  DQPhoneErrorView.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-10-28.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DQPhoneErrorViewType) {
    DQPhoneErrorViewTypeEmpty,
    DQPhoneErrorViewTypeRequestFailed,
    DQPhoneErrorViewTypeLoginRequired
};

@interface DQPhoneErrorView : UIView

@property (nonatomic, copy) dispatch_block_t buttonTappedBlock;
@property (nonatomic, assign) DQPhoneErrorViewType errorType;
@property (nonatomic, assign) CGFloat topInset;

- (void)reloadView;

// template methods
- (UIImage *)image;
- (NSString *)message;
- (NSString *)buttonTitle;

@end
