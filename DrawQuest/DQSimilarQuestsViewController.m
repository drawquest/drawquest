//
//  DQSimilarQuestsViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/3/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSimilarQuestsViewController.h"

#import "DQTextField.h"
#import "DQAlertView.h"
#import "DQPhoneErrorView.h"
#import "DQTableView.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

static const NSInteger maxTitleLength = 50;

@interface DQSimilarQuestsViewControllerErrorView : UIView

@end

@interface DQSimilarQuestsViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *titleFieldBackgroundView;
@property (nonatomic, weak) DQTableView *tableView;
@property (nonatomic, weak) DQSimilarQuestsViewControllerErrorView *errorView;

@end

@implementation DQSimilarQuestsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        // FIXME: These metrics/colors are all estimated
        UIView *titleFieldBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        titleFieldBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        titleFieldBackgroundView.backgroundColor = [UIColor dq_phoneBackgroundColor];
        titleFieldBackgroundView.layer.shadowColor = [[UIColor blackColor] CGColor];
        titleFieldBackgroundView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        titleFieldBackgroundView.layer.shadowOpacity = 0.05f;
        titleFieldBackgroundView.layer.shadowRadius = 0.0f;
        _titleFieldBackgroundView = titleFieldBackgroundView;

        // Text needs to be around at init for the QuestPublishController
        DQTextField *titleField = [[DQTextField alloc] initWithFrame:CGRectZero];
        titleField.tintColorForText = YES;
        titleField.delegate = self;
        titleField.backgroundColor = [UIColor whiteColor];
        titleField.textInset = UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 24.0f);
        titleField.layer.cornerRadius = 5.0f;
        titleField.layer.borderColor = [[UIColor dq_phoneDivider] CGColor];
        titleField.layer.borderWidth = 1.0f;
        titleField.font = [UIFont dq_questTitleSearchFont];
        titleField.placeholder = DQLocalizedString(@"Enter Your Quest Title", @"Quest title placeholder text");
        titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
        titleField.returnKeyType = UIReturnKeyNext;
        [titleFieldBackgroundView addSubview:titleField];
        _titleField = titleField;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];

    [self.view addSubview:self.titleFieldBackgroundView];

    DQTableView *tableView = [[DQTableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.showsVerticalScrollIndicator = YES;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];

    // Assume this is sparse for now because we know it will be until we implement Quest search
    DQSimilarQuestsViewControllerErrorView *errorView = [[DQSimilarQuestsViewControllerErrorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 100.0f)];
    [self.tableView setHeaderView:errorView];
    self.errorView = errorView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.titleField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView flashScrollIndicators];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // FIXME: These metrics are all estimated

    [self.titleField sizeToFit];
    self.titleFieldBackgroundView.frameWidth = self.view.frameWidth;
    self.titleFieldBackgroundView.frameHeight = self.titleField.frameHeight + 30.0f;

    self.titleField.frameWidth = self.titleFieldBackgroundView.frameWidth - 24.0f;
    self.titleField.frameCenterX = self.titleFieldBackgroundView.frameCenterX;
    self.titleField.frameCenterY = self.titleFieldBackgroundView.frameCenterY;

    self.tableView.frameHeight = self.view.frameHeight - self.titleFieldBackgroundView.frameHeight;
    self.tableView.frameY = self.titleFieldBackgroundView.frameHeight;

    [self.view layoutSubviews];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.width;
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, keyboardHeight, 0.0f);
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    self.tableView.contentInset = UIEdgeInsetsZero;
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.returnTappedOnTitleFieldBlock)
    {
        self.returnTappedOnTitleFieldBlock(self);
    }
    return YES;
}

- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;

    NSUInteger newLength = oldLength - rangeLength + replacementLength;

    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;

    return newLength <= maxTitleLength || returnKey;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

@end

