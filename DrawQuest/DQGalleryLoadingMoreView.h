//
//  DQGalleryLoadingMoreView.h
//  DrawQuest
//
//  Created by Dirk on 3/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQGalleryLoadingMoreViewStateLoading = 0,
    DQGalleryLoadingMoreViewStateLoaded,
    DQGalleryLoadingMoreViewStateLoadFailed
} DQGalleryLoadingMoreViewState;

@class DQGalleryLoadingMoreView;
typedef void (^DQGalleryLoadingMoreViewBlock)(DQGalleryLoadingMoreView *view);

@interface DQGalleryLoadingMoreView : UICollectionReusableView
@property (nonatomic, assign) DQGalleryLoadingMoreViewState galleryState;
@property (nonatomic, weak) UIButton *loadMoreButton;
@property (nonatomic, copy) NSString *sectionType;
@property (nonatomic, copy) DQGalleryLoadingMoreViewBlock loadMoreButtonTappedBlock;
@end
