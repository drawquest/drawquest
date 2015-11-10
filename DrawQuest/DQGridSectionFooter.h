//
//  DQGridSectionFooter.h
//  DrawQuest
//
//  Created by Dirk on 4/8/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQGridSectionFooterStateLoading = 0,
    DQGridSectionFooterStateLoaded,
    DQGridSectionFooterStateLoadFailed
} DQGridSectionFooterState;


@interface DQGridSectionFooter : UIControl
@property (nonatomic, assign) DQGridSectionFooterState sectionState;
@end
