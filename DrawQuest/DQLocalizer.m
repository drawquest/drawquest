//
//  DQLocalizer.m
//  DrawQuest
//
//  Created by Jim Roepcke on 12/5/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQLocalizer.h"
#import "NSFileManager+STAdditions.h"
#import "NSString+STAdditions.h"
#import "DQPapertrailLogger.h"
#import "DQUnzipper.h"

NSString *DQLocalizationSupportedLanguagesDidChangeNotification = @"DQLocalizationSupportedLanguagesDidChangeNotification";

NSString *DQLocalizerDownloadedL10nZipFileURLStringKey = @"DQLocalizerDownloadedL10nZipFileURLString";
NSString *DQLocalizerSupportedLanguagesKey = @"DQLocalizerSupportedLanguages";
NSString *DQLocalizerBundleFilename = @"DQLocalizerBundleFilename";

NSBundle *Z__sharedDQLocalizerBundle = nil;
NSString *Z__currentlyDownloadingZipFileURLString = nil;
NSOperationQueue *Z__queue = nil;

void DQLocalizerSetBundleFilename(NSString *filename)
{
    // NSLog(@"Localizer A ");
    NSBundle *result = nil;
    if ([filename length])
    {
        // NSLog(@"Localizer B ");
        NSFileManager *fm = [NSFileManager new];
        BOOL isDir = NO;
        NSString *path = [fm applicationSupportFileName:filename];
        if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            // NSLog(@"Localizer C ");
            NSBundle *bundle = [[NSBundle alloc] initWithPath:path];
            result = bundle;
        }
    }
    if (Z__sharedDQLocalizerBundle && (Z__sharedDQLocalizerBundle != [NSBundle mainBundle]))
    {
        // NSLog(@"Localizer D ");
    }
    Z__sharedDQLocalizerBundle = result ?: [NSBundle mainBundle];
    if (result)
    {
        // NSLog(@"Localizer E ");
        [[NSUserDefaults standardUserDefaults] setObject:filename forKey:DQLocalizerBundleFilename];
    }
    else
    {
        // NSLog(@"Localizer G ");
        NSString *old = [[NSUserDefaults standardUserDefaults] objectForKey:DQLocalizerBundleFilename];
        if ([old length])
        {
            // NSLog(@"Localizer H ");
            NSFileManager *fm = [NSFileManager new];
            NSString *path = [fm applicationSupportFileName:old];
            [fm removeItemAtPath:path error:NULL];
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQLocalizerBundleFilename];
    }
    // NSLog(@"Localizer I ");
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@implementation DQLocalization

+ (void)setup
{
    // NSLog(@"Localizer J ");
    if (!Z__queue)
    {
        // NSLog(@"Localizer K ");
        Z__queue = [[NSOperationQueue alloc] init];
        Z__queue.maxConcurrentOperationCount = 1;
    }
    [self setup:NO];
}

+ (BOOL)setup:(BOOL)force
{
    // NSLog(@"Localizer L ");
    BOOL result = NO;
#ifdef DEBUG
    NSString *previouslyConfiguredBundleFilename = nil;
#else
    NSString *previouslyConfiguredBundleFilename = force ? nil : [[NSUserDefaults standardUserDefaults] stringForKey:DQLocalizerBundleFilename];
#endif
    if ([previouslyConfiguredBundleFilename length])
    {
        // NSLog(@"Localizer M ");
        DQLocalizerSetBundleFilename(previouslyConfiguredBundleFilename);
        result = YES;
    }
    else
    {
        // NSLog(@"Localizer N ");
        DQLocalizerSetBundleFilename(nil);
        NSSet *languages = [NSSet setWithArray:self.supportedLanguages ?: [self allLanguages]];
        if (![languages count])
        {
            // NSLog(@"Localizer O ");
            // no languages means use the main bundle
            result = YES;
        }
        else
        {
            // NSLog(@"Localizer P ");
            NSFileManager *fm = [NSFileManager new];
            NSString *l10nPath = [fm applicationSupportFileName:@"l10n"];
            if ([fm createFreshPath:l10nPath])
            {
                // NSLog(@"Localizer Q ");
                NSString *bundleFilename = [@"l10n-enabled-" stringByAppendingString:[NSString UUIDString]];
                NSString *enabledL10nPath = [fm applicationSupportFileName:bundleFilename];
                if ([fm createFreshPath:enabledL10nPath])
                {
                    // NSLog(@"Localizer R ");
                    NSString *zipFilePath = [self zipFilePath];
                    if (zipFilePath)
                    {
                        // NSLog(@"Localizer S ");
                        if ([DQUnzipper unzipArchive:zipFilePath toDirectory:l10nPath])
                        {
                            // NSLog(@"Localizer T ");
                            if ([self enableLanguages:languages inPath:enabledL10nPath fromPath:l10nPath])
                            {
                                // NSLog(@"Localizer U ");
                                DQLocalizerSetBundleFilename(bundleFilename);
                                result = YES;
                            } // enableLanguages already logs errors
                        } // DQUnzipper already logs errors
                    } // zipFilePath already logs errors
                } // createFreshPath already logs errors
            } // createFreshPath already logs errors
        }
    }
    // NSLog(@"Localizer setup: result: %@ ", @(result));
    return result;
}

