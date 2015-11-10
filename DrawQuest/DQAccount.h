//
//  DQAccount.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-04-21.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DQAccountPushNotificationTypeQuestOfTheDay,
    DQAccountPushNotificationTypeNewColors,
    DQAccountPushNotificationTypeStarred,
    DQAccountPushNotificationTypeFacebookFriendJoined,
    DQAccountPushNotificationTypeTwitterFriendJoined
} DQAccountPushNotificationType;

@interface DQAccount : NSObject

@property (nonatomic, copy) NSString *accountID;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *avatarURL;

@property (nonatomic, copy) NSNumber *coinCount;
@property (nonatomic, copy) NSString *followerCount;
@property (nonatomic, copy) NSString *followingCount;
@property (nonatomic, assign) BOOL hasPublishedAComment;
@property (nonatomic, assign) BOOL hasPublishedAQuest;

@property (nonatomic, copy) NSArray *completedQuestIDs;
@property (nonatomic, copy) NSDate *timestampOfNewestReadActivity;

@property (nonatomic, readonly, assign) BOOL shareToFacebookOn;
@property (nonatomic, readonly, assign) BOOL shareToTwitterOn;
@property (nonatomic, readonly, assign) BOOL hasShareToFacebookOn;
@property (nonatomic, readonly, assign) BOOL hasShareToTwitterOn;

@property (nonatomic, assign) BOOL webProfileEnabled;
@property (nonatomic, assign) BOOL facebookProfileEnabled;
@property (nonatomic, readonly, assign) BOOL facebookProfileExplicitlySet;
@property (nonatomic, assign) BOOL twitterProfileEnabled;
@property (nonatomic, readonly, assign) BOOL twitterProfileExplicitlySet;
@property (nonatomic, assign) BOOL shouldShowShareWebProfile;

@property (nonatomic, assign) NSInteger lastViewedColorAlertVersion;
@property (nonatomic, assign) NSInteger currentColorAlertVersion;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *brushes;

@property (nonatomic, copy) NSNumber *homeTabBadgeTimestamp;
@property (nonatomic, copy) NSNumber *drawTabBadgeTimestamp;
@property (nonatomic, copy) NSNumber *activityTabBadgeTimestamp;

// Class Methods
+ (NSString *)authTokenForAccountWithAccountID:(NSString *)accountID forSource:(NSString *)source error:(NSError **)error;

// Initialization
- (id)initWithAccountID:(NSString *)inAccountID;
- (id)init MSDesignatedInitializer(initWithAccountID:);

- (void)takeShareToFacebookOn:(BOOL)shareToFacebookOn;
- (void)takeShareToTwitterOn:(BOOL)shareToTwitterOn;

- (NSString *)authTokenForSource:(NSString *)source;
- (void)setAuthToken:(NSString *)inAuthToken forSource:(NSString *)source;

- (BOOL)hasAuthCredentialsForSource:(NSString *)source;

@end
