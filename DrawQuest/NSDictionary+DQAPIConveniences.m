//
//  NSDictionary+DQAPIConveniences.m
//  DrawQuest
//
//  Created by Buzz Andersen on 9/14/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "NSDictionary+DQAPIConveniences.h"
#import "UIColor+DQAdditions.h"
#import "STUtils.h"

// API Keys
NSString *DQAPIKeyStringSuccess = @"success";
NSString *DQAPIKeyStringErrorType = @"error_type";
NSString *DQAPIKeyStringErrors = @"errors";
NSString *DQAPIKeyStringErrorReason = @"reason";
NSString *DQAPIKeyStringErrorMessage = @"message";
NSString *DQAPIKeyStringID = @"id";
NSString *DQAPIKeyStringMigrationTimestamp = @"migration_timestamp";
NSString *DQAPIKeyStringTimestamp = @"timestamp";
NSString *DQAPIKeyStringTimestampShort = @"ts";
NSString *DQAPIKeyStringContent = @"content";
NSString *DQAPIKeyStringQuests = @"quests";
NSString *DQAPIKeyStringQuest = @"quest";
NSString *DQAPIKeyStringComments = @"comments";
NSString *DQAPIKeyStringComment = @"comment";
NSString *DQAPIKeyStringActivites = @"activities";
NSString *DQAPIKeyStringUserID = @"user_id";
NSString *DQAPIKeyStringCommentCount = @"comment_count";
NSString *DQAPIKeyStringQuestCount = @"quest_count";
NSString *DQAPIKeyStringUserSessionID = @"sessionid";
NSString *DQAPIKeyStringUsername = @"username";
NSString *DQAPIKeyStringEmail = @"email";
NSString *DQAPIKeyStringUserEmail = @"user_email";
NSString *DQAPIKeyStringUserInfo = @"user";
NSString *DQAPIKeyStringUserFacebookURL = @"facebook_url";
NSString *DQAPIKeyStringUserTwitterURL = @"twitter_url";
NSString *DQAPIKeyStringUserDrawQuestURL = @"web_profile_url";
NSString *DQAPIKeyStringUserTumblrURL = @"tumblr_url";
NSString *DQAPIKeyUsers = @"users";
NSString *DQAPIKeyStringUserProfile = @"user_profile";
NSString *DQAPIKeyStringUserBio = @"bio";
NSString *DQAPIKeyStringUserFollowerCount = @"follower_count";
NSString *DQAPIKeyStringUserFollowingCount = @"following_count";
NSString *DQAPIKeyStringUserIsFollowing = @"viewer_is_following";
NSString *DQAPIKeyStringUserQuestCompletionCount = @"quest_completion_count";
NSString *DQAPIKeyStringPassword = @"password";
NSString *DQAPIKeyStringTitle = @"title";
NSString *DQAPIKeyStringQuestCommentsURL = @"comments_url";
NSString *DQAPIKeyStringQuestDrawingCount = @"drawing_count";
NSString *DQAPIKeyStringQuestAuthorCount = @"author_count";
NSString *DQAPIKeyQuestCompletedByUser = @"viewer_has_completed";
NSString *DQAPIKeyStringCommentQuestID = @"quest_id";
NSString *DQAPIKeyStringCommentQuestTitle = @"quest_title";
NSString *DQAPIKeyStringCommentAuthorID = @"author_id";
NSString *DQAPIKeyStringCommentAuthorName = @"author_name";
NSString *DQAPIKeyStringReactions = @"reactions";
NSString *DQAPIKeyStringNumberOfStars = @"star_count";
NSString *DQAPIKeyStringNumberOfPlaybacks = @"playback_count";
NSString *DQAPIKeyStringReactionType = @"reaction_type";
NSString *DQAPIKeyStringImageURL = @"url";
NSString *DQAPIKeyStringActivityItemActor = @"actor";
NSString *DQAPIKeyStringActivityItemThumbnailURL = @"thumbnail_url";
NSString *DQAPIKeyStringActivityItemQuestID = @"quest_id";
NSString *DQAPIKeyStringActivityItemCommentID = @"comment_id";
NSString *DQAPIKeyStringViewer = @"viewer";
NSString *DQAPIKeyStringNotificationType = @"notification_type";
NSString *DQAPIKeyStringShareChannel = @"channel";
NSString *DQAPIKeyStringFollowers = @"followers";
NSString *DQAPIKeyStringFollowing = @"following";
NSString *DQAPIKeyStringAvatarURLs = @"avatar_urls";
NSString *DQAPIKeyStringProfileAvatars = @"profile";
NSString *DQAPIKeyStringGalleryAvatars = @"gallery";
NSString *DQAPIKeyStringNonRetinaAvatarURL = @"1x";
NSString *DQAPIKeyStringMigrationAvatarURL = @"migration_avatar_url";
NSString *DQAPIKeyStringRetinaAvatarURL = @"2x";
NSString *DQAPIKeyStringCoinProducts = @"coin_products";
NSString *DQAPIKeyStringShopColorsHeader = @"colors_header";
NSString *DQAPIKeyStringShopColorPacksHeader = @"color_packs_header";
NSString *DQAPIKeyStringShopColors = @"shop_colors";
NSString *DQAPIKeyStringShopColorID = @"color_id";
NSString *DQAPIKeyStringShopColorPacks = @"color_packs";
NSString *DQAPIKeyStringShopBrushes = @"shop_brushes";
NSString *DQAPIKeyStringShopColorPackID = @"color_pack_id";
NSString *DQAPIKeyStringShopBrushID = @"brush_id";
NSString *DQAPIKeyStringShopBrushCanonicalName = @"brush_canonical_name";
NSString *DQAPIKeyStringShopTabs = @"tabs";
NSString *DQAPIKeyStringShopTabName = @"name";
NSString *DQAPIKeyStringShopTabDefault = @"default";
NSString *DQAPIKeyStringShopCoinProducts = @"coin_products";
NSString *DQAPIKeyStringShopBrushProducts = @"brush_products";
NSString *DQAPIKeyStringColorPackID = @"id";
NSString *DQAPIKeyStringColorPackCost = @"cost";
NSString *DQAPIKeyStringColorPackName = @"label";
NSString *DQAPIKeyStringColorPackSaleText = @"sale_text";
NSString *DQAPIKeyStringColorPackColors = @"colors";
NSString *DQAPIKeyStringColorPackIsNew = @"is_new";
NSString *DQAPIKeyStringColorPackIsPurchased = @"owned_by_viewer";
NSString *DQAPIKeyStringColorID = @"id";
NSString *DQAPIKeyStringColorName = @"label";
NSString *DQAPIKeyStringColorCost = @"cost";
NSString *DQAPIKeyStringColorRGBInfo = @"rgb";
NSString *DQAPIKeyStringColorIsNew = @"is_new";
NSString *DQAPIKeyStringColorIsPurchased = @"owned_by_viewer";
NSString *DQAPIKeyStringColorIsDefault = @"owned_by_default";
NSString *DQAPIKeyStringColorNeedsLightCheckmark = @"light_checkmark";
NSString *DQAPIKeyStringBrushID = @"id";
NSString *DQAPIKeyStringBrushName = @"label";
NSString *DQAPIKeyStringBrushPhoneName = @"iphone_label";
NSString *DQAPIKeyStringBrushCanonicalName = @"canonical_name";
NSString *DQAPIKeyStringBrushDescription = @"description";
NSString *DQAPIKeyStringBrushRGB = @"rgb";
NSString *DQAPIKeyStringBrushIAPIdentifier = @"iap_product_id";
NSString *DQAPIKeyStringBrushCost = @"cost";
NSString *DQAPIKeyStringBrushIsNew = @"is_new";
NSString *DQAPIKeyStringBrushIsPurchased = @"owned_by_viewer";
NSString *DQAPIKeyStringBrushIsDefault = @"owned_by_default";
NSString *DQAPIKeyStringUserColors = @"user_colors";
NSString *DQAPIKeyStringUserBrushes = @"user_brushes";
NSString *DQAPIKeyStringCoinProductDescription = @"description";
NSString *DQAPIKeyStringCoinProductAmount = @"amount";
NSString *DQAPIKeyStringCoinProductCost = @"cost";
NSString *DQAPIKeyStringCurrentQuest = @"current_quest";
NSString *DQAPIKeyStringRealtimeSync = @"realtime_sync";
NSString *DQAPIKeyStringRealtimeLastMessageID = @"last_message_id";
NSString *DQAPIKeyStringCoinBalance = @"balance";
NSString *DQAPIKeyStringRewardsInfo = @"rewards";
NSString *DQAPIKeyStringRewardsCopy = @"copy";
NSString *DQAPIKeyStringRewardsPhoneCopy = @"iphone_copy";
NSString *DQAPIKeyStringRewardsAmounts = @"amounts";
NSString *DQAPIKeyStringNextStreakDaysUntil = @"days_to_next_streak";
NSString *DQAPIKeyStringNextStreakGoal = @"next_streak_goal";
NSString *DQAPIKeyStringCompletedQuestIDs = @"completed_quest_ids";
NSString *DQAPIKeyStringInviteURL = @"invite_url";
NSString *DQAPIKeyTumblrSuccessRegexPattern = @"tumblr_success_regex";
NSString *DQAPIKeySupportedLanguages = @"supported_languages";
NSString *DQAPIKeyLocalizationZipFileURL = @"l10n_files_url";
NSString *DQAPIKeyStringOnboardingQuestID = @"onboarding_quest_id";
NSString *DQAPIKeyStringMetricName = @"name";
NSString *DQAPIKeyStringRealtimePayload = @"payload";
NSString *DQAPIKeyStringWasLoginRequest = @"login";
NSString *DQAPIKeyCommentViewTrackerUploadInterval = @"comment_view_logging_interval";
NSString *DQAPIKeyStringWebProfilePrivacy = @"web_profile_privacy";
NSString *DQAPIKeyStringFacebookPrivacy = @"facebook_privacy";
NSString *DQAPIKeyStringTwitterPrivacy = @"twitter_privacy";
NSString *DQAPIKeyStringPublishToFacebook = @"publish_to_facebook";
NSString *DQAPIKeyStringPublishToTwitter = @"publish_to_twitter";
NSString *DQAPIKeyStringAttributionCopy = @"attribution_copy";
NSString *DQAPIKeyStringAttributionUsername = @"attribution_username";
NSString *DQAPIKeyStringAttributionAvatarURLs = @"attribution_avatar_urls";
NSString *DQAPIKeyStringEmailHashList = @"email_hashes";
NSString *DQAPIKeyStringUserKV = @"user_kv";
NSString *DQAPIKeyStringGlobalBrushes = @"global_brushes";
NSString *DQAPIKeyAuthHeavyStateSync = @"heavy_state_sync";

