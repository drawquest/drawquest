//
//  DQAuthenticationConstants.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-06-12.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DQNavigationController;

typedef NS_ENUM(NSUInteger, DQAuthenticationOption) {
    DQAuthenticationOptionDefault = 0,
    DQAuthenticationOptionSignIn,
    DQAuthenticationOptionEmailSignUp,
    DQAuthenticationOptionFacebookSignUp,
    DQAuthenticationOptionTwitterSignUp,
};

typedef NS_ENUM(NSUInteger, DQAuthenticationSignupService) {
    DQAuthenticationSignupServiceNone = 0,
    DQAuthenticationSignupServiceEmail,
    DQAuthenticationSignupServiceFacebook,
    DQAuthenticationSignupServiceTwitter
};

typedef void(^DQAuthenticationCompletionBlock)(DQAuthenticationSignupService service, DQNavigationController *modalNavigationController);
