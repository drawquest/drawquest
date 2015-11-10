// CVSDMImageSnapshot.m
// CVSDrawingModel
// Created by justin carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"
#import "CVSDMImageSnapshot.h"
#import "CVSDMImageSnapshotQueue-Private_CVSDMImageSnapshot.h"

@interface CVSDMImageSnapshot ()

@property (nonatomic, strong, readwrite) NSURL * parentDirectoryURL;
@property (nonatomic, strong, readwrite) CVSDMTemporaryFile * temporaryFile;
@property (nonatomic, strong, readwrite) CVSDMImageSnapshotQueue * imageSnapshotQueue;
@property (nonatomic, assign, readwrite) CVSDMImageSnapshotIndex imageSnapshotIndex;
@property (nonatomic, strong, readwrite) CVSDMImmutableDataReference * privateDataReference;

@end

@implementation CVSDMImageSnapshot

@synthesize parentDirectoryURL = _parentDirectoryURL;
@synthesize temporaryFile = _temporaryFile;
@synthesize imageSnapshotQueue = _imageSnapshotQueue;
@synthesize imageSnapshotIndex = _imageSnapshotIndex;
@synthesize privateDataReference = _privateDataReference;

- (id)init
{
    assert(0 && "invalid initializer");
    return nil;
}

- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue
                       parentDirectoryURL:(NSURL *)pParentDirectoryURL
                       imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
                       imageSnapshotIndex:(CVSDMImageSnapshotIndex)pImageSnapshotIndex
                             dataProvider:(id<CVSDMFileExportDestinationDataProvider>)pDataProvider
                            exportClosure:(CVSDMFileExportDestinationExportClosure)pExportClosure
{
    self = [super init];
    if (!self) {
        assert(0 && "init error");
        return nil;
    }
    _parentDirectoryURL = pParentDirectoryURL.copy;
    _temporaryFile = [[CVSDMTemporaryFile alloc] initWithFileSystemIOQueue:pFileSystemIOQueue
                                                        parentDirectoryURL:pParentDirectoryURL
                                                             removalOption:CVSDMTemporaryResourceRemovalOption_Remove
                                                              dataProvider:pDataProvider
                                                             exportClosure:pExportClosure
                      ];
    _imageSnapshotQueue = pImageSnapshotQueue;
    _imageSnapshotIndex = pImageSnapshotIndex;
    if (!_parentDirectoryURL || !_temporaryFile || !_imageSnapshotQueue || !_imageSnapshotIndex) {
        assert(0 && "invalid parameter");
        return nil;
    }
    return self;
}

- (void)dealloc
{
    @autoreleasepool {
        [self disposeDataReference];
        self.temporaryFile = nil;
    }
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ | %i | %@", [super debugDescription], (int)self.imageSnapshotIndex, self.temporaryFile];
}

- (BOOL)isDataReferenceAccessible
{
    return self.temporaryFile.isFileAccessible;
}

- (CVSDMImmutableDataReference *)dataReference
{
    return self.temporaryFile.dataReference;
}

- (void)disposeDataReference
{
    if (!self.privateDataReference) {
        return;
    }

    @autoreleasepool {
        self.privateDataReference = nil;
    }
}

@end