NSString *DQAPIKeyStringQuestID = @"quest_id";
NSString *DQAPIKeyStringCommentID = @"comment_id";
NSString *DQAPIKeyStringContentID = @"content_id";
NSString *DQAPIKeyStringSinceTimestamp = @"earliest_timestamp_cutoff";
NSString *DQAPIKeyStringNewerThanDate = @"later_than";
NSString *DQAPIKeyStringOlderThanDate = @"earlier_than";
NSString *DQAPIKeyStringReceiptData = @"receipt_data";
NSString *DQAPIKeyStringFacebookToken = @"facebook_access_token";
NSString *DQAPIKeyStringFacebookShare = @"facebook_share";
NSString *DQAPIKeyStringTwitterShare = @"twitter_share";
NSString *DQAPIKeyStringTwitterToken = @"twitter_access_token";
NSString *DQAPIKeyStringTwitterSecret = @"twitter_access_token_secret";
NSString *DQAPIKeyStringEmailShare = @"email_share";
NSString *DQAPIKeyStringEmailShareList = @"email_recipients";
NSString *DQAPIKeyStringJSONPlaybackData = @"playback_data";
NSString *DQAPIKeyStringPropertyListPlaybackData = @"playback_plist_data";
NSString *DQAPIKeyStringTwitterIDs = @"twitter_ids";
NSString *DQAPIKeyStringColorAlertVersion = @"color_alert_version";
NSString *DQAPIKeyStringShareURL = @"share_url";
NSString *DQAPIKeyCommentIDs = @"comment_ids";
NSString *DQAPIKeyStringMessage = @"message";
NSString *DQAPIKeyStringReminders = @"reminders";
NSString *DQAPIKeyStringInviteReminder = @"invite";

