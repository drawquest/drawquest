//
//  DQPadGalleryViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGalleryViewController.h"

@interface DQPadGalleryViewController : DQGalleryViewController

@property (nonatomic, readonly, strong) DQQuest *quest;
@property (nonatomic, copy) void (^drawThisQuestBlock)(DQPadGalleryViewController *galleryViewController);

@end
