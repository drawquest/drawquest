// CVSDMTemporaryFileSystemResource.m
// CVSDrawingModel
// Created by J on 10/27/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

static void ValidateCVSDMTemporaryResourceRemovalOption(const CVSDMTemporaryResourceRemovalOption pRemovalOption) {
    switch (pRemovalOption) {
        case CVSDMTemporaryResourceRemovalOption_Remove :
        case CVSDMTemporaryResourceRemovalOption_DoNotRemove :
            return;

        case CVSDMTemporaryResourceRemovalOption_Undefined :
            break;
    }
    assert(0 && "invalid removal option");
}

@interface CVSDMTemporaryFileSystemResource ()

@end

@implementation CVSDMTemporaryFileSystemResource
{
    CVSDMTemporaryResourceRemovalOption removalOption;
}

@synthesize fileSystemIOQueue = _fileSystemIOQueue;
@synthesize URL = _URL;

- (id)init
{
    assert(0 && "invalid initializer");
    return nil;
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption
{
    ValidateCVSDMTemporaryResourceRemovalOption(pRemovalOption);
    self = [super init];
    if (!self) {
        return nil;
    }
    _fileSystemIOQueue = pFileSystemIOQueue;
    _URL = pURL.copy;
    if (!_fileSystemIOQueue || !_URL) {
        assert(0 && "invalid parameter");
        return nil;
    }
    removalOption = pRemovalOption;
    return self;
}

- (void)dealloc
{
    if (CVSDMTemporaryResourceRemovalOption_Remove == removalOption) {
        [self.fileSystemIOQueue removeItemAtURL:self.URL];
        _URL = nil;
    }
}

@end
