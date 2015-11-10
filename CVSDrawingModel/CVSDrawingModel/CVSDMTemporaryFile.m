// CVSDMTemporaryFile.m
// CVSDrawingModel
// Created by justin carlson on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

static const int CVSDMTemporaryFileInvalidFileNo = -1;

@interface CVSDMTemporaryFile () <CVSDMFileExportDestination>

@property (atomic, assign, readwrite) bool isFileAccessible;
@property (atomic, assign, readwrite) bool didExportData;
@end

@implementation CVSDMTemporaryFile

@synthesize isFileAccessible = _isFileAccessible;
@synthesize didExportData = _didExportData;

+ (NSURL *)createUniqueTemporaryFileWithParentDirectoryURL:(NSURL *)pParentDirectoryURL filePrefix:(NSString *)pFilePrefix
{
    assert(pParentDirectoryURL);
    assert(pFilePrefix);
    NSString * const filenameComponent = [NSString stringWithFormat:@"%@%s", pFilePrefix, "XXXXXX"];
    assert(filenameComponent);
    NSString * const directory = [NSString stringWithUTF8String:pParentDirectoryURL.fileSystemRepresentation];
    assert(directory);
    NSString * const format = [directory stringByAppendingPathComponent:filenameComponent];
    assert(format);
    const char* const fullFormatString = format.UTF8String;
    assert(fullFormatString);
    const size_t length = strlen(fullFormatString);
    if (!length) {
        assert(0 && "error composing temporary path name");
        return nil;
    }
    NSMutableData * const data = [NSMutableData dataWithBytes:fullFormatString length:1U + length];
    const int fd = mkstemp(data.mutableBytes);
    if (CVSDMTemporaryFileInvalidFileNo == fd) {
        assert(0 && "error creating temporary file");
        return nil;
    }
    const int e = close(fd);
    if (0 != e) {
        assert(0 && "error closing temporary file");
        return nil;
    }
    NSString * const path = [NSString stringWithUTF8String:data.bytes];
    if (!path) {
        assert(0 && "error getting temporary file's path");
        return nil;
    }
    NSURL * const result = [[NSURL alloc] initFileURLWithPath:path isDirectory:NO];
    if (!result) {
        assert(0 && "error converting path to URL");
        return nil;
    }
    return result;
}

// private initializer -- the real designated initializer
- (instancetype)initWithFileSystemIOQueue_private:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue fileURL:(NSURL *)pFileURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption isExistingFileURL:(bool)pIsExistingFileURL
{
    self = [super initWithFileSystemIOQueue:pFileSystemIOQueue URL:pFileURL removalOption:pRemovalOption];
    if (!self) {
        return nil;
    }
    if (pIsExistingFileURL) {
        _isFileAccessible = true;
    }
    return self;
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
#pragma unused(pFileSystemIOQueue)
#pragma unused(pURL)
#pragma unused(pRemovalOption)
    // this superclass initializer is deleted
    assert(0 && "deleted initializer called");
    return nil;
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue existingFileURL:(NSURL *)pExistingFileURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
    return [self initWithFileSystemIOQueue_private:pFileSystemIOQueue fileURL:pExistingFileURL removalOption:pRemovalOption isExistingFileURL:true];
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue parentDirectoryURL:(NSURL *)pParentDirectoryURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption dataProvider:(id<CVSDMFileExportDestinationDataProvider>)pDataProvider exportClosure:(CVSDMFileExportDestinationExportClosure)pExportClosure
{
    if (!pDataProvider || !pExportClosure) {
        assert(0 && "invalid parameter");
        return nil;
    }
    // create the temporary destination
    NSURL * const fileURL = [[self class] createUniqueTemporaryFileWithParentDirectoryURL:pParentDirectoryURL filePrefix:@""];
    assert(fileURL);
    if (!fileURL) {
        assert(0 && "failed to create temporary placeholder file");
        return nil;
    }
    // initialize self/super
    self = [self initWithFileSystemIOQueue_private:pFileSystemIOQueue fileURL:fileURL removalOption:pRemovalOption isExistingFileURL:false];
    if (!self) {
        return nil;
    }
    // enqueue the write
    id<CVSDMFileExportDestinationDataProvider> dataProvider = pDataProvider;
    CVSDMFileExportDestinationExportClosure closure = [pExportClosure copy];
    [pFileSystemIOQueue dispatch:^{
        @autoreleasepool {
            [dataProvider provideDataToExportDestination:self closure:closure];
            assert(self.didExportDataToDestination && "data provider failed to export or export failed");
        }
    }];
    return self;
}

- (void)exportDataToDestination:(NSData *)pData closure:(CVSDMFileExportDestinationExportClosure)pClosure
{
    assert(pData);
    assert(pClosure);
    assert(!self.isFileAccessible && "this object uses a write once mechanism");
    // access super's URL because self's URL is inaccessible
    if ([pData writeToURL:[super URL] atomically:NO])
    {
        [[super URL] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    else
    {
        assert(0 && "export failed");
        return;
    }
    assert(!self.isFileAccessible);
    // @todo the file should now be made readonly
    self.isFileAccessible = true;
    assert(false == self.didExportData);
    self.didExportData = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), pClosure);
}

// client can access the URL only if the export is complete
- (NSURL *)URL
{
    if (!self.isFileAccessible) {
        assert(0 && "request for file URL whose data has not yet been written");
        return nil;
    }
    NSURL * const result = [super URL];
    assert(result);
    return result;
}

- (CVSDMImmutableDataReference *)dataReference
{
    if (!self.isFileAccessible) {
        // the file has probably not completed writing
        assert(0 && "illegal attempt to access content of temporary file");
        return nil;
    }
    NSURL * const url = self.URL;
    assert(url);
    CVSDMImmutableDataReference * const data = [[CVSDMImmutableDataReference alloc] initWithDataAtURL:self.URL];
    assert(data);
    return data;
}

- (BOOL)didExportDataToDestination
{
    return self.didExportData;
}

@end
