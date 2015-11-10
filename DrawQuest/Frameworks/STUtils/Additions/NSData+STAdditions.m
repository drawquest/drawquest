//
//  NSData+STAdditions.m
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSData+STAdditions.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+STBase64.h"

@implementation NSData (STAdditions)

#pragma mark Base 64 Encoding

- (id)initWithBase64String:(NSString *)string;
{
    self = [[NSData st_dataFromBase64String:string] retain];
    return self;
}

#pragma mark SHA1

- (NSString *)sha1DigestString
{
    NSString *result = nil;
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    if (CC_SHA1([self bytes], [self length], digest))
    {
        NSData *data = [NSData dataWithBytes:(digest) length:sizeof(digest)];
        result = [[data hexString] lowercaseString];
    }
    return result;
}

#pragma mark HMAC

- (NSData *)hmacSHA1DataValueWithKey:(NSData *)keyData;
{
    void* buffer = malloc(CC_SHA1_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA1, [keyData bytes], [keyData length], [self bytes], [self length], buffer);
    return [NSData dataWithBytesNoCopy:buffer length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
}

#pragma mark Hex Strings

- (NSString *)hexString;
{
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:self.length * 2];
    const unsigned char *dataBuffer = [self bytes];
    
    for (NSUInteger characterCounter = 0; characterCounter < self.length; ++characterCounter) {
        [stringBuffer appendFormat:@"%02lX", (unsigned long)dataBuffer[characterCounter]];
    }
    
    return [[stringBuffer copy] autorelease];    
}

#pragma mark UT8

- (NSString *)UTF8String;
{
    return [[[NSString alloc] initWithBytes:[self bytes] length:[self length] encoding:NSUTF8StringEncoding] autorelease];
}

@end


@implementation NSMutableData (STAdditions)

- (void)appendUTF8StringWithFormat:(NSString *)inString, ...;
{
    va_list args;
    va_start(args, inString);
    
    [self appendUTF8StringWithFormat:inString arguments:args];
	
    va_end(args);
}

- (void)appendUTF8StringWithFormat:(NSString *)inString arguments:(va_list)inArguments;
{
    NSString *formattedString = [[NSString alloc] initWithFormat:inString arguments:inArguments];
    [self appendUTF8String:formattedString];
    [formattedString release];
}

- (void)appendUTF8String:(NSString *)inString;
{
    [self appendString:inString withEncoding:NSUTF8StringEncoding];
}

- (void)appendString:(NSString *)inString withEncoding:(NSStringEncoding)inEncoding;
{
    NSUInteger byteLength = [inString lengthOfBytesUsingEncoding:inEncoding];
    
    if (!byteLength) {
        return;
    }
    
    char *buffer = malloc(byteLength);
    
    if ([inString getBytes:buffer maxLength:byteLength usedLength:NULL encoding:inEncoding options:NSStringEncodingConversionExternalRepresentation range:NSMakeRange(0,byteLength) remainingRange:NULL]) {
        [self appendBytes:buffer length:byteLength];
    }
    
    free(buffer);
}

@end