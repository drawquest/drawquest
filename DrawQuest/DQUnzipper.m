//
//  DQUnzipper.m
//  DrawQuest
//
//  Created by Jim Roepcke on 12/5/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQUnzipper.h"
#import "DQPapertrailLogger.h"
#import "NSFileManager+STAdditions.h"
#import "ZZArchive.h"
#import "ZZArchiveEntry.h"

@implementation DQUnzipper

+ (BOOL)unzipArchive:(NSString *)zipFilePath toDirectory:(NSString *)targetDirectory
{
    BOOL result = NO;
    NSFileManager *fm = [NSFileManager new];
    if ([fm fileExistsAtPath:zipFilePath])
    {
        if ([fm recursivelyCreatePath:targetDirectory])
        {
            ZZArchive *archive = [ZZArchive archiveWithContentsOfURL:[NSURL fileURLWithPath:zipFilePath]];
            result = [self unzipZZArchive:archive toDirectory:targetDirectory withFileManager:fm];
        } // recursivelyCreatePath already logs errors
    }
    else
    {
        [DQPapertrailLogger component:@"unzipper" category:@"unzip-zip-file-not-found" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"fname": zipFilePath ?: [NSNull null]};
        }];
    }
    return result;
}

+ (BOOL)unzipData:(NSData *)data toDirectory:(NSString *)targetDirectory
{
    BOOL result = NO;
    NSFileManager *fm = [NSFileManager new];
    if ([data length])
    {
        if ([fm recursivelyCreatePath:targetDirectory])
        {
            ZZArchive *archive = [ZZArchive archiveWithData:data];
            result = [self unzipZZArchive:archive toDirectory:targetDirectory withFileManager:fm];
        } // recursivelyCreatePath already logs errors
    }
    else
    {
        [DQPapertrailLogger component:@"unzipper" category:@"unzip-data-empty" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"data-is-null": data ? @NO : @YES};
        }];
    }
    return result;
}

+ (BOOL)unzipZZArchive:(ZZArchive *)archive toDirectory:(NSString *)targetDirectory withFileManager:(NSFileManager *)fm
{
    BOOL problemsFound = NO;
    for (ZZArchiveEntry *entry in archive.entries)
    {
        NSString *filename = entry.fileName;
        if ([filename length])
        {
            NSString *targetPath = [targetDirectory stringByAppendingPathComponent:filename];
            BOOL isFileEntry = !(entry.fileMode & S_IFDIR);
            if ([fm recursivelyCreatePath:targetPath lastComponentIsFile:isFileEntry])
            {
                if (isFileEntry)
                {
                    NSError *error = nil;
                    if ([[entry newData] writeToFile:targetPath options:0 error:&error])
                    {
                        NSURL *dataURL = [NSURL fileURLWithPath:targetPath];
                        [dataURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
                    }
                    else
                    {
                        problemsFound = YES;
                        [DQPapertrailLogger component:@"unzipper" category:@"unzip-write-failed" error:error dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                            return @{@"fname": targetPath ?: [NSNull null]};
                        }];
                        break;
                    }
                }
            }
            else // recursivelyCreatePath already logs errors
            {
                problemsFound = YES;
                break;
            }
        }
        else
        {
            problemsFound = YES;
            [DQPapertrailLogger component:@"unzipper" category:@"unzip-invalid-arguments" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"fname": filename ?: [NSNull null]};
            }];
            break;
        }
    }
    return !problemsFound;
}

@end
