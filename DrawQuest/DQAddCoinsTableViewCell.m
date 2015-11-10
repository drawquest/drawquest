//
//  DQAddCoinsTableViewCell.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/2/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQAddCoinsTableViewCell.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIButton+DQAdditions.h"
#import "UIView+STAdditions.h"

#import "DQCoinsLabel.h"

@implementation DQAddCoinsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _coinsLabel = [[DQCoinsLabel alloc] initWithFrame:CGRectZero coinPosition:DQCoinsLabelCoinPositionLeft];
    [self.contentView addSubview:_coinsLabel];
    
    _purchaseButton = [DQButton dq_buttonForCellAction];
    
    self.accessoryView = _purchaseButton;
    
    return self;
}


#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentBounds = CGRectInset(self.bounds, 10.0f, 10.0f);
    CGRect leftRect;
    CGRect rightRect;
    CGRectDivide(contentBounds, &leftRect, &rightRect, 300.0f, CGRectMinXEdge);
    
    self.coinsLabel.frame = CGRectMake(0, 0, 200, 50);
    self.coinsLabel.frameCenterY = CGRectGetMidY(contentBounds);
    self.coinsLabel.frameX = 19.0;
}

@end