// This key is used to store the twitter consumer key and secret obfuscated
NSString *DQAPIKeyStringTwitterSync = @"sync";

NSString *DQAPIKeyStringSocialMessage = @"message";

// Modals
NSString *DQAPIKeyStringModals = @"modals";
NSString *DQAPIKeyStringUpgradeModalSetLastSeenVersion = @"saw_update_modal_for_version";
NSString *DQAPIKeyStringVersionOfAvailableUpgrade = @"show_update_modal_for_version";
NSString *DQAPIKeyStringShowWebProfileModal = @"show_share_web_profile_modal";
NSString *DQAPIKeyStringSawShareWebProfileModal = @"saw_share_web_profile_modal";
NSString *DQAPIKeyStringUpgradeType = @"update_modal_type";

// Feature Flags
NSString *DQAPIKeyStringFeatureFlags = @"features";
NSString *DQAPIKeyStringFeatureInviteFromFacebook = @"invite_from_facebook";
NSString *DQAPIKeyStringFeatureInviteFromTwitter = @"invite_from_twitter";
NSString *DQAPIKeyStringFeatureUserSearch = @"user_search";
NSString *DQAPIKeyStringFeatureUARegistration = @"urban_airship_registration";
NSString *DQAPIKeyStringFeatureUARegistrationBeforeAuth = @"urban_airship_registration_before_auth";
NSString *DQAPIKeyStringFeatureLogging = @"logging";

// Appirater
NSString *DQAPIKeyStringAppiraterReviewURL = @"appirater_url";

// API Value Strings
NSString *DQAPIValueActivityTypeFollow = @"followed_by_user";
NSString *DQAPIValueActivityTypeFacebookFriendJoined = @"facebook_friend_joined";
NSString *DQAPIValueActivityTypeTwitterFriendJoined = @"twitter_friend_joined";
NSString *DQAPIValueActivityTypePlayback = @"playback";
NSString *DQAPIValueActivityTypeStar = @"star";
NSString *DQAPIValueActivityTypeRemix = @"remix";
NSString *DQAPIValueActivityTypePost = @"followee_posted";
NSString *DQAPIValueActivityTypeWelcome = @"welcome";
NSString *DQAPIValueActivityTypeNewQuestOfTheDay = @"quest_of_the_day";
NSString *DQAPIValueActivityTypeStarred = @"starred";
NSString *DQAPIValueActivityTypeFeaturedInExplore = @"featured_in_explore";
NSString *DQAPIValueActivityTypeNewColors = @"new_color_alert";
NSString *DQAPIValueActivityTypeUGQ = @"followee_created_ugq";
NSString *DQAPIValuePushNotificationTypeQuestOfTheDay = @"quest_of_the_day";
NSString *DQAPIValuePushNotificationTypeStarred = @"starred";
NSString *DQAPIValuePushNotificationTypeFacebookFriendJoined = @"facebook_friend_joined";
NSString *DQAPIValuePushNotificationTypeTwitterFriendJoined = @"twitter_friend_joined";
NSString *DQAPIValueShareChannelTypeFacebook = @"facebook";
NSString *DQAPIValueShareChannelTypeTumblr = @"tumblr";
NSString *DQAPIValueShareChannelTypeEmail = @"email";
NSString *DQAPIValueShareChannelTypeTwitter = @"twitter";
NSString *DQAPIValueShareChannelTypeTextMessage = @"text_message";
NSString *DQAPIValueShareChannelTypeFlickr = @"flickr";
NSString *DQAPIValueShareChannelTypeInstagram = @"instagram";
NSString *DQAPIValueShareChannelTypeClipboard = @"clipboard";
NSString *DQAPIValueRewardTypePersonalFacebookShare = @"personal_share";
NSString *DQAPIValueRewardTypePersonalTwitterShare = @"personal_twitter_share";
NSString *DQAPIValueRewardTypeQuestOfTheDay = @"quest_of_the_day";
NSString *DQAPIValueRewardTypeArchivedQuest = @"archived_quest";
NSString *DQAPIValueRewardTypeSignup = @"first_quest";
NSString *DQAPIValueRewardTypeStar = @"star";
NSString *DQAPIValueRewardTypeStreak3 = @"streak_3";
NSString *DQAPIValueRewardTypeStreak10 = @"streak_10";
NSString *DQAPIValueRewardTypeStreak100 = @"streak_100";
NSString *DQAPIValueUpgradeTypeModal = @"modal";
NSString *DQAPIValueUpgradeTypeAlert = @"alert";

NSString *DQAPIKeyStringIsFollowing = @"is_following";
NSString *DQAPIKeyStringPage = @"pagination";
NSString *DQAPIKeyStringNextPage = @"next";
NSString *DQAPIKeyStringPreviousPage = @"previous";
NSString *DQAPIKeyStringDisplaySize = @"display_size";
NSString *DQAPIValueShopColorsTab = @"colors";
NSString *DQAPIValueShopCoinsTab = @"coins";
NSString *DQAPIValueShopBrushesTab = @"brushes";
NSString *DQAPIValueBrushesPaintbrush = @"paintbrush";
NSString *DQAPIValueBrushesMarker = @"marker";
NSString *DQAPIValueBrushesPencil = @"pencil";
NSString *DQAPIValueBrushesEraser = @"eraser";
NSString *DQAPIValueBrushesPaintbucket = @"paintbucket";
NSString *DQAPIValueBrushesCrayon = @"crayon";

