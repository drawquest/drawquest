//
//  DQAddressBookCoordinator.m
//  DrawQuest
//
//  Created by David Mauro on 10/30/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAddressBookCoordinator.h"

// Frameworks
#import <AddressBook/AddressBook.h>
#import <CommonCrypto/CommonDigest.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

// Controllers
#import "DQPublicServiceController.h"
#import "DQPrivateServiceController.h"

// Views
#import "DQActionSheet.h"
#import "DQAlertView.h"

// Additions
#import "NSDictionary+DQAPIConveniences.h"
#import "DQViewMetricsConstants.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

static NSString *DQContactsKeyStringDisplayName = @"displayName";
static NSString *DQContactsKeyStringUserName = @"userName";
static NSString *DQContactsKeyStringEmails = @"emails";
static NSString *DQContactsKeyStringPhoneNumbers = @"phoneNumbers";
static NSString *DQContactsKeyStringAvatarImage = @"avatarImage";
static NSString *DQContactsKeyStringIsFollowing = @"isFollowing";

@interface DQAddressBookCoordinator () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) DQPublicServiceController *publicServiceController;
@property (nonatomic, strong) DQPrivateServiceController *privateServiceController;
@property (nonatomic, strong) NSArray *contactsOnDrawQuest;
@property (nonatomic, strong) NSMutableIndexSet *contactsToFollow;
@property (nonatomic, strong) NSString *invitationTextMessage;
@property (nonatomic, strong) NSString *invitationEmailMessage;
@property (nonatomic, assign) ABAddressBookRef addressBookRef;
@property (nonatomic, assign) CFArrayRef allPeopleRef;
@property (nonatomic, assign) NSUInteger *invitesSent;
@property (nonatomic, assign) BOOL hasLoadedContacts;

@end

@implementation DQAddressBookCoordinator

- (void)dealloc
{
    if (_allPeopleRef)
    {
        CFRelease(_allPeopleRef);
    }
    if (_addressBookRef)
    {
        CFRelease(_addressBookRef);
    }
}

- (id)initWithPublicServiceController:(DQPublicServiceController *)publicServiceController privateServiceController:(DQPrivateServiceController *)privateServiceController
{
    self = [super init];
    if (self)
    {
        _publicServiceController = publicServiceController;
        _privateServiceController = privateServiceController;
    }
    return self;
}

#pragma mark - Helpers

- (BOOL)personHasEmailOrPhoneNumber:(ABRecordRef)person
{
    return ((ABMultiValueGetCount((__bridge ABMultiValueRef)(CFBridgingRelease(ABRecordCopyValue(person, kABPersonEmailProperty)))) > 0) ||
            (ABMultiValueGetCount((__bridge ABMultiValueRef)(CFBridgingRelease(ABRecordCopyValue(person, kABPersonPhoneProperty)))) > 0));
}

- (NSArray *)phoneNumbersForPerson:(ABRecordRef)person
{
    NSMutableArray *phones = [[NSMutableArray alloc] init];
    ABMultiValueRef phonesRef = (__bridge ABMultiValueRef)(CFBridgingRelease(ABRecordCopyValue(person, kABPersonPhoneProperty)));
    if (ABMultiValueGetCount(phonesRef) > 0)
    {
        for (CFIndex i = 0; i < ABMultiValueGetCount(phonesRef); i++)
        {
            [phones addObject:(__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phonesRef, i)];
        }
    }
    return [NSArray arrayWithArray:phones];
}

- (NSArray *)emailsForPerson:(ABRecordRef)person
{
    NSMutableArray *emails = [[NSMutableArray alloc] init];
    ABMultiValueRef emailsRef = (__bridge ABMultiValueRef)(CFBridgingRelease(ABRecordCopyValue(person, kABPersonEmailProperty)));
    if (ABMultiValueGetCount(emailsRef) > 0)
    {
        for (CFIndex i = 0; i < ABMultiValueGetCount(emailsRef); i++)
        {
            [emails addObject:(__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emailsRef, i)];
        }
    }
    return [NSArray arrayWithArray:emails];
}

