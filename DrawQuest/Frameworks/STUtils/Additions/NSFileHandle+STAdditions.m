//
//  NSFileHandle+STAdditions.m
//
//  Created by Buzz Andersen on 7/16/12.
//  Copyright (c) 2012 System of Touch. All rights reserved.
//

#import "NSFileHandle+STAdditions.h"


@implementation NSFileHandle (STAdditions)

- (NSUInteger)writeUTF8StringWithFormat:(NSString *)inString, ...;
{
    va_list args;
    va_start(args, inString);
    
    NSUInteger result = [self writeUTF8StringWithFormat:inString arguments:args];
	
    va_end(args);
    return result;
}

- (NSUInteger)writeUTF8StringWithFormat:(NSString *)inString arguments:(va_list)inArguments;
{
    NSString *formattedString = [[NSString alloc] initWithFormat:inString arguments:inArguments];
    NSUInteger result = [self writeUTF8String:formattedString];
    [formattedString release];
    return result;
}

- (NSUInteger)writeUTF8String:(NSString *)inString;
{
    return [self writeString:inString withEncoding:NSUTF8StringEncoding];
}

- (NSUInteger)writeString:(NSString *)inString withEncoding:(NSStringEncoding)inEncoding;
{
    NSUInteger byteLength = [inString lengthOfBytesUsingEncoding:inEncoding];
    
    if (!byteLength) {
        return 0;
    }
    
    char *buffer = malloc(byteLength);
    
    NSUInteger usedLength = 0;
    if ([inString getBytes:buffer maxLength:byteLength usedLength:&usedLength encoding:inEncoding options:NSStringEncodingConversionExternalRepresentation range:NSMakeRange(0,byteLength) remainingRange:NULL]) {
        NSData *stringData = [[NSData alloc] initWithBytes:buffer length:usedLength];
        [self writeData:stringData];
        [stringData release];
    }
    
    free(buffer);
    return usedLength;
}

@end
