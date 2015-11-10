// CVSDMImageSnapshot.h
// CVSDrawingModel
// Created by justin carlson on 10/24/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief defines an index/depth in the snapshot stack
 */
typedef uint32_t CVSDMImageSnapshotIndex;

/**
 @class defines an image snapshot.
 @details note that this is a temporary V2 compatibility implementation.
 */
@interface CVSDMImageSnapshot : NSObject

/**
 @return a new instance which associates the snapshot index with a URL. when self is deallocated, the resource at the URL specified is removed. designated initializer.
 */
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue
                       parentDirectoryURL:(NSURL *)pParentDirectoryURL
                       imageSnapshotQueue:(CVSDMImageSnapshotQueue *)pImageSnapshotQueue
                       imageSnapshotIndex:(CVSDMImageSnapshotIndex)pImageSnapshotIndex
                             dataProvider:(id<CVSDMFileExportDestinationDataProvider>)pDataProvider
                            exportClosure:(CVSDMFileExportDestinationExportClosure)pExportClosure;

/**
 @return the image snapshot index self was given at initialization.
 */
- (CVSDMImageSnapshotIndex)imageSnapshotIndex;

//// I/O ////

/**
 @return YES if the data reference is accessible. a data reference may not be accessible if it's not yet completed writing.
 */
- (BOOL)isDataReferenceAccessible;

/**
 @return a data reference to the previously written file. note that the data reference is held by self by default. you can dispose it using -disposeDataReference.
 @details the data is memory mapped, where possible.
 */
- (CVSDMImmutableDataReference *)dataReference;

@end
