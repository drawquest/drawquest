//
//  DQAbstractAuthViewController.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAbstractAuthViewController.h"

// Views
#import "DQTextField.h"
#import "DQButton.h"

// Additions
#import "DQAbstractAuthViewController+TemplateMethods.h"
#import "UIView+STAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "DQViewMetricsConstants.h"
#import "UIButton+DQAdditions.h"

@interface DQAbstractAuthViewController () <UITextFieldDelegate>

@property (nonatomic, strong, readwrite) NSArray *textFields;
@property (nonatomic, assign) BOOL willSubmit;
@property (nonatomic, weak) UILabel *switchQuestionLabel;
@property (nonatomic, weak) UILabel *switchActionLabel;
@property (nonatomic, weak) UIButton *switchButton;
@property (nonatomic, weak) UIView *wrapperView;
@property (nonatomic, weak) UILabel *socialHeaderImageView;
@property (nonatomic, weak) UIButton *facebookButton;
@property (nonatomic, weak) UIButton *twitterButton;
@property (nonatomic, weak) UIButton *submitButton;
@property (nonatomic, weak) UIView *textFieldsWrapper;
@property (nonatomic, weak) UITableView *fieldsTableView;


@end

@implementation DQAbstractAuthViewController

@dynamic username;
@dynamic password;
@dynamic email;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _showSocialLoginButtons = YES;
        _textFields = [self initializedTextFields];
        _willSubmit = NO;
    }
    return self;
}

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate showSocialLoginButtons:(BOOL)showSocialLoginButtons
{
    self = [self initWithDelegate:delegate];
    if (self)
    {
        _showSocialLoginButtons = showSocialLoginButtons;
    }
    return self;
}

