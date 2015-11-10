//
//  UIFont+DQAdditions.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/10/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "UIFont+DQAdditions.h"
#import "STUtils.h"


@implementation UIFont (DQAdditions)

STCachedFont(dq_activityItemUserNameFont, @"ArialRoundedMTBold", 13);
STCachedFont(dq_activityItemActivityTypeFont, @"ArialRoundedMTBold", 13);
STCachedFont(dq_galleryFooterUsernameFont, @"ArialRoundedMTBold", 20);
STCachedFont(dq_galleryFooterStatsFont, @"ArialRoundedMTBold", 18);
STCachedFont(dq_basementNavigationFont, @"ArialRoundedMTBold", 19);
STCachedFont(dq_basementProfileLabelsFont, @"ArialRoundedMTBold", 18);
STCachedFont(dq_activityTimestampFont, @"ArialRoundedMTBold", 10);
STCachedFont(dq_titleBarFont, @"ArialRoundedMTBold", 24);
STCachedFont(dq_coinsFont, @"Vanilla", 24);
STCachedFont(dq_homeQuestTitleFont, @"ArialRoundedMTBold", 12);
STCachedFont(dq_homeTimestampFont, @"ArialRoundedMTBold", 10);
STCachedFont(dq_finePrintFont, @"ArialRoundedMTBold", 12.0);
STCachedFont(dq_authTextFieldFont, @"ArialRoundedMTBold", 12.0);
STCachedFont(dq_onboardingTextFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_publishAuthHeaderFont, @"ArialRoundedMTBold", 17.0);
STCachedFont(dq_signInLabelFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_profileFollowStatsFont, @"Vanilla", 20.0);
STCachedFont(dq_profileFollowLabelFont, @"Vanilla", 16.0);
STCachedFont(dq_profileUsernameFont, @"ArialRoundedMTBold", 26.0f);
STCachedFont(dq_profileBioFont, @"ArialRoundedMTBold", 15.0);
STCachedFont(dq_profileWebLinkFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_rewardTextFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_userListUsernameFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_purchaseItemDescriptionFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_cellCheckmarkLabelFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_authCopyFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_gallerySparseFont, @"ArialRoundedMTBold", 26.0f);
STCachedFont(dq_coinsButtonFont, @"Vanilla", 18.0);
STCachedFont(dq_onboardExpositionFont, @"ArialRoundedMTBold", 18.0);
STCachedFont(dq_onboardTabsFont, @"ArialRoundedMTBold", 20.0);
STCachedFont(dq_completionLabelFont, @"ArialRoundedMTBold", 15.0);
STCachedFont(dq_sponsorCopyFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_sponsorUsernameFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_modalNavigationBarTitleFont, @"ArialRoundedMTBold", 20.0);
STCachedFont(dq_modalBarButtonItemTitleFont, @"ArialRoundedMTBold", 17.0);
STCachedFont(dq_mainActionButtonTitleFont, @"ArialRoundedMTBold", 20.0);
STCachedFont(dq_cellActionButtonTitleFont, @"ArialRoundedMTBold", 18.0);
STCachedFont(dq_modalTableHeaderFont, @"ArialRoundedMTBold", 18.0);
STCachedFont(dq_modalTableCellFont, @"ArialRoundedMTBold", 17.0);
STCachedFont(dq_modalTableCellDetailFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_modalTextFieldFont, @"ArialRoundedMTBold", 15.0);
STCachedFont(dq_modalURLStringFont, @"ArialRoundedMTBold", 12.0);
STCachedFont(dq_shopMessageFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_modalNewColorFont, @"ArialRoundedMTBold", 12.0);
STCachedFont(dq_questOfTheDayTitleFont, @"ArialRoundedMTBold", 13.0);
STCachedFont(dq_questCellTitleFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_questCellUsernameFont, @"Arial", 11.0);
STCachedFont(dq_timestampFont, @"ArialRoundedMTBold", 11.0);
STCachedFont(dq_questHeaderUsernameFont, @"ArialRoundedMTBold", 12.0);
STCachedFont(dq_questHeaderDescriptionFont, @"Arial", 10.5);
STCachedFont(dq_questTitleFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_drawingDetailUsernameFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_reactionCellUsernameFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_reactionCellDescriptionFont, @"Arial", 12.0);
STCachedFont(dq_gridCellErrorFont, @"Arial", 11.0);
STCachedFont(dq_listCellUsernameFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_listCellNotesFont, @"Arial", 15.0);
STCachedFont(dq_questTitleSearchFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_questCreationTitleFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_shareTitleFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_galleryErrorMessageFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_galleryButtonFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_emailSharingCellFont, @"Arial", 15.0);
STCachedFont(dq_emailSharingCellDetailFont, @"Arial", 13.0);
STCachedFont(dq_tourMessagesFont, @"ArialRoundedMTBold", 22.0);
STCachedFont(dq_tourPrimaryButtonFont, @"ArialRoundedMTBold", 16.0);
STCachedFont(dq_tourSecondaryButtonsFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_tourSwipeHintFont, @"Arial", 12.0);
STCachedFont(dq_segmentControlTitle, @"ArialRoundedMTBold", 11.0f);
STCachedFont(dq_segmentControlCount, @"Arial", 16.0);
STCachedFont(dq_phoneProfileUsernameFont, @"ArialRoundedMTBold", 18.0);
STCachedFont(dq_phoneProfileBioFont, @"Arial", 12.0);
STCachedFont(dq_phoneProfileFollowButtonFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneCoinsFont, @"Vanilla", 15.0);
STCachedFont(dq_phoneActivityUsername, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneActivityActivity, @"HelveticaNeue", 11.0);
STCachedFont(dq_phoneAuthTextInputFont, @"ArialRoundedMTBold", 13.0f);
STCachedFont(dq_phoneAuthSocialLoginLabelFont, @"ArialRoundedMTBold", 13.0);
STCachedFont(dq_phoneAuthSignUpMessageFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneAuthSwitchQuestionFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneAuthSwitchButtonFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneCTAButtonFont, @"ArialRoundedMTBold", 15.0);
STCachedFont(dq_phoneRewardsFont, @"ArialRoundedMTBold", 17.0);
STCachedFont(dq_phoneRewardsLargeFont, @"ArialRoundedMTBold", 20.0);
STCachedFont(dq_phoneRewardsLargeCoinsFont, @"Vanilla", 30.0);
STCachedFont(dq_phoneUserCellUsernameFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneUserCellDetailFont, @"Arial", 12.0);
STCachedFont(dq_phoneUserCellDetailBoldFont, @"Arial-BoldMT", 12.0);
STCachedFont(dq_phoneSegmentedControlFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneShopItemTitleFont, @"Arial", 18.0);
STCachedFont(dq_phoneShopItemSubTitleFont, @"Arial-BoldMT", 12.0);
STCachedFont(dq_phoneShopItemDescriptionFont, @"Arial", 12.0);
STCachedFont(dq_phoneShopPurchasedFont, @"Arial", 14.0);
STCachedFont(dq_phoneSettingsLabelFont, @"ArialRoundedMTBold", 13.0);
STCachedFont(dq_phoneSearchFont, @"ArialRoundedMTBold", 14.0);
STCachedFont(dq_phoneSearchPlaceholderFont, @"Arial", 12.0);
STCachedFont(dq_phoneQuestAttributionLabelFont, @"Arial", 12.0);

@end
