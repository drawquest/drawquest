//
//  DQGalleryErrorView.h
//  DrawQuest
//
//  Created by David Mauro on 4/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQGalleryErrorView : UIView

typedef enum {
    DQGalleryErrorViewTypeEmpty,
    DQGalleryErrorViewTypeDrawingNotFound,
    DQGalleryErrorViewTypeRequestFailed
} DQGalleryErrorViewType;

// designated initializer
- (id)initWithFrame:(CGRect)frame errorType:(DQGalleryErrorViewType)errorType buttonTappedBlock:(void (^)(DQGalleryErrorView *v))buttonTappedBlock;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithFrame:buttonTappedBlock:);
- (id)init MSDesignatedInitializer(initWithFrame:buttonTappedBlock:);

@end
