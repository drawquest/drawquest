//
//  NSDictionary+DQAPIConveniences.h
//  DrawQuest
//
//  Created by Buzz Andersen on 9/14/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DQActivityConstants.h"

// API Key Strings
extern NSString *DQAPIKeyStringSuccess;
extern NSString *DQAPIKeyStringErrorType;
extern NSString *DQAPIKeyStringErrors;
extern NSString *DQAPIKeyStringErrorReason;
extern NSString *DQAPIKeyStringErrorMessage;
extern NSString *DQAPIKeyStringID;
extern NSString *DQAPIKeyStringContent;
extern NSString *DQAPIKeyStringQuests;
extern NSString *DQAPIKeyStringQuest;
extern NSString *DQAPIKeyStringComments;
extern NSString *DQAPIKeyStringActivites;
extern NSString *DQAPIKeyStringCommentCount;
extern NSString *DQAPIKeyStringQuestCount;
extern NSString *DQAPIKeyStringMigrationTimestamp;
extern NSString *DQAPIKeyStringTimestamp;
extern NSString *DQAPIKeyStringUserInfo;
extern NSString *DQAPIKeyStringUsername;
extern NSString *DQAPIKeyStringEmail;
extern NSString *DQAPIKeyStringPassword;
extern NSString *DQAPIKeyStringTitle;
extern NSString *DQAPIKeyStringQuestCommentsURL;
extern NSString *DQAPIKeyStringQuestDrawingCount;
extern NSString *DQAPIKeyStringQuestAuthorCount;
extern NSString *DQAPIKeyQuestCompletedByUser;
extern NSString *DQAPIKeyStringCommentQuestID;
extern NSString *DQAPIKeyStringCommentQuestTitle;
extern NSString *DQAPIKeyStringCommentAuthorID;
extern NSString *DQAPIKeyStringCommentAuthorName;
extern NSString *DQAPIKeyStringReactions;
extern NSString *DQAPIKeyStringReactionType;
extern NSString *DQAPIKeyStringImageURL;
extern NSString *DQAPIKeyStringActivityItemActor;
extern NSString *DQAPIKeyStringViewer;
extern NSString *DQAPIKeyStringNotificationType;
extern NSString *DQAPIKeyStringShopColors;
extern NSString *DQAPIKeyStringShopColorID;
extern NSString *DQAPIKeyStringShopColorPacks;
extern NSString *DQAPIKeyStringShopColorPackID;
extern NSString *DQAPIKeyStringShopBrushID;
extern NSString *DQAPIKeyStringShopBrushCanonicalName;
extern NSString *DQAPIKeyStringShareChannel;
extern NSString *DQAPIKeyStringShareChannels;
extern NSString *DQAPIKeyStringQuestID;
extern NSString *DQAPIKeyStringCommentID;
extern NSString *DQAPIKeyStringContentID;
extern NSString *DQAPIKeyStringSinceTimestamp;
extern NSString *DQAPIKeyStringNewerThanDate;
extern NSString *DQAPIKeyStringOlderThanDate;
extern NSString *DQAPIKeyStringFollowers;
extern NSString *DQAPIKeyStringFollowing;
extern NSString *DQAPIKeyStringCoinProducts;
extern NSString *DQAPIKeyStringCoinProductDescription;
extern NSString *DQAPIKeyStringCoinProductAmount;
extern NSString *DQAPIKeyStringCoinProductCost;
extern NSString *DQAPIKeyStringBrushIsPurchased;
extern NSString *DQAPIKeyStringUserBrushes;
extern NSString *DQAPIKeyStringReceiptData;
extern NSString *DQAPIKeyStringFacebookToken;
extern NSString *DQAPIKeyStringFacebookShare;
extern NSString *DQAPIKeyStringTwitterShare;
extern NSString *DQAPIKeyStringTwitterToken;
extern NSString *DQAPIKeyStringTwitterSecret;
extern NSString *DQAPIKeyStringEmailShare;
extern NSString *DQAPIKeyStringEmailShareList;
extern NSString *DQAPIKeyStringJSONPlaybackData;
extern NSString *DQAPIKeyStringPropertyListPlaybackData;
extern NSString *DQAPIKeyStringRewardsInfo;
extern NSString *DQAPIKeyStringRewardsCopy;
extern NSString *DQAPIKeyStringRewardsAmounts;
extern NSString *DQAPIKeyStringCompletedQuestIDs;
extern NSString *DQAPIKeyStringMetricName;
extern NSString *DQAPIKeyStringVersionOfAvailableUpgrade;
extern NSString *DQAPIKeyStringUpgradeModalSetLastSeenVersion;
extern NSString *DQAPIKeyStringTwitterSync;
extern NSString *DQAPIKeyStringShowWebProfileModal;
extern NSString *DQAPIKeyStringSawShareWebProfileModal;
extern NSString *DQAPIKeyStringUpgradeType;
extern NSString *DQAPIKeyStringSocialMessage;
extern NSString *DQAPIKeyStringPublishToFacebook;
extern NSString *DQAPIKeyStringPublishToTwitter;
extern NSString *DQAPIKeyStringTwitterIDs;
extern NSString *DQAPIKeyStringShareURL;
extern NSString *DQAPIKeyCommentIDs;
extern NSString *DQAPIKeyStringMessage;
extern NSString *DQAPIKeyStringEmailHashList;
extern NSString *DQAPIKeyStringMigrationAvatarURL;

