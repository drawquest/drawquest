//
//  DQPadCommentPublishViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-16.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPadCommentPublishViewController.h"

// Additions
#import "STUtils.h"
#import "DQAnalyticsConstants.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "UIFont+DQAdditions.h"

// Views
#import "DQRewardTableViewCell.h"
#import "DQSharingTableViewCell.h"
#import "DQCoinsLabel.h"

static const CGFloat kDQPadPublishViewWidth = 540.0f;
static const CGFloat kDQPublishViewHeaderViewHeight = 38.0f;
static const CGFloat kDQPublishViewFooterViewHeight = 18.0f;
static const CGFloat kDQPublishViewTablePadding = 30.0f;

@interface DQPadCommentPublishViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation DQPadCommentPublishViewController

- (void)loadView
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    containerView.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.backgroundView = nil;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.delaysContentTouches = NO;
    _tableView.scrollEnabled = NO;
    [containerView addSubview:_tableView];


    self.view = containerView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = CGRectInset(self.view.bounds, 0.0f, 0.0f);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self logEvent:DQAnalyticsEventViewPublish withParameters:nil];
    [self.publishDelegate refreshRewardsInfoForCommentPublishViewController:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Rewards

- (DQSharingTableViewCell *)facebookSharingTableViewCell
{
    DQSharingTableViewCell *sharingCell = (DQSharingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    return sharingCell;
}

- (DQSharingTableViewCell *)twitterSharingTableViewCell
{
    DQSharingTableViewCell *sharingCell = (DQSharingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    return sharingCell;
}

- (void)updateDisplayRewardsInfo
{
    [super updateDisplayRewardsInfo];
    NSNumber *personalFacebookShareValue = [self.rewardsInfo numberForKey:DQAPIValueRewardTypePersonalFacebookShare] ? [self.rewardsInfo numberForKey:DQAPIValueRewardTypePersonalFacebookShare] : @(DQPublishDefaultPersonalShareRewardValue);
    NSNumber *personalTwitterShareValue = [self.rewardsInfo numberForKey:DQAPIValueRewardTypePersonalTwitterShare] ? [self.rewardsInfo numberForKey:DQAPIValueRewardTypePersonalTwitterShare] : @(DQPublishDefaultPersonalShareRewardValue);
    DQSharingTableViewCell *facebookSharingCell = [self facebookSharingTableViewCell];
    DQSharingTableViewCell *twitterSharingCell = [self twitterSharingTableViewCell];
    [facebookSharingCell setRewardAmount:[personalFacebookShareValue stringValue]];
    [twitterSharingCell setRewardAmount:[personalTwitterShareValue stringValue]];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellID = @"CoinCell";
    static NSString *SegmentedCellID = @"SegmentedCell";

    NSString *reuseIdentifier = (indexPath.section == 0) ? CellID : SegmentedCellID;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell)
    {
        Class cellClass;
        if (indexPath.section == 0)
        {
            cellClass = [DQRewardTableViewCell class];
        }
        else
        {
            cellClass = [DQSharingTableViewCell class];
        }
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    if (indexPath.section == 0)
    {
        DQRewardTableViewCell *rewardCell = (DQRewardTableViewCell *)cell;

        rewardCell.titleLabel.text = [self.rewardsDescriptions objectAtIndex:indexPath.row];

        NSNumber *rewardsValue = [self.rewardsValues objectAtIndex:indexPath.row];
        if (rewardsValue) {
            // Hack to make sure the coinsLabel has bounds > 0
            // when the view controller is pushed onto the nav stack
            rewardCell.coinsLabel.frameWidth = 85.0f;
            rewardCell.coinsLabel.frameHeight = 35.0f;
            rewardCell.coinsLabel.text = [rewardsValue stringValue];
        }
        [rewardCell setSelectionStyle:UITableViewCellEditingStyleNone];

        // Show the proper icon
        NSArray *keys = [self.rewardsInfo sortedKeys];
        NSString *currentKey = [keys objectAtIndex:[indexPath row]];
        if ([currentKey isEqual:DQAPIValueRewardTypeStreak3] || [currentKey isEqual:DQAPIValueRewardTypeStreak10] || [currentKey isEqual:DQAPIValueRewardTypeStreak100]) {
            rewardCell.iconType = DQRewardTableViewCellIconTypeFire;
        } else {
            rewardCell.iconType = DQRewardTableViewCellIconTypeCheckmark;
        }
    }
    else if (indexPath.section == 1)
    {
        DQSharingTableViewCell *sharingCell = (DQSharingTableViewCell *)cell;

        if (indexPath.row == 0) // Facebook
        {
            [sharingCell configureForFacebookIsSharing:[self.publishDataSource isSharingWithFacebookForCommentPublishViewController:self]];
            __weak typeof(self) weakSelf = self;
            sharingCell.toggledBlock = ^(DQSharingTableViewCell *cell, BOOL isOn) {
                [weakSelf.publishDataSource commentPublishViewController:weakSelf setSharingWithFacebook:isOn];
            };
        }
        else if (indexPath.row == 1) // Twitter
        {
            [sharingCell configureForTwitterIsSharing:[self.publishDataSource isSharingWithTwitterForCommentPublishViewController:self]];
            __weak typeof(self) weakSelf = self;
            sharingCell.toggledBlock = ^(DQSharingTableViewCell *cell, BOOL isOn) {
                [weakSelf.publishDataSource commentPublishViewController:weakSelf setSharingWithTwitter:isOn];
            };
        }
    }


    /*if (cell)
     {
     cell.contentView.layer.borderWidth = 1.0f;
     cell.contentView.layer.borderColor = [[UIColor dq_modalTableSeperatorColor] CGColor];
     }*/

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 0;
    if (section == 0) {
        rowCount = self.rewardsDescriptions ? self.rewardsDescriptions.count : 0;
    } else if (section == 1) {
        rowCount = 2;
    }

    return rowCount;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 63.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(26,
                                                                         0.0f,
                                                                         kDQPadPublishViewWidth - 2 * kDQPublishViewTablePadding,
                                                                         kDQPublishViewHeaderViewHeight)];
        headerLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20.0];
        headerLabel.textColor = [UIColor colorWithRed:(136/255.0) green:(136/255.0) blue:(136/255.0) alpha:1];
        headerLabel.text = DQLocalizedString(@"Share with Friends to earn extra coins", @"Prompt to have users share their drawing with friends which will earn them coins");
        [headerLabel sizeToFit];

        UIView *view = [[UIView alloc] init];
        [view addSubview:headerLabel];

        return view;
    }
    else
    {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        return kDQPublishViewHeaderViewHeight;
    }
    else
    {
        return 0.0f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kDQPublishViewFooterViewHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            BOOL sharing = [self.publishDataSource isSharingWithFacebookForCommentPublishViewController:self];
            [self.publishDataSource commentPublishViewController:self setSharingWithFacebook:!sharing];
        }
        else if (indexPath.row == 1)
        {
            BOOL sharing = [self.publishDataSource isSharingWithTwitterForCommentPublishViewController:self];
            [self.publishDataSource commentPublishViewController:self setSharingWithTwitter:!sharing];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end

@implementation DQPadCommentPublishViewController (TemplateMethods)

#pragma mark - Accessors

- (UIView *)twitterSharingView
{
    return [self twitterSharingTableViewCell];
}

@end
