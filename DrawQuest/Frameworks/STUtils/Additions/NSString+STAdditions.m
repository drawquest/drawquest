//
//  NSString+STAdditions.m
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSString+STAdditions.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+STBase64.h"
#import "NSData+STAdditions.h"
#import "NSMutableString+STAdditions.h"
#import "NSString+STAdditions.h"

@implementation NSString (STAdditions)

#pragma mark Whitespace

- (BOOL)containsWhitespace;
{
    NSRange spaceRange = [self rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (spaceRange.location != NSNotFound);
}

- (NSString *)trimLeadingAndTrailingWhiteSpace;
{
    return [[self trimLeadingWhiteSpace] trimTrailingWhiteSpace];
}

- (NSString *)trimLeadingWhiteSpace;
{
    if (!self.length) {
        return @"";
    }
    
    NSInteger whiteSpaceIndex = 0;
    
    while (whiteSpaceIndex < self.length && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:whiteSpaceIndex]]) {
        ++whiteSpaceIndex;
    }
    
    return [self substringFromIndex:whiteSpaceIndex];
}

- (NSString *)trimTrailingWhiteSpace;
{
    if (!self.length) {
        return @"";
    }
    
    NSInteger whiteSpaceIndex = self.length - 1;
    
    while (whiteSpaceIndex >= 0 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:whiteSpaceIndex]]) {
        --whiteSpaceIndex;
    }
    
    return [self substringToIndex:whiteSpaceIndex + 1];
}

#pragma mark Paths

- (NSString *)stringByRemovingLastPathComponent;
{
    NSArray *pathComponents = [self pathComponents];
    NSMutableString *returnString = [[[NSMutableString alloc] init] autorelease];
    
    NSString *lastComponent = [pathComponents lastObject];
    for (NSString *currentComponent in pathComponents) {
        if (currentComponent == lastComponent) {
            break;
        }

        [returnString appendPathComponent:currentComponent];
    }
    
    return returnString;
}

#pragma mark URL Escaping

- (NSString *)stringByEscapingQueryParameters;
{
    // Changed to reflect http://en.wikipedia.org/wiki/Percent-encoding with the addition of the "%"
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]%"), kCFStringEncodingUTF8) autorelease];
}

- (NSString *)stringByReplacingPercentEscapes;
{
    return [(NSString*)CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)self, CFSTR("")) autorelease];
}

#pragma mark Templating

- (NSString *)stringByParsingTagsWithStartDelimeter:(NSString *)inStartDelimiter endDelimeter:(NSString *)inEndDelimiter usingObject:(id)object;
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    
    [scanner setCharactersToBeSkipped:nil];
    
    while (![scanner isAtEnd]) {
        NSString *tag;
        NSString *beforeText;
        
        if ([scanner scanUpToString:inStartDelimiter intoString:&beforeText]) {
            [result appendString:beforeText];
        }
        
        if ([scanner scanString:inStartDelimiter intoString:nil]) {
            if ([scanner scanString:inEndDelimiter intoString:nil]) {
                continue;
            } else if ([scanner scanUpToString:inEndDelimiter intoString:&tag] && [scanner scanString:inEndDelimiter intoString:nil]) {
                id keyValue = [object valueForKeyPath:[tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                if (keyValue != nil) {
                    [result appendFormat:@"%@", keyValue];
                }
            }
        }
    }
    
    return result;    
}

#pragma mark Encoding

- (NSString *)stringUsingEncoding:(NSStringEncoding)encoding;
{
    return [[[NSString alloc] initWithData:[self dataUsingEncoding:encoding allowLossyConversion:YES] encoding:encoding] autorelease];
}

#pragma mark Hashes

- (NSString *)MD5String;
{
	const char *string = [self UTF8String];
	unsigned char md5_result[16];
	CC_MD5(string, (CC_LONG)[self lengthOfBytesUsingEncoding:NSUTF8StringEncoding], md5_result);
    
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            md5_result[0], md5_result[1], md5_result[2], md5_result[3], 
            md5_result[4], md5_result[5], md5_result[6], md5_result[7],
            md5_result[8], md5_result[9], md5_result[10], md5_result[11],
            md5_result[12], md5_result[13], md5_result[14], md5_result[15]];	
}

- (NSData *)hmacSHA1DataValueWithKey:(NSData *)inKey;
{
    NSData *dataValue = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [dataValue hmacSHA1DataValueWithKey:inKey];
}

#pragma mark Encoding

- (NSString *)base58String;
{
	long long num = strtoll([self UTF8String], NULL, 10);
	
	NSString *alphabet = @"123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
	
	NSUInteger baseCount = [alphabet length];
	
	NSString *encoded = @"";
	
	while (num >= baseCount) {
		double div = num / baseCount;
		long long mod = (num - (baseCount * (long long)div));
		NSString *alphabetChar = [alphabet substringWithRange: NSMakeRange(mod, 1)];
		encoded = [NSString stringWithFormat: @"%@%@", alphabetChar, encoded];
		num = (long long)div;
	}
    
	if (num) {
		encoded = [NSString stringWithFormat:@"%@%@", [alphabet substringWithRange:NSMakeRange(num, 1)], encoded];
	}
    
	return encoded;	
}