// API Response Error Type Values
NSString *DQAPIErrorTypeService = @"ServiceError";
NSString *DQAPIErrorTypeValidation = @"ValidationError";
NSString *DQAPIErrorTypeInvalidFacebookToken = @"InvalidFacebookAccessToken";
NSString *DQAPIErrorTypeInvalidTwitterToken = @"InvalidTwitterAccessToken";
NSString *DQAPIErrorTypeResponseTooLarge = @"ResponseTooLarge";

// Error Constants
NSString *DQAPIErrorDomain = @"DQErrorDomain";
NSInteger DQAPIErrorCodeUnknown = 1000;
NSInteger DQAPIErrorCodeValidationFailure = 1001;
NSInteger DQAPIErrorCodeServiceError = 1002;
NSInteger DQAPIErrorInvalidFacebookTokenError = 1003;
NSInteger DQAPIErrorInvalidTwitterTokenError = 1004;
NSInteger DQAPIErrorCodeResponseTooLarge = 1005;
NSInteger DQAPIErrorCodeNoResponseDictionary = 1006;
NSInteger DQAPIErrorCodeEmptyResponseDictionary = 1007;

// Error User Info Keys
NSString *DQAPIErrorDictionaryKey = @"ErrorDictionary";

// Activities (ViewerIsFollowing is for Explore as well)
NSString *DQAPIKeyStringActivityItemType = @"type";
NSString *DQAPIKeyStringViewerIsFollowing = @"viewer_is_following";
NSString *DQAPIKeyStringViewerHasStarred = @"viewer_has_starred";
NSString *DQActivityItemTypeStringOther = @"other";

@implementation NSDictionary (DQAPIConveniences)

#pragma mark Meta Info

- (BOOL)dq_isOK
{
    return [self boolForKey:DQAPIKeyStringSuccess];
}

- (NSString *)dq_errorType
{
    return [self stringForKey:DQAPIKeyStringErrorType];
}

- (NSDictionary *)dq_errorDictionary
{
    return [self dictionaryForKey:DQAPIKeyStringErrors];
}

- (NSString *)dq_errorReason
{
    return [self stringForKey:DQAPIKeyStringErrorReason];
}

- (NSString *)dq_errorMessage
{
    return [self stringForKey:DQAPIKeyStringErrorMessage];
}

- (NSDate *)dq_timestamp
{
    // to support quest migration from Core Data
    id timestamp = [self safeObjectForKey:DQAPIKeyStringMigrationTimestamp];
    if (timestamp)
    {
        return timestamp;
    }

    NSString *longKeyTimestampString = [self stringForKey:DQAPIKeyStringTimestamp];
    NSString *shortKeyTimestampString = [self stringForKey:DQAPIKeyStringTimestampShort];
    
    if (!longKeyTimestampString.length && !shortKeyTimestampString.length) {
        return nil;
    }
    
    return longKeyTimestampString ? [longKeyTimestampString dateValueWithTimeIntervalSince1970] : [shortKeyTimestampString dateValueWithTimeIntervalSince1970];
}

- (NSString *)dq_serverID
{
    return [self stringForKey:DQAPIKeyStringID];
}

- (NSDictionary *)dq_content
{
    return [self dictionaryForKey:DQAPIKeyStringContent];
}

#pragma mark Quest Info

- (NSDictionary *)dq_quest
{
    return [self dictionaryForKey:DQAPIKeyStringQuest];
}

- (NSArray *)dq_quests
{
    NSArray *quests = [self arrayForKey:DQAPIKeyStringQuests];
    if (quests.count) {
        return quests;
    }
    
    NSDictionary *quest = [self dictionaryForKey:DQAPIKeyStringQuest];
    if (quest) {
        return [NSArray arrayWithObject:quest];
    }
    
    return nil;
}

- (NSDictionary *)dq_currentQuest
{
    return [self dictionaryForKey:DQAPIKeyStringCurrentQuest];
}

- (NSString *)dq_questTitle
{
    return [self stringForKey:DQAPIKeyStringTitle];
}

- (NSString *)dq_questCommentsURL
{
    return [self stringForKey:DQAPIKeyStringQuestCommentsURL];
}

- (NSNumber *)dq_questDrawingCount
{
    return [self numberForKey:DQAPIKeyStringQuestDrawingCount];
}

- (NSNumber *)dq_questAuthorCount
{
    return [self numberForKey:DQAPIKeyStringQuestAuthorCount];
}

- (BOOL)dq_questCompletedByUser
{
    return [self boolForKey:DQAPIKeyQuestCompletedByUser];
}

- (NSString *)dq_attributionCopy
{
    return [self stringForKey:DQAPIKeyStringAttributionCopy];
}

- (NSString *)dq_attributionUsername
{
    return [self stringForKey:DQAPIKeyStringAttributionUsername];
}

- (NSDictionary *)dq_attributionAvatarURLs
{
    return [self objectForKey:DQAPIKeyStringAttributionAvatarURLs];
}

- (NSString *)dq_nonRetinaAttributionAvatarURL
{
    return [self.dq_attributionAvatarURLs stringForKey:DQAPIKeyStringNonRetinaAvatarURL];
}

- (NSString *)dq_retinaAttributionAvatarURL
{
    return [self.dq_attributionAvatarURLs stringForKey:DQAPIKeyStringRetinaAvatarURL];
}

- (NSString *)dq_attributionAvatarURL
{
    // support quest migration
    id migration = [self safeObjectForKey:DQAPIKeyStringMigrationAvatarURL];
    if (migration)
    {
        return migration;
    }

    if ([[UIScreen mainScreen] scale] > 1.0)
    {
        return self.dq_retinaAttributionAvatarURL;
    }
    else
    {
        return self.dq_nonRetinaAttributionAvatarURL;
    }
}

#pragma mark Comment Info

