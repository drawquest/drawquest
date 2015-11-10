//
//  NSFileHandle+STAdditions.h
//
//  Created by Buzz Andersen on 7/16/12.
//  Copyright (c) 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileHandle (STAdditions)

- (NSUInteger)writeUTF8String:(NSString *)inString;
- (NSUInteger)writeUTF8StringWithFormat:(NSString *)inString, ...;
- (NSUInteger)writeUTF8StringWithFormat:(NSString *)inString arguments:(va_list)inArguments;
- (NSUInteger)writeString:(NSString *)inString withEncoding:(NSStringEncoding)inEncoding;

@end
