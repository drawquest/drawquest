//
//  NSDictionary+STAdditions.m
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSDictionary+STAdditions.h"
#import "NSDate+STAdditions.h"
#import "NSObject+STAdditions.h"
#import "NSString+STAdditions.h"

@implementation NSDictionary (STAdditions)

#pragma mark URL Parameter Strings

+ (NSDictionary *)dictionaryWithURLEncodedString:(NSString *)urlEncodedString;
{
    NSMutableDictionary *mutableResponseDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    // split string by &s
    NSArray *encodedParameters = [urlEncodedString componentsSeparatedByString:@"&"];
    for (NSString *parameter in encodedParameters) {
        NSArray *keyValuePair = [parameter componentsSeparatedByString:@"="];
        if (keyValuePair.count == 2) {
            NSString *key = [[keyValuePair objectAtIndex:0] stringByReplacingPercentEscapes];
            NSString *value = [[keyValuePair objectAtIndex:1] stringByReplacingPercentEscapes];
            [mutableResponseDictionary setObject:value forKey:key];
        }
    }
    return mutableResponseDictionary;
}

- (NSString *)URLEncodedStringValue;
{
	if (self.count < 1) {
        return @"";
    }
	
	NSEnumerator *keyEnum = [self keyEnumerator];
	NSString *currentKey;
	
	BOOL appendAmpersand = NO;
	
	NSMutableString *parameterString = [[NSMutableString alloc] init];
	
	while ((currentKey = (NSString *)[keyEnum nextObject]) != nil) {
		id currentValue = [self objectForKey:currentKey];
		NSString *stringValue = [currentValue URLParameterStringValue];
		
		if (stringValue != nil) {
			if (appendAmpersand) {
				[parameterString appendString: @"&"];
			}
			
			NSString *escapedStringValue = [stringValue stringByEscapingQueryParameters];
			
			[parameterString appendFormat: @"%@=%@", currentKey, escapedStringValue];			
		}
		
		appendAmpersand = YES;
	}
	
	return [parameterString autorelease];
}

- (NSString *)URLEncodedQuotedKeyValueListValue;
{
	if (self.count < 1) {
        return @"";
    }
	
	NSEnumerator *keyEnum = [self keyEnumerator];
	NSString *currentKey;
	
	BOOL appendComma = NO;
	
	NSMutableString *listString = [[NSMutableString alloc] init];
	
	while ((currentKey = (NSString *)[keyEnum nextObject]) != nil) {
		id currentValue = [self objectForKey:currentKey];
		NSString *stringValue = [currentValue URLParameterStringValue];
		
		if (stringValue != nil) {
			if (appendComma) {
				[listString appendString: @", "];
			}
			
			NSString *escapedStringValue = [stringValue stringByEscapingQueryParameters];
			[listString appendFormat: @"%@=\"%@\"", currentKey, escapedStringValue];			
		}
		
		appendComma = YES;
	}
	
	return [listString autorelease];
}

#pragma mark Sorting

- (NSArray *)sortedKeys;
{
    return [[self allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSArray *)sortedArrayUsingKeyValues;
{
	NSArray *sortedKeys = [self sortedKeys];
	NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
	
	id currentKey;
	
	for (currentKey in sortedKeys) {
		[returnArray addObject:[self objectForKey:currentKey]];
	}
	
	return returnArray;
}

#pragma mark Convenience Accessors

- (id)safeObjectForKey:(id)key;
{
    id object = [self objectForKey:key];
    
    if (object && [[NSNull null] isEqual:object]) {
        object = nil;
    }
    
    return object;
}

- (id)safeObjectForKey:(id)key withClass:(Class)classType;
{
    id object = [self safeObjectForKey:key];
    return [object isKindOfClass:classType] ? object : nil;
}

- (NSDictionary *)dictionaryForKey:(id)key;
{
    return [self safeObjectForKey:key withClass:[NSDictionary class]];
}

- (NSArray *)arrayForKey:(id)key;
{
    return [self safeObjectForKey:key withClass:[NSArray class]];
}

- (NSString *)stringForKey:(id)key;
{
    id object = [self safeObjectForKey:key];
    
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [object stringValue];
    } else if ([object isKindOfClass:[NSURL class]]) {
        return [object absoluteString];
    } else if ([object isKindOfClass:[NSData class]]) {
        return [object base64String];
    } else if ([object isKindOfClass:[NSDate class]]) {
        return [object ISO8601String];
    }
    
    return nil;
}

- (NSNumber *)numberForKey:(id)key;
{
    id object = [self safeObjectForKey:key];
    
    if ([object isKindOfClass:[NSNumber class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        return [NSDecimalNumber decimalNumberWithString:object];
    }
    
    return nil;
}

- (NSData *)dataForKey:(id)key;
{
    id object = [self safeObjectForKey:key];
    
    if ([object isKindOfClass:[NSData class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        return [object dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSDate *)dateForKey:(id)key;
{
    id object = [self safeObjectForKey:key];
    
    if ([object isKindOfClass:[NSDate class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        return [object ISO8601DateValue];
    }
    
    return nil;
}

- (NSURL *)URLForKey:(id)key;
{
    id object = [self safeObjectForKey:key];
    
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)object;
        
        if (string.length) {
            return [NSURL URLWithString:string];
        }
    } else if ([object isKindOfClass:[NSURL class]]) {
        return object;
    }
    
    return nil;
}

- (BOOL)boolForKey:(id)key;
{
    id object = [self safeObjectForKey:key];
    return ([object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSString class]]) && [object boolValue];
}

- (float)floatForKey:(id)key;
{
    return [[self numberForKey:key] floatValue];
}

- (double)doubleForKey:(id)key;
{
    return [[self numberForKey:key] doubleValue];
}

- (NSUInteger)unsignedIntegerForKey:(id)key;
{
    return [[self numberForKey:key] unsignedIntegerValue];
}

- (NSInteger)integerForKey:(id)key;
{
    return [[self numberForKey:key] integerValue];
}

@end


@implementation NSMutableDictionary (CCAdditions)

- (BOOL)ifNotNilSetObject:(id)object forKey:(id)key;
{
    if (!key) {
        return NO;
    }

    if (!object) {
        object = [NSNull null];
    }

    [self setObject:object forKey:key];
    return YES;
}

- (BOOL)setSafeObject:(id)object forKey:(id)key;
{
    if (!key) {
        return NO;
    }
    
    if (!object) {
        object = [NSNull null];
    }
    
    [self setObject:object forKey:key];
    return YES;
}

- (void)setObject:(id)object forRetainedKey:(id)key;
{
    CFDictionarySetValue((CFMutableDictionaryRef)self, key, object);
}

- (void)addUniqueEntriesFromDictionary:(NSDictionary *)inDictionary;
{
    NSArray *keys = [inDictionary allKeys];
    
    for (NSString *currentKey in keys) {
        if (![self objectForKey:currentKey]) {
            id object = [inDictionary objectForKey:currentKey];
            [self setObject:object forKey:currentKey];
        }
    }
}

@end