+ (NSString *)downloadedL10nFilePath:(NSFileManager *)fm
{
    return [fm applicationSupportFileName:@"l10n.zip"];
}

+ (NSString *)zipFilePath
{
    NSFileManager *fm = [NSFileManager new];
#ifdef DEBUG
    NSString *result = nil;
#else
    NSString *result = [self downloadedL10nFilePath:fm];
#endif
    if ( ! ([result length] && [fm fileExistsAtPath:result]) )
    {
        result = [[NSBundle mainBundle] pathForResource:@"l10n" ofType:@"zip"];
        if ( ! ([result length] && [fm fileExistsAtPath:result]) )
        {
            result = nil;
            [DQPapertrailLogger component:@"localization" category:@"zip-file-path-failed" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{};
            }];
        }
    }
    // NSLog(@"Localizer zipFilePath: %@ ", result);
    return result;
}

+ (NSArray *)allLanguages
{
    return @[@"de", @"en", @"es", @"fr", @"ja", @"ko", @"nl", @"pt", @"ru", @"th", @"zh-Hant", @"zh-Hans"];
}

+ (BOOL)enableLanguages:(NSSet *)languages inPath:(NSString *)enabledL10nPath fromPath:(NSString *)l10nPath
{
    BOOL result = NO;
    NSFileManager *fm = [NSFileManager new];
    // NSLog(@"Localizer V ");

    if ([languages count] && [fm createFreshPath:enabledL10nPath])
    {
        // NSLog(@"Localizer W ");
        result = YES;
        for (NSString *lang in languages)
        {
            // NSLog(@"Localizer X %@", lang);
            if ([lang length])
            {
                // NSLog(@"Localizer Y ");
                NSString *lproj = [lang stringByAppendingPathExtension:@"lproj"];
                BOOL isDir = NO;
                NSString *symlinkTargetAbsolutePath = [l10nPath stringByAppendingPathComponent:lproj];
                NSString *symlinkTarget = [NSString stringWithFormat:@"../%@/%@.lproj", [l10nPath lastPathComponent], lang];
                // NSLog(@"Localizer symlinkTarget: %@", symlinkTarget);
                if ([fm fileExistsAtPath:symlinkTargetAbsolutePath isDirectory:&isDir] && isDir)
                {
                    // NSLog(@"Localizer Z ");
                    NSError *error = nil;
                    NSString *symlinkPath = [enabledL10nPath stringByAppendingPathComponent:lproj];
                    if ( ! [fm createSymbolicLinkAtPath:symlinkPath withDestinationPath:symlinkTarget error:&error])
                    {
                        // NSLog(@"Localizer AA ");
                        result = NO;
                        [DQPapertrailLogger component:@"localization" category:@"enable-lproj-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                            return @{@"dest-path": symlinkTarget ?: [NSNull null],
                                     @"symlink-path": symlinkPath ?: [NSNull null]};
                        }];
                        break;
                    }
                }
            }
        }
    }
    return result;
}

+ (void)setSupportedLanguages:(NSArray *)supportedLanguages
{
    // NSLog(@"Localizer AB ");
    NSSet *oldSet = [NSSet setWithArray:self.supportedLanguages ?: [self allLanguages]];
    NSSet *newSet = [NSSet setWithArray:supportedLanguages ?: [self allLanguages]];
    if (![oldSet isEqualToSet:newSet])
    {
        // NSLog(@"Localizer AC ");
        if (supportedLanguages)
        {
            // NSLog(@"Localizer AD ");
            [[NSUserDefaults standardUserDefaults] setObject:supportedLanguages forKey:DQLocalizerSupportedLanguagesKey];
        }
        else
        {
            // NSLog(@"Localizer AE ");
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQLocalizerSupportedLanguagesKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self setup:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:DQLocalizationSupportedLanguagesDidChangeNotification object:nil];
    }
    // NSLog(@"Localizer AF ");
}

+ (NSArray *)supportedLanguages
{
    NSArray *result = [[NSUserDefaults standardUserDefaults] objectForKey:DQLocalizerSupportedLanguagesKey];
    // NSLog(@"Localizer supportedLanguages: %@ ", result);
    return result;
}

+ (NSString *)displayedLanguage
{
    return [[NSLocale preferredLanguages] firstObjectCommonWithArray:[self supportedLanguages] ?: [self allLanguages]];
}