- (NSArray *)dq_comments
{
    NSArray *comments = [self arrayForKey:DQAPIKeyStringComments];
    if (comments.count) {
        return comments;
    }
    
    NSDictionary *comment = [self dictionaryForKey:DQAPIKeyStringComment];
    if (comment) {
        return [NSArray arrayWithObject:comment];
    }
    
    return nil;
}

- (NSString *)dq_commentQuestID
{
    return [self stringForKey:DQAPIKeyStringCommentQuestID];
}

- (NSString *)dq_commentQuestTitle
{
    return [self stringForKey:DQAPIKeyStringCommentQuestTitle];
}

- (NSString *)dq_commentAuthorID
{
    return [self.dq_userInfo stringForKey:DQAPIKeyStringID];
}

- (NSString *)dq_commentAuthorName
{
    return [self.dq_userInfo stringForKey:DQAPIKeyStringCommentAuthorName];
}

- (NSArray *)dq_commentReactions
{
    return [self arrayForKey:DQAPIKeyStringReactions];
}

- (NSUInteger)dq_numberOfStars
{
    return [[self numberForKey:DQAPIKeyStringNumberOfStars] unsignedIntegerValue];
}

- (NSUInteger)dq_numberOfPlaybacks
{
    return [[self numberForKey:DQAPIKeyStringNumberOfPlaybacks] unsignedIntegerValue];
}

#pragma mark Activity Item Info

- (NSArray *)dq_activities
{
    return [self arrayForKey:DQAPIKeyStringActivites];
}

- (NSString *)dq_commentActivityItemUsername
{
    return [self stringForKey:DQAPIKeyStringUsername];
}

- (NSDictionary *)dq_activityItemActorInfo
{
    return [self dictionaryForKey:DQAPIKeyStringActivityItemActor];
}

- (NSString *)dq_activityItemThumbnailURL
{
    return [self stringForKey:DQAPIKeyStringActivityItemThumbnailURL];
}

- (NSString *)dq_activityItemQuestID
{
    return [self stringForKey:DQAPIKeyStringActivityItemQuestID];
}

- (NSString *)dq_activityItemCommentID
{
    return [self stringForKey:DQAPIKeyStringActivityItemCommentID];
}

#pragma mark Auth info

- (BOOL)dq_wasLoginRequest
{
    return [self boolForKey:DQAPIKeyStringWasLoginRequest];
}

#pragma mark User Info

- (NSArray *)dq_users
{
    NSArray *users = [self arrayForKey:DQAPIKeyUsers];
    return users;
}

- (NSDictionary *)dq_userInfo
{
    NSDictionary *userInfo = [self dictionaryForKey:DQAPIKeyStringUserInfo];
    if (userInfo) {
        return userInfo;
    }
    
    return [self dictionaryForKey:DQAPIKeyStringUserProfile];
}

- (NSString *)dq_userID
{
    NSString *userID = [self stringForKey:DQAPIKeyStringUserID];
    
    return userID ? userID : [self stringForKey:DQAPIKeyStringID];
}

- (NSInteger)dq_commentCount
{
    return [self integerForKey:DQAPIKeyStringCommentCount];
}

- (NSInteger)dq_questCount
{
    return [self integerForKey:DQAPIKeyStringQuestCount];
}

- (NSString *)dq_userSessionID
{
    return [self stringForKey:DQAPIKeyStringUserSessionID];
}

- (NSString *)dq_userName
{
    return [self stringForKey:DQAPIKeyStringUsername];
}

- (NSString *)dq_userEmail
{
    return [self stringForKey:DQAPIKeyStringEmail];
}

- (NSString *)dq_userBio
{
    return [self stringForKey:DQAPIKeyStringUserBio];
}

- (NSNumber *)dq_userFollowerCount
{
    return @([self integerForKey:DQAPIKeyStringUserFollowerCount]);
}

- (NSNumber *)dq_userFollowingCount
{
    return @([self integerForKey:DQAPIKeyStringUserFollowingCount]);
}

- (BOOL)dq_userIsFollowing
{
    return [self boolForKey:DQAPIKeyStringUserIsFollowing];
}

- (NSString *)dq_userQuestCompletionCount
{
    return [self stringForKey:DQAPIKeyStringUserQuestCompletionCount];
}

- (NSDictionary *)dq_userAvatarURLs
{
    return [self objectForKey:DQAPIKeyStringAvatarURLs];
}

- (NSDictionary *)dq_profileUserAvatarURLs
{
    return [self.dq_userAvatarURLs objectForKey:DQAPIKeyStringProfileAvatars];
}

- (NSDictionary *)dq_galleryUserAvatarURLs
{
    return [self.dq_userAvatarURLs objectForKey:DQAPIKeyStringGalleryAvatars];
}

- (NSString *)dq_nonRetinaProfileUserAvatarURL
{
    return [self.dq_profileUserAvatarURLs stringForKey:DQAPIKeyStringNonRetinaAvatarURL];
}

- (NSString *)dq_retinaProfileUserAvatarURL
{
    return [self.dq_profileUserAvatarURLs stringForKey:DQAPIKeyStringRetinaAvatarURL];
}

- (NSString *)dq_nonRetinaGalleryUserAvatarURL
{
    return [self.dq_galleryUserAvatarURLs stringForKey:DQAPIKeyStringNonRetinaAvatarURL];
}

- (NSString *)dq_retinaGalleryUserAvatarURL
{
    return [self.dq_galleryUserAvatarURLs stringForKey:DQAPIKeyStringRetinaAvatarURL];
}

- (NSString *)dq_profileUserAvatarURL
{
    if ([[UIScreen mainScreen] scale] > 1.0)
    {
        return self.dq_retinaProfileUserAvatarURL;
    }
    else
    {
        return self.dq_nonRetinaProfileUserAvatarURL;
    }
}

