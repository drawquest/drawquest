//
//  DQShareWebProfileCell.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQShareWebProfileCell.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"

@interface DQShareWebProfileCell ()
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UISwitch *sharingSwitch;
@end

@implementation DQShareWebProfileCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
        _sharing = YES;
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.contentView.layer.backgroundColor = [[UIColor dq_modalTableCellBackgroundColor] CGColor];
    self.contentView.layer.cornerRadius = 10.0f;
    self.contentView.layer.borderColor = [[UIColor dq_modalTableSeperatorColor] CGColor];
    self.contentView.layer.borderWidth = 1.0f;

    self.titleLabel.textColor = [UIColor dq_modalPrimaryTextColor];
    self.titleLabel.font = [UIFont dq_rewardTextFont];
}

#pragma mark - Actions

- (IBAction)sharingSwitchChanged:(UISwitch *)sender
{
    _sharing = !self.sharing;
    if (self.sharingBlock)
    {
        self.sharingBlock(self, _sharing);
    }
}

#pragma mark - Accessors

- (void)setSharing:(BOOL)sharing
{
    [self willChangeValueForKey:@"sharing"];
    _sharing = sharing;
    self.sharingSwitch.on = sharing;
    [self didChangeValueForKey:@"sharing"];
}

- (void)setTitle:(NSString *)title
{
    [self willChangeValueForKey:@"title"];
    _title = [title copy];
    self.titleLabel.text = _title;
    [self didChangeValueForKey:@"title"];
}

@end