- (NSString *)displayNameForPerson:(ABRecordRef)person
{
    NSString *displayName = nil;
    NSString *firstName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *lastName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
    if (firstName && lastName)
    {
        displayName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    }
    else if (firstName)
    {
        displayName = firstName;
    }
    else if (lastName)
    {
        displayName = lastName;
    }
    return displayName;
}

- (UIImage *)avatarImageForPerson:(ABRecordRef)person
{
    UIImage *image = nil;
    if (person && ABPersonHasImageData(person))
    {
        NSData *imageData = (__bridge_transfer NSData *) ABPersonCopyImageData(person);
        image = [UIImage imageWithData:imageData];
    }
    return image;
}

- (NSArray *)phoneNumbersForContactAtIndex:(NSInteger)index
{
    NSArray *phoneNumbers = @[];
    if (index >= [self.contactsOnDrawQuest count])
    {
        index -= [self.contactsOnDrawQuest count];
        if (index < CFArrayGetCount(self.allPeopleRef))
        {
            ABRecordRef person = CFArrayGetValueAtIndex(self.allPeopleRef, index);
            phoneNumbers = [self phoneNumbersForPerson:person];
        }
    }
    return phoneNumbers;
}

- (NSArray *)emailsForContactAtIndex:(NSInteger)index
{
    NSArray *emails = @[];
    if (index >= [self.contactsOnDrawQuest count])
    {
        index -= [self.contactsOnDrawQuest count];
        if (index < CFArrayGetCount(self.allPeopleRef))
        {
            ABRecordRef person = CFArrayGetValueAtIndex(self.allPeopleRef, index);
            emails = [self emailsForPerson:person];
        }
    }
    return emails;
}

- (void)reloadAllPersonsRef
{
    if (_allPeopleRef)
    {
        CFRelease(_allPeopleRef);
    }
    _allPeopleRef = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(self.addressBookRef, (__bridge ABRecordRef)(CFBridgingRelease(ABAddressBookCopyDefaultSource(self.addressBookRef))), kABPersonSortByFirstName);
}

#pragma mark - DQFriendListViewControllerDataSource

- (NSString *)emptyFriendListMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"It looks like your Address Book is empty.", @"User has no contacts in their address book to invite");
}

- (NSString *)authorizationRequestMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    // Address Book should immediately request access on its own so this won't be used
    return @"DrawQuest has been denied access to your Contacts list. Please update your privacy options in your iOS settings to invite your Contacts to DrawQuest.";
}

- (NSString *)authorizationFailedMessageForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return DQLocalizedString(@"Address Book Error", @"Address book authorization failed error message");
}

