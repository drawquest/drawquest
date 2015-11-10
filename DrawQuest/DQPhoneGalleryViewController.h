//
//  DQPhoneGalleryViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/26/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGalleryViewController.h"
#import "DQPlaybackDataManager.h"

@interface DQPhoneGalleryViewController : DQGalleryViewController

@property (nonatomic, copy) dispatch_block_t dismissBlock;

@end
