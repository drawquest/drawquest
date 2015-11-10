//
//  NSFileManager+STAdditions.h
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (STAdditions)

// Support Directory Paths
- (NSString *)cachePath;
- (NSString *)cachePathIncludingAppName;
- (NSString *)cacheFileName:(NSString *)fileName;
- (NSString *)applicationSupportPath;
- (NSString *)applicationSupportPathIncludingAppName;
- (NSString *)applicationSupportFileName:(NSString *)fileName;

// Recursive Directory Creation
- (BOOL)createFreshPath:(NSString *)path;
- (BOOL)recursivelyCreatePath:(NSString *)inPath;
- (BOOL)recursivelyCreatePath:(NSString *)inPath lastComponentIsFile:(BOOL)isFile;

// File Attributes
- (unsigned long long)fileSizeAtPath:(NSString *)inPath;
- (NSDate *)modificationDateForFileAtPath:(NSString *)inPath;

@end
