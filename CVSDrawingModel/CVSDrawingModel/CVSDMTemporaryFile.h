// CVSDMTemporaryFile.h
// CVSDrawingModel
// Created by justin carlson on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief represents a temporary file
 */
@interface CVSDMTemporaryFile : CVSDMTemporaryFileSystemResource

/**
 @brief creates an empty temporary file in the specified directory URL, closes the file, and returns the URL of the file.
 */
+ (NSURL *)createUniqueTemporaryFileWithParentDirectoryURL:(NSURL *)pParentDirectoryURL filePrefix:(NSString *)pFilePrefix;

/**
 @brief initializes self to refer to a client supplied file-url. if you choose this initializer, the resource must exist and be reachable.
 @details the implementation does not verify that the client-supplied file is reachable at initialization.
 */
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue existingFileURL:(NSURL *)pExistingFileURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption;

/**
 @brief if you choose this initializer, the instance uses a newly generated (empty) temporary file.
 */
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue parentDirectoryURL:(NSURL *)pParentDirectoryURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption dataProvider:(id<CVSDMFileExportDestinationDataProvider>)pDataProvider exportClosure:(CVSDMFileExportDestinationExportClosure)pExportClosure;

/**
 @brief a file is immediately accessible if the client provided the file. otherwise, it is accessible only after it has been written.
 */
- (bool)isFileAccessible;

/**
 @brief this implementation is overridden because the implementation requires that the file is "accessible" before you can access it.
 */
- (NSURL *)URL;

/**
 @return the immutable data reference. the file must be accessible.
 */
- (CVSDMImmutableDataReference *)dataReference;

@end
