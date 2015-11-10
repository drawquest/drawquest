//
//  DQAccount.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-21.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQAccount.h"
#import "STUtils.h"
#import "STKeychain.h"
#import "DQPapertrailLogger.h"

// Defaults Constants
NSString *DQApplicationAccountUsernameDefaultsKey = @"Username";
NSString *DQApplicationAccountEmailDefaultsKey = @"Email";
NSString *DQApplicationAccountBioDefaultsKey = @"Bio";
NSString *DQApplicationAccountAvatarURLDefaultsKey = @"AvatarURL";
NSString *DQApplicationAccountCoinCountDefaultsKey = @"CoinCount";
NSString *DQApplicationAccountFollowerCountDefaultsKey = @"FollowerCount";
NSString *DQApplicationAccountFollowingCountDefaultsKey = @"FollowingCount";
NSString *DQApplicationAccountCompletedQuestsDefaultsKey = @"CompletedQuests";
NSString *DQApplicationAccountWebProfilePreferenceKey = @"WebProfilePreference";
NSString *DQApplicationAccountFacebookProfilePreferenceKey = @"FacebookProfilePreference";
NSString *DQApplicationAccountTwitterProfilePreferenceKey = @"TwitterProfilePreference";
NSString *DQApplicationAccountShouldShowShareWebProfileKey = @"ShouldShowShareWebProfile";
NSString *DQApplicationAccountTimestampOfNewestReadActivityDefaultsKey = @"TimestampOfNewestReadActivity";
NSString *DQApplicationAccountFBShareDefaultsKey = @"FBSharePreference";
NSString *DQApplicationAccountTWShareDefaultsKey = @"TWSharePreference";
NSString *DQApplicationAccountHasPublishedAComment = @"HasPublishedAComment";
NSString *DQApplicationAccountHasPublishedAQuest = @"HasPublishedAQuest";
NSString *DQApplicationAccountLastViewedColorAlertVersion = @"LastViewedColorAlertVersion";
NSString *DQApplicationAccountCurrentColorAlertVersion = @"CurrentColorAlertVersion";
NSString *DQApplicationAccountColorsKey = @"Colors";
NSString *DQApplicationAccountBrushesKey = @"Brushes";
NSString *DQApplicationAccountHomeTabBadgeTimestampKey = @"HomeTabBadgeTimestamp";
NSString *DQApplicationAccountDrawTabBadgeTimestampKey = @"DrawTabBadgeTimestamp";
NSString *DQApplicationAccountActivityTabBadgeTimestampKey = @"ActivityTabBadgeTimestamp";

// Keychain Keys
NSString *DQApplicationKeychainServiceName = @"DrawQuest";

@implementation DQAccount

@dynamic username;
@dynamic email;
@dynamic bio;
@dynamic avatarURL;
@dynamic coinCount;
@dynamic followerCount;
@dynamic followingCount;
@dynamic completedQuestIDs;
@dynamic webProfileEnabled;
@dynamic shouldShowShareWebProfile;
@dynamic timestampOfNewestReadActivity;
@dynamic shareToFacebookOn;
@dynamic shareToTwitterOn;
@dynamic brushes;
@dynamic homeTabBadgeTimestamp;
@dynamic drawTabBadgeTimestamp;
@dynamic activityTabBadgeTimestamp;

#pragma mark Initialization

- (id)initWithAccountID:(NSString *)inAccountID
{
    self = [super init];
    if (self)
    {
        _accountID = [inAccountID copy];
    }
    return self;
}


#pragma mark Accessors

- (NSString *)username
{
    return [self stringForDefaultsKey:DQApplicationAccountUsernameDefaultsKey];
}

- (void)setUsername:(NSString *)inUsername
{
    [self setDefaultsValue:inUsername forKey:DQApplicationAccountUsernameDefaultsKey];
}

- (NSString *)email;
{
    return [self stringForDefaultsKey:DQApplicationAccountEmailDefaultsKey];
}