// API Value Strings
extern NSString *DQAPIValueActivityTypeFollow;
extern NSString *DQAPIValueActivityTypeFacebookFriendJoined;
extern NSString *DQAPIValueActivityTypeTwitterFriendJoined;
extern NSString *DQAPIValueActivityTypePlayback;
extern NSString *DQAPIValueActivityTypeStar;
extern NSString *DQAPIValueActivityTypeRemix;
extern NSString *DQAPIValueActivityTypePost;
extern NSString *DQAPIValueActivityTypeWelcome;
extern NSString *DQAPIValueActivityTypeStarred;
extern NSString *DQAPIValueActivityTypeFeaturedInExplore;
extern NSString *DQAPIValueActivityTypeNewColors;
extern NSString *DQAPIValueActivityTypeUGQ;
extern NSString *DQAPIValuePushNotificationTypeQuestOfTheDay;
extern NSString *DQAPIValuePushNotificationTypeStarred;
extern NSString *DQAPIValuePushNotificationTypeFacebookFriendJoined;
extern NSString *DQAPIValuePushNotificationTypeTwitterFriendJoined;
extern NSString *DQAPIValueShareChannelTypeFacebook;
extern NSString *DQAPIValueShareChannelTypeTumblr;
extern NSString *DQAPIValueShareChannelTypeEmail;
extern NSString *DQAPIValueShareChannelTypeTwitter;
extern NSString *DQAPIValueShareChannelTypeTextMessage;
extern NSString *DQAPIValueShareChannelTypeFlickr;
extern NSString *DQAPIValueShareChannelTypeInstagram;
extern NSString *DQAPIValueShareChannelTypeClipboard;
extern NSString *DQAPIValueRewardTypePersonalFacebookShare;
extern NSString *DQAPIValueRewardTypePersonalTwitterShare;
extern NSString *DQAPIValueRewardTypeQuestOfTheDay;
extern NSString *DQAPIValueRewardTypeArchivedQuest;
extern NSString *DQAPIValueRewardTypeSignup;
extern NSString *DQAPIValueRewardTypeStar;
extern NSString *DQAPIValueRewardTypeStreak3;
extern NSString *DQAPIValueRewardTypeStreak10;
extern NSString *DQAPIValueRewardTypeStreak100;
extern NSString *DQAPIValueShopColorsTab;
extern NSString *DQAPIValueShopCoinsTab;
extern NSString *DQAPIValueShopBrushesTab;
extern NSString *DQAPIValueBrushesPaintbrush;
extern NSString *DQAPIValueBrushesMarker;
extern NSString *DQAPIValueBrushesPencil;
extern NSString *DQAPIValueBrushesEraser;
extern NSString *DQAPIValueBrushesPaintbucket;
extern NSString *DQAPIValueBrushesCrayon;
extern NSString *DQAPIValueUpgradeTypeModal;
extern NSString *DQAPIValueUpgradeTypeAlert;

// API Response Error Type Values
extern NSString *DQAPIErrorTypeService;
extern NSString *DQAPIErrorTypeValidation;
extern NSString *DQAPIErrorTypeInvalidFacebookToken;
extern NSString *DQAPIErrorTypeInvalidTwitterToken;
extern NSString *DQAPIErrorTypeResponseTooLarge;