- (NSString *)dq_galleryUserAvatarURL
{
    // support quest migration
    id migration = [self safeObjectForKey:DQAPIKeyStringMigrationAvatarURL];
    if (migration)
    {
        return migration;
    }

    if ([[UIScreen mainScreen] scale] > 1.0)
    {
        return self.dq_retinaGalleryUserAvatarURL;
    }
    else
    {
        return self.dq_nonRetinaGalleryUserAvatarURL;
    }
}

- (NSString *)dq_userFacebookURL
{
    return [self objectForKey:DQAPIKeyStringUserFacebookURL];
}

- (NSString *)dq_userTwitterURL
{
    return [self objectForKey:DQAPIKeyStringUserTwitterURL];
}

- (NSString *)dq_userDrawQuestURL
{
    return [self objectForKey:DQAPIKeyStringUserDrawQuestURL];
}

- (NSString *)dq_userTumblrURL
{
    return [self objectForKey:DQAPIKeyStringUserTumblrURL];
}

- (NSArray *)dq_followingFollowersList
{
    NSArray *followersList = [self arrayForKey:DQAPIKeyStringFollowers];
    if (followersList) {
        return followersList;
    }
    
    return [self arrayForKey:DQAPIKeyStringFollowing];
}

#pragma mark Realtime Sync Info

- (NSDictionary *)dq_realtimeSyncInfo
{
    return [self dictionaryForKey:DQAPIKeyStringRealtimeSync];
}

- (NSString *)dq_realtimeUserEmail
{
    return [self stringForKey:DQAPIKeyStringUserEmail];
}

- (NSNumber *)dq_realtimeLastMessageID
{
    return [self numberForKey:DQAPIKeyStringRealtimeLastMessageID];
}

- (NSArray *)dq_realtimeCompletedQuestIDs
{
    return [self arrayForKey:DQAPIKeyStringCompletedQuestIDs];
}

- (NSString *)dq_realtimeTumblrSuccessRegexPattern
{
    return [self stringForKey:DQAPIKeyTumblrSuccessRegexPattern];
}

- (NSArray *)dq_supportedLanguages
{
    return [self arrayForKey:DQAPIKeySupportedLanguages];
}

- (NSString *)dq_localizationZipFileURL
{
    return [self stringForKey:DQAPIKeyLocalizationZipFileURL];
}

- (NSString *)dq_realtimeOnboardingQuestID
{
    return [self stringForKey:DQAPIKeyStringOnboardingQuestID];
}

- (NSDictionary *)dq_realtimePayload
{
    return [self dictionaryForKey:DQAPIKeyStringRealtimePayload];
}

#pragma mark What's new in DrawQuest Modal

- (NSString *)dq_versionOfAvailableUpgrade
{
    return [[self dictionaryForKey:DQAPIKeyStringModals] stringForKey:DQAPIKeyStringVersionOfAvailableUpgrade];
}

- (NSString *)dq_typeOfAvailableUpgrade
{
    return [[self dictionaryForKey:DQAPIKeyStringModals] stringForKey:DQAPIKeyStringUpgradeType];
}

#pragma mark Coin Product Info

- (NSDictionary *)dq_coinProductsInfo
{
    return [self dictionaryForKey:DQAPIKeyStringShopCoinProducts];
}

- (NSDictionary *)dq_brushProductsInfo
{
    return [self dictionaryForKey:DQAPIKeyStringShopBrushProducts];
}

- (NSString *)dq_coinProductDescription
{
    return [self stringForKey:DQAPIKeyStringCoinProductDescription];
}

- (NSString *)dq_coinProductAmount
{
    return [self stringForKey:DQAPIKeyStringCoinProductAmount];
}

- (NSString *)dq_coinProductCost
{
    return [self stringForKey:DQAPIKeyStringCoinProductCost];
}

- (NSNumber *)dq_coinBalance
{
    return [self numberForKey:DQAPIKeyStringCoinBalance];
}

#pragma mark Editor Brushes

- (NSArray *)dq_globalBrushes
{
    return [self arrayForKey:DQAPIKeyStringGlobalBrushes];
}

#pragma mark Shop Info

- (NSString *)dq_shopColorsHeader
{
    return [self stringForKey:DQAPIKeyStringShopColorsHeader];
}

- (NSString *)dq_shopColorPacksHeader
{
    return [self stringForKey:DQAPIKeyStringShopColorPacksHeader];
}

- (NSArray *)dq_shopColors
{
    return [self arrayForKey:DQAPIKeyStringShopColors];
}

- (NSArray *)dq_shopColorPacks
{
    return [self arrayForKey:DQAPIKeyStringShopColorPacks];
}

- (NSArray *)dq_shopBrushes
{
    return [self arrayForKey:DQAPIKeyStringShopBrushes];
}

- (NSArray *)dq_shopTabs
{
    return [self arrayForKey:DQAPIKeyStringShopTabs];
}

- (NSString *)dq_shopTabName
{
    return [self stringForKey:DQAPIKeyStringShopTabName];
}

- (BOOL)dq_shopTabIsDefault
{
    return [self boolForKey:DQAPIKeyStringShopTabDefault];
}

- (NSString *)dq_colorPackID
{
    return [self stringForKey:DQAPIKeyStringColorPackID];
}

- (NSString *)dq_colorPackName
{
    return [self stringForKey:DQAPIKeyStringColorPackName];
}

- (NSString *)dq_colorPackSaleText
{
    return [self stringForKey:DQAPIKeyStringColorPackSaleText];
}

- (NSNumber *)dq_colorPackCost
{
    return [self numberForKey:DQAPIKeyStringColorPackCost];
}

- (NSArray *)dq_colorPackColors
{
    return [self arrayForKey:DQAPIKeyStringColorPackColors];
}

- (BOOL)dq_colorPackIsNew
{
    return [self boolForKey:DQAPIKeyStringColorPackIsNew];
}

- (BOOL)dq_colorPackIsPurchased
{
    return [self boolForKey:DQAPIKeyStringColorPackIsPurchased];
}

- (NSString *)dq_colorID
{
    return [self stringForKey:DQAPIKeyStringColorID];
}

- (NSString *)dq_colorName
{
    return [self stringForKey:DQAPIKeyStringColorName];
}

