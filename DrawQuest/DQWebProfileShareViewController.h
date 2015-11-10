//
//  DQWebProfileShareViewController.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"

@class DQTwitterController, DQFacebookController;

typedef NS_ENUM(unsigned char, DQWebProfileService)
{
    DQWebProfileServiceTwitter = 0,
    DQWebProfileServiceFacebook,
};

@interface DQWebProfileShareViewController : DQViewController

@property (nonatomic, readonly, weak) DQTwitterController *twitterController;
@property (nonatomic, readonly, weak) DQFacebookController *facebookController;
@property (nonatomic, readonly, strong) NSString *shareMessage;
@property (nonatomic, readonly, assign) BOOL shareOnFacebook;
@property (nonatomic, readonly, assign) BOOL shareOnTwitter;

- (instancetype)initWithPrivacy:(BOOL)privacy twitterController:(DQTwitterController *)twitterController facebookController:(DQFacebookController *)facebookController delegate:(id<DQViewControllerDelegate>)delegate;

@end
