//
//  DQPadCommentPublishController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadCommentPublishController.h"
#import "CVSEditorViewController.h"
#import "DQGalleryViewController.h"
#import "DQAddFriendsViewController.h"
#import "DQNavigationController.h"

@interface DQPadCommentPublishController ()

@property (nonatomic, weak) DQGalleryViewController *galleryViewController;

@end

@implementation DQPadCommentPublishController

- (void)_presentNiceJob
{
    if (self.makeNiceJobViewControllerBlock)
    {
        UIViewController *vc = self.makeNiceJobViewControllerBlock(self);

        vc.navigationItem.hidesBackButton = YES;

        UIBarButtonItem *doneButton = [self newBarButtonItemWithTitle:DQLocalizedString(@"Done", @"User is done with this action button title") action:@selector(presentingNiceJobDoneTapped:) isPrimaryAction:YES];
        vc.navigationItem.rightBarButtonItem = doneButton;

        if (self.modalNavigationController.presentingViewController)
        {
            [self.modalNavigationController pushViewController:vc animated:YES];
        }
        else
        {
            [self.modalNavigationController setViewControllers:@[vc]];
            [self.galleryViewController presentViewController:self.modalNavigationController animated:YES completion:nil];
        }
    }
    else
    {
        // TODO: fail
    }
}

- (void)_completePresentingNiceJob
{
    __weak typeof(self) weakSelf = self;
    [self.galleryViewController dismissViewControllerAnimated:YES completion:^{
        [weakSelf complete];
    }];
}

- (void)_presentAddFriends
{
    if (self.makeAddFriendsViewControllerBlock)
    {
        DQAddFriendsViewController *vc = self.makeAddFriendsViewControllerBlock(self);

        if (vc)
        {
            vc.title = DQLocalizedString(@"Add Friends", @"Title for modal where the user can invite their friends to DrawQuest");

            __weak typeof(self) weakSelf = self;
            __weak typeof(vc) weakVC = vc;
            //            vc.navigationItem.leftBarButtonItem = [self newCancelBarButtonItemWithBlock:^(id sender) {
            //                [weakVC attemptCancel:^(BOOL cancelled) {
            //                    if (cancelled)
            //                    {
            //                        [weakSelf.statechart dqCancelTask:weakSelf];
            //                    }
            //                }];
            //            }];
            vc.navigationItem.hidesBackButton = YES;
            vc.navigationItem.rightBarButtonItem = [self newBarButtonItemWithTitle:DQLocalizedString(@"Next", @"Proceed to the next phase of the current action") isPrimaryAction:YES block:^(id sender) {
                // self.publishing == NO when PresentingAddFriends, no need to publish:fromService:
                [weakVC submitWithCancellationBlock:^{
                    // do nothing, we're still presenting
                } completionBlock:^{
                    [weakSelf.statechart complete:weakSelf];
                } failureBlock:^(NSError *error) {
                    [weakSelf tellUserAboutFailureWithTitle:DQLocalizedString(@"Add Friends Failed", @"Add friends error alert title") forError:error];
                }];
            }];

            if (self.modalNavigationController.presentingViewController)
            {
                [self.modalNavigationController pushViewController:vc animated:YES];
            }
            else
            {
                [self.modalNavigationController setViewControllers:@[vc]];
                [self.galleryViewController presentViewController:self.modalNavigationController animated:YES completion:nil];
            }
        }
        else
        {
            // Skip add friends if we don't get one
            [self.statechart complete:self];
            
        }
    }
    else
    {
        // TODO: fail
    }
}

- (void)_presentGallery
{
    if (self.showGalleryBlock)
    {
        __weak typeof(self) weakSelf = self;
        self.showGalleryBlock(self, self.editorViewController, ^(DQGalleryViewController *galleryViewController) {
            CVSEditorViewController *c = weakSelf.editorViewController;
            [weakSelf.commentUploadController uploadDraftAtPath:c.draftPath
                                           forQuestWithServerID:c.quest.serverID
                                                          title:c.quest.title
                                                     shareFlags:weakSelf.shareFlags
                                            facebookAccessToken:weakSelf.facebookAccessToken
                                             twitterAccessToken:weakSelf.twitterAccessToken
                                       twitterAccessTokenSecret:weakSelf.twitterAccessTokenSecret
                                                      emailList:weakSelf.emailList];

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

- (NSString *)publishingTitle
{
    if (self.onboarding)
    {
        return DQLocalizedString(@"Share with Friends", @"Message inviting users to share the drawing they are posting with friends");
    }
    else
    {
        return DQLocalizedString(@"Nice Questing!", @"Message complementing users on a job well done as they post a drawing");
    }
}

@end
