//
//  NSString+STAdditions.h
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (STAdditions)

// Whitespace
- (BOOL)containsWhitespace;
- (NSString *)trimLeadingAndTrailingWhiteSpace;
- (NSString *)trimLeadingWhiteSpace;
- (NSString *)trimTrailingWhiteSpace;

// Paths
- (NSString *)stringByRemovingLastPathComponent;

// URL Escaping
- (NSString *)stringByEscapingQueryParameters;
- (NSString *)stringByReplacingPercentEscapes;

// Templating
- (NSString *)stringByParsingTagsWithStartDelimeter:(NSString *)inStartDelimiter endDelimeter:(NSString *)inEndDelimiter usingObject:(id)object;

// Encoding
- (NSString *)stringUsingEncoding:(NSStringEncoding)encoding;

// Hashes
- (NSString *)MD5String;
- (NSData *)hmacSHA1DataValueWithKey:(NSData *)inKey;

// Encoding
- (NSString *)base58String;
- (NSString *)base64String;

// Obfuscation
- (NSString *)reverseString;

// UUIDs
+ (NSString *)UUIDString;

// Validation
- (BOOL)isEmailAddress;

// Dates
- (NSDate *)dateValueWithMillisecondsSince1970;
- (NSDate *)dateValueWithTimeIntervalSince1970;
- (NSDate *)ISO8601DateValue;

// File Output
/*- (BOOL)appendToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;
- (BOOL)appendLineToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;*/

// Drawing
#if TARGET_OS_IPHONE
- (CGSize)drawInRect:(CGRect)inRect withFont:(UIFont *)inFont color:(UIColor *)inColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset;
- (CGSize)drawInRect:(CGRect)inRect withFont:(UIFont *)inFont lineBreakMode:(NSLineBreakMode)inLineBreakMode color:(UIColor *)inColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset;
- (CGSize)drawInRect:(CGRect)inRect withFont:(UIFont *)inFont lineBreakMode:(NSLineBreakMode)inLineBreakMode alignment:(NSTextAlignment)alignment color:(UIColor *)inColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset;
#endif

@end
