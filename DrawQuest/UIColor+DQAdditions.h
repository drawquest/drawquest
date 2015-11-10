//
//  UIColor+DQAdditions.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (DQAdditions)

+ (UIColor *)dq_borderStrokeColor;
+ (UIColor *)dq_activityItemUserNameFontColor;
+ (UIColor *)dq_activityItemActivityTypeFontColor;
+ (UIColor *)dq_basementNavigationTextColor;
+ (UIColor *)dq_basementNavigationStatusTextColor;
+ (UIColor *)dq_activityTimestampTextColor;
+ (UIColor *)dq_homeQuestTitleTextColor;
+ (UIColor *)dq_homeTimestampTextColor;
+ (UIColor *)dq_finePrintTextColor;
+ (UIColor *)dq_authTextFieldTextColor;
+ (UIColor *)dq_authTextFieldBorderColor;
+ (UIColor *)dq_authTextSwitchQuestionColor;
+ (UIColor *)dq_authTextSwitchActionColor;
+ (UIColor *)dq_authTextSwitchActionHitColor;
+ (UIColor *)dq_greenBorderColor;
+ (UIColor *)dq_separatorColor;
+ (UIColor *)dq_basementShadowBorderColor;
+ (UIColor *)dq_modalTableHeaderColor;
+ (UIColor *)dq_userSearchAutocompleteFontColor;
+ (UIColor *)dq_cellCheckmarkFontColor;
+ (UIColor *)dq_warningRed;

+ (UIColor *)dq_coinTextColor;
+ (UIColor *)dq_disabledCoinTextColor;
+ (UIColor *)dq_modalDisabledTextColor;
+ (UIColor *)dq_modalTableHeaderTextColor;
+ (UIColor *)dq_modalTableSeperatorColor;
+ (UIColor *)dq_modalTableCellBackgroundColor;
+ (UIColor *)dq_modalHighlightTextColor;
+ (UIColor *)dq_modalPrimaryTextColor;
+ (UIColor *)dq_modalSecondaryTextColor;
+ (UIColor *)dq_modalNewColorTextColor;

+ (UIColor *)dq_userSearchUsernameColor;
+ (UIColor *)dq_userSearchNumbersColor;
+ (UIColor *)dq_userSearchFollowColor;

+ (UIColor *)dq_editorToolbarBackgroundColor;
+ (UIColor *)dq_editorToolbarDividerColor;

+ (UIColor *)dq_phoneBackgroundColor;
+ (UIColor *)dq_drawingThumbStrokeColor;
+ (UIColor *)dq_timestampColor;
+ (UIColor *)dq_phoneGrayTextColor;
+ (UIColor *)dq_phoneLightGrayTextColor;
+ (UIColor *)dq_phoneDarkGrayTextColor;
+ (UIColor *)dq_phoneDivider;
+ (UIColor *)dq_phoneTableSeperatorColor;
+ (UIColor *)dq_phoneButtonOffColor;
+ (UIColor *)dq_activityFollowButtonNotFollowingColor;
+ (UIColor *)dq_phoneAuthSwitchTextColor;
+ (UIColor *)dq_phoneRewardsGray;
+ (UIColor *)dq_phoneProfileSocialLinkInactiveButtonColor;
+ (UIColor *)dq_phoneSettingsSectionHeaderTitleColor;

+ (UIColor *)dq_blueColor;
+ (UIColor *)dq_greenColor;
+ (UIColor *)dq_pinkColor;
+ (UIColor *)dq_yellowColor;
+ (UIColor *)dq_purpleColor;

+ (UIColor *)dq_defaultTabColor;
+ (UIColor *)dq_homeTabColor;
+ (UIColor *)dq_drawTabColor;
+ (UIColor *)dq_activityTabColor;
+ (UIColor *)dq_profileTabColor;
+ (UIColor *)dq_editorTabColor;
+ (UIColor *)dq_authenticationColor;

+ (UIColor *)dq_colorWithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue;
+ (UIColor *)dq_colorWithRGBArray:(NSArray *)inColorArray;

extern NSDictionary * DQDictionaryFromColor(UIColor *color);
extern UIColor * DQColorFromDictionary(NSDictionary *dictionary);

- (NSString *)dq_colorKey;

@end
