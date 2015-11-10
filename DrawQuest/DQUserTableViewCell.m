//
//  DQUserTableViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/31/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQUserTableViewCell.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

#import "DQCircularMaskImageView.h"

@implementation DQUserTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    _avatarView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectMake(19, 20, 40, 40)];
    [self.contentView addSubview:_avatarView];
    
    _usernameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _usernameLabel.backgroundColor = [UIColor clearColor];
    _usernameLabel.textColor = [UIColor colorWithRed:(252/255.0) green:(108/255.0) blue:(138/255.0) alpha:1.0];
    [self.contentView addSubview:_usernameLabel];
    
    return self;
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    [_avatarView prepareForReuse];
    _usernameLabel.text = nil;
}


#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.usernameLabel sizeToFit];
    self.usernameLabel.frameX = self.avatarView.frameMaxX + 16.0;
    self.usernameLabel.frameCenterY = self.avatarView.frameCenterY;
}

@end
