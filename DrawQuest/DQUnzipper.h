//
//  DQUnzipper.h
//  DrawQuest
//
//  Created by Jim Roepcke on 12/5/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DQUnzipper : NSObject

+ (BOOL)unzipArchive:(NSString *)zipFilePath toDirectory:(NSString *)targetDirectory;
+ (BOOL)unzipData:(NSData *)data toDirectory:(NSString *)targetDirectory;

@end
