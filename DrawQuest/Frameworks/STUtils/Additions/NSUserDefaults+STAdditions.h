//
//  NSUserDefaults+STAdditions.h
//
//  Created by Buzz Andersen on 3/7/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSUserDefaults (STAdditions)

#pragma mark Account Management Methods
- (NSMutableDictionary *)accountsInfo;
- (void)setAccountsInfo:(NSDictionary *)newAccountSpecificDefaults;
- (NSMutableDictionary *)defaultsForAccountWithName:(NSString *)accountName;
- (void)setDefaults:(NSDictionary *)defaults forAccountWithName:(NSString *)accountName;
- (void)removeAccountWithName:(NSString *)accountName;
- (NSArray *)accountsList;
- (BOOL)accountExistsForName:(NSString *)accountName;

#pragma mark Basic Object Persistence Methods
- (id)objectForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (void)setObject:(id)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (void)removeObjectForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;

#pragma mark Convenience Primitive Setters
- (void)setBool:(BOOL)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (void)setDouble:(double)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (void)setFloat:(float)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;

#pragma mark Convencience Primitive Getters
- (BOOL)boolForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (double)doubleForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (float)floatForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (NSInteger)integerForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;

#pragma mark Convencience Object Getters
- (NSDictionary *)dictionaryForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (NSArray *)arrayForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;
- (NSData *)dataForKey:(NSString *)defaultKey forAccountWithName:(NSString *)accountName;

@end
