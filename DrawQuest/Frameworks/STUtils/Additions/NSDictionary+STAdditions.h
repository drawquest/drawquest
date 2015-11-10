//
//  NSDictionary+STAdditions.h
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (STAdditions)

#pragma mark URL Parameter Strings
+ (NSDictionary *)dictionaryWithURLEncodedString:(NSString *)urlEncodedString;
- (NSString *)URLEncodedStringValue;
- (NSString *)URLEncodedQuotedKeyValueListValue;

#pragma mark Sorting
- (NSArray *)sortedKeys;
- (NSArray *)sortedArrayUsingKeyValues;

#pragma mark Convenience Accessors
- (id)safeObjectForKey:(id)key;
- (id)safeObjectForKey:(id)key withClass:(Class)classType;
- (NSDictionary *)dictionaryForKey:(id)key;
- (NSArray *)arrayForKey:(id)key;
- (NSString *)stringForKey:(id)key;
- (NSNumber *)numberForKey:(id)key;
- (NSData *)dataForKey:(id)key;
- (NSDate *)dateForKey:(id)key;
- (NSURL *)URLForKey:(id)key;
- (BOOL)boolForKey:(id)key;
- (float)floatForKey:(id)key;
- (double)doubleForKey:(id)key;
- (NSUInteger)unsignedIntegerForKey:(id)key;
- (NSInteger)integerForKey:(id)key;

@end


@interface NSMutableDictionary (CCAdditions)

// only sets if object is not nil
- (BOOL)ifNotNilSetObject:(id)object forKey:(id)key;

// converts nil objects to [NSNull null] before setting
- (BOOL)setSafeObject:(id)object forKey:(id)key;
- (void)setObject:(id)object forRetainedKey:(id)key;

- (void)addUniqueEntriesFromDictionary:(NSDictionary *)inDictionary;

@end
