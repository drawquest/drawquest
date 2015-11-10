//
//  UIColor+DQAdditions.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "UIColor+DQAdditions.h"
#import "STUtils.h"

@implementation UIColor (DQAdditions)

STCachedColor(dq_borderStrokeColor, 184.0, 177.0, 174.0, 1.0);
STCachedColor(dq_activityItemUserNameFontColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_activityItemActivityTypeFontColor, 184.0, 177.0, 177.0, 1.0);
STCachedColor(dq_basementNavigationTextColor, 154.0, 149.0, 146.0, 1.0);
STCachedColor(dq_basementNavigationStatusTextColor, 178.0, 211.0, 42.0, 1.0);
STCachedColor(dq_activityTimestampTextColor, 216.0, 216.0, 216.0, 1.0);
STCachedColor(dq_homeQuestTitleTextColor, 154.0, 149.0, 146.0, 1.0);
STCachedColor(dq_homeTimestampTextColor, 179.0, 179.0, 179.0, 1.0);
STCachedColor(dq_finePrintTextColor, 154.0, 149.0, 146.0, 1.0);
STCachedColor(dq_authTextFieldTextColor, 0.0, 0.0, 0.0, 1.0);
STCachedColor(dq_authTextFieldBorderColor, 202.0, 202.0, 202.0, 1.0);
STCachedColor(dq_authTextSwitchQuestionColor, 199.0, 199.0, 199.0, 1.0);
STCachedColor(dq_authTextSwitchActionColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_authTextSwitchActionHitColor, 178.0, 211.0, 42.0, 1.0);
STCachedColor(dq_greenBorderColor, 158.0, 201, 41.0, 8.0);
STCachedColor(dq_separatorColor, 232.0, 232.0, 232.0, 1.0);
STCachedColor(dq_basementShadowBorderColor, 154.0, 154.0, 154.0, 1.0);
STCachedColor(dq_modalTableHeaderColor, 178.0, 211.0, 42.0, 1.0);
STCachedColor(dq_userSearchAutocompleteFontColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_cellCheckmarkFontColor, 178.0, 211.0, 42.0, 1.0);
STCachedColor(dq_warningRed, 246.0, 113.0, 135.0, 1.0);

// Modal specific colors
STCachedColor(dq_coinTextColor, 244.0, 213.0, 41.0, 1.0);
STCachedColor(dq_disabledCoinTextColor, 217.0, 217.0, 217.0, 1.0);
STCachedColor(dq_modalDisabledTextColor, 199.0, 199.0, 199.0, 1.0);
STCachedColor(dq_modalTableHeaderTextColor, 178.0, 211.0, 42.0, 1.0);
STCachedColor(dq_modalTableSeperatorColor, 202.0, 202.0, 202.0, 1.0);
STCachedColor(dq_modalTableCellBackgroundColor, 247.0, 247.0, 247.0, 1.0);
STCachedColor(dq_modalHighlightTextColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_modalPrimaryTextColor, 145.0, 145.0, 145.0, 1.0);
STCachedColor(dq_modalSecondaryTextColor, 204.0, 204.0, 204.0, 1.0);
STCachedColor(dq_modalNewColorTextColor, 178.0, 211.0, 42.0, 1.0);

//User search colors
STCachedColor(dq_userSearchUsernameColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_userSearchNumbersColor, 152.0, 152.0, 152.0, 1.0);
STCachedColor(dq_userSearchFollowColor, 218.0, 218.0, 218.0, 1.0);

// Editor
STCachedColor(dq_editorToolbarBackgroundColor, 248.0, 248.0, 248.0, 1.0);
STCachedColor(dq_editorToolbarDividerColor, 235.0, 235.0, 235.0, 1.0);