- (NSNumber *)dq_colorCost
{
    return [self numberForKey:DQAPIKeyStringColorCost];
}

- (NSArray *)dq_colorRGBInfo
{
    return [self arrayForKey:DQAPIKeyStringColorRGBInfo];
}

- (BOOL)dq_colorIsNew
{
    return [self boolForKey:DQAPIKeyStringColorIsNew];
}

- (BOOL)dq_colorIsPurchased
{
    return [self boolForKey:DQAPIKeyStringColorIsPurchased] || [self boolForKey:DQAPIKeyStringColorIsDefault];
}

- (NSString *)dq_brushID
{
    return [self stringForKey:DQAPIKeyStringBrushID];
}

- (NSString *)dq_brushName
{
    return [self stringForKey:DQAPIKeyStringBrushName];
}

- (NSString *)dq_brushPhoneName
{
    return [self stringForKey:DQAPIKeyStringBrushPhoneName];
}

- (NSString *)dq_brushCanonicalName
{
    return [self stringForKey:DQAPIKeyStringBrushCanonicalName];
}

- (NSString *)dq_brushDescription
{
    return [self stringForKey:DQAPIKeyStringBrushDescription];
}

- (NSArray *)dq_brushColor
{
    return [self arrayForKey:DQAPIKeyStringBrushRGB];
}

- (NSString *)dq_brushIAPIdentifier
{
    return [self stringForKey:DQAPIKeyStringBrushIAPIdentifier];
}

- (NSNumber *)dq_brushCost
{
    return [self numberForKey:DQAPIKeyStringBrushCost];
}

- (BOOL)dq_brushIsNew
{
    return [self boolForKey:DQAPIKeyStringBrushIsNew];
}

- (BOOL)dq_brushIsPurchased
{
    return [self boolForKey:DQAPIKeyStringBrushIsPurchased] || [self boolForKey:DQAPIKeyStringBrushIsDefault];
}

- (NSArray *)dq_userColors
{
    return [self arrayForKey:DQAPIKeyStringUserColors];
}

- (NSArray *)dq_userBrushes
{
    return [self arrayForKey:DQAPIKeyStringUserBrushes];
}

#pragma mark Image Info

- (NSString *)dq_imageURL
{
    return [self stringForKey:DQAPIKeyStringImageURL];
}
#pragma mark Rewards Info

- (NSDictionary *)dq_rewardsInfo
{
    return [self dictionaryForKey:DQAPIKeyStringRewardsInfo];
}

- (NSDictionary *)dq_rewardsCopy
{
    return [self dictionaryForKey:DQAPIKeyStringRewardsCopy];
}

- (NSDictionary *)dq_rewardsPhoneCopy
{
    return [self dictionaryForKey:DQAPIKeyStringRewardsPhoneCopy];
}

- (NSDictionary *)dq_rewardsAmounts
{
    return [self dictionaryForKey:DQAPIKeyStringRewardsAmounts];
}

- (NSInteger)dq_nextStreakDaysUntil
{
    return [self integerForKey:DQAPIKeyStringNextStreakDaysUntil];
}

- (NSInteger)dq_nextStreakGoal
{
    return [self integerForKey:DQAPIKeyStringNextStreakGoal];
}

#pragma mark Playback Data

- (NSString *)dq_playbackDataJSONString
{
    return [self stringForKey:DQAPIKeyStringJSONPlaybackData];
}

#pragma mark Following Info

- (BOOL)dq_isFollowing
{
    return [self boolForKey:DQAPIKeyStringIsFollowing];
}

#pragma mark Sharing

- (NSString *)dq_sharingInviteURL
{
    return [self stringForKey:DQAPIKeyStringInviteURL];
}

- (NSString *)dq_sharingMessage
{
    return [self stringForKey:DQAPIKeyStringMessage];
}

#pragma mark Pagination

- (NSDictionary *)dq_paginationPage
{
    return [self safeObjectForKey:DQAPIKeyStringPage];
}

- (NSNumber *)dq_paginationNextPage
{
    return [self safeObjectForKey:DQAPIKeyStringNextPage];
}

- (NSString *)dq_paginationNextPageString
{
    return [self safeObjectForKey:DQAPIKeyStringNextPage];
}

- (NSNumber *)dq_paginationPreviousPage
{
    return [self safeObjectForKey:DQAPIKeyStringPreviousPage];
}

#pragma mark Explorer

- (NSNumber *)dq_exploreDisplaySize
{
    return [self safeObjectForKey:DQAPIKeyStringDisplaySize];
}

#pragma mark Settings

- (NSNumber *)dq_commentViewTrackerUploadInterval
{
    return [self numberForKey:DQAPIKeyCommentViewTrackerUploadInterval];
}

- (BOOL)dq_webProfilePrivacy
{
    return [self boolForKey:DQAPIKeyStringWebProfilePrivacy];
}

- (BOOL)dq_facebookPrivacy
{
    return [self boolForKey:DQAPIKeyStringFacebookPrivacy];
}

- (BOOL)dq_facebookPrivacyExplicitlySet
{
    return [self objectForKey:DQAPIKeyStringFacebookPrivacy] != [NSNull null] && [self objectForKey:DQAPIKeyStringFacebookPrivacy] != nil;
}

- (BOOL)dq_twitterPrivacy
{
    return [self boolForKey:DQAPIKeyStringTwitterPrivacy];
}

- (BOOL)dq_twitterPrivacyExplicitlySet
{
    return [self objectForKey:DQAPIKeyStringTwitterPrivacy] != [NSNull null] && [self objectForKey:DQAPIKeyStringTwitterPrivacy] != nil;
}

- (BOOL)dq_hasPublishToFacebook
{
    return nil != [[self valueForKey:DQAPIKeyStringUserKV] objectForKey:DQAPIKeyStringPublishToFacebook];
}

- (BOOL)dq_publishToFacebook
{
    return [[self valueForKey:DQAPIKeyStringUserKV] boolForKey:DQAPIKeyStringPublishToFacebook];
}

