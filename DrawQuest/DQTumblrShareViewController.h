//
//  DQTumblrShareViewController.h
//  DrawQuest
//
//  Created by David Mauro on 4/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQTumblrShareViewController : UIViewController

@property (nonatomic, copy) void (^shareSuccessBlock)(DQTumblrShareViewController *vc);

// designated initializer
- (id)initWithPhotoURL:(NSString *)sharePhotoURL clickThruURL:(NSString *)shareLinkURL caption:(NSString *)shareCaption tags:(NSString *)shareTags tumblrSuccessRegexPattern:(NSString *)tumblrSuccessRegexPattern;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithPhotoURL:clickThruURL:caption:tags:tumblrSuccessRegexPattern:delegate:);

@end