- (void)setEmail:(NSString *)inEmail;
{
    [self setDefaultsValue:inEmail forKey:DQApplicationAccountEmailDefaultsKey];
}

- (NSString *)bio
{
    return [self stringForDefaultsKey:DQApplicationAccountBioDefaultsKey];
}

- (void)setBio:(NSString *)inBio
{
    [self setDefaultsValue:inBio forKey:DQApplicationAccountBioDefaultsKey];
}

- (NSString *)avatarURL
{
    return [self stringForDefaultsKey:DQApplicationAccountAvatarURLDefaultsKey];
}

- (void)setAvatarURL:(NSString *)inAvatarURL
{
    [self setDefaultsValue:inAvatarURL forKey:DQApplicationAccountAvatarURLDefaultsKey];
}

- (void)setCoinCount:(NSNumber *)inCoinCount
{
    [self setDefaultsValue:inCoinCount forKey:DQApplicationAccountCoinCountDefaultsKey];
}

- (NSNumber *)coinCount
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountCoinCountDefaultsKey forAccountWithName:self.accountID];
}

- (void)setFollowerCount:(NSString *)inFollowerCount
{
    [self setDefaultsValue:inFollowerCount forKey:DQApplicationAccountFollowerCountDefaultsKey];
}

- (NSString *)followerCount
{
    NSString *count = [self stringForDefaultsKey:DQApplicationAccountFollowerCountDefaultsKey];

    return count.length ? count : @"0";
}

- (void)setFollowingCount:(NSString *)inFollowingCount
{
    [self setDefaultsValue:inFollowingCount forKey:DQApplicationAccountFollowingCountDefaultsKey];
}

- (NSString *)followingCount
{
    NSString *count = [self stringForDefaultsKey:DQApplicationAccountFollowingCountDefaultsKey];

    return count.length ? count : @"0";
}

- (void)setHasPublishedAComment:(BOOL)hasPublishedAComment
{
    [self setDefaultsBool:hasPublishedAComment forKey:DQApplicationAccountHasPublishedAComment];
}

- (BOOL)hasPublishedAComment
{
    return [self boolForDefaultsKey:DQApplicationAccountHasPublishedAComment];
}

- (void)setHasPublishedAQuest:(BOOL)hasPublishedAQuest
{
    [self setDefaultsBool:hasPublishedAQuest forKey:DQApplicationAccountHasPublishedAQuest];
}

- (BOOL)hasPublishedAQuest
{
    return [self boolForDefaultsKey:DQApplicationAccountHasPublishedAQuest];
}

- (NSString *)authTokenForSource:(NSString *)source
{
    return [[self class] authTokenForAccountWithAccountID:self.accountID forSource:source error:NULL];
}

+ (NSString *)authTokenForAccountWithAccountID:(NSString *)accountID forSource:(NSString *)source error:(NSError **)error
{
    NSString *result = [STKeychain getPasswordForUsername:accountID andServiceName:DQApplicationKeychainServiceName error:error];
    if (!result && error && *error)
    {
        // nil means "not found" when (error == nil), so only log when there's an error
        [DQPapertrailLogger component:@"account" category:@"authToken-failed" error:*error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"username": accountID ?: [NSNull null],
                     @"source": source ?: [NSNull null]};
        }];
    }
    return result;
}

- (void)setAuthToken:(NSString *)inAuthToken forSource:(NSString *)source
{
    if (!self.accountID.length) {
        return;
    }

    if (!inAuthToken.length) {
        [STKeychain deleteItemForUsername:self.accountID andServiceName:DQApplicationKeychainServiceName error:nil];
        return;
    }

    NSError *error = nil;
    BOOL result = [STKeychain storeUsername:self.accountID andPassword:inAuthToken forServiceName:DQApplicationKeychainServiceName updateExisting:YES error:&error];
    if (!result)
    {
        [DQPapertrailLogger component:@"account" category:@"setAuthToken-failed" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"username": self.accountID ?: [NSNull null],
                     @"password": inAuthToken ?: [NSNull null],
                     @"source": source ?: [NSNull null]};
        }];
        NSLog(@"Unable to store keychain password due to error: %@", error);
    }
}

