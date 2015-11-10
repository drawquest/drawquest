//
//  DQFirstQuestCompletionViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 12/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQFirstQuestCompletionViewController.h"

#import "UIFont+DQAdditions.h"
#import "UIButton+DQAdditions.h"
#import "UIView+STAdditions.h"

typedef enum {
    DQCompletionRowMenu = 0,
    DQCompletionRowStars,
    DQCompletionRowPlay,
    DQCompletionRowCoins
} DQCompletionRow;

@interface DQCompletionTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconView;

@end

@interface DQFirstQuestCompletionViewController() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *illustrationImageView;

@end

@implementation DQFirstQuestCompletionViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    view.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 66.0f;
    self.tableView.scrollEnabled = NO;

    [view addSubview:self.tableView];

    self.illustrationImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"niceQuesting_art_tools"]];
    [view addSubview:self.illustrationImageView];

    self.view = view;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGRect tableViewFrame = CGRectMake(30.0, 30.0, bounds.size.width - 30.0*2, 308.0);
    self.tableView.frame = tableViewFrame;
    [self.illustrationImageView setFrameCenterX:self.view.center.x];
    [self.illustrationImageView setFrameY:CGRectGetMaxY(tableViewFrame) + 23.0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Configuration

- (UIImage *)imageForRow:(NSInteger)row
{
    NSString *imageName = nil;
    switch (row) {
        case DQCompletionRowMenu:
            imageName = @"niceQuesting_menu";
            break;
        case DQCompletionRowStars:
            imageName = @"niceQuesting_star";
            break;
        case DQCompletionRowPlay:
            imageName = @"niceQuesting_play";
            break;
        case DQCompletionRowCoins:
            imageName = @"niceQuesting_coins";
            break;
        default:
            break;
    }
    
    return [UIImage imageNamed:imageName];
}

- (NSString *)textForRow:(NSInteger)row
{
    NSString *text = nil;
    switch (row) {
        case DQCompletionRowMenu:
            text = DQLocalizedString(@"See what's new by tapping the menu button.", @"Instructions to tap the menu button to see new activity");
            break;
        case DQCompletionRowStars:
            text = DQLocalizedString(@"Give stars to your favorite drawings.", @"Instructions to star other users' drawings");
            break;
        case DQCompletionRowPlay:
            text = DQLocalizedString(@"Play back your favorite drawings to see how your fellow Questers created their masterpiece.", @"Instructions to watch the playback for drawings");
            break;
        case DQCompletionRowCoins:
            text = DQLocalizedString(@"Earn coins by being an active Quester. Spend coins to unlock more colors!", @"Instructions for earning and spending coins");
            break;
        default:
            text = @"";
            break;
    }
    
    return text;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellID = @"Cell";
    DQCompletionTableViewCell *cell = (DQCompletionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        cell = [[DQCompletionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID];
    }
    
    cell.iconView.image = [self imageForRow:indexPath.row];
    cell.titleLabel.text = [self textForRow:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

@end

@implementation DQCompletionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont dq_completionLabelFont];
    _titleLabel.numberOfLines = 0;
    _titleLabel.textColor = [UIColor colorWithRed:0.60 green:0.58 blue:0.57 alpha:1.0];
    [self.contentView addSubview:_titleLabel];
    
    _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_iconView];
    
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentRect = CGRectInset([self.contentView bounds], 50.0f, 0.0f);
    CGRect iconRect;
    CGRect titleRect;
    CGRectDivide(contentRect, &iconRect, &titleRect, 53.0f, CGRectMinXEdge);
    
    self.iconView.frame = (CGRect){.origin = iconRect.origin, .size = CGSizeMake(73.0f, 58.0f)};
    self.iconView.center = (CGPoint){.x = _iconView.center.x, .y = CGRectGetMidY(contentRect)};

    self.titleLabel.frame = CGRectOffset(titleRect, 10.0f, 5.0f);
}

@end
