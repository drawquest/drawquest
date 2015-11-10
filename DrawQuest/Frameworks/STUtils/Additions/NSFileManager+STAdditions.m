//
//  NSFileManager+STAdditions.m
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSFileManager+STAdditions.h"
#import "NSArray+STAdditions.h"
#import "NSDate+STAdditions.h"
#import "NSString+STAdditions.h"
#include <sys/stat.h>
#import "DQPapertrailLogger.h"

@implementation NSFileManager (STAdditions)

- (NSString *)applicationSupportPath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *rootDirectory = [paths firstObject];
    
    if (!rootDirectory.length) {
        return nil;
    }

    return rootDirectory;
}

- (NSString *)applicationSupportPathIncludingAppName;
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    return [self applicationSupportFileName:appName];
}

- (NSString *)applicationSupportFileName:(NSString *)inFileName;
{
    NSString *appSupportPath = [self applicationSupportPath];
    if (!appSupportPath.length) {
        return nil;
    }
    
    if (!inFileName.length) {
        return appSupportPath;
    }
    
    return [appSupportPath stringByAppendingPathComponent:inFileName];
}

- (NSString *)cachePath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *rootDirectory = [paths firstObject];
    
    if (!rootDirectory) {
        return nil;
    }
    
    return rootDirectory;
}

- (NSString *)cachePathIncludingAppName;
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    return [self cacheFileName:appName];
}

- (NSString *)cacheFileName:(NSString *)inFileName;
{
    NSString *cachePath = [self cachePath];
    if (!cachePath.length) {
        return nil;
    }

    if (!inFileName) {
        return cachePath;
    }
    
    return [cachePath stringByAppendingPathComponent:inFileName];
}


- (BOOL)createFreshPath:(NSString *)path
{
    BOOL result = NO;

    if ([self fileExistsAtPath:path])
    {
        NSError *error = nil;
        if ([self removeItemAtPath:path error:&error])
        {
            if ([self recursivelyCreatePath:path])
            {
                result = YES;
            } // recursivelyCreatePath already logs errors
        }
        else
        {
            [DQPapertrailLogger component:@"file-manager" category:@"create-fresh-path-remove-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"path": path ?: [NSNull null]};
            }];
        }
    }
    else
    {
        if ([self recursivelyCreatePath:path])
        {
            result = YES;
        } // recursivelyCreatePath already logs errors
    }
    return result;
}

- (BOOL)recursivelyCreatePath:(NSString *)inPath;
{
    return [self recursivelyCreatePath:inPath lastComponentIsFile:NO];
}

- (BOOL)recursivelyCreatePath:(NSString *)inPath lastComponentIsFile:(BOOL)isFile;
{
    BOOL isDir = NO;
    if ([self fileExistsAtPath:inPath isDirectory:&isDir])
    {
        // if you asked for a file but it's a directory, that's bad
        if (isFile == isDir)
        {
            [DQPapertrailLogger component:@"file-manager" category:@"create-path-mismatch" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"path": inPath ?: [NSNull null],
                         @"is-file": @(isFile)};
            }];
            return NO;
        }
        return YES;
    }
    
    NSArray *pathComponents = [inPath pathComponents];
    if (!pathComponents.count || (isFile && pathComponents.count < 2)) {
        [DQPapertrailLogger component:@"file-manager" category:@"create-path-invalid-arguments" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"path": inPath ?: [NSNull null],
                     @"is-file": @(isFile)};
        }];
        return NO;
    }
    
    NSString *actualPath = isFile ? [inPath stringByRemovingLastPathComponent] : inPath;
    NSError *error = nil;
    BOOL directoryCreated = [self createDirectoryAtPath:actualPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!directoryCreated)
    {
        [DQPapertrailLogger component:@"file-manager" category:@"create-path-mkdir-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"path": inPath ?: [NSNull null],
                     @"is-file": @(isFile),
                     @"actual-path": actualPath ?: [NSNull null]};
        }];
        return NO;
    }
    else if (!isFile)
    {
        return YES;
    }

    error = nil;
    if ([[NSData data] writeToFile:inPath options:0 error:&error])
    {
        NSURL *inPathURL = [NSURL fileURLWithPath:inPath];
        [inPathURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    }
    else
    {
        [DQPapertrailLogger component:@"file-manager" category:@"create-path-touch-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"path": inPath ?: [NSNull null],
                     @"is-file": @(isFile)};
        }];
        return NO;
    }
    return YES;
}

- (unsigned long long)fileSizeAtPath:(NSString *)inPath;
{
    BOOL isDir = NO;
    if (![self fileExistsAtPath:inPath isDirectory:&isDir]) {
        return 0;
    }
    
    unsigned long long totalSize = 0;
    
    if (isDir) {
        NSDirectoryEnumerator *directoryEnum = [self enumeratorAtPath:inPath];
        NSString *currentItemPath;
        while ((currentItemPath = [directoryEnum nextObject])) {
            if ([[[directoryEnum fileAttributes] fileType] isEqualToString:NSFileTypeDirectory]) {
                totalSize += [self fileSizeAtPath:[inPath stringByAppendingPathComponent:currentItemPath]];
            } else {
                totalSize += [[directoryEnum fileAttributes] fileSize];                
            }
        }
    } else {
        NSDictionary *fileAttributes = [self attributesOfItemAtPath:inPath error:NULL];
        totalSize = fileAttributes.count ? [fileAttributes fileSize] : 0;
    }
    
    return totalSize;
}

- (NSDate *)modificationDateForFileAtPath:(NSString *)inPath;
{
    struct stat fileAttributesStruct;
    stat([inPath UTF8String], &fileAttributesStruct);
    return [NSDate dateWithCTimeStruct:fileAttributesStruct.st_mtime];
}

@end