- (BOOL)hasAuthCredentialsForSource:(NSString *)source
{
    return (self.username.length && [[self authTokenForSource:source] length]);
}

- (NSArray *)completedQuestIDs
{
    return self.accountID ? [[NSUserDefaults standardUserDefaults] arrayForKey:DQApplicationAccountCompletedQuestsDefaultsKey forAccountWithName:self.accountID] : nil;
}

- (void)setCompletedQuestIDs:(NSArray *)inCompletedQuestIDs
{
    [self setDefaultsValue:inCompletedQuestIDs forKey:DQApplicationAccountCompletedQuestsDefaultsKey];
}

- (BOOL)webProfileEnabled
{
    return [self boolForDefaultsKey:DQApplicationAccountWebProfilePreferenceKey];
}

- (void)setWebProfileEnabled:(BOOL)webProfileEnabled
{
    [self setDefaultsBool:webProfileEnabled forKey:DQApplicationAccountWebProfilePreferenceKey];
}

- (BOOL)facebookProfileEnabled
{
    return [self facebookProfileExplicitlySet] && [self boolForDefaultsKey:DQApplicationAccountFacebookProfilePreferenceKey];
}

- (void)setFacebookProfileEnabled:(BOOL)facebookProfileEnabled
{
    [self setDefaultsBool:facebookProfileEnabled forKey:DQApplicationAccountFacebookProfilePreferenceKey];
}

- (BOOL)facebookProfileExplicitlySet
{
    return nil != [self objectForDefaultsKey:DQApplicationAccountFacebookProfilePreferenceKey];
}

- (BOOL)twitterProfileEnabled
{
    return [self twitterProfileExplicitlySet] && [self boolForDefaultsKey:DQApplicationAccountTwitterProfilePreferenceKey];
}

- (void)setTwitterProfileEnabled:(BOOL)twitterProfileEnabled
{
    [self setDefaultsBool:twitterProfileEnabled forKey:DQApplicationAccountTwitterProfilePreferenceKey];
}

- (BOOL)twitterProfileExplicitlySet
{
    return nil != [self objectForDefaultsKey:DQApplicationAccountTwitterProfilePreferenceKey];
}

- (BOOL)shouldShowShareWebProfile
{
    return [self boolForDefaultsKey:DQApplicationAccountShouldShowShareWebProfileKey];
}

- (void)setShouldShowShareWebProfile:(BOOL)shouldShowShareWebProfile
{
    [self setDefaultsBool:shouldShowShareWebProfile forKey:DQApplicationAccountShouldShowShareWebProfileKey];
}

- (NSDate *)timestampOfNewestReadActivity
{
    return self.accountID ? [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountTimestampOfNewestReadActivityDefaultsKey forAccountWithName:self.accountID] : nil;
}

- (void)setTimestampOfNewestReadActivity:(NSDate *)timestampOfNewestReadActivity
{
    [self setDefaultsValue:timestampOfNewestReadActivity forKey:DQApplicationAccountTimestampOfNewestReadActivityDefaultsKey];
}

- (BOOL)hasShareToFacebookOn
{
    return nil != [self objectForDefaultsKey:DQApplicationAccountFBShareDefaultsKey];
}

- (BOOL)shareToFacebookOn
{
    return [self boolForDefaultsKey:DQApplicationAccountFBShareDefaultsKey];
}

- (void)takeShareToFacebookOn:(BOOL)shareToFacebookOn
{
    [self setDefaultsBool:shareToFacebookOn forKey:DQApplicationAccountFBShareDefaultsKey];
}

- (BOOL)hasShareToTwitterOn
{
    return nil != [self objectForDefaultsKey:DQApplicationAccountTWShareDefaultsKey];
}

- (BOOL)shareToTwitterOn
{
    return [self boolForDefaultsKey:DQApplicationAccountTWShareDefaultsKey];
}

