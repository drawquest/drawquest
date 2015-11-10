//
//  DQPadAddFriendsAuthorizeView.m
//  DrawQuest
//
//  Created by David Mauro on 10/29/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadAddFriendsAuthorizeView.h"

#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

@implementation DQPadAddFriendsAuthorizeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        self.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];

        self.message.backgroundColor = [UIColor clearColor];
        self.message.textAlignment = NSTextAlignmentCenter;
        self.message.lineBreakMode = NSLineBreakByWordWrapping;
        self.message.numberOfLines = 0;
        self.message.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15.0];
        self.message.textColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1];
    }
    return self;
}

@end
