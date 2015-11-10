//
//  DQSettingsViewController.h
//  DrawQuest
//
//  Created by Phillip Bowden on 10/25/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "DQTextField.h"
#import "DQCircularMaskImageView.h"

extern CGFloat const kDQSettingsViewControllerBottomInset;

typedef enum {
    DQSettingsSectionProfile = 0,
    DQSettingsSectionSharing,
    DQSettingsSectionLinks,
    DQSettingsSectionNotifications,
    DQSettingsSectionPassword,
    DQSettingsSectionAbout,
    DQSettingsSectionCount
} DQSettingsSection;

typedef enum {
    DQSettingsProfileRowPhoto = 0,
    DQSettingsProfileRowEmail,
    DQSettingsProfileRowBio,
    DQSettingsProfileRowCount
} DQSettingsProfileRow;

typedef enum {
    DQSettingsSharingRowFacebook = 0,
    DQSettingsSharingRowTwitter,
    DQSettingsSharingRowCount
} DQSettingsSharingRow;

typedef enum {
    DQSettingsLinksRowDrawQuest = 0,
    DQSettingsLinksRowFacebook,
    DQSettingsLinksRowTwitter,
    DQSettingsLinksRowCount
} DQSettingsLinksRow;

typedef enum {
    DQSettingsPasswordRowOldPassword = 0,
    DQSettingsPasswordRowNewPassword,
    DQSettingsPasswordRowRepeatPassword,
    DQSettingsPasswordRowCount
} DQSettingsPassswordRow;

typedef enum {
    DQSettingsNotificationsRowQuestAlerts = 0,
    DQSettingsNotificationsRowCount
} DQSettingsNotificationsRow;

typedef enum {
    DQSettingsAboutRowAbout = 0,
    DQSettingsAboutRowReportAProblem,
    DQSettingsAboutRowTermsOfService,
    DQSettingsAboutRowPrivacyPolicy,
    DQSettingsAboutRowCount
} DQSettingsAboutRow;

typedef enum {
    DQSettingsTextFieldEmail = 1,
    DQSettingsTextFieldBio,
    DQSettingsTextFieldOldPassword,
    DQSettingsTextFieldPassword,
    DQSettingsTextFieldRepeatPassword
} DQSettingsTextField;

@class DQAccountController, DQBioEditorViewController;

@interface DQSettingsViewController : DQViewController <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, readonly, assign) BOOL finishedLoading;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) NSInteger activeTextField;

@property (nonatomic, strong) DQCircularMaskImageView *avatarImageView;
@property (nonatomic, strong) DQTextField *emailTextField;
@property (nonatomic, strong) DQTextField *bioTextField;
@property (nonatomic, strong) DQTextField *oldPasswordTextField;
@property (nonatomic, strong) DQTextField *passwordTextField;
@property (nonatomic, strong) DQTextField *repeatPasswordTextField;
@property (nonatomic, strong) UISwitch *facebookSwitch;
@property (nonatomic, strong) UISwitch *twitterSwitch;
@property (nonatomic, strong) UISwitch *webProfileSwitch;
@property (nonatomic, strong) UISwitch *facebookProfileSwitch;
@property (nonatomic, strong) UISwitch *twitterProfileSwitch;
@property (nonatomic, strong) UISwitch *questAlertsSwitch;
@property (nonatomic, strong) UISwitch *starAlertsSwitch;
@property (nonatomic, strong) UISwitch *followersSwitch;

@property (nonatomic, strong) DQUser *user;

@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *oldPassword;
@property (nonatomic, copy) NSString *newPassword;

@property (nonatomic, copy) void (^signOutBlock)(DQSettingsViewController *vc);
@property (nonatomic, copy) void (^presentBioEditorViewControllerBlock)(DQSettingsViewController *vc);

// designated initializer
- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate accountController:(DQAccountController *)accountController;

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate MSDesignatedInitializer(initWithDelegate:accountController:);

- (void)save:(id)sender completionBlock:(dispatch_block_t)completionBlock failureBlock:(dispatch_block_t)failureBlock;

- (UITableViewCell *)configuredCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillBeHidden:(NSNotification *)notification;

- (void)updateDrawQuestProfileLinkInCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)updateFacebookProfileLinkInCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)updateTwitterProfileLinkInCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)bioEditorCancelTapped:(DQBioEditorViewController *)bvc;
- (void)bioEditorDoneTapped:(DQBioEditorViewController *)bvc;

// template methods
- (UIFont *)fontForTextLabelAtIndexPath:(NSIndexPath *)indexPath;
- (UIFont *)fontForDetailTextLabelAtIndexPath:(NSIndexPath *)indexPath;
- (UIColor *)textColorForTextLabelAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface DQImagePickerController : UIImagePickerController

@end