- (void)takeShareToTwitterOn:(BOOL)shareToTwitterOn
{
    [self setDefaultsBool:shareToTwitterOn forKey:DQApplicationAccountTWShareDefaultsKey];
}

- (NSInteger)lastViewedColorAlertVersion
{
    NSInteger value = 0;
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountLastViewedColorAlertVersion forAccountWithName:self.accountID];;
    if (number)
    {
        value = [number integerValue];
    }
    return value;
}

- (void)setLastViewedColorAlertVersion:(NSInteger)version
{
    [self setDefaultsValue:@(version) forKey:DQApplicationAccountLastViewedColorAlertVersion];
}

- (NSInteger)currentColorAlertVersion
{
    NSInteger value = 0;
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountCurrentColorAlertVersion forAccountWithName:self.accountID];;
    if (number)
    {
        value = [number integerValue];
    }
    return value;
}

- (void)setCurrentColorAlertVersion:(NSInteger)version
{
    [self setDefaultsValue:@(version) forKey:DQApplicationAccountCurrentColorAlertVersion];
}

- (NSArray *)colors
{
    return self.accountID ? [[NSUserDefaults standardUserDefaults] arrayForKey:DQApplicationAccountColorsKey forAccountWithName:self.accountID] : nil;
}

- (void)setColors:(NSArray *)colors
{
    [self setDefaultsValue:colors forKey:DQApplicationAccountColorsKey];
}

- (NSArray *)brushes
{
    return self.accountID ? [[NSUserDefaults standardUserDefaults] arrayForKey:DQApplicationAccountBrushesKey forAccountWithName:self.accountID] : nil;
}

- (void)setBrushes:(NSArray *)brushes
{
    [self setDefaultsValue:brushes forKey:DQApplicationAccountBrushesKey];
}


- (void)setHomeTabBadgeTimestamp:(NSNumber *)v
{
    [self setDefaultsValue:v forKey:DQApplicationAccountHomeTabBadgeTimestampKey];
}

- (NSNumber *)homeTabBadgeTimestamp
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountHomeTabBadgeTimestampKey forAccountWithName:self.accountID];
}

- (void)setDrawTabBadgeTimestamp:(NSNumber *)v
{
    [self setDefaultsValue:v forKey:DQApplicationAccountDrawTabBadgeTimestampKey];
}

- (NSNumber *)drawTabBadgeTimestamp
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountDrawTabBadgeTimestampKey forAccountWithName:self.accountID];
}

- (void)setActivityTabBadgeTimestamp:(NSNumber *)v
{
    [self setDefaultsValue:v forKey:DQApplicationAccountActivityTabBadgeTimestampKey];
}

- (NSNumber *)activityTabBadgeTimestamp
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:DQApplicationAccountActivityTabBadgeTimestampKey forAccountWithName:self.accountID];
}

#pragma mark Defaults Conveniences

- (NSString *)objectForDefaultsKey:(NSString *)inKey
{
    if (!self.accountID || !inKey.length) {
        return nil;
    }

    return [[NSUserDefaults standardUserDefaults] objectForKey:inKey forAccountWithName:self.accountID];
}

- (NSString *)stringForDefaultsKey:(NSString *)inKey
{
    return [[self objectForDefaultsKey:inKey] description];
}

- (void)setDefaultsValue:(id)inValue forKey:(NSString *)inKey
{
    if (!self.accountID || !inValue || !inKey.length) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:inValue forKey:inKey forAccountWithName:self.accountID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)boolForDefaultsKey:(NSString *)inKey
{
    return !(!self.accountID || !inKey.length) && [[NSUserDefaults standardUserDefaults] boolForKey:inKey forAccountWithName:self.accountID];

}

- (void)setDefaultsBool:(BOOL)inValue forKey:(NSString *)inKey
{
    if (!self.accountID || !inKey.length) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:inValue forKey:inKey forAccountWithName:self.accountID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
