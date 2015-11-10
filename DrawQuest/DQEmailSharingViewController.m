//
//  DQEmailSharingViewController.m
//  DrawQuest
//
//  Created by David Mauro on 10/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQEmailSharingViewController.h"

#import <AddressBookUI/AddressBookUI.h>

#import "DQButton.h"
#import "DQAlertView.h"

#import "UIFont+DQAdditions.h"

static NSString *DQEmailSharingViewControllerNameKey = @"name";
static NSString *DQEmailSharingViewControllerEmailKey = @"email";
static NSString *DQEmailSharingViewControllerCellIdentifier = @"cell";

@interface DQEmailSharingViewController () <UITableViewDelegate, UITableViewDataSource, ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, weak) UITableViewController *manualEmailViewController;
@property (nonatomic, weak) UITextField *manualEntryEmailTextField;
@property (nonatomic, weak) UITextField *manualEntryNameTextField;

@end

@implementation DQEmailSharingViewController

- (void)dealloc
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (id)initWithEmailList:(NSArray *)emailList
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _emailList = emailList;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.tableView.delegate = nil;
        self.tableView.dataSource = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)addEmailWithAddress:(NSString *)address name:(NSString *)name
{
    name = name ?: @"";
    NSMutableArray *emailList = [NSMutableArray arrayWithArray:self.emailList];
    [emailList addObject:@{DQEmailSharingViewControllerNameKey: name, DQEmailSharingViewControllerEmailKey: address}];
    _emailList = [NSArray arrayWithArray:emailList];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    if (tableView == self.tableView)
    {
        count = 2;
    }
    else if (tableView == self.manualEmailViewController.tableView)
    {
        count = 1;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (tableView == self.tableView)
    {
        if (section == 0)
        {
            count = 2;
        }
        else if (section == 1)
        {
            count = [self.emailList count];
        }
    }
    else if (tableView == self.manualEmailViewController.tableView)
    {
        count = 2;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if (tableView == self.tableView)
    {
        if (section == 1 && [self.emailList count])
        {
            title = DQLocalizedString(@"Recipients", @"Label for list of users who will receive an email");
        }
    }
    else if (tableView == self.manualEmailViewController.tableView)
    {
        title = DQLocalizedString(@"Add Email", @"Label for adding recipients' email addresses");
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DQEmailSharingViewControllerCellIdentifier];
    if ( ! cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DQEmailSharingViewControllerCellIdentifier];
        cell.textLabel.font = [UIFont dq_emailSharingCellFont];
        cell.detailTextLabel.font = [UIFont dq_emailSharingCellDetailFont];
    }

    if (tableView == self.tableView)
    {
        if (indexPath.section == 0)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (indexPath.row == 0)
            {
                cell.textLabel.text = DQLocalizedString(@"Add Email Addresses from Contacts", @"Label for adding an email address from user's address book");
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = DQLocalizedString(@"Add Email Addresses Manually", @"Label for manually adding an email address to list of recipients");
            }
        }
        else if (indexPath.section == 1)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = [[self.emailList objectAtIndex:indexPath.row] objectForKey:DQEmailSharingViewControllerNameKey];
            cell.detailTextLabel.text = [[self.emailList objectAtIndex:indexPath.row] objectForKey:DQEmailSharingViewControllerEmailKey];
        }
    }
    else if (tableView == self.manualEmailViewController.tableView)
    {
        if (indexPath.row == 0)
        {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            CGRect frame = CGRectInset(cell.bounds, 10.0f, 0.0f);
            textField.frame = frame;
            [textField setPlaceholder:@"@ Email Address"];
            [cell.contentView addSubview:textField];
            self.manualEntryEmailTextField = textField;
        }
        else if (indexPath.row == 1)
        {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            CGRect frame = CGRectInset(cell.bounds, 10.0f, 0.0f);
            textField.frame = frame;
            [textField setPlaceholder:@"Name (recommended)"];
            [cell.contentView addSubview:textField];
            self.manualEntryNameTextField = textField;
        }
    }
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL value = NO;
    if (tableView == self.tableView)
    {
        value = indexPath.section == 0;
    }
    return value;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        if (indexPath.section == 0)
        {
            if (indexPath.row == 0)
            {
                // Sort out people without emails
                ABAddressBookRef addressBook = (__bridge ABAddressBookRef)(CFBridgingRelease(ABAddressBookCreateWithOptions(NULL, nil)));
                CFArrayRef allPeople = (__bridge CFArrayRef)(CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook)));
                for (NSUInteger i = 0; i < CFArrayGetCount(allPeople); i++)
                {
                    ABRecordRef person = (__bridge ABRecordRef)(CFBridgingRelease(CFArrayGetValueAtIndex(allPeople, i)));
                    if (ABMultiValueGetCount((__bridge ABMultiValueRef)(CFBridgingRelease(ABRecordCopyValue(person, kABPersonEmailProperty)))) <= 0)
                    {
                        ABAddressBookRemoveRecord(addressBook, person, NULL);
                    }
                }
                ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
                peoplePicker.addressBook = addressBook;
                peoplePicker.peoplePickerDelegate = self;
                [peoplePicker setDisplayedProperties:[NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]]];
                [self presentViewController:peoplePicker animated:YES completion:nil];
            }
            else if (indexPath.row == 1)
            {
                UITableViewController *manualEmailViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                manualEmailViewController.tableView.delegate = self;
                manualEmailViewController.tableView.dataSource = self;
                DQButton *doneButton = [DQButton buttonWithType:UIButtonTypeCustom];
                [doneButton setTintColorForTitle:YES];
                [doneButton setTitle:DQLocalizedString(@"Add", @"Add user completion button title") forState:UIControlStateNormal];
                [doneButton sizeToFit];
                __weak typeof(self) weakSelf = self;
                doneButton.tappedBlock = ^(DQButton *button) {
                    NSString *email = weakSelf.manualEntryEmailTextField.text;
                    if (email.length)
                    {
                        NSString *name = weakSelf.manualEntryNameTextField.text;
                        [weakSelf addEmailWithAddress:email name:name];
                        [weakSelf.navigationController popViewControllerAnimated:YES];
                        weakSelf.manualEmailViewController = nil;
                        weakSelf.manualEntryEmailTextField = nil;
                        weakSelf.manualEntryNameTextField = nil;
                        [weakSelf.tableView reloadData];
                    }
                    else
                    {
                        DQAlertView *alert = [[DQAlertView alloc] initWithTitle:nil message:DQLocalizedString(@"Please enter a valid email address", @"Invalid email alert title") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                        [alert show];
                    }
                };
                manualEmailViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
                [self.navigationController pushViewController:manualEmailViewController animated:YES];

                self.manualEmailViewController = manualEmailViewController;
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL value = NO;
    if (tableView == self.tableView)
    {
        value = indexPath.section == 1;
    }
    return value;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        NSMutableArray *emailList = [NSMutableArray arrayWithArray:self.emailList];
        [emailList removeObjectAtIndex:indexPath.row];
        _emailList = emailList;
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate Methods

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person);
    CFTypeRef value = ABRecordCopyValue(person, property);
    NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(value, identifier);
    CFRelease(value), value = NULL;
    [self addEmailWithAddress:email name:name];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

@end