@implementation DQSimilarQuestsViewControllerErrorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UILabel *messageLabelOne = [[UILabel alloc] initWithFrame:CGRectZero];
        messageLabelOne.translatesAutoresizingMaskIntoConstraints = NO;
        messageLabelOne.lineBreakMode = NSLineBreakByTruncatingTail;
        messageLabelOne.numberOfLines = 0;
        messageLabelOne.textAlignment = NSTextAlignmentLeft;
        messageLabelOne.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
        messageLabelOne.textColor = [UIColor dq_phoneGrayTextColor];
        messageLabelOne.text = DQLocalizedString(@"Create your own Quest and share it with friends!", @"Instructions to create a Quest and share it with friends");
        [messageLabelOne sizeToFit];
        [self addSubview:messageLabelOne];

        UILabel *messageLabelTwo = [[UILabel alloc] initWithFrame:CGRectZero];
        messageLabelTwo.translatesAutoresizingMaskIntoConstraints = NO;
        messageLabelTwo.lineBreakMode = NSLineBreakByTruncatingTail;
        messageLabelTwo.numberOfLines = 0;
        messageLabelTwo.textAlignment = NSTextAlignmentLeft;
        messageLabelTwo.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
        messageLabelTwo.textColor = [UIColor dq_phoneGrayTextColor];
        messageLabelTwo.text = DQLocalizedString(@"Followers will see your Quest in their \"New\" tab", @"Instructions on how followers will see the new Quest");
        [messageLabelTwo sizeToFit];
        [self addSubview:messageLabelTwo];

        UILabel *messageLabelThree = [[UILabel alloc] initWithFrame:CGRectZero];
        messageLabelThree.translatesAutoresizingMaskIntoConstraints = NO;
        messageLabelThree.lineBreakMode = NSLineBreakByTruncatingTail;
        messageLabelThree.numberOfLines = 0;
        messageLabelThree.textAlignment = NSTextAlignmentLeft;
        messageLabelThree.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
        messageLabelThree.textColor = [UIColor dq_phoneGrayTextColor];
        messageLabelThree.text = DQLocalizedString(@"Popular Quests appear in the \"All\" tab. Share yours to increase your chances!", @"Instructions on how the new Quest can become popular");
        [messageLabelThree sizeToFit];
        [self addSubview:messageLabelThree];

        UILabel *bulletOne = [[UILabel alloc] initWithFrame:CGRectZero];
        bulletOne.translatesAutoresizingMaskIntoConstraints = NO;
        bulletOne.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
        bulletOne.textColor = [UIColor dq_phoneGrayTextColor];
        bulletOne.text = @"•";
        [bulletOne sizeToFit];
        [self addSubview:bulletOne];

        UILabel *bulletTwo = [[UILabel alloc] initWithFrame:CGRectZero];
        bulletTwo.translatesAutoresizingMaskIntoConstraints = NO;
        bulletTwo.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
        bulletTwo.textColor = [UIColor dq_phoneGrayTextColor];
        bulletTwo.text = @"•";
        [bulletTwo sizeToFit];
        [self addSubview:bulletTwo];

        UILabel *bulletThree = [[UILabel alloc] initWithFrame:CGRectZero];
        bulletThree.translatesAutoresizingMaskIntoConstraints = NO;
        bulletThree.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:13.0f];
        bulletThree.textColor = [UIColor dq_phoneGrayTextColor];
        bulletThree.text = @"•";
        [bulletThree sizeToFit];
        [self addSubview:bulletThree];

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        NSDictionary *viewBindings = NSDictionaryOfVariableBindings(messageLabelOne, messageLabelTwo, messageLabelThree);
        NSDictionary *metrics = @{@"leftInset": @(35), @"rightInset": @(15), @"vInset": @(10), @"linePadding": @(13)};

        DQVisualConstraints(self, @"H:|-leftInset-[messageLabelOne]-rightInset-|");
        DQVisualConstraints(self, @"H:|-leftInset-[messageLabelTwo]-rightInset-|");
        DQVisualConstraints(self, @"H:|-leftInset-[messageLabelThree]-rightInset-|");
        DQVisualConstraints(self, @"V:|-vInset-[messageLabelOne]-linePadding-[messageLabelTwo]-linePadding-[messageLabelThree]-vInset-|");

        CGFloat bulletPadding = 3.0f;
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bulletOne attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageLabelOne attribute:NSLayoutAttributeLeft multiplier:1.0f constant:-bulletPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bulletOne attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:messageLabelOne attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:bulletTwo attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageLabelTwo attribute:NSLayoutAttributeLeft multiplier:1.0f constant:-bulletPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bulletTwo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:messageLabelTwo attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:bulletThree attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageLabelThree attribute:NSLayoutAttributeLeft multiplier:1.0f constant:-bulletPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bulletThree attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:messageLabelThree attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
    return self;
}

@end
