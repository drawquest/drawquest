//
//  DQExploreSearchBar.m
//  DrawQuest
//
//  Created by Dirk on 4/16/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQExploreSearchBar.h"

#import "UIColor+DQAdditions.h"

@interface DQExploreSearchBar()
@end

@implementation DQExploreSearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.layer.cornerRadius = 3;
        self.tintColor = [UIColor dq_blueColor];
        [self setPlaceholder:DQLocalizedString(@"Search People", @"Search for users search field placeholder text")];
        [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [self setAutocorrectionType:UITextAutocorrectionTypeNo];
        [self setReturnKeyType:UIReturnKeySearch];
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setFont:[UIFont systemFontOfSize:15]];
        
        UIImageView *searchIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_search_Magnifying_glass"]];
        searchIconImageView.frame = CGRectMake(0, 0, 29, 28);
        searchIconImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:searchIconImageView];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 29 , 0 );
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 29 , 0 );
    
}

@end
