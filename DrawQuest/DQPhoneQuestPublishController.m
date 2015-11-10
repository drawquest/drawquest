//
//  DQPhoneQuestPublishController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 10/4/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneQuestPublishController.h"
#import "CVSEditorViewController.h"
#import "DQPhoneDrawViewController.h"
#import "DQGalleryViewController.h"

@interface DQPhoneQuestPublishController ()

@property (nonatomic, weak) DQGalleryViewController *galleryViewController;

@end

@implementation DQPhoneQuestPublishController

- (void)_presentNiceJob
{
    // FIXME: implement
    NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
}

- (void)_completePresentingNiceJob
{
    // FIXME: implement
    NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
}

- (void)_presentAddFriends
{
    // FIXME: implement
    NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
}

- (void)_presentGallery
{
    if (self.showGalleryBlock)
    {
        __weak typeof(self) weakSelf = self;
        self.showGalleryBlock(self, ^(DQGalleryViewController *galleryViewController) {
            galleryViewController.galleryViewControllerFirstTimeViewDidAppearBlock = ^(DQGalleryViewController *galleryViewController) {
                weakSelf.galleryViewController = galleryViewController;
                [weakSelf.statechart complete:weakSelf];
            };
        });
    }
    else
    {
        // FIXME: fail
    }
}

@end
