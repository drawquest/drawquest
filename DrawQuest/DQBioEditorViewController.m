//
//  DQBioEditorViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQBioEditorViewController.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

// Views
#import "DQTableViewCell.h"

#define kMaxCharacters 500

@interface DQBioEditorTableViewCell : DQTableViewCell <UITextViewDelegate>

@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) dispatch_block_t keyboardDoneTappedBlock;

@end

@interface DQBioEditorViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DQBioEditorTableViewCell *cell;

@end

@implementation DQBioEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.backgroundView = nil;
        tableView.scrollEnabled = NO;
        tableView.backgroundColor = [UIColor dq_phoneBackgroundColor];
        _tableView = tableView;

        DQBioEditorTableViewCell *cell = [[DQBioEditorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        __weak typeof(self) weakSelf = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.keyboardDoneTappedBlock = ^{
            if (weakSelf.keyboardDoneTappedBlock)
            {
                weakSelf.keyboardDoneTappedBlock();
            }
        };
        _cell = cell;
    }
    return self;
}

- (void)loadView
{
    self.view = self.tableView;
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

- (NSString *)text
{
    return self.cell.text;
}

- (void)setText:(NSString *)text
{
    self.cell.text = text;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 46.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = 46.0f;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frameWidth, height)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 0.0f, tableView.frameWidth - 15.0f, height)];
    [view addSubview:label];
    label.backgroundColor = [UIColor dq_phoneBackgroundColor];
    label.font = [UIFont dq_modalTableHeaderFont];
    label.textColor = [UIColor dq_phoneSettingsSectionHeaderTitleColor];
    label.text = DQLocalizedString(@"Bio", @"A short label for the biographical information of the user");
    return view;
}

@end

@implementation DQBioEditorTableViewCell
{
    UITextView *_textView;
    UILabel *_remainingLabel;
}

// @dynamic text;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.font = [UIFont dq_phoneSettingsLabelFont];
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.returnKeyType = UIReturnKeyDone;
        _textView.delegate = self;
        // _textView.backgroundColor = [UIColor yellowColor];

        _remainingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _remainingLabel.font = [UIFont dq_phoneSettingsLabelFont];
        _remainingLabel.textColor = [UIColor dq_phoneGrayTextColor];
        _remainingLabel.textAlignment = NSTextAlignmentRight;
        // _remainingLabel.backgroundColor = [UIColor blueColor];
        [self addSubview:_textView];
        [self addSubview:_remainingLabel];
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    _textView.textColor = self.tintColor;
}

- (NSString *)text
{
    return _textView.text;
}

- (void)setText:(NSString *)text
{
    _textView.text = text;
    [self updateRemainingLabelTextWithTextLength:[text length]];
    [self setNeedsLayout];
}

- (void)updateRemainingLabelTextWithTextLength:(NSUInteger)newLength
{
    _remainingLabel.text = [NSString stringWithFormat:DQLocalizedString(@"%lu characters remaining", @"Number of characters left for a user to fill in before they reach the maximum limit"), (unsigned long)(kMaxCharacters - newLength)];
    [self setNeedsLayout];
}

- (void)prepareForReuse
{
    self.text = nil;
    [super prepareForReuse];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _remainingLabel.frame = CGRectMake(15, 130, self.frameWidth - 30, 20);
    _textView.frame = CGRectMake(15, 15, self.frameWidth - 30, 105);
    // NSLog(@"_textView.frame = %@", NSStringFromCGRect(_textView.frame));
    // NSLog(@"_remainingLabel.frame = %@", NSStringFromCGRect(_remainingLabel.frame));
}

#pragma mark -
#pragma mark UItextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL returnKey = [text rangeOfString:@"\n"].location != NSNotFound;
    if (returnKey)
    {
//        [textView resignFirstResponder];
        if (self.keyboardDoneTappedBlock)
        {
            self.keyboardDoneTappedBlock();
        }
        return NO;
    }
    else
    {
        NSUInteger oldLength = [textView.text length];
        NSUInteger replacementLength = [text length];
        NSUInteger rangeLength = range.length;

        NSUInteger newLength = oldLength - rangeLength + replacementLength;

        BOOL result = newLength <= kMaxCharacters;
        [self updateRemainingLabelTextWithTextLength:newLength];
        return result;
    }
}

@end