// Phone specific
STCachedColor(dq_phoneBackgroundColor, 248.0, 248.0, 248.0, 1.0);
STCachedColor(dq_drawingThumbStrokeColor, 200.0, 200.0, 200.0, 1.0);
STCachedColor(dq_timestampColor, 200.0, 200.0, 200.0, 1.0);
STCachedColor(dq_phoneGrayTextColor, 180.0, 180.0, 180.0, 1.0);
STCachedColor(dq_phoneLightGrayTextColor, 200.0, 200.0, 200.0, 1.0);
STCachedColor(dq_phoneDarkGrayTextColor, 155.0, 155.0, 155.0, 1.0);
STCachedColor(dq_phoneDivider, 230.0, 230.0, 230.0, 1.0);
STCachedColor(dq_phoneTableSeperatorColor, 195.0, 195.0, 195.0, 1.0);
STCachedColor(dq_phoneButtonOffColor, 200.0, 200.0, 200.0, 1.0);
STCachedColor(dq_activityFollowButtonNotFollowingColor, 200.0, 200.0, 200.0, 1.0);
STCachedColor(dq_phoneAuthSwitchTextColor, 155.0, 155.0, 155.0, 1.0);
STCachedColor(dq_phoneRewardsGray, 121.0, 121.0, 121.0, 1.0f);
STCachedColor(dq_phoneProfileSocialLinkInactiveButtonColor, 228.0, 228.0, 228.0, 1.0);
STCachedColor(dq_phoneSettingsSectionHeaderTitleColor, 155.0, 155.0, 155.0, 1.0);
STCachedColor(dq_defaultTabColor, 200.0f, 200.0f, 200.0f, 1.0f);

// Brand Colors
STCachedColor(dq_blueColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_greenColor, 90.0, 229.0, 181.0, 1.0);
STCachedColor(dq_pinkColor, 254.0, 120.0, 143.0, 1.0);
STCachedColor(dq_yellowColor, 255.0, 210.0, 97.0, 1.0);
STCachedColor(dq_purpleColor, 202.0, 149.0, 234.0, 1.0);

// Phone Tabs
/* Original colors
STCachedColor(dq_homeTabColor, 103.0, 206.0, 218.0, 1.0);
STCachedColor(dq_drawTabColor, 253.0, 204.0, 32.0, 1.0);
STCachedColor(dq_activityTabColor, 224.0, 145.0, 234.0, 1.0);
STCachedColor(dq_profileTabColor, 178.0, 219.0, 55.0, 1.0);
STCachedColor(dq_editorTabColor, 246.0, 113.0, 135.0, 1.0);
 */

+ (UIColor *)dq_homeTabColor
{
    return [UIColor dq_blueColor];
}

+ (UIColor *)dq_drawTabColor
{
    return [UIColor dq_greenColor];
}

+ (UIColor *)dq_activityTabColor
{
    return [UIColor dq_yellowColor];
}

+ (UIColor *)dq_profileTabColor
{
    return [UIColor dq_pinkColor];
}

+ (UIColor *)dq_editorTabColor
{
    return [UIColor dq_greenColor];
}

+ (UIColor *)dq_authenticationColor
{
    return [UIColor dq_pinkColor];
}

+ (UIColor *)dq_colorWithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue
{
    return [UIColor colorWithRed:red / 255.0  green:green / 255.0f blue:blue / 255.0f alpha:1.0f];
}

+ (UIColor *)dq_colorWithRGBArray:(NSArray *)inColorArray;
{
    if (!inColorArray || inColorArray.count < 3) {
        return nil;
    }
    
    NSInteger red = [(NSNumber *)[inColorArray objectAtIndex:0] integerValue];
    NSInteger green = [(NSNumber *)[inColorArray objectAtIndex:1] integerValue];
    NSInteger blue = [(NSNumber *)[inColorArray objectAtIndex:2] integerValue];
    
    return [self dq_colorWithRed:red green:green blue:blue];
}

NSDictionary * DQDictionaryFromColor(UIColor *color)
{
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    return @{@"r" : @(red), @"g" : @(green), @"b" : @(blue)};
}


UIColor * DQColorFromDictionary(NSDictionary *dictionary)
{
    CGFloat red = [dictionary[@"r"] floatValue];
    CGFloat green = [dictionary[@"g"] floatValue];
    CGFloat blue = [dictionary[@"b"] floatValue];
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

- (NSString *)dq_colorKey
{
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];

    return [NSString stringWithFormat:@"%f,%f,%f,%f", red, green, blue, alpha];
}

@end