// Error Codes
extern NSString *DQAPIErrorDomain;
extern NSInteger DQAPIErrorCodeUnknown;
extern NSInteger DQAPIErrorCodeValidationFailure;
extern NSInteger DQAPIErrorInvalidFacebookTokenError;
extern NSInteger DQAPIErrorInvalidTwitterTokenError;
extern NSInteger DQAPIErrorCodeServiceError;
extern NSInteger DQAPIErrorCodeResponseTooLarge;
extern NSInteger DQAPIErrorCodeNoResponseDictionary;
extern NSInteger DQAPIErrorCodeEmptyResponseDictionary;

// Error User Info Keys
extern NSString *DQAPIErrorDictionaryKey;

// Activities
extern NSString *DQActivityItemTypeStringOther;

@interface NSDictionary (DQAPIConveniences)

// Meta Info
@property (nonatomic, readonly) BOOL dq_isOK;
@property (nonatomic, readonly) NSString *dq_errorType;
@property (nonatomic, readonly) NSDictionary *dq_errorDictionary;
@property (nonatomic, readonly) NSString *dq_errorReason;
@property (nonatomic, readonly) NSString *dq_errorMessage;
@property (nonatomic, readonly) NSDate *dq_timestamp;
@property (nonatomic, readonly) NSString *dq_serverID;
@property (nonatomic, readonly) NSDictionary *dq_content;

// Quest Info
@property (nonatomic, readonly) NSDictionary *dq_quest;
@property (nonatomic, readonly) NSArray *dq_quests;
@property (nonatomic, readonly) NSDictionary *dq_currentQuest;
@property (nonatomic, readonly) NSString *dq_questTitle;
@property (nonatomic, readonly) NSString *dq_questCommentsURL;
@property (nonatomic, readonly) NSNumber *dq_questDrawingCount;
@property (nonatomic, readonly) NSNumber *dq_questAuthorCount;
@property (nonatomic, readonly) BOOL dq_questCompletedByUser;
@property (nonatomic, readonly) NSString *dq_attributionCopy;
@property (nonatomic, readonly) NSString *dq_attributionUsername;
@property (nonatomic, readonly) NSString *dq_attributionAvatarURL;

// Comment Info
@property (nonatomic, readonly) NSArray *dq_comments;
@property (nonatomic, readonly) NSString *dq_commentQuestID;
@property (nonatomic, readonly) NSString *dq_commentQuestTitle;
@property (nonatomic, readonly) NSString *dq_commentAuthorID;
@property (nonatomic, readonly) NSString *dq_commentAuthorName;
@property (nonatomic, readonly) NSArray *dq_commentReactions;
@property (nonatomic, readonly) NSUInteger dq_numberOfStars;
@property (nonatomic, readonly) NSUInteger dq_numberOfPlaybacks;

// Activity Item Info
@property (nonatomic, readonly) NSArray *dq_activities;
@property (nonatomic, readonly) NSDictionary *dq_activityItemActorInfo;
@property (nonatomic, readonly) NSString *dq_activityItemThumbnailURL;
@property (nonatomic, readonly) NSString *dq_activityItemQuestID;
@property (nonatomic, readonly) NSString *dq_activityItemCommentID;

// Auth info
@property (nonatomic, readonly) BOOL dq_wasLoginRequest;

// User Info
@property (nonatomic, readonly) NSArray *dq_users;
@property (nonatomic, readonly) NSDictionary *dq_userInfo;
@property (nonatomic, readonly) NSString *dq_userID;
@property (nonatomic, readonly) NSInteger dq_commentCount;
@property (nonatomic, readonly) NSInteger dq_questCount;
@property (nonatomic, readonly) NSString *dq_userSessionID;
@property (nonatomic, readonly) NSString *dq_userName;
@property (nonatomic, readonly) NSString *dq_userBio;
@property (nonatomic, readonly) NSString *dq_userEmail;
@property (nonatomic, readonly) NSNumber *dq_userFollowerCount;
@property (nonatomic, readonly) NSNumber *dq_userFollowingCount;
@property (nonatomic, readonly) BOOL dq_userIsFollowing;
@property (nonatomic, readonly) NSString *dq_userQuestCompletionCount;
@property (nonatomic, readonly) NSString *dq_profileUserAvatarURL;
@property (nonatomic, readonly) NSString *dq_galleryUserAvatarURL;
@property (nonatomic, readonly) NSString *dq_userFacebookURL;
@property (nonatomic, readonly) NSString *dq_userTwitterURL;
@property (nonatomic, readonly) NSString *dq_userDrawQuestURL;
@property (nonatomic, readonly) NSString *dq_userTumblrURL;

