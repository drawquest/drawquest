// CVSDMTemporaryDirectory.m
// CVSDrawingModel
// Created by J on 10/26/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

@interface CVSDMTemporaryDirectory ()

@end

@implementation CVSDMTemporaryDirectory

+ (NSURL *)systemTemporaryDirectory
{
    return [[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
}

+ (NSURL *)createUniqueTemporaryDirectoryInParentDirectory:(NSURL *)pParentDirectory
{
    return [self createUniqueTemporaryDirectoryInParentDirectory:pParentDirectory directoryPrefix:@""];
}

+ (NSURL *)createUniqueTemporaryDirectoryInParentDirectory:(NSURL *)pParentDirectory directoryPrefix:(NSString *)pDirectoryPrefix
{
    if (!pParentDirectory || !pDirectoryPrefix) {
        assert(0 && "invalid parameter");
        return nil;
    }
    {
        __strong NSError * outError = nil;
        if (![pParentDirectory checkResourceIsReachableAndReturnError:&outError]) {
            assert(0 && "invalid parent directory");
            return nil;
        }
        if (nil != outError) {
            assert(0 && "error checking validity of directory URL");
            return nil;
        }
    }

    NSString * const temporaryDirectory = [NSString stringWithUTF8String:pParentDirectory.fileSystemRepresentation].stringByStandardizingPath;
    assert(temporaryDirectory);
    const char Suffix[] = "XXXXXX";
    NSString * const component = [NSString stringWithFormat:@"%@%s", pDirectoryPrefix, Suffix];
    assert(component);
    NSString * const format = [temporaryDirectory stringByAppendingPathComponent:component];
    assert(format);
    const char* const fileSystemRepresentation = format.UTF8String;
    assert(fileSystemRepresentation);
    const size_t len = strlen(fileSystemRepresentation);
    assert(len);
    NSMutableData * const utf = [NSMutableData dataWithBytes:fileSystemRepresentation length:1 + len];
    assert(utf);
    const char* root = mkdtemp(utf.mutableBytes);
    if (!root) {
        assert(0 && "error creating temporary directory");
        return nil;
    }
    NSString * const path = [NSString stringWithUTF8String:root];
    if (!path) {
        assert(0 && "error converting temporary directory string");
        return nil;
    }
    NSURL * const result = [[NSURL alloc] initFileURLWithPath:path isDirectory:YES];
    assert(result);
    return result;
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
    return [super initWithFileSystemIOQueue:pFileSystemIOQueue URL:pURL removalOption:pRemovalOption];
}

+ (instancetype)temporaryDirectoryWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
    return [[self alloc] initWithFileSystemIOQueue:pFileSystemIOQueue URL:pURL removalOption:pRemovalOption];
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
    NSURL * const tmp = [[self class] systemTemporaryDirectory];
    assert(tmp);
    NSURL * const url = [[self class] createUniqueTemporaryDirectoryInParentDirectory:tmp];
    assert(url);
    return [self initWithFileSystemIOQueue:pFileSystemIOQueue URL:url removalOption:pRemovalOption];
}

+ (instancetype)temporaryDirectoryWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
    return [[self alloc] initWithFileSystemIOQueue:pFileSystemIOQueue removalOption:pRemovalOption];
}

@end
