// CVSDMImmutableDataReference.h
// CVSDrawingModel
// Created by justin carlson on 10/21/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief represents a resource which is read-only. many of the designs lean on immutability, so this type is a good way to reduce physical memory consumption and can improve I/O times.
 @details this is a NSData wrapper, but is intended to be a general purpose base or a component used in I/O routines.
 */
@interface CVSDMImmutableDataReference : NSObject

// designated initializer
- (instancetype)initWithData:(NSData *)pData;

/**
 @brief initializes self with the data at the specified URL
 */
- (instancetype)initWithDataAtURL:(NSURL *)pURL;

/**
 @return the NSData self represents.
 */
- (NSData *)data;

/**
 @return the reference URL if the origin is known, else nil.
 @details be aware of cases where you may use a link rather than a physical copy.
 */
- (NSURL *)URL;

@end
