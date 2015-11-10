// CVSDMTemporaryFileSystemResource.h
// CVSDrawingModel
// Created by J on 10/27/13.
// Copyright (c) 2013 Canvas. All rights reserved.

@interface CVSDMTemporaryFileSystemResource : NSObject

// designated initializer
- (instancetype)initWithFileSystemIOQueue:(CVSDMFileSystemIOQueue *)pFileSystemIOQueue URL:(NSURL *)pURL removalOption:(CVSDMTemporaryResourceRemovalOption)pRemovalOption;

/**
 @brief the resource's I/O queue
 */
@property (nonatomic, readonly) CVSDMFileSystemIOQueue * fileSystemIOQueue;

/**
 @brief the location of the directory self represents
 */
@property (nonatomic, readonly) NSURL * URL;

@end