@property (nonatomic, readonly) NSArray *dq_followingFollowersList;

// Realtime Sync
@property (nonatomic, readonly) NSDictionary *dq_realtimeSyncInfo;
@property (nonatomic, readonly) NSString *dq_realtimeUserEmail;
@property (nonatomic, readonly) NSNumber *dq_realtimeLastMessageID;
@property (nonatomic, readonly) NSArray *dq_realtimeCompletedQuestIDs;
@property (nonatomic, readonly) NSString *dq_realtimeTumblrSuccessRegexPattern;
@property (nonatomic, readonly) NSArray *dq_supportedLanguages;
@property (nonatomic, readonly) NSString *dq_localizationZipFileURL;
@property (nonatomic, readonly) NSString *dq_realtimeOnboardingQuestID;
@property (nonatomic, readonly) NSDictionary *dq_realtimePayload;

// What's new in DrawQuest Modal
@property (nonatomic, readonly) NSString *dq_versionOfAvailableUpgrade;
@property (nonatomic, readonly) NSString *dq_typeOfAvailableUpgrade;

// Coins
@property (nonatomic, readonly) NSString *dq_coinProductDescription;
@property (nonatomic, readonly) NSString *dq_coinProductAmount;
@property (nonatomic, readonly) NSString *dq_coinProductCost;
@property (nonatomic, readonly) NSNumber *dq_coinBalance;

// Shop
@property (nonatomic, readonly) NSString *dq_shopColorsHeader;
@property (nonatomic, readonly) NSString *dq_shopColorPacksHeader;
@property (nonatomic, readonly) NSArray *dq_shopColors;
@property (nonatomic, readonly) NSArray *dq_shopColorPacks;
@property (nonatomic, readonly) NSArray *dq_shopBrushes;
@property (nonatomic, readonly) NSArray *dq_shopTabs;
@property (nonatomic, readonly) NSString *dq_shopTabName;
@property (nonatomic, readonly) BOOL dq_shopTabIsDefault;
@property (nonatomic, readonly) NSString *dq_colorPackID;
@property (nonatomic, readonly) NSString *dq_colorPackName;
@property (nonatomic, readonly) NSString *dq_colorPackSaleText;
@property (nonatomic, readonly) NSNumber *dq_colorPackCost;
@property (nonatomic, readonly) NSArray *dq_colorPackColors;
@property (nonatomic, readonly) BOOL dq_colorPackIsNew;
@property (nonatomic, readonly) BOOL dq_colorPackIsPurchased;
@property (nonatomic, readonly) NSString *dq_colorID;
@property (nonatomic, readonly) NSString *dq_colorName;
@property (nonatomic, readonly) NSNumber *dq_colorCost;
@property (nonatomic, readonly) NSArray *dq_colorRGBInfo;
@property (nonatomic, readonly) BOOL dq_colorIsNew;
@property (nonatomic, readonly) BOOL dq_colorIsPurchased;
@property (nonatomic, readonly) NSString *dq_brushID;
@property (nonatomic, readonly) NSString *dq_brushName;
@property (nonatomic, readonly) NSString *dq_brushPhoneName;
@property (nonatomic, readonly) NSString *dq_brushCanonicalName;
@property (nonatomic, readonly) NSString *dq_brushDescription;
@property (nonatomic, readonly) NSArray *dq_brushColor;
@property (nonatomic, readonly) NSString *dq_brushIAPIdentifier;
@property (nonatomic, readonly) NSNumber *dq_brushCost;
@property (nonatomic, readonly) BOOL dq_brushIsNew;
@property (nonatomic, readonly) BOOL dq_brushIsPurchased;
@property (nonatomic, readonly) NSArray *dq_userColors;
@property (nonatomic, readonly) NSArray *dq_userBrushes;
@property (nonatomic, readonly) NSDictionary *dq_coinProductsInfo;
@property (nonatomic, readonly) NSDictionary *dq_brushProductsInfo;