- (BOOL)dq_hasPublishToTwitter
{
    return nil != [[self valueForKey:DQAPIKeyStringUserKV] objectForKey:DQAPIKeyStringPublishToTwitter];
}

- (BOOL)dq_publishToTwitter
{
    return [[self valueForKey:DQAPIKeyStringUserKV] boolForKey:DQAPIKeyStringPublishToTwitter];
}

#pragma mark Reminders

- (NSDictionary *)dq_reminders
{
    return [self dictionaryForKey:DQAPIKeyStringReminders];
}

- (NSInteger)dq_inviteReminder
{
    return [self integerForKey:DQAPIKeyStringInviteReminder];
}

#pragma mark Auth Heavy State Sync

- (NSDictionary *)dq_authHeavyStateSync
{
    return [self dictionaryForKey:DQAPIKeyAuthHeavyStateSync];
}

#pragma mark Twitter Sync

- (NSString *)dq_twitterSync
{
    return [self stringForKey:DQAPIKeyStringTwitterSync];
}

#pragma mark Web profiles

- (BOOL)dq_showWebProfileModal
{
    return [[self dictionaryForKey:DQAPIKeyStringModals] boolForKey:DQAPIKeyStringShowWebProfileModal];
}

#pragma mark Logging Configuration

- (NSDictionary *)dq_loggingConfiguration
{
    return [self dictionaryForKey:DQAPIKeyStringFeatureLogging];
}

#pragma mark Feature Flags

- (NSDictionary *)dq_featureFlags
{
    return [self dictionaryForKey:DQAPIKeyStringFeatureFlags];
}

- (BOOL)dq_featureInviteFromFacebook
{
    return [self.dq_featureFlags boolForKey:DQAPIKeyStringFeatureInviteFromFacebook];
}

- (BOOL)dq_featureInviteFromTwitter
{
    return [self.dq_featureFlags boolForKey:DQAPIKeyStringFeatureInviteFromTwitter];
}

- (BOOL)dq_featureUserSearch
{
    return [self.dq_featureFlags boolForKey:DQAPIKeyStringFeatureUserSearch];
}

- (BOOL)dq_featureEnableUARegistration
{
    id o = [self.dq_featureFlags safeObjectForKey:DQAPIKeyStringFeatureUARegistration];
    return (!o) || [o boolValue];
}

- (BOOL)dq_featureEnableUARegistrationBeforeAuth
{
    id o = [self.dq_featureFlags safeObjectForKey:DQAPIKeyStringFeatureUARegistrationBeforeAuth];
    return (!o) || [o boolValue];
}

#pragma mark - Appirater

- (NSString *)dq_appiraterReviewURL
{
    return [self stringForKey:DQAPIKeyStringAppiraterReviewURL];
}

#pragma mark - Colors

- (NSInteger)dq_colorAlertVersion
{
    return [self integerForKey:DQAPIKeyStringColorAlertVersion];
}

#pragma mark Sorting methods for in app purchases

- (NSArray *)sortedKeysByNumericValues;
{
    return [[self allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger n1 = [[[(NSString*)obj1 componentsSeparatedByString:@"."] lastObject] integerValue];
        NSInteger n2 = [[[(NSString*)obj2 componentsSeparatedByString:@"."] lastObject] integerValue];
        
        return n1 > n2;
    }];
}

- (NSArray *)sortedArrayUsingNumericKeyValues;
{
	NSArray *sortedKeys = [self sortedKeysByNumericValues];
	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	id currentKey;
	
	for (currentKey in sortedKeys) {
		[returnArray addObject:[self objectForKey:currentKey]];
	}
	
	return returnArray;
}

#pragma mark - Activities

#pragma mark Reaction Info

- (DQActivityItemType)dq_reactionActivityType
{
    DQActivityItemType type = DQActivityItemTypeOther;

    NSString *reactionString = [self stringForKey:DQAPIKeyStringReactionType];
    if ([reactionString isEqualToString:DQAPIValueActivityTypePlayback])
    {
        type = DQActivityItemTypePlayback;
    }
    else if ([reactionString isEqualToString:DQAPIValueActivityTypeStar] || [reactionString isEqualToString:DQAPIValueActivityTypeStarred])
    {
        type = DQActivityItemTypeStar;
    }

    return type;
}

#pragma mark Follow and Star States

- (NSNumber *)dq_viewerIsFollowing
{
    return [self numberForKey:DQAPIKeyStringViewerIsFollowing];
}

- (NSNumber *)dq_viewerHasStarred
{
    return [self numberForKey:DQAPIKeyStringViewerHasStarred];
}

- (DQActivityItemType)dq_activityItemActivityType
{
    NSString *activityTypeString = [self stringForKey:DQAPIKeyStringActivityItemType];
    if ([activityTypeString length])
    {
        if ([activityTypeString isEqualToString:DQAPIValueActivityTypeFollow])
        {
            return DQActivityItemTypeFollow;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeFeaturedInExplore])
        {
            return DQActivityItemTypeFeaturedInExplore;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeFacebookFriendJoined])
        {
            return DQActivityItemTypeFacebookFriendJoined;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeTwitterFriendJoined])
        {
            return DQActivityItemTypeTwitterFriendJoined;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeStar] || [activityTypeString isEqualToString:DQAPIValueActivityTypeStarred])
        {
            return DQActivityItemTypeStar;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypePlayback])
        {
            return DQActivityItemTypePlayback;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeRemix])
        {
            return DQActivityItemTypeRemix;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypePost])
        {
            return DQActivityItemTypePost;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeWelcome])
        {
            return DQActivityItemTypeWelcome;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeNewColors])
        {
            return DQActivityItemTypeNewColors;
        }
        else if ([activityTypeString isEqualToString:DQAPIValueActivityTypeUGQ])
        {
            return DQActivityItemTypeUGQ;
        }
    }
    return DQActivityItemTypeUnknown;
}

@end
