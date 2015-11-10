//
//  DQPhoneAddFriendsAuthorizeView.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPhoneAddFriendsAuthorizeView.h"

#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

@implementation DQPhoneAddFriendsAuthorizeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.message.backgroundColor = [UIColor clearColor];
        self.message.textAlignment = NSTextAlignmentCenter;
        self.message.lineBreakMode = NSLineBreakByWordWrapping;
        self.message.numberOfLines = 0;
        self.message.font = [UIFont dq_galleryErrorMessageFont];
        self.message.textColor = [UIColor dq_modalPrimaryTextColor];
    }
    return self;
}

@end