- (NSUInteger)numberOfRowsInFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    NSUInteger count = (int)CFArrayGetCount(self.allPeopleRef) + [self.contactsOnDrawQuest count];
    return count;
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController displayNameAtIndex:(NSUInteger)index
{
    NSString *displayName = @"";
    if (index < [self.contactsOnDrawQuest count])
    {
        NSDictionary *contact = [self.contactsOnDrawQuest objectAtIndex:index];
        displayName = [contact objectForKey:DQContactsKeyStringDisplayName];
    }
    else
    {
        index -= [self.contactsOnDrawQuest count];
        ABRecordRef person = CFArrayGetValueAtIndex(self.allPeopleRef, index);
        displayName = [self displayNameForPerson:person];
    }
    return displayName;
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController avatarImageURLAtIndex:(NSUInteger)index
{
    // Uses the optional avatarImage method below instead
    return @"";
}

- (UIImage *)friendListViewController:(DQFriendListViewController *)friendListViewController avatarImageAtIndex:(NSUInteger)index
{
    UIImage *image = nil;
    if (index < [self.contactsOnDrawQuest count])
    {
        NSDictionary *contact = [self.contactsOnDrawQuest objectAtIndex:index];
        image = [contact objectForKey:DQContactsKeyStringAvatarImage];
    }
    else
    {
        index -= [self.contactsOnDrawQuest count];
        if (index < CFArrayGetCount(self.allPeopleRef))
        {
            ABRecordRef person = CFArrayGetValueAtIndex(self.allPeopleRef, index);
            image = [self avatarImageForPerson:person];
        }
    }
    return image;
}

- (NSString *)friendListViewController:(DQFriendListViewController *)friendListViewController dqUsernameAtIndex:(NSUInteger)index
{
    NSString *displayName = nil;
    if (index < [self.contactsOnDrawQuest count])
    {
        NSDictionary *contact = [self.contactsOnDrawQuest objectAtIndex:index];
        displayName = [contact objectForKey:DQContactsKeyStringUserName];
    }
    return displayName;
}

- (NSUInteger)numberOfInvitesSentOrPendingForFriendListViewController:(DQFriendListViewController *)friendListViewController
{
    return self.invitesSent;
}

#pragma mark - DQFriendListViewControllerDelegate

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController hasPermissionsWithCompletionBlock:(void (^)(BOOL))completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    if (_addressBookRef)
    {
        CFRelease(_addressBookRef);
    }
    _addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
        if (completionBlock)
        {
            completionBlock(YES);
        }
    }
    else
    {
        // Ask for permissions right away if we don't already have them.
        ABAddressBookRequestAccessWithCompletion(self.addressBookRef, ^(bool isAuthorized, CFErrorRef errorRef) {
            if (isAuthorized)
            {
                [self reloadAllPersonsRef];
            }
            if (completionBlock)
            {
                completionBlock(isAuthorized);
            }
        });
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController requestPermissionsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock accountSelectedBlock:(dispatch_block_t)accountSelectedBlock fromView:(UIView *)view
{
    // This will never get called because we don't have a button
}

- (DQButton *)friendListViewController:(DQFriendListViewController *)friendListViewController requestAccessButtonWithTappedBlock:(DQButtonBlock)tappedBlock
{
    // Don't return a button because they have to manually chanage their settings
    return nil;
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController loadFriendsWithCompletionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock noFriendsBlock:(dispatch_block_t)noFriendsBlock
{
    if (self.hasLoadedContacts)
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }
    else
    {
        self.hasLoadedContacts = YES;
        [self reloadAllPersonsRef];

        // Create a list of emails to check for DQ membership
        NSMutableArray *emailHashList = [[NSMutableArray alloc] init];
        NSMutableDictionary *recordIDs = [[NSMutableDictionary alloc] init];
        for (CFIndex i = 0; i < CFArrayGetCount(self.allPeopleRef); i++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex(self.allPeopleRef, i);
            if ([self personHasEmailOrPhoneNumber:person] && [self displayNameForPerson:person])
            {
                NSMutableArray *emails = [[NSMutableArray alloc] initWithArray:[self emailsForPerson:person]];
                for (NSString *email in emails)
                {
                    [recordIDs setObject:@((int)ABRecordGetRecordID(person)) forKey:email];
                }
            }
            else
            {
                // Remove anyone with no name or relevant contact info
                ABAddressBookRemoveRecord(self.addressBookRef, person, NULL);
            }
        }
        [self reloadAllPersonsRef];
        [recordIDs enumerateKeysAndObjectsUsingBlock:^(NSString *email, NSNumber *recordID, BOOL *stop) {
            unsigned char digest[CC_SHA1_DIGEST_LENGTH];
            NSData *stringBytes = [email dataUsingEncoding: NSUTF8StringEncoding];
            if (CC_SHA1([stringBytes bytes], [stringBytes length], digest))
            {
                NSData *data = [NSData dataWithBytes:(digest) length:sizeof(digest)];
                NSString *hash = [NSString stringWithFormat:@"%@", data];
                hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
                hash = [hash substringWithRange:NSMakeRange(1, [hash length]-2)];
                [emailHashList addObject:hash];
            }
        }];

        // Contacts already on DrawQuest Request
        __weak typeof(self) weakSelf = self;
        [self.publicServiceController requestUsernamesFromEmailHashList:emailHashList withCompletionBlock:^(DQHTTPRequest *request, NSDictionary *responseDictionary) {
            dispatch_block_t messageReadyBlock = ^{
                NSMutableArray *contactsOnDrawquest = [[NSMutableArray alloc] init];
                NSArray *users = responseDictionary.dq_users;
                for (NSDictionary *user in users)
                {
                    ABRecordID recordID = (ABRecordID)[[recordIDs objectForKey:user[@"email"]] intValue];
                    ABRecordRef person = ABAddressBookGetPersonWithRecordID(weakSelf.addressBookRef, recordID);
                    // One contact could match multiple DQ accounts
                    if (person)
                    {
                        NSDictionary *contact = @{
                                                  DQContactsKeyStringUserName: user[@"username"] ?: @"",
                                                  DQContactsKeyStringDisplayName: [weakSelf displayNameForPerson:person] ?: @"",
                                                  DQContactsKeyStringAvatarImage: [weakSelf avatarImageForPerson:person] ?: [UIImage new],
                                                  DQContactsKeyStringIsFollowing: user[@"viewer_is_following"] ?: @(NO)
                                                  };
                        [contactsOnDrawquest addObject:contact];
                        // Remove this user from the address book since they will appear as a DQ Contact
                        ABAddressBookRemoveRecord(weakSelf.addressBookRef, person, NULL);
                    }
                }
                [self reloadAllPersonsRef];
                weakSelf.contactsOnDrawQuest = [NSArray arrayWithArray:contactsOnDrawquest];
                weakSelf.contactsToFollow = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, [weakSelf.contactsOnDrawQuest count])];

                // Finish up
                if (CFArrayGetCount(self.allPeopleRef) || [self.contactsOnDrawQuest count])
                {
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }
                else
                {
                    if (noFriendsBlock)
                    {
                        noFriendsBlock();
                    }
                }
            };
            
            if (weakSelf.messageForInviteBlock)
            {
                weakSelf.messageForInviteBlock(DQAPIValueShareChannelTypeEmail, ^void(NSString *message) {
                    self.invitationEmailMessage = message;
                    weakSelf.messageForInviteBlock(DQAPIValueShareChannelTypeTextMessage, ^void(NSString *message) {
                        self.invitationTextMessage = message;
                        messageReadyBlock();
                    });
                });
            }
            else
            {
                @throw [NSException exceptionWithName:NSGenericException reason:@"DQAddressBookCoordinator: messageForInviteBlock not defined." userInfo:nil];
            }
        }];
    }
}

