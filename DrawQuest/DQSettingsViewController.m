//
//  DQSettingsViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQSettingsViewController.h"

// Additions
#import <MessageUI/MessageUI.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import "DQAnalyticsConstants.h"
#import "UIButton+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "DQViewMetricsConstants.h"
#import "DQNotifications.h"

// Models
#import "DQAccount.h"
#import "DQUser.h"

// Controllers
#import "DQAccountController.h"
#import "DQTwitterController.h"
#import "DQDataStoreController.h"
#import "DQPrivateServiceController.h"
#import "DQPublicServiceController.h"
#import "DQBioEditorViewController.h"

// Views
#import "DQActionSheet.h"
#import "DQHUDView.h"
#import "DQButton.h"
#import "DQTableViewCell.h"

// Subclasses
#import "DQPadSettingsViewController.h"
#import "DQPhoneSettingsViewController.h"

CGFloat const kDQSettingsViewControllerBottomInset = -20.0f;

@interface DQSettingsViewController () <UIActionSheetDelegate, UINavigationControllerDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, readwrite, assign) BOOL finishedLoading;
@property (nonatomic, strong) DQAccountController *accountController;
@property (nonatomic, copy) NSString *webProfileURLString;
@property (nonatomic, copy) NSString *facebookProfileURLString;
@property (nonatomic, copy) NSString *twitterProfileURLString;
@property (nonatomic, weak) DQHUDView *hudView;

@end

@implementation DQSettingsViewController
{
    BOOL __GUARD_viewWillAppearTwice;
    BOOL __GUARD_viewDidAppearTwice;
    BOOL __GUARD_viewWillDisappearTwice;
    BOOL _firstAppearance;
}

@dynamic bio;
@dynamic email;
@dynamic oldPassword;
@dynamic newPassword;