+ (void)startDownloadZipFileURLString:(NSString *)url completionBlock:(dispatch_block_t)completionBlock failureBlock:(dispatch_block_t)failureBlock
{
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:300.0];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:Z__queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data)
        {
            NSFileManager *fm = [NSFileManager new];
            NSString *tempDir = NSTemporaryDirectory();
            NSString *testDir = [tempDir stringByAppendingPathComponent:[NSString UUIDString]];
            if ([fm recursivelyCreatePath:testDir])
            {
                if ([DQUnzipper unzipData:data toDirectory:testDir])
                {
                    [fm removeItemAtPath:testDir error:NULL];
                    NSString *zipFilePath = [self downloadedL10nFilePath:fm];
                    NSError *error = nil;
                    if ( (![fm fileExistsAtPath:zipFilePath]) || [fm removeItemAtPath:zipFilePath error:&error] )
                    {
                        error = nil;
                        if ([data writeToFile:zipFilePath options:NSDataWritingAtomic error:&error])
                        {
                            NSURL *zipFileURL = [NSURL fileURLWithPath:zipFilePath];
                            [zipFileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([self setup:YES])
                                {
                                    if (completionBlock)
                                    {
                                        completionBlock();
                                    }
                                }
                                else if (failureBlock)
                                {
                                    failureBlock();
                                }
                            });
                        }
                        else
                        {
                            [DQPapertrailLogger component:@"localization" category:@"write-downloaded-zip-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                                return @{@"path": zipFilePath ?: [NSNull null]};
                            }];
                            if (failureBlock)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    failureBlock();
                                });
                            }
                        }
                    }
                    else
                    {
                        [DQPapertrailLogger component:@"localization" category:@"remove-old-downloaded-zip-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                            return @{@"path": zipFilePath ?: [NSNull null]};
                        }];
                        if (failureBlock)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                failureBlock();
                            });
                        }
                    }
                }
                else // unzipData already logs errors
                {
                    if (failureBlock)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            failureBlock();
                        });
                    }
                }
            } // recursivelyCreatePath already logs errors
            else
            {
                if (failureBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failureBlock();
                    });
                }
            }
        }
        else
        {
            NSHTTPURLResponse *httpURLResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
            [DQPapertrailLogger component:@"localization" category:@"download-zip-failed" error:connectionError httpURLResponse:httpURLResponse dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"url": url ?: [NSNull null]};
            }];
            if (failureBlock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock();
                });
            }
        }
    }];
}

+ (void)requestDownloadZipFileFromURLString:(NSString *)url completionBlock:(dispatch_block_t)completionBlock
{
    if ([url length])
    {
        if (Z__currentlyDownloadingZipFileURLString)
        {
            if (![Z__currentlyDownloadingZipFileURLString isEqualToString:url])
            {
                [Z__queue cancelAllOperations];
                Z__currentlyDownloadingZipFileURLString = [url copy];
                [self startDownloadZipFileURLString:url completionBlock:^{
                    Z__currentlyDownloadingZipFileURLString = nil;
                    if (completionBlock)
                    {
                        completionBlock();
                    }
                } failureBlock:^{
                    Z__currentlyDownloadingZipFileURLString = nil;
                }];
            }
        }
        else
        {
            Z__currentlyDownloadingZipFileURLString = [url copy];
            [self startDownloadZipFileURLString:url completionBlock:^{
                Z__currentlyDownloadingZipFileURLString = nil;
                if (completionBlock)
                {
                    completionBlock();
                }
            } failureBlock:^{
                Z__currentlyDownloadingZipFileURLString = nil;
            }];
        }
    }
    else
    {
        if (Z__currentlyDownloadingZipFileURLString)
        {
            [Z__queue cancelAllOperations];
            Z__currentlyDownloadingZipFileURLString = nil;
        }
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

+ (void)setZipFileURLString:(NSString *)zipFileURLString
{
    NSString *current = self.zipFileURLString;
    if ([zipFileURLString length])
    {
        if (![zipFileURLString isEqualToString:current])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestDownloadZipFileFromURLString:zipFileURLString completionBlock:^{
                    [[NSUserDefaults standardUserDefaults] setObject:zipFileURLString forKey:DQLocalizerDownloadedL10nZipFileURLStringKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DQLocalizerDidUpdate" object:nil userInfo:nil];
                }];
            });
        }
    }
    else if (current)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestDownloadZipFileFromURLString:nil completionBlock:^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:DQLocalizerDownloadedL10nZipFileURLStringKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSFileManager *fm = [NSFileManager new];
                NSError *error = nil;
                NSString *path = [self downloadedL10nFilePath:fm];
                if ( (![fm fileExistsAtPath:path]) || [fm removeItemAtPath:path error:&error])
                {
                    if ([self setup:YES])
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"DQLocalizerDidUpdate" object:nil userInfo:nil];
                    }
                }
                else
                {
                    [DQPapertrailLogger component:@"localization" category:@"remove-downloaded-zip-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                        return @{@"path": path ?: [NSNull null]};
                    }];
                }
            }];
        });
    }
}

+ (NSString *)zipFileURLString
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:DQLocalizerDownloadedL10nZipFileURLStringKey];
}

@end