//Editor Brushes
@property (nonatomic, readonly) NSArray *dq_globalBrushes;

// Image Info
@property (nonatomic, readonly) NSString *dq_imageURL;

// Page Info
@property (nonatomic, readonly) NSDictionary *dq_paginationPage;
@property (nonatomic, readonly) NSNumber *dq_paginationNextPage;
@property (nonatomic, readonly) NSString *dq_paginationNextPageString;
@property (nonatomic, readonly) NSNumber *dq_paginationPreviousPage;

// Explorer
@property (nonatomic, readonly) NSNumber *dq_exploreDisplaySize;

// Settings
@property (nonatomic, readonly) NSNumber *dq_commentViewTrackerUploadInterval;
@property (nonatomic, readonly) BOOL dq_webProfilePrivacy;
@property (nonatomic, readonly) BOOL dq_facebookPrivacy;
@property (nonatomic, readonly) BOOL dq_facebookPrivacyExplicitlySet;
@property (nonatomic, readonly) BOOL dq_twitterPrivacy;
@property (nonatomic, readonly) BOOL dq_twitterPrivacyExplicitlySet;
@property (nonatomic, readonly) BOOL dq_publishToFacebook;
@property (nonatomic, readonly) BOOL dq_publishToTwitter;
@property (nonatomic, readonly) BOOL dq_hasPublishToFacebook;
@property (nonatomic, readonly) BOOL dq_hasPublishToTwitter;

// Reminders
@property (nonatomic, readonly) NSDictionary *dq_reminders;
@property (nonatomic, readonly) NSInteger dq_inviteReminder;

// Auth Heavy State Sync
- (NSDictionary *)dq_authHeavyStateSync;

// Rewards Info
@property (nonatomic, readonly) NSDictionary *dq_rewardsInfo;
@property (nonatomic, readonly) NSDictionary *dq_rewardsCopy;
@property (nonatomic, readonly) NSDictionary *dq_rewardsPhoneCopy;
@property (nonatomic, readonly) NSDictionary *dq_rewardsAmounts;
@property (nonatomic, readonly) NSInteger dq_nextStreakDaysUntil;
@property (nonatomic, readonly) NSInteger dq_nextStreakGoal;

// Playback Data
@property (nonatomic, readonly) NSString *dq_playbackDataJSONString;

// Following Info
@property (nonatomic, readonly) BOOL dq_isFollowing;

// Sharing Info
@property (nonatomic, readonly) NSString *dq_sharingInviteURL;
@property (nonatomic, readonly) NSString *dq_sharingMessage;

// Twitter Sync (obfuscated consumer key and secret)
@property (nonatomic, readonly) NSString *dq_twitterSync;

// Web Profiles
@property (nonatomic, readonly) BOOL dq_showWebProfileModal;

// Logging Configuration
@property (nonatomic, readonly) NSDictionary *dq_loggingConfiguration;

// Feature Flags
@property (nonatomic, readonly) NSDictionary *dq_featureFlags;
@property (nonatomic, readonly) BOOL dq_featureInviteFromFacebook;
@property (nonatomic, readonly) BOOL dq_featureInviteFromTwitter;
@property (nonatomic, readonly) BOOL dq_featureUserSearch;
@property (nonatomic, readonly) BOOL dq_featureEnableUARegistration;
@property (nonatomic, readonly) BOOL dq_featureEnableUARegistrationBeforeAuth;

// Appirater
@property (nonatomic, readonly) NSString *dq_appiraterReviewURL;

// Colors
@property (nonatomic, readonly) NSInteger dq_colorAlertVersion;

// Sorting based on numeric substrings in keys
- (NSArray *)sortedKeysByNumericValues;
- (NSArray *)sortedArrayUsingNumericKeyValues;

// Activities
@property (nonatomic, readonly, assign) DQActivityItemType dq_reactionActivityType;
@property (nonatomic, readonly, assign) DQActivityItemType dq_activityItemActivityType;

// Follow and Star States
@property (nonatomic, readonly, strong) NSNumber *dq_viewerIsFollowing;
@property (nonatomic, readonly, strong) NSNumber *dq_viewerHasStarred;

@end