- (void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationFacebookPrivacyUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQApplicationTwitterPrivacyUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQFacebookProfileURLUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DQTwitterProfileURLUpdatedNotification object:nil];
}

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate accountController:(DQAccountController *)accountController
{
    if ([self class] == [DQSettingsViewController class])
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self = [[DQPadSettingsViewController alloc] initWithDelegate:delegate accountController:accountController];
        }
        else
        {
            self = [[DQPhoneSettingsViewController alloc] initWithDelegate:delegate accountController:accountController];
        }
    }
    else
    {
        self = [super initWithDelegate:delegate];
        if (self)
        {
            _firstAppearance = YES;
            self.title = DQLocalizedString(@"Settings", @"The title for the area where the user can change their account settings");
            _accountController = accountController;

            CGFloat height = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 48.0f : 44.0f;
            CGRect textFieldFrame = CGRectMake(0.0f, 0.0f, 370.0f, height);
            _emailTextField = [[DQTextField alloc] initWithFrame:textFieldFrame];
            _emailTextField.placeholder = DQLocalizedString(@"email@email.com", @"A simple email placeholder that is obviously an invalid placeholder email");
            _emailTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _emailTextField.textAlignment = NSTextAlignmentRight;
            _emailTextField.returnKeyType = UIReturnKeyGo;
            _emailTextField.tag = DQSettingsTextFieldEmail;
            _emailTextField.delegate = self;


            _bioTextField = [[DQTextField alloc] initWithFrame:textFieldFrame];
            _bioTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _bioTextField.textAlignment = NSTextAlignmentRight;
            _bioTextField.returnKeyType = UIReturnKeyGo;
            _bioTextField.tag = DQSettingsTextFieldBio;
            _bioTextField.delegate = self;
            _bioTextField.tintColorForText = YES;
            _bioTextField.tintColor = [UIColor colorWithRed:(252/255.0) green:(134/255.0) blue:(155/255.0) alpha:1];

            textFieldFrame.size.width = 250.0f;
            _oldPasswordTextField = [[DQTextField alloc] initWithFrame:textFieldFrame];
            _oldPasswordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _oldPasswordTextField.textAlignment = NSTextAlignmentRight;
            _oldPasswordTextField.placeholder = DQLocalizedString(@"Old Password", @"The user's old password before they change it");
            _oldPasswordTextField.secureTextEntry = YES;
            _oldPasswordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            _oldPasswordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            _oldPasswordTextField.returnKeyType = UIReturnKeyNext;
            _oldPasswordTextField.tag = DQSettingsTextFieldOldPassword;
            _oldPasswordTextField.delegate = self;

            _passwordTextField = [[DQTextField alloc] initWithFrame:textFieldFrame];
            _passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _passwordTextField.textAlignment = NSTextAlignmentRight;
            _passwordTextField.placeholder = DQLocalizedString(@"New Password", @"The user's new password they would like to change it to");
            _passwordTextField.secureTextEntry = YES;
            _passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            _passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            _passwordTextField.returnKeyType = UIReturnKeyNext;
            _passwordTextField.tag = DQSettingsTextFieldPassword;
            _passwordTextField.delegate = self;

            _repeatPasswordTextField = [[DQTextField alloc] initWithFrame:textFieldFrame];
            _repeatPasswordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _repeatPasswordTextField.textAlignment = NSTextAlignmentRight;
            _repeatPasswordTextField.placeholder = DQLocalizedString(@"Repeat New Password", @"The user's new password they would like to change it to repeated for safety");
            _repeatPasswordTextField.secureTextEntry = YES;
            _repeatPasswordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            _repeatPasswordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            _repeatPasswordTextField.returnKeyType = UIReturnKeyGo;
            _repeatPasswordTextField.tag = DQSettingsTextFieldRepeatPassword;
            _repeatPasswordTextField.delegate = self;

            _facebookSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [_facebookSwitch addTarget:self action:@selector(facebookSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            _facebookSwitch.on = _accountController.loggedInAccount.shareToFacebookOn;

            _twitterSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [_twitterSwitch addTarget:self action:@selector(twitterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            _twitterSwitch.on = _accountController.loggedInAccount.shareToTwitterOn;

            _webProfileSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [_webProfileSwitch addTarget:self action:@selector(webProfileSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            _webProfileSwitch.on = _accountController.loggedInAccount.webProfileEnabled;

            _facebookProfileSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [_facebookProfileSwitch addTarget:self action:@selector(facebookProfileSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            _facebookProfileSwitch.on = _accountController.loggedInAccount.facebookProfileEnabled;

            _twitterProfileSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [_twitterProfileSwitch addTarget:self action:@selector(twitterProfileSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            _twitterProfileSwitch.on = _accountController.loggedInAccount.twitterProfileEnabled;

            _questAlertsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [_questAlertsSwitch addTarget:self action:@selector(questAlertsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            _questAlertsSwitch.on = _accountController.questOfTheDayPushEnabled;

            self.emailTextField.font = [UIFont dq_phoneSettingsLabelFont];
            self.emailTextField.tintColorForText = YES;
            self.bioTextField.font = [UIFont dq_phoneSettingsLabelFont];
            self.bioTextField.tintColorForText = YES;
            self.oldPasswordTextField.font = [UIFont dq_phoneSettingsLabelFont];
            self.oldPasswordTextField.tintColorForText = YES;
            self.passwordTextField.font = [UIFont dq_phoneSettingsLabelFont];
            self.passwordTextField.tintColorForText = YES;
            self.repeatPasswordTextField.font = [UIFont dq_phoneSettingsLabelFont];
            self.repeatPasswordTextField.tintColorForText = YES;
            self.avatarImageView = [[DQCircularMaskImageView alloc] initWithFrame:CGRectMake(0, 0, 39, 39)];
        }
    }
    return self;
}

- (NSString *)bio
{
    return self.bioTextField.text;
}

- (void)setBio:(NSString *)bio
{
    self.bioTextField.text = bio;
}

- (NSString *)email
{
    return self.emailTextField.text;
}

- (void)setEmail:(NSString *)email
{
    self.emailTextField.text = email;
}

- (NSString *)oldPassword
{
    return self.oldPasswordTextField.text;
}

- (void)setOldPassword:(NSString *)oldPassword
{
    self.oldPasswordTextField.text = oldPassword;
}

- (NSString *)newPassword
{
    return self.passwordTextField.text;
}

- (void)setNewPassword:(NSString *)newPassword
{
    self.passwordTextField.text = newPassword;
    self.repeatPasswordTextField.text = newPassword;
}

- (void)showErrorWithTitle:(NSString *)title description:(NSString *)description
{
    if (!title) {
        title = DQLocalizedString(@"Error", @"Generic error alert title");
    }

    if (!description) {
        description = DQLocalizedString(@"Unknown error.", @"Unknown error alert message");
    }

    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
    [errorAlert show];
}

#pragma mark - UIViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.backgroundView = nil;
    UIEdgeInsets contentInset = tableView.contentInset;
    contentInset.bottom += kDQSettingsViewControllerBottomInset;
    tableView.contentInset = contentInset;
    [view addSubview:tableView];
    self.tableView = tableView;
    self.view = view;

    self.email = self.accountController.loggedInAccount.email;
    self.bio = self.accountController.loggedInAccount.bio;
    self.oldPassword = nil;
    self.newPassword = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor dq_phoneBackgroundColor];
    self.tableView.backgroundColor = [UIColor dq_phoneBackgroundColor];
    [self configureSignOutFooter];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (__GUARD_viewWillAppearTwice) return;
    __GUARD_viewWillAppearTwice = NO;
    __GUARD_viewWillDisappearTwice = NO;
    __GUARD_viewDidAppearTwice = NO;
    [super viewWillAppear:animated];

    if (_firstAppearance)
    {
        DQHUDView *hud = [[DQHUDView alloc] initWithFrame:self.view.bounds];
        hud.text = DQLocalizedString(@"Loading", @"The user must wait as a request is currently being made.");
        self.hudView = hud;
        [hud showInView:self.view animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (__GUARD_viewDidAppearTwice) return;
    __GUARD_viewWillDisappearTwice = NO;
    __GUARD_viewDidAppearTwice = YES;
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookPrivacyChanged:) name:DQApplicationFacebookPrivacyUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterPrivacyChanged:) name:DQApplicationTwitterPrivacyUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookProfileURLChanged:) name:DQFacebookProfileURLUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterProfileURLChanged:) name:DQTwitterProfileURLUpdatedNotification object:nil];

    if (_firstAppearance)
    {
        _firstAppearance = NO;

        __weak typeof(self) weakSelf = self;
        __weak UIView *weakView = self.view;
        [self.publicServiceController requestProfileInfoForUsername:self.loggedInAccount.username completionBlock:^(DQHTTPRequest *request) {
            if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
            {
                [weakSelf.hudView hideAnimated:YES];
                weakSelf.hudView = nil;
                NSDictionary *responseDictionary = request.dq_responseDictionary;
                NSArray *infoArray = @[responseDictionary];

                [weakSelf.dataStoreController createOrUpdateUsersFromJSONList:infoArray inBackground:YES withCompletionBlock:^(NSArray *objects) {
                    // Get Profile URLs directly for now
                    DQUser *user = [objects firstObject];
                    self.user = user;
                    weakSelf.webProfileURLString = [responseDictionary stringForKey:@"web_profile_url"];
                    weakSelf.facebookProfileURLString = [responseDictionary stringForKey:@"facebook_url"];
                    weakSelf.twitterProfileURLString = [responseDictionary stringForKey:@"twitter_url"];
                    weakSelf.finishedLoading = YES;
                    [weakSelf.tableView reloadData];
                }];
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (weakSelf && weakView && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
            {
                [weakSelf.hudView hideAnimated:YES];
                weakSelf.hudView = nil;
                NSString *errorDescription = request.error.dq_displayDescription;
                if (request.responseStatusCode == 404)
                {
                    errorDescription = DQLocalizedString(@"Your profile no longer exists.", @"The user's profile has been removed from the server error message");
                }
                [weakSelf showErrorWithTitle:DQLocalizedString(@"Profile error:", @"Profile error alert title") description:errorDescription];
            }
        }];

        [self logEvent:DQAnalyticsEventViewSettings withParameters:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (__GUARD_viewWillDisappearTwice) return;
    __GUARD_viewWillDisappearTwice = YES;
    __GUARD_viewDidAppearTwice = NO;
    __GUARD_viewWillAppearTwice = NO;
    [self unregisterForKeyboardNotifications];
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Configuration

- (void)configureSignOutFooter
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frameWidth, 125)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    DQButton *signOutButton = [DQButton buttonWithType:UIButtonTypeCustom];
    signOutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [footerView addSubview:signOutButton];

    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:signOutButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10.0]];
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:signOutButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:40.0]];
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:signOutButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[signOutButton(width)]" options:0 metrics:@{@"width": @(kDQFormPhoneCTAButtonWidth)} views:NSDictionaryOfVariableBindings(signOutButton)]];
    [signOutButton setTitle:DQLocalizedString(@"Sign Out", @"Sign the currently signed in user out of DrawQuest") forState:UIControlStateNormal];
    signOutButton.titleLabel.font = [UIFont dq_modalTableHeaderFont];
    [signOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    signOutButton.backgroundColor = [UIColor dq_phoneButtonOffColor];
    signOutButton.layer.cornerRadius = 5.0;
    __weak typeof(self) weakSelf = self;
    signOutButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.signOutBlock)
        {
            weakSelf.signOutBlock(weakSelf);
        }
    };
    self.tableView.tableFooterView = footerView;
}

- (NSString *)titleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = nil;
    if (indexPath.section == DQSettingsSectionProfile) {
        switch(indexPath.row) {
            case DQSettingsProfileRowPhoto:
                title = DQLocalizedString(@"Photo", @"Label for the photo avatar to represent the user");
                break;
            case DQSettingsProfileRowEmail:
                title = DQLocalizedString(@"Email", @"Email");
                break;
            case DQSettingsProfileRowBio:
                title = DQLocalizedString(@"Bio", @"A short label for the biographical information of the user");
                break;
            default:
                break;
        }

    } else if (indexPath.section == DQSettingsSectionLinks) {
        switch(indexPath.row) {
            case DQSettingsLinksRowDrawQuest:
                title = DQLocalizedString(@"DrawQuest Profile Page", @"Label for a link to the user's DrawQuest profile web page");
                break;
            case DQSettingsLinksRowFacebook:
                title = DQLocalizedString(@"Facebook Profile Page", @"Label for a link to the user's Facebook profile web page");
                break;
            case DQSettingsLinksRowTwitter:
                title = DQLocalizedString(@"Twitter Profile Page", @"Label for a link to the user's Twitter profile web page");
                break;
            default:
                break;
        }

    } else if (indexPath.section == DQSettingsSectionSharing) {
        switch(indexPath.row) {
            case DQSettingsSharingRowFacebook:
                title = DQLocalizedString(@"Share to Facebook Timeline", @"Label for option to share posts to their Facebook timeline by default");
                break;
            case DQSettingsSharingRowTwitter:
                title = DQLocalizedString(@"Share to Twitter", @"Label for option to share posts to their Twitter followers by default");
                break;
            /*
            case DQSettingsSharingRowTumblr:
                title = DQLocalizedString(@"Tumblr", @"Tumblr");
                break;
            */
            default:
                break;
        }
    
    } else if (indexPath.section == DQSettingsSectionPassword) {
        switch(indexPath.row) {
            case DQSettingsPasswordRowOldPassword :
                title = DQLocalizedString(@"Current Password", @"The user's current password before they change it, placeholder text");
                break;
            case DQSettingsPasswordRowNewPassword:
                title = DQLocalizedString(@"New Password", @"The user's new password they would like to change it to");
                break;
            case DQSettingsPasswordRowRepeatPassword:
                title = DQLocalizedString(@"New Password Again", @"The user's new password they would like to change it to repeated for safety, placeholder text");
                break;
            default:
                break;
        }
    
    } else if (indexPath.section == DQSettingsSectionNotifications) {
        switch(indexPath.row) {
            case DQSettingsNotificationsRowQuestAlerts:
                title = DQLocalizedString(@"Quest of the Day Alerts", @"Label for the option to receive push notifications when there is a new Quest of the Day");
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == DQSettingsSectionAbout)
    {
        switch(indexPath.row) {
            case DQSettingsAboutRowAbout:
            {
                NSString *buildInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"DQBuildInfo"];
                if ([buildInfo length])
                {
                    title = [DQLocalizedString(@"About DrawQuest", @"Navigation title for about us modal") stringByAppendingFormat:@" %@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], buildInfo];
                }
                else
                {
                    title = [DQLocalizedString(@"About DrawQuest", @"Navigation title for about us modal") stringByAppendingFormat:@" %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
                }
                break;
            }
            case DQSettingsAboutRowReportAProblem:
                title = DQLocalizedString(@"Report a Problem", @"Label to report problems to staff");
                break;
            case DQSettingsAboutRowTermsOfService:
                title = DQLocalizedString(@"Terms of Service", @"Label to view the Terms of Service");
                break;
            case DQSettingsAboutRowPrivacyPolicy:
                title = DQLocalizedString(@"Privacy Policy", @"Label to view the Privacy Policy");
                break;
            default:
                break;
        }
    }

    return title;
}

- (UIFont *)fontForTextLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIFont dq_phoneSettingsLabelFont];
}

- (UIFont *)fontForDetailTextLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIFont dq_phoneSettingsLabelFont];
}

- (UIColor *)textColorForTextLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIColor dq_phoneGrayTextColor];
}

- (void)updateDrawQuestProfileLinkInCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.tintAdjustmentMode = self.loggedInAccount.webProfileEnabled ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;
    cell.detailTextLabel.text = self.loggedInAccount.webProfileEnabled ? self.webProfileURLString : nil;
    [cell setNeedsLayout];
}

- (void)updateFacebookProfileLinkInCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.tintAdjustmentMode = self.loggedInAccount.facebookProfileEnabled ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;
    cell.detailTextLabel.text = self.loggedInAccount.facebookProfileEnabled ? self.facebookProfileURLString : nil;
    [cell setNeedsLayout];
}

- (void)updateTwitterProfileLinkInCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.tintAdjustmentMode = self.loggedInAccount.twitterProfileEnabled ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;
    cell.detailTextLabel.text = self.loggedInAccount.twitterProfileEnabled ? self.twitterProfileURLString : nil;
    [cell setNeedsLayout];
}

- (UITableViewCell *)configuredCell:(UITableViewCell *)inCell forIndexPath:(NSIndexPath *)indexPath
{
    DQTableViewCell *cell = (DQTableViewCell *)inCell;
    cell.textLabel.text = [self titleForRowAtIndexPath:indexPath];
    cell.textLabel.font = [self fontForTextLabelAtIndexPath:indexPath];
    cell.textLabel.textColor = [self textColorForTextLabelAtIndexPath:indexPath];
    cell.detailTextLabel.font = [self fontForDetailTextLabelAtIndexPath:indexPath];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:(252/255.0) green:(134/255.0) blue:(155/255.0) alpha:1];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == DQSettingsSectionProfile) {
        if (indexPath.row == DQSettingsProfileRowBio) {
            cell.accessoryView = self.bioTextField;
        } else if (indexPath.row == DQSettingsProfileRowEmail) {
            cell.accessoryView = self.emailTextField;
        }
    } else if (indexPath.section == DQSettingsSectionSharing) {
        if (indexPath.row == DQSettingsSharingRowFacebook) {
            cell.accessoryView = self.facebookSwitch;
        } else if (indexPath.row == DQSettingsSharingRowTwitter) {
            cell.accessoryView = self.twitterSwitch;
        }
    } else if (indexPath.section == DQSettingsSectionLinks) {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        if (indexPath.row == DQSettingsLinksRowDrawQuest) {
            cell.accessoryView = self.webProfileSwitch;
            [self updateDrawQuestProfileLinkInCell:cell atIndexPath:indexPath];
        } else if (indexPath.row == DQSettingsLinksRowFacebook) {
            cell.accessoryView = self.facebookProfileSwitch;
            [self updateFacebookProfileLinkInCell:cell atIndexPath:indexPath];
        } else if (indexPath.row == DQSettingsLinksRowTwitter) {
            cell.accessoryView = self.twitterProfileSwitch;
            [self updateTwitterProfileLinkInCell:cell atIndexPath:indexPath];
        }
    } else if (indexPath.section == DQSettingsSectionPassword) {
        if (indexPath.row == DQSettingsPasswordRowOldPassword) {
            cell.accessoryView = self.oldPasswordTextField;
        } else if (indexPath.row == DQSettingsPasswordRowNewPassword) {
            cell.accessoryView = self.passwordTextField;
        } else if (indexPath.row == DQSettingsPasswordRowRepeatPassword) {
            cell.accessoryView = self.repeatPasswordTextField;
        }
    } else if (indexPath.section == DQSettingsSectionNotifications) {
        if (indexPath.row == DQSettingsNotificationsRowQuestAlerts) {
            cell.accessoryView = self.questAlertsSwitch;
        }
    }
    else if (indexPath.section == DQSettingsSectionAbout)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_phone"]];
    }

    if (indexPath.section == DQSettingsSectionProfile)
    {
        if (indexPath.row == DQSettingsProfileRowPhoto)
        {
            cell.accessoryView = self.avatarImageView;
            self.avatarImageView.imageURL = self.user.avatarURL;
        }
        else if (indexPath.row == DQSettingsProfileRowBio)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    }
    else if (indexPath.section == DQSettingsSectionLinks)
    {
        cell.detailTextLabel.textColor = cell.tintColor;
        cell.dq_tintColorDidChangeBlock = ^(DQTableViewCell *cell) {
            cell.detailTextLabel.textColor = cell.tintColor;
        };

        if (indexPath.row == DQSettingsLinksRowDrawQuest)
        {
            cell.imageView.image = [[UIImage imageNamed:@"icon_socialProfile_DrawQuest"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [cell setNeedsLayout];
        }
        else if (indexPath.row == DQSettingsLinksRowFacebook)
        {
            cell.imageView.image = [[UIImage imageNamed:@"icon_socialProfile_facebook"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [cell setNeedsLayout];
        }
        else if (indexPath.row == DQSettingsLinksRowTwitter)
        {
            cell.imageView.image = [[UIImage imageNamed:@"icon_socialProfile_twitter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [cell setNeedsLayout];
        }
    }

    return cell;
}

- (void)bioCellSelected
{
    if (self.presentBioEditorViewControllerBlock)
    {
        self.presentBioEditorViewControllerBlock(self);
    }
}

- (void)bioEditorCancelTapped:(DQBioEditorViewController *)bvc
{
}

- (void)bioEditorDoneTapped:(DQBioEditorViewController *)bvc
{
    self.bio = bvc.text;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellID = [NSString stringWithFormat:@"cell-%@-%@", @(indexPath.section), @(indexPath.row)];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if (!cell) {
        NSInteger style = UITableViewCellStyleValue1;
        if (indexPath.section == DQSettingsSectionLinks)
        {
            style = UITableViewCellStyleSubtitle;
        }
        cell = [[DQTableViewCell alloc] initWithStyle:style reuseIdentifier:CellID];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.5f;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.minimumScaleFactor = 0.5f;
    }
    
    cell = [self configuredCell:cell forIndexPath:indexPath];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount;
    switch (section) {
        case DQSettingsSectionProfile:
            rowCount = DQSettingsProfileRowCount;
            break;

        case DQSettingsSectionSharing:
            rowCount = DQSettingsSharingRowCount;
            break;

        case DQSettingsSectionLinks:
            rowCount = DQSettingsLinksRowCount;
            break;

        case DQSettingsSectionPassword:
            rowCount = DQSettingsPasswordRowCount;
            break;
            
        case DQSettingsSectionNotifications:
            rowCount = DQSettingsNotificationsRowCount;
            break;

        case DQSettingsSectionAbout:
            rowCount = DQSettingsAboutRowCount;
            break;

        default:
            rowCount = 0;
    }
    
    return rowCount;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return DQSettingsSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    switch (section) {
        case DQSettingsSectionProfile:
            title = DQLocalizedString(@"Profile", @"Label for the user's own profile");
            break;

        case DQSettingsSectionSharing:
            title = DQLocalizedString(@"Sharing", @"Label for sharing options");
            break;

        case DQSettingsSectionLinks:
            title = DQLocalizedString(@"Social Profile Links", @"Label for links to web profile for various services");
            break;

        case DQSettingsSectionPassword:
            title = DQLocalizedString(@"Change Password", @"Label for changing the user's password");
            break;
        
        case DQSettingsSectionNotifications:
            title = DQLocalizedString(@"Notifications", @"Label for notification options");
            break;

        case DQSettingsSectionAbout:
            title = DQLocalizedString(@"Support", @"Label for support links");
            break;

        default:
            title = nil;
    }
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48.0f;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section ? 29.0f : 46.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = section ? 29.0f : 46.0f;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frameWidth, height)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, section ? -8.0f : 0.0f, tableView.frameWidth - 15.0f, height)];
    [view addSubview:label];
    label.backgroundColor = [UIColor dq_phoneBackgroundColor];
    label.font = [UIFont dq_modalTableHeaderFont];
    label.textColor = [UIColor dq_phoneSettingsSectionHeaderTitleColor];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DQSettingsSectionLinks)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        NSString *urlString = cell.detailTextLabel.text;
        if ([urlString length])
        {
            NSURL *url = [NSURL URLWithString:urlString];
            [[UIApplication sharedApplication] openURL:url];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if ((indexPath.section == DQSettingsSectionProfile) && (indexPath.row == DQSettingsProfileRowBio))
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self bioCellSelected];
    }
    else if ((indexPath.section == DQSettingsSectionProfile) && (indexPath.row == DQSettingsProfileRowPhoto))
    {
        [self showImagePicker];
    }
    else if (indexPath.section == DQSettingsSectionAbout)
    {
        if (indexPath.row == DQSettingsAboutRowAbout)
        {
            [self showAbout];
        }
        else if (indexPath.row == DQSettingsAboutRowReportAProblem)
        {
            struct utsname systemInfo;
            int unameResult = uname(&systemInfo);
            NSString *model = unameResult == 0 ? [NSString stringWithUTF8String:systemInfo.machine] : [[UIDevice currentDevice] model];

            NSString *version = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] description] stringByEscapingQueryParameters];
            NSString *username = [self.loggedInAccount.username stringByEscapingQueryParameters];
            NSString *device = [model stringByEscapingQueryParameters];
            NSString *os = [[[UIDevice currentDevice] systemVersion] stringByEscapingQueryParameters];
            NSString *displayedLanguage = [[DQLocalization displayedLanguage] stringByEscapingQueryParameters];
            NSString *preferredLanguage = [[[[NSLocale preferredLanguages] firstObject] description] stringByEscapingQueryParameters];
            NSString *ifv = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByEscapingQueryParameters];
            NSString *url = [NSString stringWithFormat:@"%@support?ver=%@&username=%@&dev=%@&os=%@&disp=%@&pref=%@&ifv=%@", [self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey], version, username, device, os, displayedLanguage, preferredLanguage, ifv];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
        else if (indexPath.row == DQSettingsAboutRowTermsOfService)
        {
            // TODO: this URL should be server controllable
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey] stringByAppendingString:@"terms"]]];
        }
        else if (indexPath.row == DQSettingsAboutRowPrivacyPolicy)
        {
            // TODO: this URL should be server controllable
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey] stringByAppendingString:@"privacy"]]];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *selectedImage = nil;
    if ([info objectForKey:UIImagePickerControllerEditedImage])  {
        selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (!selectedImage) {
        return;
    }
    
    DQHUDView *hud = [self showHUDWithDescription:DQLocalizedString(@"Setting Avatar", @"Photo is being uploaded and set as user's avatar loading indicator label")];

    __weak typeof(self) weakSelf = self;
    [self.privateServiceController requestAvatarChangeWithImageData:UIImagePNGRepresentation(selectedImage) completionBlock:^(DQHTTPRequest *request, id JSONObject) {
        weakSelf.avatarImageView.image = selectedImage;
        [hud hideAnimated:YES];
        if (request)
        {
            if (request.error) {
                [self handleError:request.error];
            } else {
                [self handleSuccessWithDescription:DQLocalizedString(@"Updated avatar.", @"Photo was successfully uploaded as user's new avatar indicator label")];
            }
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // nothing, but leave this here so subclasses can call super
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.bioTextField)
    {
        [self bioCellSelected];
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField.tag;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField.tag == DQSettingsTextFieldOldPassword) {
        UITextField *nextField = (UITextField *)[self.view viewWithTag:DQSettingsPasswordRowNewPassword];
        [nextField becomeFirstResponder];
    } else if (textField.tag == DQSettingsTextFieldPassword) {
        UITextField *nextField = (UITextField *)[self.view viewWithTag:DQSettingsTextFieldRepeatPassword];
        [nextField becomeFirstResponder];
    }
    
    return YES;
}


- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

#pragma mark - Actions

- (void)facebookPrivacyChanged:(NSNotification *)notification
{
    [self.facebookProfileSwitch setOn:self.loggedInAccount.facebookProfileEnabled animated:YES];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:DQSettingsLinksRowFacebook inSection:DQSettingsSectionLinks];
    [self updateFacebookProfileLinkInCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (void)facebookProfileURLChanged:(NSNotification *)notification
{
    self.facebookProfileURLString = [notification object];
    [self.tableView reloadData];
}

- (void)twitterPrivacyChanged:(NSNotification *)notification
{
    [self.twitterProfileSwitch setOn:self.loggedInAccount.twitterProfileEnabled animated:YES];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:DQSettingsLinksRowTwitter inSection:DQSettingsSectionLinks];
    [self updateTwitterProfileLinkInCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (void)twitterProfileURLChanged:(NSNotification *)notification
{
    self.twitterProfileURLString = [notification object];
    [self.tableView reloadData];
}

- (void)save:(id)sender completionBlock:(dispatch_block_t)completionBlock failureBlock:(dispatch_block_t)failureBlock
{
    if (![self validateFormAndReportErrors]) {
        if (failureBlock)
        {
            failureBlock();
        }
        return;
    }
    
    NSString *email = self.email;
    NSString *oldPassword = self.oldPassword;
    NSString *newPassword = self.newPassword;
    NSString *bioText = self.bio;

    UITextField *activeTextField = (UITextField *)[self.view viewWithTag:self.activeTextField];
    [activeTextField resignFirstResponder];
    
    DQHUDView *hud = [self showHUDWithDescription:DQLocalizedString(@"Updating Settings", @"Settings are being updated loading indicator label")];
    
    [self.privateServiceController requestChangeProfileInfoWithEmail:email oldPassword:oldPassword newPassword:newPassword bioText:bioText completionBlock:^(DQHTTPRequest *request, id JSONObject) {
        [hud hideAnimated:YES];
        if (request)
        {
            if (request.error) {
                [self handleError:request.error];
                if (failureBlock)
                {
                    failureBlock();
                }
            } else {
                if (email.length) {
                    self.accountController.loggedInAccount.email = email;
                }
                self.accountController.loggedInAccount.bio = bioText;

                if (completionBlock)
                {
                    completionBlock();
                }
            }
        }
        else if (failureBlock)
        {
            failureBlock(); // FIXME: create error for this
        }
    }];
}

- (void)showImagePicker
{
    BOOL cameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL libraryAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    
    if (cameraAvailable && libraryAvailable)
    {
        __weak typeof(self) weakSelf = self;
        DQActionSheet *actionSheet = [[DQActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") destructiveButtonTitle:nil otherButtonTitles:DQLocalizedString(@"Take a Photo", @"Prompt to use the camera function to take a photo as avatar"), DQLocalizedString(@"Choose Existing", @"Prompt to choose a photo from the device's Camera Roll to use as avatar"), nil];
        actionSheet.dq_completionBlock = ^(DQActionSheet *sheet, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                [weakSelf presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
            } else if (buttonIndex == 1) {
                [weakSelf presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            }
        };
        [actionSheet showInView:self.view];
    }
    else
    {
        DQImagePickerController *imagePicker = [[DQImagePickerController alloc] init];
        imagePicker.allowsEditing = YES;
        imagePicker.delegate = self;
        if (cameraAvailable)
        {
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
        }
        else if (libraryAvailable)
        {
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
    }
}

- (void)presentImagePicker:(DQImagePickerController *)imagePicker
{
    // subclasses must override
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    DQImagePickerController *imagePicker = [[DQImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = sourceType;
    imagePicker.allowsEditing = YES;

    [self presentImagePicker:imagePicker];
}

- (void)facebookSwitchChanged:(id)sender
{
    UISwitch *faceSwitch = (UISwitch *)sender;
    __weak typeof(self) weakSelf = self;
    if (faceSwitch.on) {
        faceSwitch.enabled = NO;
        [self requestFacebookPublishAccessForFeature:@"settings-facebook-switch" cancellationBlock:^{
            faceSwitch.on = NO;
            faceSwitch.enabled = YES;
        } completionBlock:^(NSString *facebookToken) {
            [weakSelf.accountController setShareToFacebookOn:YES completionBlock:^{
                faceSwitch.enabled = YES;
            } failureBlock:^(NSError *error) {
                // TODO: display an error message?
                faceSwitch.enabled = YES;
            }];
        } failureBlock:^(NSError *error) {
            faceSwitch.on = NO;
            faceSwitch.enabled = YES;
            if (error) {
                NSString *message = error.dq_displayDescription;

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alertView show];
            }
        }];
    } else {
        faceSwitch.enabled = NO;
        [weakSelf.accountController setShareToFacebookOn:NO completionBlock:^{
            faceSwitch.enabled = YES;
        } failureBlock:^(NSError *error) {
            // TODO: display an error message?
            faceSwitch.enabled = YES;
        }];
    }
}

- (void)twitterSwitchChanged:(id)sender
{
    UISwitch *faceSwitch = (UISwitch *)sender;
    __weak typeof(self) weakSelf = self;
    if (faceSwitch.on) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:DQSettingsSharingRowTwitter inSection:DQSettingsSectionSharing];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self requestTwitterAccessInView:cell withCancellationBlock:^{
            faceSwitch.on = NO;
            faceSwitch.enabled = YES;
        } accountSelectedBlock:^{
            faceSwitch.enabled = NO;
        } completionBlock:^{
            [weakSelf.accountController setShareToTwitterOn:YES completionBlock:^{
                faceSwitch.enabled = YES;
            } failureBlock:^(NSError *error) {
                // TODO: display an error message?
                faceSwitch.enabled = YES;
            }];
        } failureBlock:^(NSError *error) {
            faceSwitch.on = NO;
            faceSwitch.enabled = YES;
            if (error) {
                NSString *message = error.dq_displayDescription;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alertView show];
            }
        }];
    } else {
        faceSwitch.enabled = NO;
        [weakSelf.accountController setShareToTwitterOn:NO completionBlock:^{
            faceSwitch.enabled = YES;
        } failureBlock:^(NSError *error) {
            faceSwitch.enabled = YES;
        }];
    }
}

- (void)webProfileSwitchChanged:(id)sender
{
    UISwitch *webSwitch = (UISwitch *)sender;
    webSwitch.enabled = NO;
    BOOL webSwitchOn = webSwitch.on;
    
    __weak typeof(self) weakSelf = self;
    __weak UIView *weakView = self.view;
    [self.privateServiceController requestWebProfilePrivacyChange:( ! webSwitchOn) completionBlock:^(DQHTTPRequest *request, id JSONObject) {
        if (weakSelf && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
        {
            weakSelf.loggedInAccount.webProfileEnabled = webSwitchOn;
            webSwitch.enabled = YES;
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:DQSettingsLinksRowDrawQuest inSection:DQSettingsSectionLinks];
            [weakSelf updateDrawQuestProfileLinkInCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            if ( ! (request && JSONObject))
            {
                [webSwitch setOn:( ! webSwitchOn) animated:YES];
            }
        }
    } failureBlock:^(DQHTTPRequest *request) {
        if (weakSelf && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
        {
            webSwitch.enabled = YES;
            [webSwitch setOn:webSwitchOn animated:YES];
        }
    }];
}

- (void)facebookProfileSwitchChanged:(id)sender
{
    UISwitch *faceSwitch = (UISwitch *)sender;
    BOOL needToForceOn = faceSwitch.on && self.loggedInAccount.facebookProfileExplicitlySet;
    
    __weak typeof(self) weakSelf = self;
    if (faceSwitch.on) {
        faceSwitch.enabled = NO;
        [self requestFacebookPublishAccessForFeature:@"settings-facebook-profile-switch" cancellationBlock:^{
            faceSwitch.on = NO;
            faceSwitch.enabled = YES;
        } completionBlock:^(NSString *facebookToken) {
            if (needToForceOn)
            {
                [weakSelf.accountController setShareFacebookProfileOn:YES completionBlock:^(DQHTTPRequest *request) {
                    faceSwitch.enabled = YES;
                } failureBlock:^(DQHTTPRequest *request) {
                    faceSwitch.on = NO;
                    faceSwitch.enabled = YES;
                    if (request.error) {
                        NSString *message = request.error.dq_displayDescription;
                        
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                        [alertView show];
                    }
                }];
            }
            else
            {
                faceSwitch.enabled = YES;
            }
        } failureBlock:^(NSError *error) {
            faceSwitch.on = NO;
            faceSwitch.enabled = YES;
            if (error) {
                NSString *message = error.dq_displayDescription;
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alertView show];
            }
        }];
    } else {
        faceSwitch.enabled = NO;
        [weakSelf.accountController setShareFacebookProfileOn:NO completionBlock:^(DQHTTPRequest *request){
            faceSwitch.enabled = YES;
        } failureBlock:^(DQHTTPRequest *request) {
            // TODO: display an error message?
            faceSwitch.enabled = YES;
        }];
    }
}

- (void)twitterProfileSwitchChanged:(id)sender
{
    UISwitch *twitterSwitch = (UISwitch *)sender;
    BOOL needToForceOn = twitterSwitch.on && self.loggedInAccount.twitterProfileExplicitlySet;
    
    __weak typeof(self) weakSelf = self;
    if (twitterSwitch.on) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:DQSettingsLinksRowTwitter inSection:DQSettingsSectionLinks];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        twitterSwitch.enabled = NO;
        [self requestTwitterAccessInView:cell withCancellationBlock:^{
            twitterSwitch.on = NO;
            twitterSwitch.enabled = YES;
        } accountSelectedBlock:^{
            // Do nothing here
        } completionBlock:^{
            if (needToForceOn)
            {
                [weakSelf.accountController setShareTwitterProfileOn:YES completionBlock:^(DQHTTPRequest *request) {
                    twitterSwitch.enabled = YES;
                } failureBlock:^(DQHTTPRequest *request) {
                    twitterSwitch.on = NO;
                    twitterSwitch.enabled = YES;
                    if (request.error) {
                        NSString *message = request.error.dq_displayDescription;
                        
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Twitter Error", @"Twitter error alert title") message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                        [alertView show];
                    }
                }];
            }
            else
            {
                twitterSwitch.enabled = YES;
            }
        } failureBlock:^(NSError *error) {
            twitterSwitch.on = NO;
            twitterSwitch.enabled = YES;
            if (error) {
                NSString *message = error.dq_displayDescription;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Twitter Error", @"Twitter error alert title") message:message delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                [alertView show];
            }
        }];
    } else {
        twitterSwitch.enabled = NO;
        [weakSelf.accountController setShareTwitterProfileOn:NO completionBlock:^(DQHTTPRequest *request){
            twitterSwitch.enabled = YES;
        } failureBlock:^(DQHTTPRequest *request) {
            twitterSwitch.enabled = YES;
        }];
    }
}

- (void)questAlertsSwitchChanged:(id)sender
{
    UISwitch *alertsSwitch = (UISwitch *)sender;
    BOOL QOTDPushEnabled = alertsSwitch.on;

    self.accountController.questOfTheDayPushEnabled = QOTDPushEnabled;
    //[self.accountController updateUAPushSettings]; // FIXME: this should be called internally in DQAccountController
}

- (void)deleteAccountButtonPressed:(id)sender
{
    if (![MFMailComposeViewController canSendMail]) {
        return;
    }

    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setToRecipients:@[@"closeaccount@example.com"]];
    [mailComposeViewController setMessageBody:DQLocalizedString(@"Please close my account and remove all the content associated with it. I understand that this cannot be undone.\n\nThe reason I'm closing my account is:", @"Request to delete account email body with reason for doing so asked of user") isHTML:NO];
    [self presentViewController:mailComposeViewController animated:YES completion:nil];
}

#pragma mark - Validation

- (BOOL)validateFormAndReportErrors
{
    NSString *currentPasswordText = self.oldPassword;
    NSString *newPasswordText = self.newPassword;
    NSString *repeatPasswordText = self.repeatPasswordTextField.text;
    
    if (!currentPasswordText.length && (newPasswordText.length || repeatPasswordText.length)) {
        [self handleErrorWithDescription:DQLocalizedString(@"Please enter your old password.", @"The user failed to enter an old password during password change error alert message")];
        return NO;
    } else if (currentPasswordText.length && (!newPasswordText.length || !repeatPasswordText.length)) {
        [self handleErrorWithDescription:DQLocalizedString(@"Please enter and repeat your new password.", @"The user failed to enter and/or repeat a new password during password change error alert message")];
        return NO;
    } else if ((newPasswordText.length || repeatPasswordText.length) && ![newPasswordText isEqualToString:repeatPasswordText]) {
        [self handleErrorWithDescription:DQLocalizedString(@"Passwords must match.", @"The user failed to enter matching passwords during password change error alert message")];
        return NO;
    }
    
    return YES;
}

#pragma mark - Response Handling

- (void)handleError:(NSError *)inError
{
    NSString *failureReason = inError.dq_displayDescription;
    [self handleErrorWithDescription:failureReason];
}

- (void)handleErrorWithDescription:(NSString *)inDescription
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Error", @"Generic error alert title") message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
    [alertView show];
}

- (void)handleSuccessWithDescription:(NSString *)inDescription
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Success", @"Successful request indicator label") message:inDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
    [alertView show];
}

- (DQHUDView *)showHUDWithDescription:(NSString *)inDescription
{
    DQHUDView *hud = [[DQHUDView alloc] initWithFrame:self.parentViewController.view.bounds];
    [hud showInView:self.parentViewController.view animated:YES];
    hud.text = inDescription;
    return hud;
}

#pragma mark - Keyboard notifications

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGFloat keyboardHeight = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.width;
    CGFloat screenHeight = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat modalHeight = CGRectGetHeight([self.navigationController view].bounds);
    CGFloat heightDiff = keyboardHeight - screenHeight + modalHeight;
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, kDQSettingsViewControllerBottomInset + heightDiff, 0.0f);

    UITextField *activeTextField = (UITextField *)[self.view viewWithTag:self.activeTextField];
    CGRect fieldFrame = [self.navigationController.view convertRect:activeTextField.frame fromView:activeTextField.superview];
    if (CGRectGetMaxY(fieldFrame) > screenHeight - keyboardHeight)
    {
        CGPoint scrollPoint = CGPointMake(0.0, self.tableView.contentOffset.y + heightDiff);
        [self.tableView setContentOffset:scrollPoint animated:NO];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, kDQSettingsViewControllerBottomInset, 0.0f);
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

@implementation DQImagePickerController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (BOOL)shouldAutorotate
{
    return NO;
}

@end
