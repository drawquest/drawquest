// CVSDMImmutableDataReference.m
// CVSDrawingModel
// Created by justin carlson on 10/21/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"

@implementation CVSDMImmutableDataReference
{
    NSData * data;
    NSURL * URL;
}

- (instancetype)initWithData:(NSData *)pData
{
    self = [super init];
    if (!self) {
        return nil;
    }
    data = pData.copy;
    if (!data) {
        return nil;
    }
    return self;
}

- (instancetype)initWithDataAtURL:(NSURL *)pURL
{
    self = [super init];
    if (!self) {
        return nil;
    }
    NSError * __autoreleasing outError = nil;
    data = [[NSData alloc] initWithContentsOfURL:pURL options:NSDataReadingMappedAlways error:&outError];
    if (!data) {
        return nil;
    }
    if (outError) {
        assert(0 && "error reading data at URL");
        return nil;
    }
    URL = pURL.copy;
    return self;
}

- (NSData *)data
{
    return data;
}

- (NSURL *)URL
{
    return URL;
}

@end
