//
//  DQLocalizer.h
//  DrawQuest
//
//  Created by Jim Roepcke on 12/5/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSObjCRuntime.h>

extern NSString *DQLocalizationSupportedLanguagesDidChangeNotification;

extern NSBundle *Z__sharedDQLocalizerBundle;

NS_INLINE NS_FORMAT_ARGUMENT(1) NSString *DQLocalizedString(NSString *const key, NSString *const comment)
{
    return [Z__sharedDQLocalizerBundle localizedStringForKey:key value:@"" table:nil];
}

NS_INLINE NS_FORMAT_ARGUMENT(4) NSString *DQLocalizedStringWithDefaultValue(NSString *const key, id _, id __, NSString *const val, NSString *const comment)
{
    // using @"" instead of val because we've seen weird behaviour with it
    // just make sure you have translations for keys used with this function
    return [Z__sharedDQLocalizerBundle localizedStringForKey:key value:@"" table:nil];
}

@interface DQLocalization : NSObject

+ (void)setup;

+ (NSString *)displayedLanguage; // first language in common between preferred languages and (supported languages ?: all languages)

+ (NSArray *)allLanguages; // all languages we ship with the app
+ (NSArray *)supportedLanguages; // server-controlled list of languages the localizer should use
+ (void)setSupportedLanguages:(NSArray *)inSupportedLanguagesArray;

+ (void)setZipFileURLString:(NSString *)zipFileURLString;

@end
