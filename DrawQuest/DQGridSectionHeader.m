//
//  DQGridSectionHeader.m
//  DrawQuest
//
//  Created by Dirk on 4/5/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGridSectionHeader.h"
#import "UIFont+DQAdditions.h"

static const CGRect kDQTitleRect = { { 17.0f, 0.0f }, { 970.0f, 52.0f } };

@implementation DQGridSectionHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:kDQTitleRect];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20.0f];
        titleLabel.textColor = [UIColor colorWithRed:(154/255.0) green:(154/255.0) blue:(154/255.0) alpha:1];
        titleLabel.text = DQLocalizedString(@"Try These Recent Quests", @"Label for a list of recent Quests the user can complete");
        
        [self addSubview:titleLabel];
        _titleLabel = titleLabel;
        
        UIView *gradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1136, 1)];
        gradientView.backgroundColor = [UIColor colorWithRed:(232/255.0) green:(232/255.0) blue:(232/255.0) alpha:1.0];
        [self addSubview:gradientView];
        
        self.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];
        
        [self setClipsToBounds:NO];
    }
    return self;
}

@end