- (UIView *)friendListViewController:(DQFriendListViewController *)friendListViewController accessoryViewAtIndex:(NSUInteger)index
{
    // Follow toggle for people on DrawQuest
    if (index < [self.contactsOnDrawQuest count])
    {
        return [self accessoryViewForFriendsOnDrawQuestWithFriendListViewController:friendListViewController atIndex:index];
    }
    // Disclosure for everyone else
    else
    {
        return [self accessoryViewForFriendsNotOnDrawQuestAtIndex:index];
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController didSelectFriendAtIndex:(NSUInteger)index accessoryView:(UIView *)accessoryView
{
    if (self.presentActionSheetBlock && index >= [self.contactsOnDrawQuest count])
    {
        index -= [self.contactsOnDrawQuest count];
        ABRecordRef person = CFArrayGetValueAtIndex(self.allPeopleRef, index);
        NSArray *emails = [self emailsForPerson:person];
        NSArray *phoneNumbers = [self phoneNumbersForPerson:person];
        NSString *displayName = [self displayNameForPerson:person];

        DQActionSheet *sheet = [[DQActionSheet alloc] initWithTitle:[NSString stringWithFormat:DQLocalizedString(@"Invite %@ to DrawQuest", @"Invite user action sheet title"), displayName] delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (NSString *email in emails)
        {
            [sheet addButtonWithTitle:email];
        }
        for (NSString *phoneNumber in phoneNumbers)
        {
            [sheet addButtonWithTitle:phoneNumber];
        }
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view")];
        sheet.dq_completionBlock = ^(DQActionSheet *sheet, NSInteger buttonIndex) {
            NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
            if (buttonIndex < [emails count])
            {
                // Email
                if (self.presentViewControllerBlock)
                {
                    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
                    [controller setSubject:self.subjectLine];
                    [controller setToRecipients:@[title]];
                    [controller setMessageBody:self.invitationEmailMessage isHTML:NO];
                    controller.mailComposeDelegate = self;
                    self.presentViewControllerBlock(controller);
                }
            }
            else
            {
                // Messages
                if(self.presentViewControllerBlock && [MFMessageComposeViewController canSendText])
                {
                    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
                    controller.messageComposeDelegate = self;
                    controller.body = self.invitationTextMessage;
                    controller.recipients = @[title];

                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                    self.presentViewControllerBlock(controller);
                }
                else
                {
                    DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Messages Error", @"Messages app error title") message:DQLocalizedString(@"There was an error opening the Messages app.", @"Messages app error message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                    [alert show];
                }
            }
        };
        self.presentActionSheetBlock(sheet);
    }
}

- (void)friendListViewController:(DQFriendListViewController *)friendListViewController sendPendingRequestsWithCancellationBlock:(dispatch_block_t)cancellationBlock completionBlock:(dispatch_block_t)completionBlock failureBlock:(void (^)(NSError *))failureBlock
{
    if ([self.contactsToFollow count])
    {
        NSMutableArray *usernames = [[NSMutableArray alloc] init];
        __weak typeof(self) weakSelf = self;
        [self.contactsToFollow enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            NSDictionary *contact = [weakSelf.contactsOnDrawQuest objectAtIndex:idx];
            // Remove contacts we're already following
            if ( ! [contact boolForKey:DQContactsKeyStringIsFollowing])
            {
                [usernames addObject:[contact objectForKey:DQContactsKeyStringUserName]];
            }
        }];
        if ([usernames count])
        {
            [self.privateServiceController requestFollowForUsersWithNames:usernames completionBlock:^(DQHTTPRequest *request, id JSONObject) {
                if (request.error)
                {
                    if (failureBlock)
                    {
                        failureBlock(request.error);
                    }
                }
                else
                {
                    if (weakSelf.logFollowBlock)
                    {
                        weakSelf.logFollowBlock(weakSelf);
                    }
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                }
            }];
        }
        else if (completionBlock)
        {
            completionBlock();
        }
    }
    else if (completionBlock)
    {
        completionBlock();
    }
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (error)
    {
        DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Mail Error", @"Mail app error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        if (result == MFMailComposeResultSent)
        {
            self.invitesSent += 1;
        }
    }
    [controller.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark MFMessageComposeViewControllerDelegate Methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    if (result == MessageComposeResultSent)
    {
        self.invitesSent += 1;
    }
    [controller.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation DQAddressBookCoordinator (TemplateMethods)

- (UIView *)accessoryViewForFriendsOnDrawQuestWithFriendListViewController:(DQFriendListViewController *)friendListViewController atIndex:(NSInteger)index
{
    // FIXME: Make this button do something
    DQButton *button = [DQButton buttonWithImage:[UIImage imageNamed:@"activity_follow"] selectedImage:[UIImage imageNamed:@"activity_following"]];
    button.selected = YES;
    button.frameWidth = kDQFormPhoneAddFriendsAccessoryWidth;
    button.frameHeight = kDQFormPhoneAddFriendsAccessoryHeight;
    button.layer.cornerRadius = 4.0f;
    button.tintColorForBackground = YES;
    __weak typeof(self) weakSelf = self;
    button.tappedBlock = ^(DQButton *button) {
        // Allow toggling for users we aren't already following
        NSDictionary *contact = [weakSelf.contactsOnDrawQuest objectAtIndex:index];
        if (! [contact boolForKey:DQContactsKeyStringIsFollowing])
        {
            button.selected = ! button.selected;
        }
    };
    button.selectedBlock = ^(DQButton *button, BOOL isSelected) {
        button.tintColorForBackground = isSelected;
        if (isSelected)
        {
            [weakSelf.contactsToFollow addIndex:index];
        }
        else
        {
            [weakSelf.contactsToFollow removeIndex:index];
            button.backgroundColor = [UIColor dq_phoneButtonOffColor];
        }
    };
    return button;
}

- (UIView *)accessoryViewForFriendsNotOnDrawQuestAtIndex:(NSInteger *)index
{
    UIImageView *disclosure = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_disclosure_phone"]];
    return disclosure;
}

@end
