// CVSDMTemporaryDirectory.h
// CVSDrawingModel
// Created by J on 10/26/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @class represents a temporary directory. option to delete at dealloc is also provided.
 */
@interface CVSDMTemporaryDirectory : CVSDMTemporaryFileSystemResource

/**
 @return the system's temporary directory
 */
+ (NSURL *)systemTemporaryDirectory;

/**
 @return a newly created directory located in @p pParentDirectory with the prefix @p pDirectoryPrefix and with 6 random characters. nil parameters are not permitted, but the prefix may be empty.
 */
+ (NSURL *)createUniqueTemporaryDirectoryInParentDirectory:(NSURL *)pParentDirectory directoryPrefix:(NSString *)pDirectoryPrefix;

/**
 @brief like +createUniqueTemporaryDirectoryInParentDirectory:directoryPrefix:, but omits the directory prefix.
 */
+ (NSURL *)createUniqueTemporaryDirectoryInParentDirectory:(NSURL *)pParentDirectory;

/**
 @brief initializes a temporary directory instance at the URL specified (which the client creates).
 */
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption;
+ (instancetype)temporaryDirectoryWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption;

/**
 @brief creates a temporary directory in +systemTemporaryDirectory.
 */
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption;
+ (instancetype)temporaryDirectoryWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption;

@end