- (NSString *)base64String;
{
    NSData *stringData = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [stringData st_base64EncodedString];
}

#pragma mark Obfuscation

-(NSString *)reverseString
{
    NSMutableString *reversedStr;
    NSUInteger len = [self length];
    
    reversedStr = [NSMutableString stringWithCapacity:len];     
    
    while (len > 0) {
        [reversedStr appendString:
         [NSString stringWithFormat:@"%C", [self characterAtIndex:--len]]];
    }
    
    return reversedStr;
}

#pragma mark UUIDs

+ (NSString *)UUIDString;
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *string = (NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    
    return [string autorelease];
}

#pragma mark Validation

- (BOOL)isEmailAddress;
{
    // emails can't have whitespace
    if ([self containsWhitespace]) {
        return NO;
    }
    
    // boot it immediately if it has more than one @ symbol
    // foo @ foo.com
    // foo @ foo @ foo . com
    if ([self componentsSeparatedByString:@"@"].count > 2) {
        return NO;
    }
    
    NSString *emailRegex = @"[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$";
    return [self rangeOfString:emailRegex options:NSRegularExpressionSearch].location != NSNotFound;
}

#pragma mark Dates

- (NSDate *)dateValueWithMillisecondsSince1970;
{
    return [NSDate dateWithTimeIntervalSince1970:[self doubleValue] / 1000];
}

- (NSDate *)dateValueWithTimeIntervalSince1970;
{
    return [NSDate dateWithTimeIntervalSince1970:[self doubleValue]];
}

// Adapted from Sam Soffes
// http://coding.scribd.com/2011/05/08/how-to-drastically-improve-your-app-with-an-afternoon-and-instruments/

- (NSDate *)ISO8601DateValue;
{
    if (!self.length) {
        return nil;
    }
    
    struct tm tm;
    time_t t;    
    
    strptime([self cStringUsingEncoding:NSUTF8StringEncoding], "%Y-%m-%dT%H:%M:%S%z", &tm);
    tm.tm_isdst = -1;
    t = mktime(&tm);
    
    return [NSDate dateWithTimeIntervalSince1970:t + [[NSTimeZone localTimeZone] secondsFromGMT]];
}

#pragma mark File Output

/*- (BOOL)appendLineToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;
{
    if (!self.length) {
        return NO;
    }
    
    NSString *newLineString = self;
    
    if ([self characterAtIndex:[self length] - 1] != '\n') {
        newLineString = [self stringByAppendingString:@"\n"];
    }
    
    return [newLineString appendToFile:path atomically:useAuxiliaryFile usingEncoding:encoding error:error];
}

- (BOOL)appendToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fileHandle) {
        return [self writeToFile:path atomically:useAuxiliaryFile encoding:encoding error:error];
    }
    
    [fileHandle truncateFileAtOffset:[fileHandle seekToEndOfFile]];
    NSData *encodedData = [self dataUsingEncoding:encoding];
    
    if (!encodedData) {
        return NO;
    }
    
    [fileHandle writeData:encodedData];
    return YES;
}*/

#pragma mark Drawing

#if TARGET_OS_IPHONE

- (CGSize)drawInRect:(CGRect)inRect withFont:(UIFont *)inFont color:(UIColor *)inColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset;
{
    return [self drawInRect:inRect withFont:inFont lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentLeft color:inColor shadowColor:inShadowColor shadowOffset:inShadowOffset];
}

- (CGSize)drawInRect:(CGRect)inRect withFont:(UIFont *)inFont lineBreakMode:(NSLineBreakMode)inLineBreakMode color:(UIColor *)inColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset;
{
    return [self drawInRect:inRect withFont:inFont lineBreakMode:inLineBreakMode alignment:NSTextAlignmentLeft color:inColor shadowColor:inShadowColor shadowOffset:inShadowOffset];
}

- (CGSize)drawInRect:(CGRect)inRect withFont:(UIFont *)inFont lineBreakMode:(NSLineBreakMode)inLineBreakMode alignment:(NSTextAlignment)inAlignment color:(UIColor *)inColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset;
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, inShadowOffset, 0.0, inShadowColor.CGColor);
    CGContextSetFillColorWithColor(context, inColor.CGColor);
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    paragraphStyle.alignment = inAlignment;
    paragraphStyle.lineBreakMode = inLineBreakMode;
    NSDictionary *attributes = @{NSFontAttributeName: inFont, NSParagraphStyleAttributeName: paragraphStyle};
    [self drawInRect:inRect withAttributes:attributes];
    CGSize renderedSize = [self sizeWithAttributes:attributes];
    CGContextRestoreGState(context);

    return renderedSize;
}

#endif

@end