- (void)addFieldToFields:(NSMutableArray *)textFields atIndex:(NSUInteger)index fieldCount:(NSUInteger)fieldCount
{
    DQTextField *textField = [[DQTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor whiteColor];
    textField.textColor = [UIColor dq_authTextFieldTextColor];
    textField.placeholder = [self placeholderForFieldAtIndex:index];
    textField.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.tag = index;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.returnKeyType = (index != fieldCount - 1) ? UIReturnKeyNext : UIReturnKeyGo;
    textField.delegate = self;
    [self customizeField:textField atIndex:index];
    [textFields addObject:textField];
}

- (NSArray *)initializedTextFields
{
    NSMutableArray *textFields = [[NSMutableArray alloc] init];
    NSUInteger fieldCount = [self numberOfFields];

    for (NSUInteger index = 0; index < fieldCount; index++) {
        [self addFieldToFields:textFields
                       atIndex:index
                    fieldCount:fieldCount];
    }

    return textFields;
}

- (NSString *)username
{
    NSUInteger idx = [self indexOfUsernameField];
    if (idx == NSNotFound)
    {
        return nil;
    }
    else
    {
        UITextField *f = [self.textFields objectAtIndex:idx];
        return f.text;
    }
}

- (void)setUsername:(NSString *)username
{
    NSUInteger idx = [self indexOfUsernameField];
    if (idx != NSNotFound)
    {
        UITextField *f = [self.textFields objectAtIndex:idx];
        f.text = username;
    }
}

- (NSString *)password
{
    NSUInteger idx = [self indexOfPasswordField];
    if (idx == NSNotFound)
    {
        return nil;
    }
    else
    {
        UITextField *f = [self.textFields objectAtIndex:idx];
        return f.text;
    }
}

- (void)setPassword:(NSString *)password
{
    NSUInteger idx = [self indexOfPasswordField];
    if (idx != NSNotFound)
    {
        UITextField *f = [self.textFields objectAtIndex:idx];
        f.text = password;
    }
}

- (NSString *)email
{
    NSUInteger idx = [self indexOfEmailField];
    if (idx == NSNotFound)
    {
        return nil;
    }
    else
    {
        UITextField *f = [self.textFields objectAtIndex:idx];
        return f.text;
    }
}

- (void)setEmail:(NSString *)email
{
    NSUInteger idx = [self indexOfEmailField];
    if (idx != NSNotFound)
    {
        UITextField *f = [self.textFields objectAtIndex:idx];
        f.text = email;
    }    
}

#pragma mark -
#pragma mark Submitting

- (void)submitButtonPressed:(id)sender
{
    [self submit:sender];
}

- (void)submit:(id)sender
{
    if ([self validateFormAndReportErrors])
    {
        self.willSubmit = YES;
        [self.view endEditing:YES];
        [self finish];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSUInteger lastFieldIndex = [self numberOfFields] - 1;

    if (textField.tag == lastFieldIndex)
    {
        self.willSubmit = YES;
        [textField resignFirstResponder];
        [self submit:textField];
    }
    else
    {
        self.willSubmit = NO;
        UITextField *nextField = (UITextField *)[self.view viewWithTag:textField.tag + 1];
        [nextField becomeFirstResponder];
    }

    return YES;
}

#pragma mark - Actions

- (void)facebook:(id)sender
{
    if (self.facebookBlock)
    {
        self.facebookBlock(self);
    }
}

- (void)twitter:(id)sender
{
    if (self.twitterBlock)
    {
        self.twitterBlock(self, sender);
    }
}

- (void)switchButtonTouchDown:(id)sender
{
    self.switchQuestionLabel.highlighted = YES;
    self.switchActionLabel.highlighted = YES;
}

- (void)switchButtonTouchUpOutside:(id)sender
{
    self.switchQuestionLabel.highlighted = NO;
    self.switchActionLabel.highlighted = NO;
}

- (void)switchButtonTouchUpInside:(id)sender
{
    self.switchQuestionLabel.highlighted = NO;
    self.switchActionLabel.highlighted = NO;
    if (self.switchBlock)
    {
        self.switchBlock(self);
    }
}

#pragma mark - Validation

- (void)showErrorWithDescription:(NSString *)description
{
    if (!description)
    {
        description = DQLocalizedString(@"Unknown error.", @"Unknown error alert message");
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Authentication Error", @"Authentication error alert title") message:description delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UITextField *textField = self.textFields[indexPath.row];
    textField.frame = CGRectMake(15, 0, self.view.frame.size.width, 44);
    
    [cell addSubview:textField];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.textFields.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:FALSE];
}


#pragma mark - UIViewController

- (void)loadView
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.backgroundColor = [UIColor colorWithRed:(248/255.0) green:(248/255.0) blue:(248/255.0) alpha:1];

        UIView *wrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        [view addSubview:wrapperView];
        self.wrapperView = wrapperView;

        UIView *bottomView = nil;
        
        UITableView *tableView = [[UITableView alloc] init];
        tableView.delegate = self;
        tableView.dataSource = self;
        [self.wrapperView addSubview:tableView];
        self.fieldsTableView = tableView;
        
        UIButton *submitButton = [UIButton dq_buttonForMainAction];
        submitButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15];
        [submitButton setTitle:self.submitButtonTitle forState:UIControlStateNormal];
        submitButton.layer.cornerRadius = 3;
        submitButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        [submitButton addTarget:self action:@selector(submitButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:submitButton];
        self.submitButton = submitButton;
        bottomView = submitButton;
        
        UIView *endView = [[UIView alloc] initWithFrame:CGRectMake(0, 525, 540, 64)];
        endView.backgroundColor = [UIColor colorWithRed:(229/255.0) green:(229/255.0) blue:(229/255.0) alpha:1];
        [self.wrapperView addSubview:endView];

        if ([self showSocialLoginButtons])
        {
            NSString *headerImageName = [self headerImageName];
            if (headerImageName)
            {
                UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                headerLabel.backgroundColor = [UIColor clearColor];
                headerLabel.font = [UIFont dq_signInLabelFont];
                headerLabel.textColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1];
                headerLabel.text = headerImageName;
                [view addSubview:headerLabel];
                [headerLabel sizeToFit];
                self.socialHeaderImageView = headerLabel;
            }

            UIButton *facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [facebookButton addTarget:self action:@selector(facebook:) forControlEvents:UIControlEventTouchUpInside];
            UIImage *facebookButtonImage = [UIImage imageNamed:@"button_facebook_short"];
            [facebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
            [view addSubview:facebookButton];
            self.facebookButton = facebookButton;

            UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [twitterButton addTarget:self action:@selector(twitter:) forControlEvents:UIControlEventTouchUpInside];
            UIImage *twitterButtonImage = [UIImage imageNamed:@"button_twitter_short"];
            [twitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
            [view addSubview:twitterButton];
            self.twitterButton = twitterButton;

            bottomView = facebookButton;
        }

        if ([self showSwitchButton])
        {
            
            
            UILabel *switchQuestion = [[UILabel alloc] initWithFrame:CGRectZero];
            switchQuestion.backgroundColor = [UIColor clearColor];
            switchQuestion.font = [UIFont dq_signInLabelFont];
            switchQuestion.textColor = [UIColor colorWithRed:(155/255.0) green:(155/255.0) blue:(155/255.0) alpha:1];
            switchQuestion.text = [self switchQuestionText];
            switchQuestion.adjustsFontSizeToFitWidth = YES;
            switchQuestion.minimumScaleFactor = 0.5;
            [endView addSubview:switchQuestion];
            self.switchQuestionLabel = switchQuestion;
            
            UIButton *switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
            switchButton.backgroundColor = [UIColor colorWithRed:(195/255.0) green:(195/255.0) blue:(195/255.0) alpha:1];
            switchButton.titleLabel.textColor = [UIColor whiteColor];
            switchButton.titleLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:15];
            [switchButton setTitle:[self switchActionText] forState:UIControlStateNormal];
            switchButton.layer.cornerRadius = 3;
            switchButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
            [switchButton addTarget:self action:@selector(switchButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
            [switchButton addTarget:self action:@selector(switchButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
            [switchButton addTarget:self action:@selector(switchButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            self.switchButton = switchButton;
            [endView addSubview:switchButton];
  
        }
        
        self.view = view;
    }
    else
    {

#define DQVisualConstraints(view, format) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewBindings]]
#define DQVisualConstraintsWithOptions(view, format, opts) [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:viewBindings]]

        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.backgroundColor = [UIColor dq_phoneBackgroundColor];

        UIView *textFieldsWrapper = [[UIView alloc] initWithFrame:CGRectZero];
        textFieldsWrapper.backgroundColor = [UIColor dq_phoneDivider];
        [view addSubview:textFieldsWrapper];
        for (DQTextField *textField in self.textFields)
        {
            textField.font = [UIFont dq_phoneAuthTextInputFont];
            textField.textInset = UIEdgeInsetsMake(0.0f, 25.0f, 0.0f, 25.0f);
            [textFieldsWrapper addSubview:textField];
        }
        self.textFieldsWrapper = textFieldsWrapper;

        DQButton *submitButton = [DQButton buttonWithType:UIButtonTypeCustom];
        submitButton.tintColorForBackground = YES;
        submitButton.translatesAutoresizingMaskIntoConstraints = NO;
        submitButton.layer.cornerRadius = 4.0f;
        submitButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
        [submitButton addTarget:self action:@selector(submitButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [submitButton setTitle:self.submitButtonTitle forState:UIControlStateNormal];
        [view addSubview:submitButton];

        [view addConstraint:[NSLayoutConstraint constraintWithItem:submitButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:textFieldsWrapper attribute:NSLayoutAttributeBottom multiplier:1.0f constant:20.0f]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:submitButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[submitButton(buttonWidth)]" options:0 metrics:@{@"buttonWidth": @(kDQFormPhoneCTAButtonWidth)} views:NSDictionaryOfVariableBindings(submitButton)]];

        if ([self showSocialLoginButtons])
        {
            UILabel *socialLoginLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            socialLoginLabel.translatesAutoresizingMaskIntoConstraints = NO;
            socialLoginLabel.text = [self textForSocialLabel];
            socialLoginLabel.font = [UIFont dq_phoneAuthSocialLoginLabelFont];
            socialLoginLabel.textColor = [UIColor dq_phoneLightGrayTextColor];
            socialLoginLabel.textAlignment = NSTextAlignmentCenter;
            socialLoginLabel.adjustsFontSizeToFitWidth = YES;
            socialLoginLabel.minimumScaleFactor = 0.5f;
            [view addSubview:socialLoginLabel];

            UIView *socialWrapper = [[UIView alloc] initWithFrame:CGRectZero];
            socialWrapper.translatesAutoresizingMaskIntoConstraints = NO;
            [view addSubview:socialWrapper];

            UIButton *facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
            facebookButton.translatesAutoresizingMaskIntoConstraints = NO;
            [facebookButton addTarget:self action:@selector(facebook:) forControlEvents:UIControlEventTouchUpInside];
            UIImage *facebookButtonImage = [UIImage imageNamed:@"button_facebook_short"];
            [facebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
            [socialWrapper addSubview:facebookButton];

            UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
            twitterButton.translatesAutoresizingMaskIntoConstraints = NO;
            [twitterButton addTarget:self action:@selector(twitter:) forControlEvents:UIControlEventTouchUpInside];
            UIImage *twitterButtonImage = [UIImage imageNamed:@"button_twitter_short"];
            [twitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
            [socialWrapper addSubview:twitterButton];

            NSDictionary *viewBindings = NSDictionaryOfVariableBindings(socialLoginLabel, socialWrapper, facebookButton, twitterButton, submitButton);
            NSDictionary *metrics = @{@"vPadding": @(10), @"priority": @(UILayoutPriorityDefaultHigh), @"hPadding": @(10)};

            DQVisualConstraints(view, @"H:|-hPadding@priority-[socialLoginLabel]-hPadding@priority-|");
            DQVisualConstraintsWithOptions(view, @"V:[submitButton]-vPadding@priority-[socialLoginLabel]-vPadding@priority-[socialWrapper]", NSLayoutFormatAlignAllCenterX);

            DQVisualConstraints(socialWrapper, @"H:|[facebookButton]-hPadding@priority-[twitterButton]|");
            DQVisualConstraints(socialWrapper, @"V:|[facebookButton]|");
            DQVisualConstraints(socialWrapper, @"V:|[twitterButton]|");
        }

        if ([self showSwitchButton])
        {
            UIView *switchWrapper = [[UIView alloc] initWithFrame:CGRectZero];
            switchWrapper.translatesAutoresizingMaskIntoConstraints = NO;
            switchWrapper.backgroundColor = [UIColor dq_phoneDivider];
            [view addSubview:switchWrapper];

            UILabel *switchQuestion = [[UILabel alloc] initWithFrame:CGRectZero];
            switchQuestion.translatesAutoresizingMaskIntoConstraints = NO;
            [switchQuestion setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            switchQuestion.backgroundColor = [UIColor clearColor];
            switchQuestion.font = [UIFont dq_phoneAuthSwitchQuestionFont];
            switchQuestion.textColor = [UIColor dq_phoneAuthSwitchTextColor];
            switchQuestion.text = [self switchQuestionText];
            switchQuestion.textAlignment = NSTextAlignmentRight;
            switchQuestion.adjustsFontSizeToFitWidth = YES;
            switchQuestion.minimumScaleFactor = 0.5;
            [switchWrapper addSubview:switchQuestion];

            UIButton *switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
            switchButton.contentEdgeInsets = UIEdgeInsetsMake(6.0f, 12.0f, 6.0f, 12.0f);
            switchButton.layer.cornerRadius = 4.0f;
            switchButton.backgroundColor = [UIColor dq_phoneLightGrayTextColor];
            switchButton.titleLabel.font = [UIFont dq_phoneAuthSwitchButtonFont];
            switchButton.translatesAutoresizingMaskIntoConstraints = NO;
            [switchButton setTitle:[self switchActionText] forState:UIControlStateNormal];
            [switchButton addTarget:self action:@selector(switchButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
            [switchButton addTarget:self action:@selector(switchButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
            [switchButton addTarget:self action:@selector(switchButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            [switchWrapper addSubview:switchButton];

            NSDictionary *viewBindings = NSDictionaryOfVariableBindings(switchWrapper, switchQuestion, switchButton);
            NSDictionary *metrics = @{@"padding": @(18), @"priority": @(UILayoutPriorityDefaultHigh)};

            DQVisualConstraints(view, @"H:|[switchWrapper]|");
            DQVisualConstraints(view, @"V:[switchWrapper]|");

            DQVisualConstraints(switchWrapper, @"H:|-padding@priority-[switchQuestion]-padding@priority-[switchButton]-padding@priority-|");
            DQVisualConstraints(switchWrapper, @"V:|-padding@priority-[switchButton]-padding@priority-|");

            [switchWrapper addConstraint:[NSLayoutConstraint constraintWithItem:switchQuestion attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:switchButton attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
        }

        self.view = view;

#undef DQVisualConstraints
#undef DQVisualConstraintsWithOptions
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        CGRect bounds = self.view.bounds;
        bounds = CGRectInset(bounds, 0, kDQFormWrapperInsetVertical);
        self.wrapperView.frame = bounds;

        UIView *bottomView = nil;
        

        NSUInteger tableHeight = 44 * self.textFields.count;
        
        _fieldsTableView.frame = CGRectMake(0, 41, self.view.frame.size.width, tableHeight);
        _fieldsTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _fieldsTableView.scrollEnabled = FALSE;
        _fieldsTableView.layer.borderColor = [UIColor colorWithRed:(221/255.0) green:(221/255.0) blue:(221/255.0) alpha:1].CGColor;
        _fieldsTableView.layer.borderWidth = 1;
        
        
        
        CGFloat centerX = self.view.center.x;
        
        self.submitButton.frameWidth = 196;
        self.submitButton.frameCenterX = self.view.center.x;
        self.submitButton.frameY = CGRectGetMaxY(_fieldsTableView.frame) + 60;
        
        bottomView = self.submitButton;

        if ([self showSocialLoginButtons])
        {
            if (self.socialHeaderImageView)
            {
                
                self.socialHeaderImageView.frame = CGRectMake(0.0f, bottomView.frameMaxY + 15.0, self.socialHeaderImageView.frame.size.width, self.socialHeaderImageView.frame.size.height);
                self.socialHeaderImageView.frameCenterX = centerX;
                bottomView = self.socialHeaderImageView;
            }

            self.facebookButton.frame = CGRectMake(centerX - 10.0 - 133, CGRectGetMaxY(bottomView.frame) + 15.0, 133, 30);
            self.twitterButton.frame = CGRectMake(centerX + 10.0, CGRectGetMinY(self.facebookButton.frame), 133, 30);
            bottomView = self.facebookButton;
        }

        if ([self showSwitchButton])
        {
            [self.switchQuestionLabel sizeToFit];
            [self.switchButton sizeToFit];

            self.switchQuestionLabel.frameWidth = 186.0f;
            CGFloat totalWidth = 186.0f + 10.0f + self.switchButton.frameWidth;
            CGFloat xOffset = (self.switchButton.superview.frameWidth - totalWidth)/2.0f;

            self.switchQuestionLabel.frameX = xOffset;
            self.switchButton.frameX = xOffset + 186.0f + 10.0f;

            self.switchQuestionLabel.frameCenterY = self.switchQuestionLabel.superview.boundsCenterY + 0.5f;
            self.switchButton.frameCenterY = (int)self.switchButton.superview.boundsCenterY;
            
            bottomView = self.switchButton;
        }
        [self viewDidLayoutSubviewsCustomizeLayoutWithBottomView:bottomView];
    }
    else
    {
        UIView *lastView;
        self.textFieldsWrapper.frameY = 38.0f;
        self.textFieldsWrapper.frameWidth = self.view.frameWidth;
        for (UITextField *textField in self.textFields)
        {
            textField.frameY = lastView.frameMaxY + 1.0f;
            textField.frameWidth = textField.superview.frameWidth;
            textField.frameHeight = 50.0f;
            lastView = textField;
        }
        self.textFieldsWrapper.frameHeight = lastView.frameMaxY + 1.0f;

        [self.view layoutSubviews];
    }
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return !self.willSubmit;
}


@end
