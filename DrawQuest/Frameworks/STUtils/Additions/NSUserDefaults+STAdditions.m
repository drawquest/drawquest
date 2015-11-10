//
//  NSUserDefaults+STAddtions.m
//
//  Created by Buzz Andersen on 3/7/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSUserDefaults+STAdditions.h"
#import "NSDictionary+STAdditions.h"

@implementation NSUserDefaults (STAdditions)

#pragma mark Account Management Methods

- (NSMutableDictionary *)accountsInfo;
{
	NSMutableDictionary *accountsInfo = [[self dictionaryForKey:@"UserDefaultAccountsInfo"] mutableCopy];
    
    if (!accountsInfo) {
        accountsInfo = [[NSMutableDictionary alloc] init];
    }
    
    return [accountsInfo autorelease];
}

- (void)setAccountsInfo:(NSDictionary *)newAccountsInfo;
{
    [self setObject:newAccountsInfo forKey:@"UserDefaultAccountsInfo"];
}

- (NSMutableDictionary *)defaultsForAccountWithName:(NSString *)accountName;
{
    NSMutableDictionary *accountDefaults = [[[self accountsInfo] objectForKey:[accountName lowercaseString]] mutableCopy];
    return [accountDefaults autorelease];
}

- (void)setDefaults:(NSDictionary *)defaults forAccountWithName:(NSString *)accountName;
{
    NSMutableDictionary *accountsInfo = [self accountsInfo];
    
    if (!accountsInfo) {
        accountsInfo = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    [accountsInfo setObject:defaults forKey:[accountName lowercaseString]];
    [self setAccountsInfo:accountsInfo];
}

- (void)removeAccountWithName:(NSString *)accountName;
{
    NSMutableDictionary *accountsInfo = [self accountsInfo];
    [accountsInfo removeObjectForKey:[accountName lowercaseString]];
    [self setAccountsInfo:accountsInfo];
}

- (NSArray *)accountsList;
{
    return [[self accountsInfo] sortedArrayUsingKeyValues];
}

- (BOOL)accountExistsForName:(NSString *)accountName;
{
	NSArray *accounts = [[self accountsInfo] allKeys];
	
    if (!accountName || accounts.count < 1) return NO;
    
	NSString *currentAccountName;
	
	for (currentAccountName in accounts) {
		if ([[accountName lowercaseString] isEqualToString: [currentAccountName lowercaseString]]) {
			return YES;
		}
	}
	
	return NO;
}

#pragma mark Basic Object Persistence Methods

- (void)setObject:(id)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    if (!accountName.length) {
        return [self setObject:value forKey:defaultKey];
    }
    
    NSMutableDictionary *accountDefaults = [self defaultsForAccountWithName:accountName];
    
    if (!accountDefaults) {
        accountDefaults = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    if (!value) {
        [accountDefaults removeObjectForKey:defaultKey];
    } else {
        [accountDefaults setObject:value forKey:defaultKey];
    }
    
    [self setDefaults:accountDefaults forAccountWithName:accountName];
}

- (id)objectForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    if (!accountName.length) {
        return [self objectForKey:defaultKey];
    }
    
    id value = [[self defaultsForAccountWithName:accountName] objectForKey:defaultKey];
    
    if (!value) {
        value = [self objectForKey:defaultKey];
    }
    
    return value;
}

- (void)removeObjectForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    if (!accountName.length) {
        [self removeObjectForKey:defaultKey];
    }
    
    NSMutableDictionary *accountDefaults = [self defaultsForAccountWithName:accountName];
    [accountDefaults removeObjectForKey:defaultKey];
    [self setDefaults:accountDefaults forAccountWithName:accountName];
}

#pragma mark Convenience Primitive Setters

- (void)setBool:(BOOL)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    NSNumber *numberValue = @(value);
    [self setObject:numberValue forKey:defaultKey forAccountWithName:accountName];
}

- (void)setDouble:(double)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    NSNumber *numberValue = @(value);
    [self setObject:numberValue forKey:defaultKey forAccountWithName:accountName];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    NSNumber *numberValue = @(value);
    [self setObject:numberValue forKey:defaultKey forAccountWithName:accountName];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    NSNumber *numberValue = @(value);
    [self setObject:numberValue forKey:defaultKey forAccountWithName:accountName];
}

#pragma mark Convenience Primitive Getters

- (BOOL)boolForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];

    return !(!value || ![value isKindOfClass:[NSNumber class]]) && [(NSNumber *)value boolValue];

}

- (double)doubleForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return 0.0;
    }
    
    return [(NSNumber *)value doubleValue];    
}

- (float)floatForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return 0.0F;
    }
    
    return [(NSNumber *)value floatValue];
}

- (NSInteger)integerForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return 0;
    }
    
    return [(NSNumber *)value integerValue];
}

#pragma mark Convenience Object Getters

- (NSDictionary *)dictionaryForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];
    
    if (!value || ![value isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return (NSDictionary *)value;
}

- (NSArray *)arrayForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];
    
    if (!value || ![value isKindOfClass:[NSArray class]]) {
        return nil;
    }   
    
    return (NSArray *)value;
}

- (NSData *)dataForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
{
    id value = [self objectForKey:defaultKey forAccountWithName:accountName];
    
    if (!value || ![value isKindOfClass:[NSData class]]) {
        return nil;
    }   
    
    return (NSData *)value;
}

@end
