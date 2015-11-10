//
//  DQPhoneCommentPublishController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-18.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneCommentPublishController.h"

// View Controllers
#import "CVSEditorViewController.h"
#import "DQPublishAuthViewController.h"
#import "DQPhoneDrawViewController.h"
#import "DQGalleryViewController.h"
#import "DQNavigationController.h"

@interface DQPhoneCommentPublishController ()

@property (nonatomic, weak) DQGalleryViewController *galleryViewController;

@end

@implementation DQPhoneCommentPublishController

- (void)_presentNiceJob
{
    // FIXME: implement
    NSLog(@"not implemented yet: %@", NSStringFromSelector(_cmd));
    [self.statechart complete:self];
}

- (void)_completePresentingNiceJob
{
    // FIXME: implement
    [self complete];
}

- (void)_presentAddFriends
{
    // iPhone will not do this as part of flow
    [self.statechart complete:self];
}

- (void)_presentAuth
{
    if (self.makePublishAuthViewControllerBlock)
    {
        __weak typeof(self) weakSelf = self;
        self.modalNavigationController = self.makeModalNavigationControllerBlock(self);
        DQPublishAuthViewController *vc = self.makePublishAuthViewControllerBlock(self);
        vc.title = DQLocalizedString(@"Join DrawQuest", @"Sign up modal title");

        UIBarButtonItem *backButtonItem = [self newPhoneBarButtonItemWithImageNamed:@"button_topNav_back" buttonBlock:^(DQButton *button) {
            [weakSelf.statechart dqCancelTask:weakSelf];
        }];
        vc.navigationItem.leftBarButtonItem = backButtonItem;
        vc.facebookBlock = ^(DQPublishAuthViewController *c) {
            [weakSelf.statechart auth:weakSelf withOption:@(DQAuthenticationOptionFacebookSignUp)];
        };
        vc.twitterBlock = ^(DQPublishAuthViewController *c, UIView *sender) {
            [weakSelf.statechart authTwitter:weakSelf fromView:sender];
        };
        vc.drawQuestBlock = ^(DQPublishAuthViewController *c) {
            [weakSelf.statechart auth:weakSelf withOption:@(DQAuthenticationOptionEmailSignUp)];
        };
        vc.signInBlock = ^(DQPublishAuthViewController *c) {
            [weakSelf.statechart auth:weakSelf withOption:@(DQAuthenticationOptionSignIn)];
        };
        [self.modalNavigationController setViewControllers:@[vc]];
        [self.editorViewController presentViewController:self.modalNavigationController animated:YES completion:nil];
    }
    else
    {
        // TODO: fail
    }
}

- (void)_presentGallery
{
    if (self.isOnboarding)
    {
        CVSEditorViewController *c = self.editorViewController;
        [self.commentUploadController uploadDraftAtPath:c.draftPath
                                       forQuestWithServerID:c.quest.serverID
                                                      title:c.quest.title
                                                 shareFlags:self.shareFlags
                                        facebookAccessToken:self.facebookAccessToken
                                         twitterAccessToken:self.twitterAccessToken
                                   twitterAccessTokenSecret:self.twitterAccessTokenSecret
                                                  emailList:self.emailList];
        if (self.showHomeBlock)
        {
            self.showHomeBlock(self, self.editorViewController);
        }
        [self.statechart complete:self];
    }
    else if (self.showGalleryBlock)
    {
        CVSEditorViewController *c = self.editorViewController;
        [self.commentUploadController uploadDraftAtPath:c.draftPath
                                   forQuestWithServerID:c.quest.serverID
                                                  title:c.quest.title
                                             shareFlags:self.shareFlags
                                    facebookAccessToken:self.facebookAccessToken
                                     twitterAccessToken:self.twitterAccessToken
                               twitterAccessTokenSecret:self.twitterAccessTokenSecret
                                              emailList:self.emailList];
        if (self.showGalleryBlock)
        {
            __weak typeof(self) weakSelf = self;
            self.showGalleryBlock(self, self.editorViewController, ^(DQGalleryViewController *galleryViewController) {
                weakSelf.galleryViewController = galleryViewController;
            });
        }
        [self.statechart complete:self];
    }
    else
    {
        // FIXME: fail
    }
}

- (NSString *)publishingTitle
{
    return DQLocalizedString(@"Share", @"Drawing being published with options to share the drawing modal title");
}

- (void)_postComplete
{
    [self.statechart gallery:self];
}

@end
